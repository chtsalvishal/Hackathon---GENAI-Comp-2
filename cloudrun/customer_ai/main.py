"""
Customer AI Processor — Cloud Run service.

Fire-and-forget design: POST /process returns 202 immediately and starts a
background thread. GET /status polls progress. The Cloud Workflow calls
/process, then polls /status every 30 s until status == "done".

Environment variables:
  GOOGLE_CLOUD_PROJECT  — GCP project ID (set automatically by Cloud Run)
  CONCURRENCY           — number of parallel Gemini requests (default: 200)
  LOCATION              — Vertex AI region (default: australia-southeast1)
"""

import asyncio
import io
import json
import logging
import os
import re
import threading
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone

from flask import Flask, jsonify
from google.cloud import bigquery
import vertexai
from vertexai.generative_models import GenerativeModel, GenerationConfig

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
PROJECT_ID  = os.environ.get("GOOGLE_CLOUD_PROJECT", "vishal-sandpit-474523")
LOCATION    = os.environ.get("LOCATION", "australia-southeast1")
CONCURRENCY = int(os.environ.get("CONCURRENCY", "200"))
MODEL_NAME  = "gemini-2.0-flash-001"

SOURCE_TABLE = f"{PROJECT_ID}.gold.dim_customers_analyst"
OUTPUT_TABLE = f"{PROJECT_ID}.ai.customer_ai_raw"

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

# Initialise Vertex AI once at module load
vertexai.init(project=PROJECT_ID, location=LOCATION)

# ---------------------------------------------------------------------------
# Global job state (single-instance — max_instance_count = 1 in Terraform)
# ---------------------------------------------------------------------------
_job_lock = threading.Lock()
_job_state: dict = {
    "status":         "idle",   # idle | running | done | error
    "rows_processed": 0,
    "success":        0,
    "errors":         0,
    "message":        "",
    "started_at":     None,
    "finished_at":    None,
}


def _reset_job() -> None:
    global _job_state
    _job_state = {
        "status": "idle", "rows_processed": 0,
        "success": 0, "errors": 0, "message": "",
        "started_at": None, "finished_at": None,
    }


# ---------------------------------------------------------------------------
# Prompt + parsing
# ---------------------------------------------------------------------------
def _build_prompt(segment: str, churn_risk: str) -> str:
    return (
        "Respond with ONLY a JSON object. No markdown, no code blocks.\n"
        'Format: {"persona":"2-sentence customer profile",'
        '"strategy":"one specific retention action"}\n'
        f"Segment:{segment} Risk:{churn_risk}"
    )


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
# Gemini call (synchronous — wrapped in thread executor for concurrency)
# ---------------------------------------------------------------------------
def _call_gemini_sync(row: dict, model: GenerativeModel) -> dict:
    prompt = _build_prompt(row["customer_segment"], row["churn_risk"])
    try:
        response = model.generate_content(
            prompt,
            generation_config=GenerationConfig(temperature=0.1, max_output_tokens=150),
        )
        raw = response.text or ""
        persona, strategy = _parse(raw)
        status = ""
    except Exception as exc:
        persona  = FALLBACK_PERSONA
        strategy = FALLBACK_STRATEGY
        status   = str(exc)[:500]
        log.warning("Gemini error for %s: %s", row["customer_id"], status)

    return {
        "customer_id":  row["customer_id"],
        "persona":      persona,
        "strategy":     strategy,
        "status":       status,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


# ---------------------------------------------------------------------------
# Async orchestration
# ---------------------------------------------------------------------------
async def _process_all(rows: list[dict]) -> list[dict]:
    model     = GenerativeModel(MODEL_NAME)
    semaphore = asyncio.Semaphore(CONCURRENCY)
    loop      = asyncio.get_running_loop()
    executor  = ThreadPoolExecutor(max_workers=CONCURRENCY)

    async def _call(row: dict) -> dict:
        async with semaphore:
            return await loop.run_in_executor(executor, _call_gemini_sync, row, model)

    results = await asyncio.gather(*[_call(row) for row in rows])
    executor.shutdown(wait=False)
    return list(results)


# ---------------------------------------------------------------------------
# BigQuery helpers
# ---------------------------------------------------------------------------
def _read_customers(bq: bigquery.Client) -> list[dict]:
    query = f"""
        SELECT
            customer_id,
            COALESCE(customer_segment, 'Unknown') AS customer_segment,
            COALESCE(churn_risk,       'Unknown') AS churn_risk
        FROM `{SOURCE_TABLE}`
        WHERE order_count > 0
          AND customer_segment IS NOT NULL
          AND churn_risk       IS NOT NULL
    """
    return [dict(row) for row in bq.query(query).result()]


def _write_results(bq: bigquery.Client, results: list[dict]) -> None:
    """
    Atomic WRITE_TRUNCATE load job — replaces the entire table each run.
    Eliminates duplicates from previous daily runs without a prior DELETE.
    """
    ndjson = "\n".join(json.dumps(r) for r in results)
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
        rows = _read_customers(bq)
        log.info("Loaded %d customers from dim_customers_analyst", len(rows))

        if not rows:
            with _job_lock:
                _job_state.update(
                    status="done", rows_processed=0, message="no rows",
                    finished_at=datetime.now(timezone.utc).isoformat(),
                )
            return

        results = asyncio.run(_process_all(rows))
        log.info("Gemini inference complete — %d results", len(results))

        _write_results(bq, results)

        success_count = sum(1 for r in results if r["status"] == "")
        error_count   = len(results) - success_count
        log.info("Written %d rows (%d errors) to %s", len(results), error_count, OUTPUT_TABLE)

        with _job_lock:
            _job_state.update(
                status="done",
                rows_processed=len(results),
                success=success_count,
                errors=error_count,
                finished_at=datetime.now(timezone.utc).isoformat(),
            )

    except Exception as exc:
        log.exception("Job failed: %s", exc)
        with _job_lock:
            _job_state.update(
                status="error",
                message=str(exc)[:500],
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

    thread = threading.Thread(target=_run_job, daemon=True)
    thread.start()
    log.info("Customer AI processor started (background thread)")
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
    return jsonify({"status": "healthy", "project": PROJECT_ID}), 200


# ---------------------------------------------------------------------------
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port, debug=False)
