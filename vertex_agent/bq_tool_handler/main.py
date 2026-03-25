"""
Vertex AI Agent Builder — BigQuery Tool Handler  v2.0
Cloud Run service that executes BigQuery SQL and returns results.
Called by the Dialogflow CX agent when the query_bigquery tool is invoked.
"""
import json
import os
import sys
from decimal import Decimal

from flask import Flask, request, jsonify
from google.cloud import bigquery

app = Flask(__name__)

PROJECT = os.environ.get("PROJECT_ID", "vishal-sandpit-474523")
LOCATION = os.environ.get("BQ_LOCATION", "australia-southeast1")

MAX_ROWS_DEFAULT = 50
MAX_ROWS_HARD_CAP = 200

bq_client = None


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def get_bq() -> bigquery.Client:
    global bq_client
    if bq_client is None:
        bq_client = bigquery.Client(project=PROJECT)
    return bq_client


def is_safe_query(sql: str) -> bool:
    """Return True only for read-only SELECT statements."""
    upper = sql.upper().strip()
    for kw in ("INSERT", "UPDATE", "DELETE", "DROP", "CREATE",
               "ALTER", "TRUNCATE", "MERGE"):
        if kw in upper:
            return False
    return True


def serialize_value(v):
    """
    Convert a BigQuery result value to a JSON-serialisable Python type.
    Numeric types (float, int, Decimal) are kept as numbers so the agent
    receives proper figures rather than quoted strings.
    """
    if v is None:
        return None
    if isinstance(v, (int, float)):
        return v
    if isinstance(v, Decimal):
        return float(v)
    # bigquery.Row nested types arrive as dicts/lists already; handle both.
    if isinstance(v, (dict, list)):
        return v
    return str(v)


def resolve_max_rows(body: dict) -> int:
    """Return the effective row limit, honouring request override."""
    requested = body.get("max_rows", MAX_ROWS_DEFAULT)
    try:
        requested = int(requested)
    except (TypeError, ValueError):
        requested = MAX_ROWS_DEFAULT
    return min(max(requested, 1), MAX_ROWS_HARD_CAP)


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "version": "2.0", "project": PROJECT}), 200


@app.route("/", methods=["POST", "GET"])
def bq_tool_handler():
    if request.method == "GET":
        return jsonify({"status": "ok", "service": "bq-tool-handler",
                        "version": "2.0"}), 200

    body = request.get_json(silent=True) or {}

    # Dialogflow CX wraps tool input under toolCall.inputParameters;
    # fall back to the raw body for direct API calls.
    tool_call = body.get("toolCall", {})
    params = tool_call.get("inputParameters", body)

    sql = params.get("sql", "").strip()
    max_rows = resolve_max_rows(params)

    if not sql:
        return jsonify({"results": "[]", "error": "No SQL provided"}), 200

    if not is_safe_query(sql):
        return jsonify({"results": "[]",
                        "error": "Only SELECT queries are allowed"}), 200

    print(f"[bq-tool] executing sql={sql!r} max_rows={max_rows}",
          file=sys.stderr)

    try:
        job = get_bq().query(sql, location=LOCATION)
        rows = list(job.result(timeout=30))[:max_rows]
        results = [
            {k: serialize_value(v) for k, v in dict(row).items()}
            for row in rows
        ]
        print(f"[bq-tool] rows_returned={len(results)}", file=sys.stderr)
        return jsonify({"results": json.dumps(results), "error": ""}), 200

    except Exception as exc:
        print(f"[bq-tool] error={exc}", file=sys.stderr)
        return jsonify({"results": "[]", "error": str(exc)[:500]}), 200


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
