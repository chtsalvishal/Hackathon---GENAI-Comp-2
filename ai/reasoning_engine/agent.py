"""
Intelia Warehouse — Vertex AI Reasoning Engine Agent
Provides conversational analytics over BigQuery for C-suite stakeholders.
"""

import os
import vertexai
from vertexai.preview import reasoning_engines
from langchain_google_vertexai import ChatVertexAI
from langchain.agents import AgentExecutor, create_tool_calling_agent
from langchain_core.prompts import ChatPromptTemplate
from google.cloud import bigquery

PROJECT_ID = os.environ.get("PROJECT_ID", "vishal-sandpit-474523")
REGION = os.environ.get("REGION", "australia-southeast1")

vertexai.init(project=PROJECT_ID, location=REGION)
bq_client = bigquery.Client(project=PROJECT_ID)


def run_bq_query(sql: str) -> str:
    """Execute a BigQuery SQL query and return results as a formatted string."""
    try:
        df = bq_client.query(sql).to_dataframe()
        if df.empty:
            return "No results found."
        return df.to_string(index=False, max_rows=20)
    except Exception as e:
        return f"Query error: {str(e)}"


# Import tools from tools.py
from tools import (
    query_revenue_summary,
    query_customer_segments,
    query_platform_metrics,
    query_gemini_insights,
    query_product_performance,
    query_pipeline_status,
)

TOOLS = [
    query_revenue_summary,
    query_customer_segments,
    query_platform_metrics,
    query_gemini_insights,
    query_product_performance,
    query_pipeline_status,
]

SYSTEM_PROMPT = """You are the Intelia Data Intelligence Agent — an expert analyst for a retail data warehouse.
You help C-suite executives (CCO, CPO, CTO) get precise, data-driven answers from the Intelia BigQuery warehouse.

Available data:
- Revenue and orders (gold.fct_orders, gold.mart_revenue_summary)
- Customer profiles with AI insights (ai.customer_concierge, gold.dim_customers)
- Product performance (gold.dim_products, ai.product_upsell)
- Platform metrics: query performance, slot usage, AI adoption (INFORMATION_SCHEMA)
- Pipeline status and audit logs (governance.batch_audit_log)

Always:
1. Use the most specific tool available for the question
2. Provide the answer with key numbers first, then context
3. If data is unavailable, say so clearly rather than guessing
4. Format numbers with commas and 2 decimal places for currency
"""

prompt = ChatPromptTemplate.from_messages([
    ("system", SYSTEM_PROMPT),
    ("human", "{input}"),
    ("placeholder", "{agent_scratchpad}"),
])

llm = ChatVertexAI(model_name="gemini-1.5-pro", temperature=0.1, project=PROJECT_ID)
agent = create_tool_calling_agent(llm, TOOLS, prompt)
agent_executor = AgentExecutor(agent=agent, tools=TOOLS, verbose=True, max_iterations=5)


class InteliaWarehouseAgent(reasoning_engines.Queryable):
    """Deployable Reasoning Engine class for Vertex AI."""

    def query(self, input: str) -> str:
        result = agent_executor.invoke({"input": input})
        return result.get("output", "Unable to process query.")


def deploy_agent():
    """Deploy the agent to Vertex AI Reasoning Engine."""
    app = reasoning_engines.ReasoningEngine.create(
        InteliaWarehouseAgent(),
        requirements=[
            "google-cloud-bigquery>=3.0.0",
            "google-cloud-aiplatform>=1.38.0",
            "langchain>=0.1.0",
            "langchain-google-vertexai>=0.1.0",
            "pandas>=2.0.0",
        ],
        display_name="Intelia Warehouse Intelligence Agent",
        description="Conversational analytics agent for CCO, CPO, CTO stakeholders",
    )
    print(f"Agent deployed: {app.resource_name}")
    return app


if __name__ == "__main__":
    deploy_agent()
