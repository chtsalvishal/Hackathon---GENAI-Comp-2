"""
BigQuery search tools for the Intelia Reasoning Engine Agent.
Each tool maps to a specific stakeholder question domain.
"""

from langchain.tools import tool
from google.cloud import bigquery
import pandas as pd

PROJECT_ID = "vishal-sandpit-474523"
bq_client = bigquery.Client(project=PROJECT_ID)


def _run_query(sql: str, description: str = "") -> str:
    try:
        df = bq_client.query(sql).to_dataframe()
        if df.empty:
            return "No data found for this query."
        return df.to_string(index=False, max_rows=25)
    except Exception as e:
        return f"Error running {description}: {str(e)}"


@tool
def query_revenue_summary(question: str) -> str:
    """Query revenue data: gross sales, monthly trends, revenue vs targets.
    Use for CCO questions about revenue performance, monthly totals, year-over-year comparisons."""
    sql = """
    SELECT
      FORMAT_DATE('%Y-%m', summary_date)   AS month,
      SUM(gross_revenue)                   AS total_revenue,
      SUM(order_count)                     AS total_orders,
      SUM(unique_customers)                AS unique_customers,
      ROUND(AVG(avg_order_value), 2)       AS avg_order_value
    FROM `vishal-sandpit-474523.gold.mart_revenue_summary`
    WHERE summary_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
    GROUP BY 1
    ORDER BY 1 DESC
    LIMIT 12
    """
    return _run_query(sql, "revenue summary")


@tool
def query_customer_segments(question: str) -> str:
    """Query customer segmentation, LTV distribution, churn risk, top customers.
    Use for CCO questions about customer health, retention, or specific customer profiles."""
    sql = """
    SELECT
      customer_segment,
      churn_risk,
      COUNT(*)                                    AS customer_count,
      ROUND(AVG(total_lifetime_value), 2)         AS avg_ltv,
      ROUND(SUM(total_lifetime_value), 2)         AS total_segment_revenue,
      ROUND(AVG(days_since_last_purchase), 0)     AS avg_days_inactive
    FROM `vishal-sandpit-474523.gold.dim_customers`
    GROUP BY 1, 2
    ORDER BY total_segment_revenue DESC
    """
    return _run_query(sql, "customer segments")


@tool
def query_platform_metrics(question: str) -> str:
    """Query platform performance: query execution times, slot utilization, AI adoption rates.
    Use for CTO questions about warehouse performance, resource usage, or platform health."""
    sql = """
    SELECT
      DATE(creation_time)                                                       AS query_date,
      COUNT(*)                                                                   AS total_queries,
      COUNTIF(query LIKE '%ai.%' OR query LIKE '%ML.GENERATE_TEXT%')            AS ai_queries,
      ROUND(
        COUNTIF(query LIKE '%ai.%' OR query LIKE '%ML.GENERATE_TEXT%') / COUNT(*) * 100, 1
      )                                                                          AS ai_adoption_pct,
      ROUND(AVG(TIMESTAMP_DIFF(end_time, start_time, MILLISECOND)) / 1000, 2)  AS avg_exec_secs,
      ROUND(AVG(total_slot_ms / NULLIF(TIMESTAMP_DIFF(end_time, start_time, MILLISECOND), 0)), 1) AS avg_slots
    FROM `region-australia-southeast1`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
    WHERE DATE(creation_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
      AND state = 'DONE'
      AND job_type = 'QUERY'
    GROUP BY 1
    ORDER BY 1 DESC
    LIMIT 30
    """
    return _run_query(sql, "platform metrics")


@tool
def query_gemini_insights(question: str) -> str:
    """Retrieve Gemini-generated customer personas and retention strategies.
    Use for CCO questions about specific customer behaviour, why a customer might churn, or personalised strategies."""
    sql = """
    SELECT
      customer_id,
      customer_name,
      customer_segment,
      churn_risk,
      total_lifetime_value,
      days_since_last_purchase,
      gemini_persona_and_strategy
    FROM `vishal-sandpit-474523.ai.customer_concierge`
    WHERE generation_status = 'success'
    ORDER BY total_lifetime_value DESC
    LIMIT 10
    """
    return _run_query(sql, "Gemini customer insights")


@tool
def query_product_performance(question: str) -> str:
    """Query product sales performance, top categories, revenue by product.
    Use for CPO questions about product performance, category trends, top sellers."""
    sql = """
    SELECT
      p.category,
      p.product_name,
      SUM(oi.quantity)               AS units_sold,
      ROUND(SUM(oi.subtotal), 2)    AS total_revenue,
      COUNT(DISTINCT o.order_id)    AS order_count,
      COUNT(DISTINCT o.customer_id) AS unique_buyers
    FROM `vishal-sandpit-474523.gold.fct_orders` o
    JOIN `vishal-sandpit-474523.silver.stg_order_items` oi USING (order_id)
    JOIN `vishal-sandpit-474523.gold.dim_products` p USING (product_id)
    WHERE o.order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
    GROUP BY 1, 2
    ORDER BY total_revenue DESC
    LIMIT 20
    """
    return _run_query(sql, "product performance")


@tool
def query_pipeline_status(question: str) -> str:
    """Query data pipeline status: last run times, batch processing status, any failures.
    Use for CTO questions about data freshness, pipeline health, or delta processing."""
    sql = """
    SELECT
      entity,
      status,
      batch_id,
      rows_processed,
      started_at,
      completed_at,
      error_message
    FROM `vishal-sandpit-474523.governance.batch_audit_log`
    ORDER BY started_at DESC
    LIMIT 20
    """
    return _run_query(sql, "pipeline status")
