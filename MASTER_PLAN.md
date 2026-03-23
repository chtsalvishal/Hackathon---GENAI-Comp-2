# Business-in-a-Box: BigQuery + Gemini Warehouse — Master Plan
**Project**: vishal-sandpit-474523 | **Git**: https://github.com/chtsalvishal/Hackathon---GENAI-Comp-2 | **Date**: 2026-03-23

---

## Mission
Transform raw GCS data into a fully governed, AI-enriched BigQuery warehouse with decision-ready dashboards for CCO, CPO, and CTO stakeholders — deployable to any new GCP project by changing two lines in `terraform.tfvars`.

---

## Team Structure & Ownership

| Role | Owner | Workstream |
|------|-------|-----------|
| Principal Architect | Architect Agent | Overall design, integration, board narrative |
| Infrastructure Engineer | Infra Agent | Terraform modules, IAM, GCS lifecycle, APIs |
| Data Engineer | Data Agent | Dataform Bronze/Silver/Gold + Delta MERGE |
| AI/ML Engineer | AI Agent | BQML ML.GENERATE_TEXT, Reasoning Engine, Agent tools |
| BI Engineer | BI Agent | LookML, Looker dashboards, Looker Studio, BigQuery Canvas |
| Governance Lead | Governance Agent | Data Catalog, policy tags, lineage, compliance score, model governance |

---

## Repository Structure

```
intelia-warehouse/
├── terraform/
│   ├── main.tf                          # Root orchestrator
│   ├── variables.tf                     # All variable declarations
│   ├── terraform.tfvars                 # CHANGE ONLY THIS per client
│   ├── outputs.tf
│   └── modules/
│       ├── project_services/            # Enable all required GCP APIs
│       ├── iam/                         # Analyst vs AI Developer roles
│       ├── bigquery/                    # Datasets + remote Gemini connection
│       ├── storage/                     # GCS staging + lifecycle to Coldline
│       ├── vertex_ai/                   # AI binding, Reasoning Engine
│       ├── dataform/                    # Dataform repo + workspace
│       └── data_catalog/               # Policy tag taxonomy (PII, revenue)
│
├── dataform/
│   ├── dataform.json
│   ├── environments.json                # dev / staging / prod release configs
│   ├── definitions/
│   │   ├── bronze/                      # External tables → gs://intelia-hackathon-files/
│   │   │   ├── ext_customers.sqlx
│   │   │   ├── ext_orders.sqlx
│   │   │   ├── ext_order_items.sqlx
│   │   │   └── ext_products.sqlx
│   │   ├── silver/                      # Cleaned + type-cast + nulls handled
│   │   │   ├── stg_customers.sqlx
│   │   │   ├── stg_orders.sqlx
│   │   │   ├── stg_order_items.sqlx
│   │   │   └── stg_products.sqlx
│   │   ├── gold/                        # Business-ready, stakeholder-facing
│   │   │   ├── dim_customers.sqlx
│   │   │   ├── dim_products.sqlx
│   │   │   ├── fct_orders.sqlx
│   │   │   └── mart_revenue_summary.sqlx
│   │   ├── delta/                       # MERGE upsert scripts for batch_0* files
│   │   │   ├── delta_customers.sqlx
│   │   │   ├── delta_orders.sqlx
│   │   │   ├── delta_order_items.sqlx
│   │   │   └── delta_products.sqlx
│   │   ├── governance/                  # Audit + idempotency tracking
│   │   │   └── batch_audit_log.sqlx     # Records every batch run + status
│   │   ├── assertions/                  # Dataform data quality tests
│   │   │   ├── assert_customers_no_nulls.sqlx
│   │   │   ├── assert_orders_valid_amounts.sqlx
│   │   │   └── assert_referential_integrity.sqlx
│   │   └── ai/                          # Gemini-powered views
│   │       ├── customer_concierge.sqlx  # ML.GENERATE_TEXT personas
│   │       └── ai_enriched_profiles.sqlx
│   └── includes/
│       ├── governance_tags.js           # PII + sensitive_revenue tag helpers
│       └── schema_evolution.js          # Helper for safe column-add migrations
│
├── ai/
│   ├── reasoning_engine/
│   │   ├── agent.py                     # Vertex AI Reasoning Engine agent
│   │   ├── tools.py                     # BQ search tools for ad-hoc queries
│   │   └── requirements.txt
│   ├── bq_data_agent/
│   │   └── agent_config.yaml            # Native BigQuery Data Agent config + tool definitions
│   ├── vertex_ai_studio/
│   │   └── prompt_templates.json        # Versioned prompts for ML.GENERATE_TEXT
│   └── evaluation/
│       ├── model_eval.py                # Gemini output quality scoring
│       └── usage_stats.sql              # Gemini call volume, latency, cost via INFORMATION_SCHEMA
│
├── looker/
│   ├── models/
│   │   └── intelia_warehouse.model.lkml
│   ├── views/
│   │   ├── customers.view.lkml
│   │   ├── orders.view.lkml
│   │   ├── products.view.lkml
│   │   ├── customer_concierge.view.lkml # AI personas column
│   │   └── platform_metrics.view.lkml  # AI adoption + slot utilization
│   └── dashboards/
│       ├── cco_revenue_retention.dashboard.lookml
│       ├── cpo_product_performance.dashboard.lookml  # CPO dashboard
│       └── cto_platform_governance.dashboard.lookml
│
├── looker_studio/
│   └── board_report_template.json       # Looker Studio template for board presentation
│
├── bigquery_canvas/
│   └── executive_canvas.json            # BQ Canvas notebook for ad-hoc C-suite exploration
│
├── scripts/
│   ├── bootstrap.sh                     # Full one-command deploy
│   ├── load_initial_data.sh             # One-time core file load
│   ├── trigger_delta_pipeline.sh        # On-demand delta trigger
│   └── teardown.sh                      # Clean removal of all resources
│
├── monitoring/
│   ├── pipeline_alerts.tf               # Cloud Monitoring alert policies
│   └── budget_alert.tf                  # Budget alert at 80% / 100% spend threshold
│
└── docs/
    ├── board_presentation.md            # C-suite narrative
    └── schema_registry/
        ├── customers_schema.json        # Canonical schema per entity
        ├── orders_schema.json
        ├── order_items_schema.json
        └── products_schema.json
```

---

## 1. Infrastructure & Security (Terraform)

### Single-point configuration (`terraform.tfvars`)
```hcl
project_id = "vishal-sandpit-474523"
region     = "australia-southeast1"
```

### APIs to enable (module: `project_services`)
- `bigquery.googleapis.com`
- `bigqueryconnection.googleapis.com`
- `bigquerydatatransfer.googleapis.com`
- `aiplatform.googleapis.com`
- `dataform.googleapis.com`
- `storage.googleapis.com`
- `datacatalog.googleapis.com`
- `looker.googleapis.com`
- `cloudresourcemanager.googleapis.com`
- `iam.googleapis.com`
- `monitoring.googleapis.com`
- `logging.googleapis.com`

### IAM Design (module: `iam`)
| Role | Permissions | Principals |
|------|------------|-----------|
| `roles/bigquery.dataViewer` + `roles/bigquery.jobUser` | Read BQ, run queries | Data Analysts group |
| `roles/bigquery.dataEditor` + `roles/aiplatform.user` | Write BQ, call Vertex | AI Developers group |
| `roles/dataform.editor` | Manage Dataform repos | Data Engineers group |
| `roles/datacatalog.tagEditor` | Apply policy tags | Governance team |
| **NO** `roles/bigquery.admin` | Prevent privilege escalation | All non-infra principals |

### Secret Manager — Secure Credential Storage
All sensitive values (service account keys, Looker API credentials, connection strings) stored in Secret Manager — never in `.tf` files or environment variables:
```hcl
resource "google_secret_manager_secret" "looker_api_key" {
  secret_id = "looker-api-key"
  replication { auto {} }
}
# Terraform outputs reference secrets, not raw values
output "looker_api_key_secret_name" {
  value = google_secret_manager_secret.looker_api_key.name
}
```

### Cost Governance — Budget Alerts + Service Disablement
```hcl
# Budget alert at 80% and 100% of monthly cap
resource "google_billing_budget" "project_budget" {
  billing_account = var.billing_account_id
  amount { specified_amount { currency_code = "AUD"; units = "500" } }
  threshold_rules { threshold_percent = 0.8 }
  threshold_rules { threshold_percent = 1.0 }
  all_updates_rule {
    pubsub_topic = google_pubsub_topic.budget_alerts.id
  }
}
# Label all BQ jobs for cost attribution
# data_engineer / ai_developer / dashboard / delta_pipeline
```
- All resources tagged with `cost_centre`, `environment`, `workload` labels
- Unused APIs explicitly disabled — only the 12 APIs listed above are active
- BigQuery on-demand pricing (no reserved slots) for development; reservation only for production

### BigQuery Remote Connection (Gemini 1.5 Pro)
```hcl
resource "google_bigquery_connection" "gemini_connection" {
  connection_id = "gemini-pro-connection"
  location      = var.region
  cloud_resource {}
}
# Grant connection SA the Vertex AI User role
resource "google_project_iam_member" "gemini_connection_vertex" {
  role   = "roles/aiplatform.user"
  member = "serviceAccount:${google_bigquery_connection.gemini_connection.cloud_resource[0].service_account_id}"
}
```

### GCS Delta Bucket Lifecycle Policy
```hcl
lifecycle_rule {
  condition { age = 90 }  # Move batches older than 90 days to Coldline
  action    { type = "SetStorageClass"; storage_class = "COLDLINE" }
}
lifecycle_rule {
  condition { age = 365 }
  action    { type = "Delete" }  # Delete after 1 year
}
```

---

## 2. Data Engineering — Medallion Architecture (Dataform)

### Bronze Layer — External Tables (GCS → BigQuery)
- External tables pointing directly to `gs://intelia-hackathon-files/*.csv`
- No data movement; query-in-place for audit trail
- Schema inference + explicit column mapping

### Silver Layer — Standardization
- Cast all types (dates, decimals, UUIDs)
- Null handling and deduplication
- Standardize customer email to lowercase, phone normalization
- Apply Dataform `tags: ["pii"]` on PII columns (email, phone, name)
- Apply `tags: ["sensitive_revenue"]` on revenue/price columns

### Gold Layer — Business-Ready
| Table | Description |
|-------|------------|
| `dim_customers` | SCD-ready customer dimension |
| `dim_products` | Product catalogue with categories |
| `fct_orders` | Grain: one row per order with all metrics |
| `mart_revenue_summary` | Pre-aggregated daily/monthly revenue for dashboards |

### Delta Pattern — MERGE Upsert
```sql
-- delta_customers.sqlx (example pattern for all 4 entities)
MERGE `gold.dim_customers` AS target
USING (
  SELECT * FROM `bronze.ext_customers_delta`
  WHERE _FILE_NAME LIKE '%batch_0%'
    AND DATE(_PARTITIONTIME) = CURRENT_DATE()
) AS source
ON target.customer_id = source.customer_id
WHEN MATCHED THEN UPDATE SET ...
WHEN NOT MATCHED THEN INSERT ...
```
- Triggered by Cloud Scheduler or Dataform schedule
- Detects new `batch_0*` files via `_FILE_NAME` pseudo-column on external tables
- Idempotent — safe to re-run

### Schema Evolution Strategy
New columns in batch files must not break existing pipelines. The approach:

| Scenario | Handling |
|----------|---------|
| New column in delta batch CSV | BigQuery external table uses `schemaUpdateOptions: ALLOW_FIELD_ADDITION` — new column auto-added as `NULLABLE` |
| Column renamed in batch file | Schema registry (`docs/schema_registry/`) defines canonical names; `schema_evolution.js` include maps old → new name before Silver transform |
| Column removed from batch file | External table retains the column as `NULL` for missing rows; Silver layer fills with default value + logs warning to `governance.schema_change_log` |
| Data type change (e.g., INT → STRING) | Silver layer explicit `SAFE_CAST` with fallback — cast failures logged to `governance.cast_error_log`, never silently dropped |
| Breaking change | Blocked in CI via Dataform schema assertion; requires manual migration script + schema registry version bump |

```js
// includes/schema_evolution.js
const SCHEMA_VERSIONS = {
  customers: { v1: ["customer_id","name","email"], v2: ["customer_id","name","email","phone"] },
};
module.exports = { SCHEMA_VERSIONS };
```

### Delta Pipeline Orchestration — Event-Driven Architecture
Files land in GCS → pipeline triggers automatically without polling:

```
gs://intelia-hackathon-files/batch_0* file arrives
        │
        ▼
GCS Pub/Sub Notification (object finalize)
        │
        ▼
Eventarc trigger → Cloud Workflows
        │
        ├─ Step 1: Log batch arrival to governance.batch_audit_log (status: RECEIVED)
        ├─ Step 2: Validate file name matches pattern batch_0[0-9]*_{entity}_delta.csv
        ├─ Step 3: Check batch_audit_log — skip if batch_id already COMPLETED (idempotency)
        ├─ Step 4: Trigger Dataform compilation + delta MERGE run
        ├─ Step 5: Run Dataform assertions
        ├─ Step 6: Update batch_audit_log (status: COMPLETED or FAILED)
        └─ Step 7: Publish success/failure to Cloud Monitoring
```

### Batch Idempotency Tracking Table
```sql
-- governance/batch_audit_log.sqlx
CREATE TABLE IF NOT EXISTS `governance.batch_audit_log` (
  batch_id        STRING NOT NULL,   -- e.g. "batch_01_customers_delta"
  file_name       STRING NOT NULL,   -- full GCS path
  entity          STRING NOT NULL,   -- customers | orders | order_items | products
  status          STRING NOT NULL,   -- RECEIVED | RUNNING | COMPLETED | FAILED
  rows_processed  INT64,
  rows_merged     INT64,
  rows_inserted   INT64,
  error_message   STRING,
  started_at      TIMESTAMP,
  completed_at    TIMESTAMP,
  run_by          STRING             -- Dataform SA identity
)
PARTITION BY DATE(started_at)
CLUSTER BY entity, status;
```
Any re-run of the same `batch_id` checks this table first — if `COMPLETED`, the step is skipped entirely.

### Dataform Data Quality Assertions
Every Silver and Gold table has mandatory assertions that must pass before the next layer runs:
```sql
-- assertions/assert_customers_no_nulls.sqlx
config { type: "assertion", tags: ["quality", "silver"] }
SELECT customer_id, email
FROM ${ref("stg_customers")}
WHERE customer_id IS NULL OR email IS NULL
-- Zero rows expected — any row here = pipeline failure + alert
```

| Assertion | Layer | Rule |
|-----------|-------|------|
| `assert_customers_no_nulls` | Silver | customer_id, email never null |
| `assert_orders_valid_amounts` | Silver | order_total > 0 and <= 1,000,000 |
| `assert_referential_integrity` | Gold | Every order has a valid customer_id in dim_customers |
| `assert_products_valid_price` | Silver | unit_price > 0 |
| `assert_no_duplicate_order_ids` | Gold | COUNT(order_id) = COUNT(DISTINCT order_id) |
| `assert_delta_row_count` | Delta | Merged rows > 0 (empty batch = warning, not failure) |

### BigQuery Partition & Clustering Strategy
Directly impacts CTO query performance metrics:

| Table | Partition | Cluster | Rationale |
|-------|-----------|---------|-----------|
| `fct_orders` | `ORDER BY order_date` (DAY) | `customer_id, product_id` | Date-range scans for revenue; joins on customer/product |
| `mart_revenue_summary` | `DATE(summary_date)` (MONTH) | `region, channel` | Monthly rollups for CCO dashboard |
| `dim_customers` | None (small dimension) | `customer_segment, region` | Filtered by segment in CCO profiles tile |
| `ai.customer_concierge` | None (view, no storage) | — | View over partitioned gold tables |
| `governance.batch_audit_log` | `DATE(started_at)` (DAY) | `entity, status` | Fast lookups for idempotency checks |

### Dataform Environments (dev / staging / prod)
```json
// environments.json
{
  "defaultLocation": "australia-southeast1",
  "environments": [
    {
      "name": "dev",
      "compilationOverrides": { "defaultDatabase": "vishal-sandpit-474523", "defaultSchema": "dev_" }
    },
    {
      "name": "staging",
      "compilationOverrides": { "defaultDatabase": "vishal-sandpit-474523", "defaultSchema": "staging_" }
    },
    {
      "name": "production",
      "compilationOverrides": { "defaultDatabase": "vishal-sandpit-474523", "defaultSchema": "" },
      "scheduledExecutionConfigs": [
        { "cron": "0 3 * * *", "tags": ["daily_refresh"] },
        { "cron": "*/30 * * * *", "tags": ["delta"] }
      ]
    }
  ]
}
```

### Data Lineage
- Dataform's built-in lineage DAG tracks Bronze → Silver → Gold → AI views
- All `sqlx` files declare explicit `ref()` dependencies
- Exported to Data Catalog via Dataform's native integration
- Lineage visible in BigQuery UI: table → "Data Lineage" tab shows full upstream/downstream graph

---

## 3. AI Layer

### Customer Concierge View (ML.GENERATE_TEXT)
```sql
-- customer_concierge.sqlx
CREATE OR REPLACE VIEW `ai.customer_concierge` AS
SELECT
  c.customer_id,
  c.customer_name,
  c.total_lifetime_value,
  c.purchase_frequency,
  ML.GENERATE_TEXT(
    MODEL `ai.gemini_pro_model`,
    STRUCT(
      CONCAT(
        'Customer: ', c.customer_name,
        '. LTV: $', CAST(c.total_lifetime_value AS STRING),
        '. Orders: ', CAST(c.order_count AS STRING),
        '. Top category: ', c.top_category,
        '. Last purchase: ', CAST(c.last_purchase_date AS STRING),
        '. Task: Generate a 2-sentence customer persona and a specific retention strategy.'
      ) AS prompt,
      STRUCT(
        0.2 AS temperature,
        256 AS max_output_tokens
      ) AS generation_config
    )
  ).ml_generate_text_llm_result AS gemini_persona_and_strategy
FROM `gold.dim_customers` c
```

### Vertex AI Studio — Prompt Engineering
Used to design, version, and test all `ML.GENERATE_TEXT` prompts before deploying to production:
- Prompts stored in `ai/vertex_ai_studio/prompt_templates.json` with version numbers
- Each prompt version tested in Vertex AI Studio Prompt Gallery against sample customer records
- Approved prompt version pinned in `customer_concierge.sqlx` — no ad-hoc prompt changes in prod
- Prompt templates parameterised so tone/language can be adjusted per client without code changes

### BigQuery Data Agent (Native — Conversational Analytics)
The **native BigQuery Data Agent** (separate from the Reasoning Engine) provides a natural language interface directly in the BigQuery console:
```yaml
# ai/bq_data_agent/agent_config.yaml
agent_name: intelia-data-agent
description: "Conversational analytics agent for C-suite questions over the Intelia warehouse"
data_sources:
  - dataset: gold
    tables: [dim_customers, dim_products, fct_orders, mart_revenue_summary]
  - dataset: ai
    tables: [customer_concierge, ai_enriched_profiles]
  - dataset: governance
    tables: [batch_audit_log]
allowed_roles:
  - roles/bigquery.dataViewer
sample_questions:
  - "What was our revenue last month vs the month before?"
  - "Which customers have the highest churn risk?"
  - "Show me top 10 products by order volume this quarter"
  - "What percentage of customers made a repeat purchase?"
```
- Accessible via BigQuery console "Data Agent" panel — no code, no SQL required
- C-suite and CCO/CPO can ask questions in plain English and get chart + SQL back
- Complements dashboards for unplanned questions

### BigQuery Canvas — Interactive Executive Exploration
BigQuery Canvas provides a visual, notebook-style workspace for exploratory analysis beyond static dashboards:
- `bigquery_canvas/executive_canvas.json` pre-built canvas with:
  - Revenue trend cell (connected to `mart_revenue_summary`)
  - Customer segment map cell (connected to `dim_customers`)
  - Gemini insights explorer (connected to `ai.customer_concierge`)
  - Delta pipeline status cell (connected to `governance.batch_audit_log`)
- Canvas shared with CCO/CTO/CPO as a "live scratch pad" for board meeting preparation
- Each canvas cell has an AI "Explain this result" button powered by Gemini

### Vertex AI Reasoning Engine — BigQuery Data Agent (Custom)
```python
# agent.py — Vertex AI Reasoning Engine
from vertexai.preview.reasoning_engines import ReasoningEngine, Tool

SEARCH_TOOLS = [
    Tool(
        name="query_revenue_summary",
        description="Query daily/monthly revenue, compare to targets. Use for CTO/CCO revenue questions.",
        func=lambda q: bq_client.query(revenue_sql(q)).to_dataframe()
    ),
    Tool(
        name="query_customer_segments",
        description="Retrieve customer segments, LTV buckets, churn risk scores.",
        func=lambda q: bq_client.query(segments_sql(q)).to_dataframe()
    ),
    Tool(
        name="query_platform_metrics",
        description="Query slot utilization, query execution times, AI adoption rates from INFORMATION_SCHEMA.",
        func=lambda q: bq_client.query(platform_sql(q)).to_dataframe()
    ),
    Tool(
        name="query_gemini_insights",
        description="Retrieve Gemini-generated personas and retention strategies for specific customers.",
        func=lambda q: bq_client.query(insights_sql(q)).to_dataframe()
    ),
]

agent = ReasoningEngine.create(
    reasoning_engine=LangchainAgent(model="gemini-1.5-pro", tools=SEARCH_TOOLS),
    requirements=["google-cloud-bigquery", "langchain-google-vertexai"],
)
```

---

## 4. Executive Dashboards

### CCO Dashboard — Revenue & Retention

**Tile 1: Gross Revenue vs Target**
```sql
SELECT
  DATE_TRUNC(order_date, MONTH) AS month,
  SUM(order_total) AS gross_revenue,
  10000000 AS monthly_target,  -- configurable via BQ param table
  ROUND(SUM(order_total) / 10000000 * 100, 1) AS pct_of_target
FROM `gold.fct_orders`
GROUP BY 1 ORDER BY 1
```

**Tile 2: Customer Profiles with Gemini Insights**
```sql
SELECT
  customer_id,
  customer_name,
  total_lifetime_value AS "LTV (Raw Data)",
  purchase_frequency AS "Purchase Frequency (Raw)",
  gemini_persona_and_strategy AS "Gemini AI Insight"
FROM `ai.customer_concierge`
ORDER BY total_lifetime_value DESC
LIMIT 100
```

**Tile 3: 12-Month Cohort Retention**
```sql
SELECT
  cohort_month,
  months_since_first_purchase,
  COUNT(DISTINCT customer_id) AS active_customers,
  ROUND(COUNT(DISTINCT customer_id) / FIRST_VALUE(COUNT(DISTINCT customer_id))
    OVER (PARTITION BY cohort_month ORDER BY months_since_first_purchase) * 100, 1) AS retention_rate
FROM (
  SELECT
    c.customer_id,
    DATE_TRUNC(MIN(o.order_date) OVER (PARTITION BY c.customer_id), MONTH) AS cohort_month,
    DATE_DIFF(DATE_TRUNC(o.order_date, MONTH),
      MIN(o.order_date) OVER (PARTITION BY c.customer_id), MONTH) AS months_since_first_purchase
  FROM `gold.fct_orders` o
  JOIN `gold.dim_customers` c USING (customer_id)
  WHERE o.order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
)
GROUP BY 1, 2
ORDER BY 1, 2
```

### CPO Dashboard — Product Performance

> **Non-negotiable #4**: Answer CCO, **CPO** and CTO specific needs.

The CPO needs to understand which products are performing, which categories are growing, and where product-level AI can drive upsell.

**Tile 1: Product Revenue by Category**
```sql
SELECT
  p.category,
  p.product_name,
  SUM(oi.quantity) AS units_sold,
  SUM(oi.quantity * oi.unit_price) AS category_revenue,
  ROUND(SUM(oi.quantity * oi.unit_price) /
    SUM(SUM(oi.quantity * oi.unit_price)) OVER () * 100, 1) AS revenue_share_pct
FROM `gold.fct_orders` o
JOIN `gold.dim_products` p USING (product_id)
JOIN `gold.fct_order_items` oi USING (order_id)
WHERE o.order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
GROUP BY 1, 2
ORDER BY category_revenue DESC
```

**Tile 2: Product-Level Gemini Upsell Recommendations**
```sql
SELECT
  p.product_id,
  p.product_name,
  p.category,
  COUNT(DISTINCT o.customer_id) AS unique_buyers,
  ML.GENERATE_TEXT(
    MODEL `ai.gemini_pro_model`,
    STRUCT(
      CONCAT(
        'Product: ', p.product_name, ' in category: ', p.category,
        '. Sold to ', CAST(COUNT(DISTINCT o.customer_id) AS STRING), ' unique customers. ',
        'Suggest 2 cross-sell or upsell strategies to increase basket size.'
      ) AS prompt,
      STRUCT(0.3 AS temperature, 200 AS max_output_tokens) AS generation_config
    )
  ).ml_generate_text_llm_result AS gemini_upsell_strategy
FROM `gold.fct_orders` o
JOIN `gold.fct_order_items` oi USING (order_id)
JOIN `gold.dim_products` p USING (product_id)
GROUP BY p.product_id, p.product_name, p.category
ORDER BY unique_buyers DESC
LIMIT 50
```

**Tile 3: New vs Repeat Buyer Ratio by Product**
```sql
SELECT
  p.product_name,
  COUNTIF(customer_order_rank = 1) AS new_buyer_orders,
  COUNTIF(customer_order_rank > 1) AS repeat_buyer_orders,
  ROUND(COUNTIF(customer_order_rank > 1) /
    COUNT(*) * 100, 1) AS repeat_buyer_pct
FROM (
  SELECT oi.product_id,
    RANK() OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS customer_order_rank
  FROM `gold.fct_orders` o
  JOIN `gold.fct_order_items` oi USING (order_id)
)
JOIN `gold.dim_products` p USING (product_id)
GROUP BY p.product_name
ORDER BY repeat_buyer_pct DESC
```

### CTO Dashboard — Platform & Governance

**Tile 1: AI Adoption Rate**
```sql
SELECT
  DATE(creation_time) AS query_date,
  COUNTIF(referenced_tables LIKE '%ai.customer_concierge%'
       OR referenced_tables LIKE '%ai.ai_enriched%') AS ai_queries,
  COUNT(*) AS total_queries,
  ROUND(COUNTIF(referenced_tables LIKE '%ai%') / COUNT(*) * 100, 1) AS ai_adoption_pct
FROM `region-australia-southeast1`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE DATE(creation_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1 ORDER BY 1
```

**Tile 2: Query Performance & Slot Utilization**
```sql
SELECT
  DATE(creation_time) AS query_date,
  ROUND(AVG(total_slot_ms / TIMESTAMP_DIFF(end_time, start_time, MILLISECOND)), 1) AS avg_slots_used,
  ROUND(AVG(TIMESTAMP_DIFF(end_time, start_time, MILLISECOND)) / 1000, 2) AS avg_exec_time_secs,
  ROUND(AVG(total_bytes_processed) / POW(1024,3), 2) AS avg_gb_processed
FROM `region-australia-southeast1`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE state = 'DONE' AND DATE(creation_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1 ORDER BY 1
```

**Tile 3: Governance Compliance Score**
```sql
SELECT
  table_schema AS dataset,
  table_name,
  COUNT(*) AS total_columns,
  COUNTIF(policy_tags IS NOT NULL) AS tagged_columns,
  ROUND(COUNTIF(policy_tags IS NOT NULL) / COUNT(*) * 100, 1) AS compliance_score_pct
FROM `vishal-sandpit-474523`.INFORMATION_SCHEMA.COLUMN_FIELD_PATHS
LEFT JOIN `region-australia-southeast1`.INFORMATION_SCHEMA.TABLE_OPTIONS
  USING (table_schema, table_name)
WHERE table_schema IN ('gold', 'silver', 'ai')
GROUP BY 1, 2
ORDER BY compliance_score_pct ASC
```

---

## 5. Data Governance Overlay

### Data Catalog Policy Tag Taxonomy
```
Intelia Data Taxonomy
├── PII
│   ├── customer_email
│   ├── customer_phone
│   └── customer_name
├── Sensitive Financial
│   ├── order_total
│   ├── unit_price
│   └── lifetime_value
└── Internal Use Only
    └── internal_cost
```

- Policy tags enforced via column-level security in BigQuery
- Data Analysts cannot see raw PII without explicit masking policy grant
- All tag coverage tracked in CTO compliance score tile

### Row-Level Security (Authorized Views)
Column-level PII masking is not enough — row-level access is needed for regional or team-based data separation:
```sql
-- Authorized view: Analysts only see their region's customers
CREATE OR REPLACE VIEW `gold.dim_customers_authorised` AS
SELECT * FROM `gold.dim_customers`
WHERE region = SESSION_USER_REGION()  -- mapped via IAM attribute
```
- Each stakeholder role gets an authorized view, not direct table access
- CCO sees all regions; regional managers see their own subset
- Authorized views granted via Terraform `google_bigquery_dataset_access` resource

### Model Governance & Usage Statistics
Full AI model lifecycle tracking — addresses Governance guidance #4 explicitly:

| Artefact | Where Stored | Purpose |
|----------|-------------|---------|
| Prompt templates | `ai/vertex_ai_studio/prompt_templates.json` (versioned v1, v2...) | Reproducibility — pinned version deployed to prod |
| Model version | Data Catalog entry on `ai.gemini_pro_model` | Which Gemini model version is in use |
| Evaluation scores | `ai.model_evaluation_log` BQ table | Weekly coherence + relevance scores per prompt version |
| Usage statistics | `ai/evaluation/usage_stats.sql` querying `INFORMATION_SCHEMA.JOBS` | Call volume, avg latency, bytes billed per Gemini invocation |
| Cost per insight | Derived from usage stats | $/customer-insight for ROI reporting to CTO |

```sql
-- ai/evaluation/usage_stats.sql
SELECT
  DATE(creation_time) AS date,
  COUNT(*) AS gemini_calls,
  ROUND(AVG(TIMESTAMP_DIFF(end_time, start_time, MILLISECOND)) / 1000, 2) AS avg_latency_secs,
  ROUND(SUM(total_bytes_billed) / POW(1024,3), 4) AS total_gb_billed
FROM `region-australia-southeast1`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE statement_type = 'SELECT'
  AND query LIKE '%ML.GENERATE_TEXT%'
  AND DATE(creation_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1 ORDER BY 1
```

### Cloud Monitoring — Pipeline Alerting & Data Freshness SLAs
```hcl
# monitoring/pipeline_alerts.tf
resource "google_monitoring_alert_policy" "dataform_pipeline_failure" {
  display_name = "Dataform Pipeline Failure"
  conditions {
    condition_threshold {
      filter = "metric.type=\"logging.googleapis.com/user/dataform_pipeline_status\" AND metric.labels.status=\"FAILED\""
      threshold_value = 1
      comparison      = "COMPARISON_GT"
      duration        = "0s"
    }
  }
  notification_channels = [google_monitoring_notification_channel.email.name]
}

resource "google_monitoring_alert_policy" "data_freshness_sla" {
  display_name = "Gold Layer Stale — SLA Breach"
  # Fires if fct_orders has not been updated in > 6 hours
  conditions {
    condition_threshold {
      filter = "metric.type=\"bigquery.googleapis.com/storage/table_data_size\" AND resource.labels.table_id=\"fct_orders\""
    }
  }
}
```
- Delta pipeline failure → immediate email + PagerDuty notification
- Data freshness SLA: Gold layer must refresh within 6 hours of batch arrival
- Assertion failures → alert with table name + failing row count
- Budget threshold breach → alert to project owner

---

## 6. Security Hardening

1. **No permission leaks**: All SA permissions are minimum-viable, granted per module
2. **Delta bucket lifecycle**: Coldline after 90 days, Delete after 365 days
3. **Column-level security**: PII columns masked for Analyst role via policy tags
4. **Audit logging**: BigQuery data access logs enabled via Terraform
5. **Service account per workload**: Dataform SA, Reasoning Engine SA, Looker SA — all separate
6. **VPC-SC ready**: Variables for optional VPC Service Controls perimeter
7. **Disable unused APIs**: Only listed APIs enabled; all others remain off

---

## 7. Deployment Runbook

### New Project Setup (5 steps)
```bash
# 1. Clone repo
git clone https://github.com/chtsalvishal/Hackathon---GENAI-Comp-2
cd Hackathon---GENAI-Comp-2

# 2. Set your project in ONE file
echo 'project_id = "your-new-project"\nregion = "australia-southeast1"' > terraform/terraform.tfvars

# 3. Authenticate
gcloud auth application-default login

# 4. Deploy everything
./scripts/bootstrap.sh

# 5. Trigger initial data load
./scripts/load_initial_data.sh
```

`bootstrap.sh` sequence:
1. `terraform init && terraform apply` (all modules)
2. Push Dataform repo to GCP Dataform
3. Run Dataform Bronze → Silver → Gold pipeline
4. Deploy Reasoning Engine agent to Vertex AI
5. Verify Looker API connection

---

## 8. Board Presentation Summary

### The Problem
C-suite at Intelia waited **days** for data insights. Analysts manually extracted CSVs. No AI enrichment. Zero governance.

### The Solution
A fully automated, governed, AI-first data warehouse that answers executive questions **in seconds**:

| Stakeholder | Question | Time Before | Time After | Tool |
|------------|---------|------------|-----------|------|
| CCO | "What is our revenue vs target this month?" | 2 days (manual) | **< 3 seconds** | Looker tile |
| CCO | "Why is Customer X churning?" | 1 week (analyst) | **Instant** | Gemini persona in dashboard |
| CCO | "Show me 12-month retention by cohort" | 3 days | **< 5 seconds** | Pre-computed Gold layer |
| CPO | "Which product category is growing fastest?" | 3 days (analyst) | **< 5 seconds** | CPO Looker dashboard |
| CPO | "What upsell strategies work for our top products?" | Never done | **Instant** | Gemini product upsell tile |
| CPO | "Are new or repeat buyers driving revenue?" | 1 week | **< 5 seconds** | CPO repeat buyer tile |
| CTO | "How many queries are hitting our AI views?" | Unknown | **Real-time** | INFORMATION_SCHEMA tile |
| CTO | "Are we compliant with data governance?" | Manual audit (1 week) | **Live score** | Policy tag coverage % |
| CTO | "What's our slot consumption trend?" | Not measured | **30-day chart** | CTO dashboard |
| Any | Ad-hoc question not on a dashboard | Days (analyst ticket) | **< 1 minute** | BigQuery Data Agent (conversational) |
| Any | Exploratory board prep analysis | Days (PowerPoint) | **Minutes** | BigQuery Canvas live workspace |

### Analytics Tool Selection Guide
Each analytics tool has a defined role — no overlap, no confusion:

| Tool | Audience | Use Case | Format |
|------|---------|---------|--------|
| **Looker (LookML)** | CCO, CPO, CTO | Governed, always-on operational dashboards; source of truth metrics | Embedded dashboards |
| **Looker Studio** | Board / C-suite | Polished, branded board-presentation report; shareable link | PDF / interactive report |
| **BigQuery Canvas** | CCO, CPO, CTO | Live exploratory analysis, board meeting prep, "what-if" questions | Notebook-style workspace |
| **BigQuery Data Agent** | Any stakeholder | Ad-hoc plain-English questions not covered by dashboards | Conversational + chart |
| **Vertex AI Reasoning Engine** | Technical users / CTO | Complex multi-step queries, cross-dataset reasoning | API / chat interface |
| **Vertex AI Studio** | AI/ML team | Prompt design, testing, version approval before prod deployment | Studio UI |

### Why This Architecture
- **Medallion (Bronze/Silver/Gold)**: Separation of concerns — raw data preserved, business logic isolated
- **Dataform**: SQL-native transformation with lineage, testing, and scheduling built in
- **ML.GENERATE_TEXT**: Gemini runs inside BigQuery — no data leaves the warehouse, no API keys to manage
- **Reasoning Engine**: Natural language → SQL → insight, for ad-hoc CTO questions not on a dashboard
- **Terraform**: Entire environment reproducible in ~15 minutes on any GCP project

### Client Pitch
> "We deploy a production-grade AI data warehouse in your GCP project in under 30 minutes.
> Your C-suite gets live answers to revenue, retention, and platform questions — enriched by Gemini AI —
> from a single dashboard. No analysts in the loop. Full governance. Fully automated."

---

## Implementation Sprints

### Sprint 1 — Infrastructure Foundation (Day 1)
- [ ] Terraform: project_services module (12 APIs only, all others off)
- [ ] Terraform: IAM module — Analyst, AI Dev, Data Engineer, Governance roles; separate SAs per workload
- [ ] Terraform: BigQuery datasets (bronze, silver, gold, ai, governance)
- [ ] Terraform: GCS staging bucket + lifecycle (Coldline 90d, Delete 365d)
- [ ] Terraform: BigQuery remote connection to Gemini 1.5 Pro + SA Vertex AI User grant
- [ ] Terraform: Data Catalog taxonomy + policy tags (PII, sensitive_revenue, internal_use_only)
- [ ] Terraform: Secret Manager secrets (Looker API key, SA credentials)
- [ ] Terraform: Budget alert at 80% + 100% with Pub/Sub notification
- [ ] Terraform: Cloud Monitoring alert policies (pipeline failure, data freshness SLA)
- [ ] Terraform: Audit logging enabled for BigQuery data access

### Sprint 2 — Data Pipeline (Day 1-2)
- [ ] Dataform environments.json (dev / staging / prod release configs)
- [ ] Dataform: Bronze external tables (customers, orders, order_items, products) with schemaUpdateOptions
- [ ] Dataform: Silver staging layer (cleaning, SAFE_CAST, dedup, PII/revenue tagging)
- [ ] Dataform: Gold dims + facts with partition/clustering strategy applied
- [ ] Dataform: Delta MERGE scripts for all 4 entities (idempotency via batch_audit_log check)
- [ ] Dataform: governance/batch_audit_log table (idempotency tracking)
- [ ] Dataform: All 6 data quality assertions
- [ ] Dataform: includes/governance_tags.js + includes/schema_evolution.js
- [ ] Cloud Workflows: Event-driven delta orchestration (GCS → Eventarc → Workflow → Dataform)
- [ ] docs/schema_registry: Canonical schema JSON files for all 4 entities

### Sprint 3 — AI Layer (Day 2)
- [ ] Terraform: Vertex AI Reasoning Engine provisioning
- [ ] BQML: Remote model creation (gemini-pro via BQ connection)
- [ ] Dataform: customer_concierge view (ML.GENERATE_TEXT with versioned prompt)
- [ ] Dataform: product upsell view (ML.GENERATE_TEXT for CPO dashboard)
- [ ] Vertex AI Studio: Prompt template v1 tested + approved; stored in prompt_templates.json
- [ ] Python: Vertex AI Reasoning Engine agent + 4 search tools
- [ ] YAML: Native BigQuery Data Agent config (agent_config.yaml)
- [ ] BigQuery Canvas: executive_canvas.json with 4 pre-built cells
- [ ] Python: Model evaluation script + usage_stats.sql for model governance

### Sprint 4 — Dashboards (Day 2-3)
- [ ] LookML: Core views (customers, orders, products, AI personas, platform_metrics)
- [ ] LookML: CCO dashboard (revenue vs target, Gemini profiles, 12-month cohort)
- [ ] LookML: CPO dashboard (product revenue by category, Gemini upsell tile, new vs repeat buyers)
- [ ] LookML: CTO dashboard (AI adoption %, query perf + slots, compliance score)
- [ ] Looker Studio: board_report_template.json for board presentation
- [ ] BigQuery Authorized Views: regional row-level security for all stakeholder roles

### Sprint 5 — Automation & Packaging (Day 3)
- [ ] scripts/bootstrap.sh (clone → tfvars → terraform apply → Dataform push → agent deploy → verify)
- [ ] scripts/load_initial_data.sh
- [ ] scripts/trigger_delta_pipeline.sh
- [ ] scripts/teardown.sh (clean removal of all resources)
- [ ] docs/board_presentation.md with Time-to-Insight table (CCO + CPO + CTO)
- [ ] End-to-end smoke test: fresh project → bootstrap → load data → assert quality passes → check all dashboard tiles resolve
- [ ] Verify terraform.tfvars is the ONLY file changed per client deployment
