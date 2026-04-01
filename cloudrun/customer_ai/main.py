"""
Customer AI Processor — Cloud Run service.

Replaces the 4 Dataform customer_ai_*.sqlx shards.
Reads dim_customers_analyst from BigQuery, calls Gemini async with up to
CONCURRENCY parallel requests, writes results to ai.customer_ai_raw.

The Cloud Workflow calls POST /process after the main Dataform refresh
completes and before the ai_aggregate Dataform step runs customer_concierge.

Environment variables:
  GOOGLE_CLOUD_PROJECT  — GCP project ID (set automatically by Cloud Run)
  CONCURRENCY           — number of parallel Gemini requests (default: 50)
  LOCATION              — Vertex AI region (default: australia-southeast1)
"""

import asyncio
import json
import logging
import os
import re
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone

from flask import Flask, jsonify
from google.cloud import bigquery
import vertexai
from vertexai.generative_models import GenerativeModel, GenerationConfig

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
PROJECT_ID   = os.environ.get("GOOGLE_CLOUD_PROJECT", "vishal-sandpit-474523")
LOCATION     = os.environ.get("LOCATION", "australia-southeast1")
CONCURRENCY  = int(os.environ.get("CONCURRENCY", "50"))
MODEL_NAME   = "gemini-2.5-flash"

SOURCE_TABLE = f"{PROJECT_ID}.gold.dim_customers_analyst"
OUTPUT_TABLE = f"{PROJECT_ID}.ai.customer_ai_raw"

WRITE_BATCH_SIZE = 500   # rows per BigQuery streaming-insert batch
MAX_WORKERS      = CONCURRENCY  # thread pool size matches concurrency

FALLBACK_PERSONA  = "Valued customer"
FALLBACK_STRATEGY = "Monitor engagement"

logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)

app = Flask(__name__)

# Initialise Vertex AI once at module load (not per request)
vertexai.init(project=PROJECT_ID, location=LOCATION)


# ---------------------------------------------------------------------------
# Prompt + parsing — identical logic to customer_ai_1.sqlx
# ---------------------------------------------------------------------------
def _build_prompt(segment: str, churn_risk: str) -> str:
    return (
        "Respond with ONLY a JSON object. No markdown, no code blocks.\n"
        'Format: {"persona":"2-sentence customer profile",'
        '"strategy":"one specific retention action"}\n'
        f"Segment:{segment} Risk:{churn_risk}"
    )


def _parse(raw_text: str) -> tuple[str, str]:
    """
    Mirrors the SQL pipeline:
      REGEXP_EXTRACT(raw_text, r'\\{[\\s\\S]*\\}')  -> json_payload
      JSON_VALUE(json_payload, '$.persona')          -> persona
      JSON_VALUE(json_payload, '$.strategy')         -> strategy
    """
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
# Gemini call (synchronous — wrapped in thread executor for async concurrency)
# ---------------------------------------------------------------------------
def _call_gemini_sync(row: dict, model: GenerativeModel) -> dict:
    prompt = _build_prompt(row["customer_segment"], row["churn_risk"])
    try:
        response = model.generate_content(
            prompt,
            generation_config=GenerationConfig(
                temperature=0.1,
                max_output_tokens=150,
            ),
        )
        raw      = response.text or ""
        persona, strategy = _parse(raw)
        status   = ""   # convention: '' = success (matches BQ ML behaviour)
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
    executor  = ThreadPoolExecutor(max_workers=MAX_WORKERS)

    async def _call(row: dict) -> dict:
        async with semaphore:
            return await loop.run_in_executor(executor, _call_gemini_sync, row, model)

    tasks   = [_call(row) for row in rows]
    results = await asyncio.gather(*tasks)
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


def _write_results(bq: bigquery.Client, results: list[dict]) -> list:
    """Batch-writes rows to customer_ai_raw; returns any insert errors."""
    all_errors = []
    for i in range(0, len(results), WRITE_BATCH_SIZE):
        batch  = results[i : i + WRITE_BATCH_SIZE]
        errors = bq.insert_rows_json(OUTPUT_TABLE, batch)
        if errors:
            all_errors.extend(errors)
            log.error("Insert errors for batch %d: %s", i // WRITE_BATCH_SIZE, errors)
    return all_errors


# ---------------------------------------------------------------------------
# Flask endpoints
# ---------------------------------------------------------------------------
@app.route("/process", methods=["POST"])
def process():
    log.info("Customer AI processor started")
    bq = bigquery.Client(project=PROJECT_ID)

    rows = _read_customers(bq)
    log.info("Loaded %d customers from dim_customers_analyst", len(rows))

    if not rows:
        return jsonify({"status": "ok", "rows_processed": 0, "message": "no rows"}), 200

    results = asyncio.run(_process_all(rows))
    log.info("Gemini inference complete — %d results", len(results))

    errors = _write_results(bq, results)
    if errors:
        return jsonify({"status": "error", "errors": errors[:10]}), 500

    success_count = sum(1 for r in results if r["status"] == "")
    error_count   = len(results) - success_count
    log.info("Written %d rows (%d errors) to %s", len(results), error_count, OUTPUT_TABLE)

    return jsonify({
        "status":        "ok",
        "rows_processed": len(results),
        "success":        success_count,
        "errors":         error_count,
    }), 200


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy", "project": PROJECT_ID}), 200


# ---------------------------------------------------------------------------
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port, debug=False)
