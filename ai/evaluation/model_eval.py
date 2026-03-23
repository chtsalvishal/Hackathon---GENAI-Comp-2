"""
Gemini Model Evaluation Script
Runs weekly to assess output quality of ML.GENERATE_TEXT calls.
Writes results to ai.model_evaluation_log in BigQuery.
"""

import os
import json
import re
from datetime import datetime, date
from google.cloud import bigquery
import vertexai
from vertexai.generative_models import GenerativeModel

PROJECT_ID = os.environ.get("PROJECT_ID", "vishal-sandpit-474523")
REGION = os.environ.get("REGION", "australia-southeast1")
EVAL_TABLE = f"{PROJECT_ID}.ai.model_evaluation_log"
SAMPLE_SIZE = 50

bq_client = bigquery.Client(project=PROJECT_ID)
vertexai.init(project=PROJECT_ID, location=REGION)
model = GenerativeModel("gemini-1.5-pro")


def get_sample_outputs() -> list[dict]:
    """Fetch a sample of recent Gemini outputs from customer_concierge view."""
    sql = f"""
    SELECT customer_id, customer_name, customer_segment, churn_risk,
           gemini_persona_and_strategy, generation_status
    FROM `{PROJECT_ID}.ai.customer_concierge`
    WHERE generation_status = 'success'
      AND DATE(generated_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
    ORDER BY RAND()
    LIMIT {SAMPLE_SIZE}
    """
    return bq_client.query(sql).to_dataframe().to_dict("records")


def score_output(output: str, customer_segment: str) -> dict:
    """Score a single Gemini output on coherence, relevance, and actionability."""
    scores = {
        "coherence": 0,
        "relevance": 0,
        "actionability": 0,
        "length_ok": 0,
    }

    if not output or len(output.strip()) < 20:
        return scores

    # Length check: should be 50-500 characters
    scores["length_ok"] = 1 if 50 <= len(output) <= 500 else 0

    # Coherence: contains two parts (persona + strategy)
    scores["coherence"] = 1 if len(output.split("\n")) >= 2 or len(output.split(".")) >= 2 else 0

    # Relevance: mentions customer-relevant terms
    relevant_terms = ["customer", "purchase", "retain", "loyal", "offer", "discount", "engage"]
    scores["relevance"] = 1 if any(term in output.lower() for term in relevant_terms) else 0

    # Actionability: contains action words
    action_words = ["send", "offer", "provide", "recommend", "invite", "create", "launch", "target"]
    scores["actionability"] = 1 if any(word in output.lower() for word in action_words) else 0

    return scores


def write_eval_results(results: list[dict]):
    """Write evaluation results to BigQuery."""
    # Ensure table exists
    schema = [
        bigquery.SchemaField("eval_id", "STRING"),
        bigquery.SchemaField("eval_date", "DATE"),
        bigquery.SchemaField("prompt_version", "STRING"),
        bigquery.SchemaField("sample_size", "INTEGER"),
        bigquery.SchemaField("avg_coherence_score", "FLOAT"),
        bigquery.SchemaField("avg_relevance_score", "FLOAT"),
        bigquery.SchemaField("avg_actionability_score", "FLOAT"),
        bigquery.SchemaField("avg_length_ok_score", "FLOAT"),
        bigquery.SchemaField("overall_quality_score", "FLOAT"),
        bigquery.SchemaField("pass_threshold", "BOOLEAN"),
        bigquery.SchemaField("evaluated_at", "TIMESTAMP"),
        bigquery.SchemaField("notes", "STRING"),
    ]

    summary = {
        "eval_id": f"eval_{date.today().strftime('%Y%m%d')}",
        "eval_date": str(date.today()),
        "prompt_version": "v1",
        "sample_size": len(results),
        "avg_coherence_score": sum(r["coherence"] for r in results) / len(results),
        "avg_relevance_score": sum(r["relevance"] for r in results) / len(results),
        "avg_actionability_score": sum(r["actionability"] for r in results) / len(results),
        "avg_length_ok_score": sum(r["length_ok"] for r in results) / len(results),
        "overall_quality_score": sum(
            r["coherence"] + r["relevance"] + r["actionability"] + r["length_ok"]
            for r in results
        ) / (len(results) * 4),
        "pass_threshold": None,
        "evaluated_at": datetime.utcnow().isoformat(),
        "notes": f"Automated weekly evaluation run on {len(results)} samples",
    }
    summary["pass_threshold"] = summary["overall_quality_score"] >= 0.7

    errors = bq_client.insert_rows_json(EVAL_TABLE, [summary])
    if errors:
        print(f"Errors writing eval results: {errors}")
    else:
        print(f"Evaluation complete. Overall quality score: {summary['overall_quality_score']:.2%}")
        print(f"Pass threshold (>=70%): {summary['pass_threshold']}")


def run_evaluation():
    print(f"Starting model evaluation -- {date.today()}")
    samples = get_sample_outputs()
    if not samples:
        print("No samples available for evaluation.")
        return

    scored = []
    for sample in samples:
        output = sample.get("gemini_persona_and_strategy", "")
        segment = sample.get("customer_segment", "")
        scores = score_output(output, segment)
        scored.append(scores)

    write_eval_results(scored)


if __name__ == "__main__":
    run_evaluation()
