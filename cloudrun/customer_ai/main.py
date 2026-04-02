"""
Customer AI Processor — Cloud Run service.

BQ ML chunked approach: reads all customers, splits into chunks of CHUNK_SIZE,
runs ML.GENERATE_TEXT per chunk via BigQuery (completes in seconds each),
processes CHUNK_PARALLEL chunks concurrently.

Fire-and-forget: POST /process returns 202 immediately; background thread runs.
GET /status polls progress every 30s from the workflow.

Environment variables:
  GOOGLE_CLOUD_PROJECT  — set automatically by Cloud Run
  CHUNK_SIZE            — rows per BQ ML call (default: 1000)
  CHUNK_PARALLEL        — concurrent BQ ML jobs (default: 3)
"""

import io
import json
import logging
import os
import re
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone

from flask import Flask, jsonify
from google.cloud import bigquery

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
PROJECT_ID     = os.environ.get("GOOGLE_CLOUD_PROJECT", "vishal-sandpit-474523")
CHUNK_SIZE     = int(os.environ.get("CHUNK_SIZE",     "1000"))
CHUNK_PARALLEL = int(os.environ.get("CHUNK_PARALLEL", "10"))

SOURCE_TABLE = f"{PROJECT_ID}.gold.dim_customers_analyst"
OUTPUT_TABLE = f"{PROJECT_ID}.ai.customer_ai_raw"
BQML_MODEL   = f"{PROJECT_ID}.ai.gemini_pro_model"

OUTPUT_SCHEMA = [
    bigquery.SchemaField("customer_id",  "STRING"),
    bigquery.SchemaField("persona",      "STRING"),
    bigquery.SchemaField("strategy",     "STRING"),
    bigquery.SchemaField("status",       "STRING"),
    bigquery.SchemaField("generated_at", "TIMESTAMP"),
]

FALLBACK_PERSONA  = "Valued customer"
FALLBACK_STRATEGY = "Monitor engagement"

logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)

app = Flask(__name__)

# ---------------------------------------------------------------------------
# Global job state (single-instance — max_instance_count=1 in Terraform)
# ---------------------------------------------------------------------------
_job_lock  = threading.Lock()
_job_state: dict = {
    "status":         "idle",
    "rows_processed": 0,
    "chunks_done":    0,
    "chunks_total":   0,
    "success":        0,
    "errors":         0,
    "message":        "",
    "started_at":     None,
    "finished_at":    None,
}


def _reset_job() -> None:
    global _job_state
    _job_state = {
        "status": "idle", "rows_processed": 0, "chunks_done": 0, "chunks_total": 0,
        "success": 0, "errors": 0, "message": "", "started_at": None, "finished_at": None,
    }


# ---------------------------------------------------------------------------
# Parsing — extract persona/strategy from BQ ML JSON result
# ---------------------------------------------------------------------------
def _parse(raw_text: str) -> tuple[str, str]:
    if not raw_text:
        return FALLBACK_PERSONA, FALLBACK_STRATEGY
    match = re.search(r'\{[\s\S]*\}', raw_text)
    if not match:
        return FALLBACK_PERSONA, FALLBACK_STRATEGY
    try:
        obj = json.loads(match.group(0))
    except (json.JSONDecodeError, ValueError):
        return FALLBACK_PERSONA, FALLBACK_STRATEGY
    return (
        str(obj.get("persona")  or FALLBACK_PERSONA),
        str(obj.get("strategy") or FALLBACK_STRATEGY),
    )


# ---------------------------------------------------------------------------
# BigQuery helpers
# ---------------------------------------------------------------------------
def _read_all_customers(bq: bigquery.Client) -> list[dict]:
    query = f"""
        SELECT customer_id, customer_segment, churn_risk
        FROM `{SOURCE_TABLE}`
        WHERE order_count > 0
          AND customer_segment IS NOT NULL
          AND churn_risk       IS NOT NULL
        ORDER BY customer_id
    """
    return [dict(row) for row in bq.query(query).result()]


def _run_bqml_chunk(bq: bigquery.Client, chunk: list[dict], chunk_num: int) -> list[dict]:
    """
    Runs ML.GENERATE_TEXT on up to CHUNK_SIZE customers via a parameterised
    BigQuery query. Each chunk completes in seconds — BQ ML handles its own
    internal parallelism against the remote Gemini endpoint.
    """
    ids = [r["customer_id"] for r in chunk]

    query = f"""
        WITH base AS (
          SELECT customer_id, customer_segment, churn_risk
          FROM `{SOURCE_TABLE}`
          WHERE customer_id IN UNNEST(@ids)
            AND order_count > 0
        ),
        ai_results AS (
          SELECT
            customer_id,
            ml_generate_text_llm_result,
            ml_generate_text_status
          FROM ML.GENERATE_TEXT(
            MODEL `{BQML_MODEL}`,
            (
              SELECT
                customer_id,
                CONCAT(
                  'Respond with ONLY a JSON object. No markdown, no code blocks.\\n',
                  'Format: {{"persona":"2-sentence customer profile","strategy":"one specific retention action"}}\\n',
                  'Segment:', customer_segment, ' Risk:', churn_risk
                ) AS prompt
              FROM base
            ),
            STRUCT(
              0.1  AS temperature,
              150  AS max_output_tokens,
              TRUE AS flatten_json_output
            )
          )
        )
        SELECT b.customer_id, r.ml_generate_text_llm_result, r.ml_generate_text_status
        FROM base b
        JOIN ai_results r USING (customer_id)
    """

    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ArrayQueryParameter("ids", "STRING", ids)
        ]
    )

    rows = list(bq.query(query, job_config=job_config).result())
    log.info("Chunk %d/%d — %d rows returned from BQ ML", chunk_num + 1,
             _job_state["chunks_total"], len(rows))

    ts      = datetime.now(timezone.utc).isoformat()
    results = []
    for row in rows:
        raw    = row["ml_generate_text_llm_result"] or ""
        status = row["ml_generate_text_status"]     or ""
        # BQ ML: empty status = success, non-empty = error message
        if status:
            persona, strategy = FALLBACK_PERSONA, FALLBACK_STRATEGY
        else:
            persona, strategy = _parse(raw)
        results.append({
            "customer_id":  row["customer_id"],
            "persona":      persona,
            "strategy":     strategy,
            "status":       status,
            "generated_at": ts,
        })

    return results


def _write_results(bq: bigquery.Client, results: list[dict]) -> None:
    """Atomic WRITE_TRUNCATE — replaces the entire table, no duplicates."""
    ndjson     = "\n".join(json.dumps(r) for r in results)
    job_config = bigquery.LoadJobConfig(
        write_disposition="WRITE_TRUNCATE",
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
        schema=OUTPUT_SCHEMA,
    )
    bq.load_table_from_file(
        io.BytesIO(ndjson.encode()),
        OUTPUT_TABLE,
        job_config=job_config,
    ).result()


# ---------------------------------------------------------------------------
# Background job
# ---------------------------------------------------------------------------
def _run_job() -> None:
    global _job_state
    bq = bigquery.Client(project=PROJECT_ID)

    with _job_lock:
        _job_state["status"]     = "running"
        _job_state["started_at"] = datetime.now(timezone.utc).isoformat()

    try:
        all_customers = _read_all_customers(bq)
        log.info("Loaded %d customers from dim_customers_analyst", len(all_customers))

        if not all_customers:
            with _job_lock:
                _job_state.update(status="done", rows_processed=0, message="no rows",
                                  finished_at=datetime.now(timezone.utc).isoformat())
            return

        # Split into fixed-size chunks
        chunks = [all_customers[i:i + CHUNK_SIZE]
                  for i in range(0, len(all_customers), CHUNK_SIZE)]

        with _job_lock:
            _job_state["chunks_total"] = len(chunks)

        log.info("%d chunks x %d rows | %d parallel BQ ML jobs",
                 len(chunks), CHUNK_SIZE, CHUNK_PARALLEL)

        all_results: list[dict] = []

        with ThreadPoolExecutor(max_workers=CHUNK_PARALLEL) as executor:
            futures = {
                executor.submit(_run_bqml_chunk, bq, chunk, i): i
                for i, chunk in enumerate(chunks)
            }
            for future in as_completed(futures):
                chunk_results = future.result()
                all_results.extend(chunk_results)
                with _job_lock:
                    _job_state["chunks_done"]    += 1
                    _job_state["rows_processed"] += len(chunk_results)

        success_count = sum(1 for r in all_results if r["status"] == "")
        error_count   = len(all_results) - success_count

        log.info("All chunks complete — %d rows | %d success | %d errors",
                 len(all_results), success_count, error_count)

        _write_results(bq, all_results)
        log.info("Written %d rows to %s", len(all_results), OUTPUT_TABLE)

        with _job_lock:
            _job_state.update(
                status="done",
                rows_processed=len(all_results),
                success=success_count,
                errors=error_count,
                finished_at=datetime.now(timezone.utc).isoformat(),
            )

    except Exception as exc:
        log.exception("Job failed: %s", exc)
        with _job_lock:
            _job_state.update(
                status="error",
                message=f"{type(exc).__name__}: {str(exc)[:450]}",
                finished_at=datetime.now(timezone.utc).isoformat(),
            )


# ---------------------------------------------------------------------------
# Flask endpoints
# ---------------------------------------------------------------------------
@app.route("/process", methods=["POST"])
def process():
    with _job_lock:
        if _job_state["status"] == "running":
            return jsonify({"status": "already_running"}), 409
        _reset_job()

    threading.Thread(target=_run_job, daemon=True).start()
    log.info("BQ ML chunked processor started (chunk_size=%d, parallel=%d)",
             CHUNK_SIZE, CHUNK_PARALLEL)
    return jsonify({"status": "started"}), 202


@app.route("/status", methods=["GET"])
def status():
    with _job_lock:
        snapshot = dict(_job_state)
    if snapshot["status"] == "error":
        return jsonify(snapshot), 500
    if snapshot["status"] in ("idle", "running"):
        return jsonify(snapshot), 202
    return jsonify(snapshot), 200


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy", "project": PROJECT_ID,
                    "chunk_size": CHUNK_SIZE, "chunk_parallel": CHUNK_PARALLEL}), 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port, debug=False)
