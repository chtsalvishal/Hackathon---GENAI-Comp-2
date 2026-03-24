"""
Vertex AI Agent Builder — BigQuery Tool Handler
Cloud Run service that executes BigQuery SQL and returns results.
Called by the Dialogflow CX agent when the query_bigquery tool is invoked.
"""
import json
import os
from flask import Flask, request, jsonify
from google.cloud import bigquery

app = Flask(__name__)

PROJECT = os.environ.get("PROJECT_ID", "vishal-sandpit-474523")
LOCATION = os.environ.get("BQ_LOCATION", "australia-southeast1")
MAX_ROWS = 100

bq_client = None


def get_bq():
    global bq_client
    if bq_client is None:
        bq_client = bigquery.Client(project=PROJECT)
    return bq_client


def is_safe_query(sql: str) -> bool:
    upper = sql.upper().strip()
    for kw in ("INSERT", "UPDATE", "DELETE", "DROP", "CREATE", "ALTER", "TRUNCATE", "MERGE"):
        if kw in upper:
            return False
    return True


@app.route("/", methods=["POST", "GET"])
def bq_tool_handler():
    if request.method == "GET":
        return jsonify({"status": "ok", "service": "bq-tool-handler"}), 200

    body = request.get_json(silent=True) or {}

    # Dialogflow CX sends tool input under toolCall.inputParameters
    tool_call = body.get("toolCall", {})
    params = tool_call.get("inputParameters", body)
    sql = params.get("sql", "").strip()

    if not sql:
        return jsonify({"results": "[]", "error": "No SQL provided"}), 200

    if not is_safe_query(sql):
        return jsonify({"results": "[]", "error": "Only SELECT queries are allowed"}), 200

    try:
        job = get_bq().query(sql, location=LOCATION)
        rows = list(job.result(timeout=30))[:MAX_ROWS]
        results = [{k: (str(v) if v is not None else None) for k, v in dict(r).items()} for r in rows]
        return jsonify({"results": json.dumps(results), "error": ""}), 200
    except Exception as e:
        return jsonify({"results": "[]", "error": str(e)[:500]}), 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
