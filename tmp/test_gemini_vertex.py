"""
Validates Gemini connectivity, thread safety, and throughput before deploying
the Cloud Run customer-ai-processor.

Tests:
  1. Single call (basic connectivity)
  2. 5 concurrent calls on SEPARATE model instances (thread-safe approach)
  3. 20 concurrent calls (throughput / quota check)

Run from project root:
  python tmp/test_gemini_vertex.py

Requirements:
  pip install google-cloud-aiplatform vertexai
  gcloud auth application-default login
  gcloud auth application-default set-quota-project YOUR_PROJECT_ID
"""

import asyncio
import json
import logging
import os
import re
import time
from concurrent.futures import ThreadPoolExecutor

import vertexai
from vertexai.generative_models import GenerativeModel, GenerationConfig

PROJECT_ID = os.environ.get("GOOGLE_CLOUD_PROJECT", "vishal-sandpit-474523")
LOCATION   = os.environ.get("LOCATION", "australia-southeast1")
MODEL_NAME = "gemini-2.5-flash"

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)

TEST_PROMPT = (
    "Respond with ONLY a JSON object. No markdown, no code blocks.\n"
    'Format: {"persona":"2-sentence customer profile","strategy":"one specific retention action"}\n'
    "Segment:Premium Risk:High"
)

FALLBACK_PERSONA  = "Valued customer"
FALLBACK_STRATEGY = "Monitor engagement"


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


def call_gemini_safe(row_id: str) -> dict:
    """
    Creates its own GenerativeModel instance — thread-safe.
    This is the pattern used in the fixed main.py.
    """
    model = GenerativeModel(MODEL_NAME)  # NEW instance per call
    t0 = time.time()
    try:
        response = model.generate_content(
            TEST_PROMPT,
            generation_config=GenerationConfig(temperature=0.1, max_output_tokens=150),
        )
        raw     = response.text or ""
        latency = round(time.time() - t0, 2)
        persona, strategy = _parse(raw)

        if persona == FALLBACK_PERSONA and strategy == FALLBACK_STRATEGY:
            return {"id": row_id, "status": "parse_failed", "latency": latency,
                    "raw": raw[:300]}
        return {"id": row_id, "status": "ok", "latency": latency,
                "persona": persona[:80], "strategy": strategy[:80]}

    except Exception as exc:
        latency = round(time.time() - t0, 2)
        return {"id": row_id, "status": "error", "latency": latency,
                "error_type": type(exc).__name__, "error": str(exc)[:400]}


async def run_concurrent(n: int, label: str) -> None:
    log.info("=== %s: %d concurrent calls ===", label, n)
    semaphore = asyncio.Semaphore(n)
    loop      = asyncio.get_running_loop()
    executor  = ThreadPoolExecutor(max_workers=n)

    async def _call(i: int) -> dict:
        async with semaphore:
            return await loop.run_in_executor(executor, call_gemini_safe, f"row_{i}")

    t0      = time.time()
    results = await asyncio.gather(*[_call(i) for i in range(n)])
    wall    = round(time.time() - t0, 2)
    executor.shutdown(wait=False)

    ok       = [r for r in results if r["status"] == "ok"]
    failures = [r for r in results if r["status"] != "ok"]
    latencies = [r["latency"] for r in results]
    avg_lat  = round(sum(latencies) / len(latencies), 2)
    rps      = round(n / wall, 1)

    log.info("  %d/%d succeeded | avg latency %.2fs | wall %.2fs | throughput %.1f req/s",
             len(ok), n, avg_lat, wall, rps)

    if failures:
        log.warning("  FAILURES:")
        for f in failures[:3]:
            log.warning("    %s", json.dumps(f))
    else:
        log.info("  Sample result: persona=%r", ok[0]["persona"][:60] if ok else "N/A")

    if len(ok) == n:
        log.info("  PASS ✓")
    else:
        log.warning("  PARTIAL FAIL — %d errors", len(failures))

    return rps if ok else 0


def main():
    log.info("Initialising Vertex AI | project=%s location=%s model=%s",
             PROJECT_ID, LOCATION, MODEL_NAME)
    vertexai.init(project=PROJECT_ID, location=LOCATION)

    # ── Test 1: Single call ──────────────────────────────────────────────────
    log.info("=== TEST 1: Single call (basic connectivity) ===")
    result = call_gemini_safe("single_test")
    log.info("Result: %s", json.dumps(result, indent=2))

    if result["status"] != "ok":
        log.error(
            "Single call failed — check model name (%s), region (%s), and IAM permissions.",
            MODEL_NAME, LOCATION,
        )
        log.error("Error: %s", result.get("error") or result.get("raw"))
        return

    single_latency = result["latency"]
    log.info("TEST 1 PASS ✓ — latency %.2fs", single_latency)

    # ── Test 2: 5 concurrent ─────────────────────────────────────────────────
    rps_5 = asyncio.run(run_concurrent(5, "TEST 2"))

    # ── Test 3: 20 concurrent ────────────────────────────────────────────────
    rps_20 = asyncio.run(run_concurrent(20, "TEST 3"))

    # ── Summary — always show a prediction ───────────────────────────────────
    log.info("=== SUMMARY ===")
    log.info("Single-call latency:   %.2f s", single_latency)

    if rps_20 and rps_20 > 0:
        # Concurrent throughput measured — most accurate
        est_at_30 = round(1000 / (rps_20 * 30 / 20), 0)
        log.info("Throughput at c=20:    %.1f req/s", rps_20)
        log.info("Throughput at c=30:    ~%.1f req/s (projected)", rps_20 * 30 / 20)
        log.info("Est. time / 1000 rows: ~%.0f s  (concurrency=30)", est_at_30)
    else:
        # Concurrent calls failed — estimate from single-call latency only
        est_at_30 = round(1000 * single_latency / 30, 0)
        log.warning("Concurrent calls had errors — estimate from single-call latency")
        log.info("Est. time / 1000 rows: ~%.0f s  (concurrency=30, rough)", est_at_30)

    log.info("Recommended CONCURRENCY: 30  (safe for Gemini 2.5 Flash RPM quota)")
    log.info("To increase throughput, raise CONCURRENCY env var in Cloud Run and re-test")


if __name__ == "__main__":
    main()
