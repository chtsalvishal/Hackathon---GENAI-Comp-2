#!/usr/bin/env python3
"""
Test Python async pathway for calling Gemini directly on customer data.

Compares throughput/latency of direct Python SDK vs the current BQ ML approach.

Tests:
  - asyncio + semaphore concurrency model
  - Per-request latency measurement
  - JSON response parsing (identical logic to customer_ai_1.sqlx)
  - Throughput extrapolation to 100K / 450K rows

Usage:
  pip install google-generativeai
  export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
  python tmp/test_python_gemini_pathway.py

  OR with an API key:
  python tmp/test_python_gemini_pathway.py --api-key YOUR_KEY
"""

import argparse
import asyncio
import json
import re
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from statistics import mean, median, stdev

try:
    import google.generativeai as genai
    from google.generativeai.types import GenerationConfig
except ImportError:
    print("ERROR: google-generativeai not installed.")
    print("Run:  pip install google-generativeai")
    sys.exit(1)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
MODEL_NAME     = "gemini-2.0-flash"
FALLBACK_MODEL = "gemini-1.5-flash"
TEMPERATURE    = 0.1
MAX_TOKENS     = 150

FALLBACK_PERSONA  = "Valued customer"
FALLBACK_STRATEGY = "Monitor engagement"


# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------
@dataclass
class CustomerRow:
    customer_id:      str
    customer_segment: str
    churn_risk:       str

    def prompt(self) -> str:
        """Identical prompt to customer_ai_1.sqlx CONCAT() expression."""
        return (
            "Respond with ONLY a JSON object. No markdown, no code blocks.\n"
            'Format: {"persona":"2-sentence customer profile",'
            '"strategy":"one specific retention action"}\n'
            f"Segment:{self.customer_segment} Risk:{self.churn_risk}"
        )


@dataclass
class AIResult:
    customer_id:  str
    persona:      str
    strategy:     str
    raw_text:     str
    latency_ms:   float
    success:      bool
    generated_at: str


# ---------------------------------------------------------------------------
# Parsing — mirrors the SQL:
#   REGEXP_EXTRACT(raw_text, r'\{[\s\S]*\}')
#   JSON_VALUE(json_payload, '$.persona')
#   JSON_VALUE(json_payload, '$.strategy')
# ---------------------------------------------------------------------------
def parse_response(raw_text: str) -> tuple[str, str]:
    if not raw_text:
        return FALLBACK_PERSONA, FALLBACK_STRATEGY
    match = re.search(r'\{[\s\S]*\}', raw_text)
    if not match:
        return FALLBACK_PERSONA, FALLBACK_STRATEGY
    try:
        obj = json.loads(match.group(0))
    except (json.JSONDecodeError, ValueError):
        return FALLBACK_PERSONA, FALLBACK_STRATEGY
    persona  = obj.get("persona")  or FALLBACK_PERSONA
    strategy = obj.get("strategy") or FALLBACK_STRATEGY
    return str(persona), str(strategy)


# ---------------------------------------------------------------------------
# Async Gemini caller
# ---------------------------------------------------------------------------
async def call_gemini(
    customer:  CustomerRow,
    semaphore: asyncio.Semaphore,
    model_name: str,
) -> AIResult:
    t0 = time.perf_counter()
    async with semaphore:
        try:
            model = genai.GenerativeModel(model_name)
            # google-generativeai is synchronous; run in thread pool
            loop = asyncio.get_running_loop()
            response = await loop.run_in_executor(
                None,
                lambda: model.generate_content(
                    customer.prompt(),
                    generation_config=GenerationConfig(
                        temperature=MAX_TOKENS and TEMPERATURE,
                        max_output_tokens=MAX_TOKENS,
                    ),
                ),
            )
            raw = response.text or ""
            persona, strategy = parse_response(raw)
            return AIResult(
                customer_id=customer.customer_id,
                persona=persona,
                strategy=strategy,
                raw_text=raw,
                latency_ms=(time.perf_counter() - t0) * 1000,
                success=True,
                generated_at=datetime.now(timezone.utc).isoformat(),
            )
        except Exception as exc:
            return AIResult(
                customer_id=customer.customer_id,
                persona=FALLBACK_PERSONA,
                strategy=FALLBACK_STRATEGY,
                raw_text=f"ERROR: {exc}",
                latency_ms=(time.perf_counter() - t0) * 1000,
                success=False,
                generated_at=datetime.now(timezone.utc).isoformat(),
            )


async def run_batch(
    customers: list[CustomerRow],
    concurrency: int,
    model_name: str,
) -> tuple[list[AIResult], float]:
    sem = asyncio.Semaphore(concurrency)
    t0 = time.perf_counter()
    tasks = [call_gemini(c, sem, model_name) for c in customers]
    results = await asyncio.gather(*tasks)
    wall_clock = time.perf_counter() - t0
    return list(results), wall_clock


# ---------------------------------------------------------------------------
# Test dataset — same segments/risks as our dim_customers_analyst values
# ---------------------------------------------------------------------------
TEST_CUSTOMERS = [
    CustomerRow("CUST001", "Platinum", "Active"),
    CustomerRow("CUST002", "Gold",     "At Risk"),
    CustomerRow("CUST003", "Silver",   "Cooling"),
    CustomerRow("CUST004", "Bronze",   "Churned"),
    CustomerRow("CUST005", "Gold",     "Active"),
    CustomerRow("CUST006", "Platinum", "At Risk"),
    CustomerRow("CUST007", "Silver",   "Active"),
    CustomerRow("CUST008", "Bronze",   "Cooling"),
    CustomerRow("CUST009", "Gold",     "Churned"),
    CustomerRow("CUST010", "Silver",   "At Risk"),
]


# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------
SEP = "=" * 72
SEP2 = "-" * 72

def report(results: list[AIResult], wall_sec: float, concurrency: int):
    latencies = [r.latency_ms for r in results]
    successes = [r for r in results if r.success]
    failures  = [r for r in results if not r.success]

    actual_rps  = len(results) / wall_sec
    # Conservative sustained RPS at 80% efficiency
    sustained_rps = actual_rps * 0.80

    print(f"\n{SEP}")
    print("PYTHON ASYNC GEMINI — TEST RESULTS")
    print(SEP)
    print(f"Model:       {MODEL_NAME}")
    print(f"Concurrency: {concurrency} parallel requests")
    print(f"Rows:        {len(results)}")
    print(f"Succeeded:   {len(successes)}   Failed: {len(failures)}")

    print(f"\n{SEP2}")
    print("PER-ROW OUTPUT")
    print(SEP2)
    for r in results:
        tag = "OK " if r.success else "ERR"
        print(
            f"[{tag}] {r.customer_id:8} | {r.latency_ms:6.0f}ms | "
            f"persona: {r.persona[:45]:45} | "
            f"strategy: {r.strategy[:35]}"
        )

    print(f"\n{SEP2}")
    print("LATENCY STATS (ms)")
    print(SEP2)
    print(f"  Min    : {min(latencies):7.1f}")
    print(f"  p50    : {median(latencies):7.1f}")
    print(f"  Avg    : {mean(latencies):7.1f}")
    print(f"  Max    : {max(latencies):7.1f}")
    if len(latencies) > 1:
        print(f"  StdDev : {stdev(latencies):7.1f}")
    print(f"\n  Wall-clock total : {wall_sec:.2f}s")
    print(f"  Actual RPS       : {actual_rps:.1f}")
    print(f"  Sustained RPS    : {sustained_rps:.1f}  (80% efficiency estimate)")

    print(f"\n{SEP2}")
    print("EXTRAPOLATION  (vs BQ ML ~6 RPS ceiling)")
    print(SEP2)
    print(f"  {'Rows':>8}  {'Python async':>14}  {'BQ ML 4-shards':>16}  {'Speedup':>8}")
    print(f"  {'-'*8}  {'-'*14}  {'-'*16}  {'-'*8}")
    bq_ml_rps = 6.0
    for n in [10_000, 50_000, 100_000, 200_000, 450_000]:
        py_sec  = n / sustained_rps
        bq_sec  = n / bq_ml_rps
        speedup = bq_sec / py_sec
        py_str  = _fmt_time(py_sec)
        bq_str  = _fmt_time(bq_sec)
        print(f"  {n:>8,}  {py_str:>14}  {bq_str:>16}  {speedup:>7.1f}x")

    print(f"\n{SEP2}")
    print("SAMPLE OUTPUT (first 3 rows as JSON)")
    print(SEP2)
    sample = [
        {
            "customer_id": r.customer_id,
            "persona":     r.persona,
            "strategy":    r.strategy,
            "generated_at": r.generated_at,
        }
        for r in results[:3]
    ]
    print(json.dumps(sample, indent=2))

    print(f"\n{SEP2}")
    print("FEASIBILITY VERDICT")
    print(SEP2)
    if sustained_rps >= 20:
        verdict = "HIGH — Python async is significantly faster than BQ ML"
    elif sustained_rps >= 10:
        verdict = "MEDIUM — Python async is moderately faster than BQ ML"
    else:
        verdict = "LOW — Python async offers limited advantage over BQ ML at this quota tier"

    print(f"  Verdict: {verdict}")
    print(f"  Recommendation:")
    if sustained_rps >= 20:
        print("    -> Replace BQ ML shards with Cloud Run async worker")
        print("    -> Target concurrency=50+ for production (limited by Gemini quota)")
        print("    -> Expected 100K customers in < 5 minutes")
    elif sustained_rps >= 10:
        print("    -> Python async helps, but increase concurrency beyond 5")
        print("    -> Consider Vertex AI Batch for large runs (100K+)")
    else:
        print("    -> Quota is the bottleneck; request quota increase first")
        print("    -> Vertex AI Batch Prediction bypasses user quota entirely")

    print(f"\n{SEP}\n")


def _fmt_time(seconds: float) -> str:
    if seconds < 60:
        return f"{seconds:.0f}s"
    elif seconds < 3600:
        return f"{seconds/60:.1f} min"
    else:
        return f"{seconds/3600:.1f} hrs"


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description="Test Python async Gemini pathway")
    parser.add_argument("--api-key",    type=str, default=None,
                        help="Gemini API key (uses ADC if not set)")
    parser.add_argument("--concurrency", type=int, default=5,
                        help="Number of concurrent Gemini requests (default: 5)")
    parser.add_argument("--model",      type=str, default=MODEL_NAME,
                        help=f"Gemini model name (default: {MODEL_NAME})")
    args = parser.parse_args()

    if args.api_key:
        genai.configure(api_key=args.api_key)

    model_name  = args.model
    concurrency = args.concurrency

    print(f"\n{SEP}")
    print("PYTHON ASYNC GEMINI PATHWAY — FEASIBILITY TEST")
    print(SEP)
    print(f"  Model:          {model_name}")
    print(f"  Concurrency:    {concurrency}")
    print(f"  Test rows:      {len(TEST_CUSTOMERS)}")
    print(f"  Auth:           {'API key' if args.api_key else 'Application Default Credentials'}")
    print(f"  Started:        {datetime.now(timezone.utc).isoformat()}")
    print(f"  Prompt format:  identical to customer_ai_1.sqlx\n")

    print("Running... (each call ~ 100-200ms, 10 rows with concurrency=5 ~ 0.2-1s total)")

    try:
        results, wall_sec = asyncio.run(
            run_batch(TEST_CUSTOMERS, concurrency, model_name)
        )
    except Exception as exc:
        print(f"\nFATAL ERROR: {exc}")
        print("\nTroubleshooting:")
        print("  1. Set GOOGLE_APPLICATION_CREDENTIALS to your service account key")
        print("  2. Or pass --api-key YOUR_GEMINI_API_KEY")
        print("  3. Ensure 'Generative Language API' is enabled in GCP console")
        print("  4. Check the service account has roles/aiplatform.user")
        sys.exit(1)

    report(results, wall_sec, concurrency)


if __name__ == "__main__":
    main()
