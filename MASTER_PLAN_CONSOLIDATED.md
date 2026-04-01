# Business-in-a-Box: Google-Native AI Data Warehouse — Consolidated Master Plan

**Product**: Intelia Business-in-a-Box
**Project**: `vishal-sandpit-474523` | **Region**: `australia-southeast1`
**Architecture**: V2 Google-Native (no Python orchestration)
**Last Updated**: 2026-04-01

---

## 1. Executive Summary / Mission

Intelia's Business-in-a-Box is a production-grade, fully automated, AI-enriched BigQuery data warehouse deployable to any GCP project by changing four values in a single file (`terraform.tfvars`) and running `terraform apply`.

**Mission**: Transform raw CSV data landing in GCS into governed, AI-enriched, executive-ready insights for CCO, CPO, and CTO stakeholders — with zero analyst intervention and full data lineage — in under 30 minutes from cold start.

**Client pitch**: "We deploy a production-grade AI data warehouse in your GCP project in under 30 minutes. Your C-suite gets live answers to revenue, retention, and platform questions — enriched by Gemini 2.5 Flash — from a single dashboard. No analysts in the loop. Full governance. Fully automated. Change four values in one file. Run terraform apply. Done."

---

## 2. What's New: V2 vs V1

| V1 (Python Spaghetti) | V2 (Google-Native) |
|-----------------------|--------------------|
| Python scripts calling Dataform REST API | Dataform Release + Workflow Configurations (Terraform-managed) |
| Python OAuth2 token refresh + polling loops | Eliminated — no Python orchestration anywhere |
| `trigger_delta_pipeline.sh` shell script | GCS → Pub/Sub → Eventarc → Cloud Workflows (fully event-driven) |
| Manual `bq` / `gcloud` CLI calls | Terraform declarative management |
| Dataform assertions for data quality | Dataplex Data Quality scans + scorecards |
| Undocumented lineage | BigQuery native lineage + Dataplex lineage (auto-captured) |
| Manual BigQuery connection creation | Terraform `google_bigquery_connection` resource |
| `scripts/bootstrap.sh` | `terraform apply` from cold start |
| No CI/CD pipeline | Cloud Build triggers on GitHub push |
| No structured monitoring | Cloud Monitoring dashboards + Dataplex quality alerts |
| `dataform/` subfolder (V1 path) | Root-level `definitions/` folder (active V2 pipeline) |
| Gemini views were SQL views | All AI outputs are materialized tables |

---

## 3. Full Architecture Diagram

```
+-------------------------------------------------------------------+
|  DATA SOURCES                                                     |
|  Source Systems -> GCS  gs://vishal-sandpit-474523-delta-staging/ |
|                          batch_*_customers_delta.csv              |
|                          batch_*_orders_delta.csv                 |
|                          batch_*_order_items_delta.csv            |
|                          batch_*_products_delta.csv               |
+--------------------------------+----------------------------------+
                                 | GCS Object Finalize notification
                                 v
+-------------------------------------------------------------------+
|  EVENT-DRIVEN TRIGGER LAYER                                       |
|                                                                   |
|  Cloud Pub/Sub  topic: delta-arrivals                             |
|       |                                                           |
|  Eventarc trigger  (object.finalize on GCS bucket)               |
|       |                                                           |
|  Cloud Workflows: delta-ingest-workflow                           |
|    1. Extract entity from filename (regex)                        |
|    2. Idempotency check -> governance.batch_audit_log             |
|    3. Call Dataform API: compile from main + invoke [delta] tag   |
|    4. Poll Dataform until SUCCEEDED / FAILED (30s intervals)      |
|    5. Write result to batch_audit_log                             |
|    6. Emit custom Cloud Monitoring metric                         |
|                                                                   |
|  Cloud Scheduler (daily):  0 0 * * * -> daily_refresh workflow   |
+--------------------------------+----------------------------------+
                                 |
                                 v
+-------------------------------------------------------------------+
|  DATAFORM PIPELINE  (Git: main branch, root definitions/)         |
|                                                                   |
|  BRONZE (tag: bronze)                                             |
|  +-- ext_customers / ext_orders / ext_order_items / ext_products  |
|  |     External tables -> GCS (query-in-place, no copy)          |
|  +-- ext_*_delta  (LOAD DATA OVERWRITE, autodetect=true)         |
|       Captures new columns automatically on every run            |
|                                                                   |
|  SILVER (tag: silver)                                             |
|  +-- stg_customers   TRIM / lowercase / date parse               |
|  +-- stg_orders      TRIM / date parse / amount cast             |
|  +-- stg_order_items TRIM / subtotal computation                 |
|  +-- stg_products    TRIM / price cast / category normalise      |
|                                                                   |
|  GOLD (tag: gold)                                                 |
|  +-- dim_customers         SCD Type 1 dimension + PII policy tags|
|  +-- dim_customers_analyst PII-masked analyst-safe table         |
|  +-- dim_products          Product catalogue + margin_pct        |
|  +-- fct_orders            Fact table, clustered by customer/date |
|  +-- mart_revenue_summary  Monthly revenue roll-up by country    |
|  +-- mart_executive_summary  Per-customer MoM metrics (no AI)   |
|  +-- rpt_cco_dashboard     Flat order-grain table for CCO LS     |
|  +-- rpt_cpo_dashboard     Flat item-grain table for CPO LS      |
|                                                                   |
|  DELTA (tag: delta) <- event-driven, per file arrival            |
|  +-- delta_customers   schema evolution + MERGE + audit log      |
|  +-- delta_orders      schema evolution + MERGE + audit log      |
|  +-- delta_order_items schema evolution + MERGE + audit log      |
|  +-- delta_products    schema evolution + MERGE + audit log      |
|                                                                   |
|  AI (tag: ai)                                                     |
|  +-- bqml_model           gemini-2.5-flash REMOTE MODEL         |
|  +-- customer_ai_1..4     shard tables (ML.GENERATE_TEXT)        |
|  +-- customer_concierge   materialized table (union of shards)   |
|  +-- product_ai_1..4      shard tables (ML.GENERATE_TEXT)        |
|  +-- product_upsell       materialized table (union of shards)   |
|  +-- ai_enriched_profiles full customer enrichment (table)       |
|  +-- mart_executive_summary_enriched  gold + Gemini (table)     |
|                                                                   |
|  GOVERNANCE (tag: governance)                                     |
|  +-- batch_audit_log      idempotency + pipeline tracking        |
|  +-- schema_change_log    new column detection events            |
|  +-- business_glossary    queryable term definitions             |
|  +-- rpt_cto_dashboard    pipeline run history (table for LS)    |
+--------------------------------+----------------------------------+
                                 |
                                 v
+-------------------------------------------------------------------+
|  BIGQUERY DATA GOVERNANCE (Dataplex)                              |
|                                                                   |
|  Dataplex Lake: intelia-warehouse                                 |
|  +-- Zone: raw      -> GCS bucket (storage type)                 |
|  +-- Zone: curated  -> bronze, silver, gold datasets             |
|  +-- Zone: product  -> ai, governance datasets                   |
|                                                                   |
|  Data Quality Scans (Terraform-managed, scheduled)               |
|  +-- dim_customers:  customer_id NOT NULL, email regex, freshness|
|  +-- fct_orders:     order_date NOT NULL, total_amount range     |
|  +-- dim_products:   unit_price > 0, product_id NOT NULL         |
|  Scorecards visible in Dataplex console + Cloud Monitoring alerts |
|                                                                   |
|  Policy Tag Taxonomy (PII / Sensitive Financial / Internal)       |
|  +-- first_name, last_name, customer_name, email, phone -> PII   |
|  +-- total_lifetime_value, unit_price -> Sensitive Financial      |
|  +-- cost_price -> Internal Use Only                             |
|                                                                   |
|  BigQuery Native Lineage (zero-config, auto-captured)            |
|  GCS -> bronze -> silver -> gold -> ai  (visible in BQ UI)       |
+--------------------------------+----------------------------------+
                                 |
                                 v
+-------------------------------------------------------------------+
|  CONSUMPTION LAYER                                                |
|                                                                   |
|  Looker Studio  (no infra — connects directly to BigQuery)        |
|  +-- CCO Dashboard: rpt_cco_dashboard source                     |
|  +-- CPO Dashboard: rpt_cpo_dashboard source                     |
|  +-- CTO Dashboard: rpt_cto_dashboard source                     |
|                                                                   |
|  BigQuery Data Agent  (natural language -> SQL, no code)         |
|  +-- Configured with gold + ai dataset access                    |
|                                                                   |
|  BigQuery Canvas  (C-suite ad-hoc exploration + Gemini explain)  |
|                                                                   |
|  Vertex AI Agent Builder  (custom agentic workflows)             |
|  +-- Connects to gold + ai datasets, BQ query + insight tools    |
+-------------------------------------------------------------------+
```

---

## 4. Complete Dataform Pipeline

### 4.1 Bronze Layer

All Bronze tables live in the `bronze` BigQuery dataset. External tables are query-in-place (no data movement). Delta tables use `LOAD DATA OVERWRITE` with `autodetect=true` so new CSV columns are absorbed automatically on every run.

| File | Type | Description |
|------|------|-------------|
| `bronze/ext_customers.sqlx` | External table | Query-in-place over full customer CSV |
| `bronze/ext_orders.sqlx` | External table | Query-in-place over full orders CSV |
| `bronze/ext_order_items.sqlx` | External table | Query-in-place over full order items CSV |
| `bronze/ext_products.sqlx` | External table | Query-in-place over full products CSV |
| `bronze/ext_customers_delta.sqlx` | Native table (LOAD DATA OVERWRITE) | Delta batch file, autodetect schema |
| `bronze/ext_orders_delta.sqlx` | Native table (LOAD DATA OVERWRITE) | Delta batch file, autodetect schema |
| `bronze/ext_order_items_delta.sqlx` | Native table (LOAD DATA OVERWRITE) | Delta batch file, autodetect schema |
| `bronze/ext_products_delta.sqlx` | Native table (LOAD DATA OVERWRITE) | Delta batch file, autodetect schema |

### 4.2 Silver Layer

All Silver tables live in the `silver` dataset. All are materialized tables. Handles type casting, null management, deduplication, and PII/revenue column tagging.

| File | Table | Key Transforms |
|------|-------|---------------|
| `silver/stg_customers.sqlx` | `stg_customers` | TRIM, lowercase email/name, date parse, phone normalise |
| `silver/stg_orders.sqlx` | `stg_orders` | TRIM, date parse, SAFE_CAST amounts, status normalise |
| `silver/stg_order_items.sqlx` | `stg_order_items` | TRIM, subtotal = quantity * unit_price, discount apply |
| `silver/stg_products.sqlx` | `stg_products` | TRIM, price/cost cast, margin_pct compute, category normalise |

### 4.3 Gold Layer

All Gold tables live in the `gold` dataset. All are materialized tables. Business-ready, stakeholder-facing.

| File | Table | Description |
|------|-------|-------------|
| `gold/dim_customers.sqlx` | `dim_customers` | SCD Type 1 customer dimension; PII columns carry BigQuery policy tags |
| `gold/dim_customers_analyst.sqlx` | `dim_customers_analyst` | PII-masked version: email SHA-256 hashed, phone truncated, name initialised; lifetime_value bucketed |
| `gold/dim_products.sqlx` | `dim_products` | Product catalogue with category, brand, margin_pct, is_active |
| `gold/fct_orders.sqlx` | `fct_orders` | Order fact, clustered by customer/date; is_first_order flag computed |
| `gold/mart_revenue_summary.sqlx` | `mart_revenue_summary` | Monthly revenue roll-up by country; clustered by summary_date, country |
| `gold/mart_executive_summary.sqlx` | `mart_executive_summary` | Per-customer MoM metrics (no AI columns); clustered by segment/churn/country |
| `gold/rpt_cco_dashboard.sqlx` | `rpt_cco_dashboard` | Flat order-grain table for CCO Looker Studio; 24-month window |
| `gold/rpt_cpo_dashboard.sqlx` | `rpt_cpo_dashboard` | Flat item-grain table for CPO Looker Studio; joins product_upsell |

### 4.4 Delta Layer

Delta operations run as `type: "operations"` in Dataform (DDL/DML). Triggered per file arrival by Cloud Workflows. Each operation is fully idempotent via `batch_audit_log` check.

| File | Target Table | Key Logic |
|------|-------------|-----------|
| `delta/delta_customers.sqlx` | `gold.dim_customers` | Schema evolution detect -> ALTER TABLE -> MERGE -> audit log |
| `delta/delta_orders.sqlx` | `gold.fct_orders` | Schema evolution detect -> ALTER TABLE -> MERGE -> audit log |
| `delta/delta_order_items.sqlx` | `silver.stg_order_items` | Schema evolution detect -> ALTER TABLE -> MERGE -> audit log |
| `delta/delta_products.sqlx` | `gold.dim_products` | Schema evolution detect -> ALTER TABLE -> MERGE -> audit log |

**Delta Idempotency Pattern** (all 4 entities share this structure):
```sql
-- Check if today's batch already completed
SET batch_already_processed = (
  SELECT COUNT(*) > 0
  FROM `governance.batch_audit_log`
  WHERE batch_id = CONCAT('delta_customers_', FORMAT_DATE('%Y%m%d', CURRENT_DATE()))
    AND status = 'COMPLETED'
);

IF NOT batch_already_processed THEN
  -- Insert RUNNING record
  -- Schema evolution: detect new columns via INFORMATION_SCHEMA, ALTER TABLE
  -- Static MERGE for all known columns with COALESCE(source, target) updates
  -- Dynamic MERGE for new columns (EXECUTE IMMEDIATE)
  -- Update audit log to COMPLETED
END IF;
```

**Schema Evolution Logic**:
1. Query `INFORMATION_SCHEMA.COLUMNS` on the delta table
2. Compare against columns in the target Gold table
3. `EXECUTE IMMEDIATE` an `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` for each new column (typed STRING initially)
4. A second dynamic MERGE populates the new columns for all matched rows
5. Event logged to `governance.schema_change_log`

### 4.5 AI Layer

All AI tables live in the `ai` dataset. All are materialized tables (not views).

| File | Table | Description |
|------|-------|-------------|
| `ai/bqml_model.sqlx` | `ai.gemini_pro_model` | BQML remote model: Gemini 2.5 Flash via `gemini-pro-connection` |
| `ai/customer_ai_1.sqlx` | `ai.customer_ai_1` | Shard 1 of 4: ML.GENERATE_TEXT over customer segment 1 |
| `ai/customer_ai_2.sqlx` | `ai.customer_ai_2` | Shard 2 of 4 |
| `ai/customer_ai_3.sqlx` | `ai.customer_ai_3` | Shard 3 of 4 |
| `ai/customer_ai_4.sqlx` | `ai.customer_ai_4` | Shard 4 of 4 |
| `ai/customer_concierge.sqlx` | `ai.customer_concierge` | Union of 4 shards; post_operations drops shards after union |
| `ai/product_ai_1.sqlx` | `ai.product_ai_1` | Shard 1 of 4: ML.GENERATE_TEXT over product segment 1 |
| `ai/product_ai_2.sqlx` | `ai.product_ai_2` | Shard 2 of 4 |
| `ai/product_ai_3.sqlx` | `ai.product_ai_3` | Shard 3 of 4 |
| `ai/product_ai_4.sqlx` | `ai.product_ai_4` | Shard 4 of 4 |
| `ai/product_upsell.sqlx` | `ai.product_upsell` | Union of 4 shards; post_operations drops shards after union |
| `ai/ai_enriched_profiles.sqlx` | `ai.ai_enriched_profiles` | Full customer join: dim_customers + customer_concierge + top_category |
| `ai/mart_executive_summary_enriched.sqlx` | `ai.mart_executive_summary_enriched` | Gold executive summary + Gemini persona column |

### 4.6 Governance Layer

| File | Table | Description |
|------|-------|-------------|
| `governance/batch_audit_log.sqlx` | `governance.batch_audit_log` | Pipeline run log; partitioned by `DATE(started_at)`, clustered by `entity, status` |
| `governance/schema_change_log.sqlx` | `governance.schema_change_log` | Schema evolution events; partitioned by `DATE(detected_at)`, clustered by `table_name, change_type` |
| `governance/business_glossary.sqlx` | `governance.business_glossary` | Authoritative term definitions (Customer, Order, Revenue, Churn Risk, Delta Pipeline, Gemini Insight) |
| `governance/rpt_cto_dashboard.sqlx` | `governance.rpt_cto_dashboard` | Materialized table: pipeline run history for CTO Looker Studio dashboard |

---

## 5. AI Schema: Chunked ML.GENERATE_TEXT

### 5.1 Why Chunked (Shard) Inference

`ML.GENERATE_TEXT` has per-query row limits. To process all customers and products without hitting those limits, each population is split into 4 shards using a deterministic FARM_FINGERPRINT modulo hash. Each shard runs as a separate materialized table (`customer_ai_1` through `customer_ai_4`), then the final table (`customer_concierge`) unions them and cleans up the shards via `post_operations`.

### 5.2 Shard Assignment

```sql
-- Consistent, reproducible shard assignment using hash modulo
MOD(ABS(FARM_FINGERPRINT(customer_id)), 4) = 0  -- shard 1 processes this row
MOD(ABS(FARM_FINGERPRINT(customer_id)), 4) = 1  -- shard 2 processes this row
-- etc.
```

Within each shard file, two internal batches (`batch_id = 0` and `batch_id = 1`) are computed via a secondary hash, further reducing rows per ML.GENERATE_TEXT call.

### 5.3 Prompt Structure and JSON Contract

All prompts instruct the model to return **only** a JSON array with no markdown or explanation:

**Customer prompt**:
```
Return ONLY valid JSON array.
Do not include markdown or explanation.
If invalid, return [].

Format:
[{"customer_id":"","persona":"","strategy":""}]

Segment: {customer_segment}, Risk: {churn_risk}
```

**Product prompt**:
```
Return ONLY valid JSON array.
Do not include markdown or explanation.
If invalid, return [].

Format:
[{"product_id":"","cross_sell":"","upsell":""}]

Name: {product_name}, Category: {category}
```

### 5.4 JSON Extraction Pipeline

The raw model output is a nested BQML response object. Extraction proceeds in three steps:

```sql
-- Step 1: Navigate nested BQML response structure
JSON_VALUE(raw_output, '$.candidates[0].content.parts[0].text') AS raw_text

-- Step 2: Liberal regex to extract the JSON array or object regardless of
--         any surrounding whitespace or partial markdown leakage
REGEXP_EXTRACT(raw_text, r"(\[[\s\S]*\]|\{[\s\S]*\})") AS json_payload

-- Step 3: Parse with COALESCE to handle both array and object forms
COALESCE(
  JSON_VALUE(json_payload, '$[0].persona'),   -- array form (expected)
  JSON_VALUE(json_payload, '$.persona')       -- object form (fallback)
) AS persona
```

This three-step approach (navigate -> extract -> parse with fallback) handles model responses that return an object instead of an array, and gracefully survives partial markdown leakage.

### 5.5 customer_concierge (Materialized Table)

- **Source**: `ai.customer_ai_1` through `ai.customer_ai_4`
- **Post-operations**: DROP TABLE IF EXISTS on each shard (sequential, not parallel)
- **Output columns**: `customer_id`, `persona`, `strategy`, `status`, `generated_at`, `gemini_persona_and_strategy` (concat of persona + strategy)
- **Fallback values**: If persona is NULL → "Generic"; if strategy is NULL → "Monitor Engagement"
- **Tags**: `["ai", "daily_refresh"]`

### 5.6 product_upsell (Materialized Table)

- **Source**: `ai.product_ai_1` through `ai.product_ai_4`
- **Post-operations**: DROP TABLE IF EXISTS on each shard (sequential)
- **Output columns**: `product_id`, `cross_sell`, `upsell`, `status`, `generated_at`, `gemini_upsell_strategy` (concat of cross_sell + upsell)
- **Fallback values**: If cross_sell is NULL → "No Cross-sell Strategy"; if upsell is NULL → "Basic Upsell"
- **Tags**: `["ai", "daily_refresh"]`

### 5.7 BQML Model Definition

```sql
-- definitions/ai/bqml_model.sqlx
CREATE OR REPLACE MODEL `PROJECT.ai.gemini_pro_model`
REMOTE WITH CONNECTION `australia-southeast1.gemini-pro-connection`
OPTIONS (endpoint = 'gemini-2.5-flash');
```

The connection `gemini-pro-connection` is a `google_bigquery_connection` resource created by Terraform. The connection's service account is granted `roles/aiplatform.user` to call Vertex AI.

---

## 6. Dashboard Layer

All three dashboard tables are **materialized tables** (not views). They are pre-joined, pre-filtered flat tables designed for direct Looker Studio connection — Looker Studio aggregates from the flat grain, requiring no complex SQL in the data source.

### 6.1 rpt_cco_dashboard (gold dataset)

**Grain**: One row per order (order-grain)
**Window**: Last 24 months
**Tags**: `gold`, `daily_refresh`, `dashboard`, `cco`

| Column | Source | Description |
|--------|--------|-------------|
| `order_id` | `fct_orders` | Order identifier |
| `order_date` | `fct_orders` | Transaction date |
| `year_month` | computed | `FORMAT_DATE('%Y-%m', order_date)` for time-series |
| `customer_id` | `fct_orders` | Customer reference |
| `order_revenue` | `fct_orders.total_amount` | Revenue per order |
| `item_count` | `fct_orders` | Items in order |
| `avg_item_price` | `fct_orders` | Average item price |
| `country` | `fct_orders.shipping_country` | Geography for geo map |
| `customer_type` | computed | 'New' if is_first_order else 'Returning' |
| `customer_segment` | `dim_customers_analyst` | Platinum / Gold / Silver / Bronze |
| `churn_risk` | `dim_customers_analyst` | Active / Cooling / At Risk / Churned |
| `lifetime_value_band` | `dim_customers_analyst` | Bucketed LTV (0-999 / 1000-4999 / etc.) |

**Looker Studio use cases**: Revenue scorecard, MoM trend line, new vs returning bar, country geo map, segment pie, churn risk filter, LTV band histogram.

### 6.2 rpt_cpo_dashboard (gold dataset)

**Grain**: One row per order item (item-grain)
**Window**: Last 24 months
**Tags**: `gold`, `daily_refresh`, `dashboard`, `cpo`

| Column | Source | Description |
|--------|--------|-------------|
| `order_item_id` | `stg_order_items` | Item identifier |
| `order_date` | `fct_orders` | Transaction date |
| `year_month` | computed | Month label for trend |
| `product_id` | `dim_products` | Product reference |
| `product_name` | `dim_products` | Product display name |
| `category` | `dim_products` | Product category |
| `sub_category` | `dim_products` | Product sub-category |
| `brand` | `dim_products` | Product brand |
| `units_sold` | `stg_order_items.quantity` | Quantity per line item |
| `unit_price` | `stg_order_items` | Actual sale price |
| `discount` | `stg_order_items` | Discount applied |
| `item_revenue` | `stg_order_items.subtotal` | Revenue per line |
| `margin_pct` | `dim_products` | Gross margin percentage |
| `gemini_upsell_strategy` | `product_upsell` | Gemini cross-sell + upsell text |
| `upsell_status` | `product_upsell.generation_status` | AI generation status |

**Looker Studio use cases**: Category revenue bar, product revenue leaderboard, brand performance, margin trend, units sold, Gemini upsell strategy filter/table.

### 6.3 rpt_cto_dashboard (governance dataset)

**Grain**: One row per pipeline run
**Tags**: `governance`, `daily_refresh`, `dashboard`, `cto`

| Column | Source | Description |
|--------|--------|-------------|
| `run_date` | `batch_audit_log.started_at` | Date of pipeline run |
| `run_ts` | `batch_audit_log.started_at` | Timestamp formatted for display |
| `entity` | `batch_audit_log` | customers / orders / order_items / products |
| `status` | `batch_audit_log` | RUNNING / COMPLETED / FAILED |
| `source_file` | `batch_audit_log` | GCS file path that triggered run |
| `rows_merged` | `batch_audit_log` | Rows merged in MERGE operation |
| `rows_inserted` | `batch_audit_log` | Net new rows inserted |
| `rows_updated` | `batch_audit_log` | Rows updated |
| `error_message` | `batch_audit_log` | Error detail if FAILED |
| `duration_secs` | computed | `DATETIME_DIFF(completed_at, started_at, SECOND)` |
| `dataform_run_id` | `batch_audit_log` | Dataform invocation reference |

**Looker Studio use cases**: Pipeline health scorecard, run history table, failure rate trend, duration chart, row throughput, error message filter.

---

## 7. Infrastructure: Terraform Modules

### Single-Point Configuration

Only four values change per client deployment:
```hcl
# terraform/terraform.tfvars
project_id                 = "new-client-project-id"
region                     = "australia-southeast1"
billing_account_id         = "XXXXX-XXXXX-XXXXX"
github_app_installation_id = 123456789
```

### Module Map (15 Modules, Actual Codebase)

| # | Module | Resources Created |
|---|--------|-------------------|
| 1 | `project_services` | Enables 22 APIs exactly; `disable_on_destroy = true` |
| 2 | `iam` | Service accounts per workload + IAM bindings (least-privilege) |
| 3 | `secret_manager` | GitHub token secret; no plaintext credentials anywhere |
| 4 | `storage` | GCS staging bucket + lifecycle (Coldline 90d, Delete 365d) + Pub/Sub notification |
| 5 | `bigquery` | Datasets (bronze/silver/gold/ai/governance) + Gemini remote connection |
| 6 | `data_catalog` | Policy tag taxonomy (PII / Sensitive Financial / Internal Use Only) + BQ audit logging |
| 7 | `dataform` | Repository linked to GitHub + release config (main branch) + workflow configs |
| 8 | `vertex_ai` | Validates aiplatform API; Gemini connection SA granted `roles/aiplatform.user` |
| 9 | `pubsub` | `delta-arrivals` topic + subscription |
| 10 | `eventarc` | Trigger: GCS `object.finalize` -> Cloud Workflows delta-ingest |
| 11 | `cloud_workflows` | `delta-ingest-workflow.yaml` + `daily-refresh-workflow.yaml` |
| 12 | `cloud_scheduler` | Daily full-refresh cron (00:00 AEDT) |
| 13 | `dataplex` | Lake + 3 zones (raw/curated/product) + data quality scan configs |
| 14 | `monitoring` | Budget alert (80%/100%), pipeline failure alert, data freshness SLA alert |
| 15 | `cloud_build` | CI/CD triggers on GitHub: PR validation + main branch deploy |

### APIs Enabled (22 total)

```hcl
"bigquery.googleapis.com"
"bigqueryconnection.googleapis.com"
"bigquerydatatransfer.googleapis.com"
"bigquerydatapolicy.googleapis.com"
"aiplatform.googleapis.com"
"dataform.googleapis.com"
"dataplex.googleapis.com"
"datacatalog.googleapis.com"
"storage.googleapis.com"
"pubsub.googleapis.com"
"eventarc.googleapis.com"
"workflows.googleapis.com"
"cloudscheduler.googleapis.com"
"cloudbuild.googleapis.com"
"secretmanager.googleapis.com"
"monitoring.googleapis.com"
"logging.googleapis.com"
"iam.googleapis.com"
"cloudresourcemanager.googleapis.com"
"cloudaicompanion.googleapis.com"      # Gemini for BigQuery / Data Agent
"discoveryengine.googleapis.com"       # Vertex AI Agent Builder
"billingbudgets.googleapis.com"        # Budget alerts
```

All others remain off. `disable_on_destroy = true` disables APIs on `terraform destroy`.

### IAM: Service Accounts Per Workload

| Service Account | Purpose | Key Roles |
|----------------|---------|-----------|
| `dataform-sa` | Runs all Dataform jobs | `bigquery.dataEditor`, `bigquery.jobUser`, `dataform.serviceAgent` |
| `workflows-sa` | Executes Cloud Workflows | `dataform.editor`, `bigquery.jobUser`, `workflows.invoker` |
| `eventarc-sa` | Routes GCS events to Workflows | `eventarc.eventReceiver`, `workflows.invoker` |
| `scheduler-sa` | Triggers Cloud Workflows on schedule | `workflows.invoker` |
| `gemini-connection-sa` | BigQuery ML -> Vertex AI | `aiplatform.user` |
| `dataplex-sa` | Runs data quality scans | `bigquery.dataViewer`, `dataplex.viewer` |
| `cloudbuild-sa` | CI/CD: validates + deploys Dataform | `dataform.editor`, `source.reader` |

No personal credentials in any pipeline. `gcloud auth application-default login` is for local development only.

### Dataform: Release + Workflow Configurations

```hcl
resource "google_dataform_release_config" "production" {
  name          = "production"
  git_commitish = "main"
}

resource "google_dataform_workflow_config" "daily_refresh" {
  name           = "daily-refresh"
  release_config = google_dataform_release_config.production.id
  invocation_config {
    included_tags                    = ["daily_refresh"]
    transitive_dependencies_included = true
  }
}
```

---

## 8. Event-Driven Orchestration: Cloud Workflows Delta-Ingest

This replaces all Python orchestration permanently. Every new `batch_*` file landing in GCS automatically triggers the correct delta pipeline with zero manual intervention.

### End-to-End Flow

```
New file: gs://PROJECT-delta-staging/batch_02_orders_delta.csv
    |
    +-- GCS emits Pub/Sub notification on object.finalize
    |
    +-- Eventarc routes to Cloud Workflows: delta-ingest-workflow
    |
    +-- Workflow steps:
        1. Parse filename -> extract entity (e.g., "orders")
        2. Check governance.batch_audit_log -- skip if already COMPLETED
        3. POST to Dataform compilationResults API (gitCommitish: main)
        4. POST to Dataform workflowInvocations (includedTags: ["delta"])
        5. Poll workflowInvocations until SUCCEEDED or FAILED (30s sleep loop)
        6. Write final status to governance.batch_audit_log via BQ jobs API
        7. Emit custom Cloud Monitoring metric: delta_pipeline_result
```

### Workflow YAML (abbreviated)

```yaml
# terraform/modules/cloud_workflows/delta-ingest-workflow.yaml
main:
  params: [event]
  steps:
    - extract_filename:
        assign:
          - filename: ${event.data.name}
          - entity:   <regex-extracted entity name>

    - check_idempotency:
        call: googleapis.bigquery.v2.jobs.query
        args:
          body:
            query: >
              SELECT COUNT(*) > 0 AS already_done
              FROM `governance.batch_audit_log`
              WHERE batch_id = CONCAT('delta_', entity, '_', FORMAT_DATE('%Y%m%d', CURRENT_DATE()))
                AND status = 'COMPLETED'
        result: idempotency_response

    - skip_if_done:
        switch:
          - condition: ${idempotency_response.rows[0].f[0].v == "true"}
            next: end

    - compile_dataform:
        call: http.post  # Dataform compilationResults API
        args: { gitCommitish: main }
        result: compile_result

    - invoke_delta:
        call: http.post  # Dataform workflowInvocations API
        args: { includedTags: ["delta"] }
        result: invocation

    - poll_loop:
        steps:
          - check_state: { call: http.get, result: poll_result }
          - evaluate_state:
              switch:
                - condition: ${poll_result.body.state == "SUCCEEDED"}
                  next: log_success
                - condition: ${poll_result.body.state == "FAILED"}
                  next: log_failure
          - wait: { call: sys.sleep, args: { seconds: 30 }, next: check_state }

    - log_success:
        call: googleapis.bigquery.v2.jobs.insert  # UPDATE batch_audit_log -> COMPLETED
```

### Schedulers

| Scheduler | Cron | Trigger | Purpose |
|-----------|------|---------|---------|
| Daily refresh | `0 0 * * *` | `daily-refresh-workflow` | Full pipeline run: bronze -> silver -> gold -> AI |
| (Eventarc) | On file arrival | `delta-ingest-workflow` | Per-entity incremental MERGE |

---

## 9. Data Governance

### Dataplex Lake Structure

```
Dataplex Lake: intelia-warehouse
+-- Zone: raw-zone      (STORAGE type)  -> GCS staging bucket
+-- Zone: curated-zone  (BIGQUERY type) -> bronze, silver, gold datasets
+-- Zone: product-zone  (BIGQUERY type) -> ai, governance datasets
```

### Data Quality Scans (Terraform-Managed)

Scans run 30 minutes after the daily Dataform run. Scorecards visible in Dataplex console. Failures trigger Cloud Monitoring alert (score below 95% threshold).

| Scan | Table | Rules |
|------|-------|-------|
| `dim-customers-quality` | `gold.dim_customers` | customer_id NOT NULL, email regex valid, total_lifetime_value >= 0, freshness < 25h |
| `fct-orders-quality` | `gold.fct_orders` | order_date NOT NULL, total_amount 0-1,000,000, order_id UNIQUE |
| `dim-products-quality` | `gold.dim_products` | unit_price > 0, product_id NOT NULL |

### Policy Tag Taxonomy

```
Intelia Data Taxonomy (Dataplex / Data Catalog)
+-- PII
|   +-- first_name, last_name, customer_name  -> masked for Analyst role
|   +-- email                                 -> masked for Analyst role
|   +-- phone                                 -> masked for Analyst role
+-- Sensitive Financial
|   +-- total_lifetime_value
|   +-- unit_price, cost_price
+-- Internal Use Only
    +-- cost_price (product margin inputs)
```

Policy tags are applied directly in `dim_customers.sqlx` via Dataform column metadata. Analysts who lack the `datacatalog.categoryFineGrainedReader` permission see the column as `NULL`.

`dim_customers_analyst` provides a pre-masked version: email is SHA-256 hashed, phone is truncated to last 4 digits, names are initialised, lifetime value is bucketed.

### batch_audit_log Schema

```sql
-- governance.batch_audit_log
-- Partitioned by DATE(started_at), Clustered by [entity, status]
batch_id        STRING    -- e.g. "delta_customers_20260401"
source_file     STRING    -- GCS path
entity          STRING    -- customers | orders | order_items | products
status          STRING    -- RUNNING | COMPLETED | FAILED
rows_merged     INT64
rows_inserted   INT64
rows_updated    INT64
error_message   STRING
started_at      TIMESTAMP
completed_at    TIMESTAMP
dataform_run_id STRING
```

### schema_change_log Schema

```sql
-- governance.schema_change_log
-- Partitioned by DATE(detected_at), Clustered by [table_name, change_type]
event_id    STRING
table_name  STRING
column_name STRING
change_type STRING    -- NEW_COLUMN | TYPE_CHANGE | COLUMN_REMOVED
old_value   STRING
new_value   STRING
detected_at TIMESTAMP
handled_by  STRING
```

### business_glossary

Queryable table of authoritative definitions for: Customer, Order, Revenue, Product, Churn Risk, Delta Pipeline, Gemini Insight. Each entry includes `domain`, `owner`, `update_frequency`, `example_query`, and `related_tables`.

### BigQuery Native Lineage

Auto-captured by BigQuery for all Dataform-run jobs. Visible in BigQuery UI under each table's "Data Lineage" tab:

```
gs://bucket/customers.csv
  -> bronze.ext_customers_delta    (LOAD DATA OVERWRITE)
  -> gold.dim_customers            (MERGE via delta_customers)
  -> gold.dim_customers_analyst    (CREATE OR REPLACE TABLE AS SELECT)
  -> ai.customer_ai_1..4           (ML.GENERATE_TEXT)
  -> ai.customer_concierge         (UNION ALL)
  -> ai.ai_enriched_profiles       (JOIN)
```

---

## 10. Deployment Guide

### Prerequisites

- GCP project with billing enabled
- GitHub repository connected via Cloud Build GitHub App
- `gcloud auth application-default login` on local machine

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/chtsalvishal/Hackathon---GENAI-Comp-2.git
cd Hackathon---GENAI-Comp-2

# 2. Edit the ONE file that changes per client (4 values only)
#    terraform/terraform.tfvars:
#      project_id                 = "new-client-project-id"
#      region                     = "australia-southeast1"
#      billing_account_id         = "XXXXX-XXXXX-XXXXX"
#      github_app_installation_id = 123456789

# 3. Deploy all infrastructure
cd terraform
terraform init
terraform apply -auto-approve

# 4. Upload source data to GCS (one-time seed)
gsutil -m cp data/*.csv gs://new-client-delta-staging/

# 5. Dataform Workflow Config auto-runs on its cron schedule.
#    OR: manually trigger via GCP Console -> Dataform -> Workflow Configurations
```

### What `terraform apply` Creates

- GCS staging bucket with lifecycle rules
- All BigQuery datasets (bronze / silver / gold / ai / governance)
- BigQuery remote Gemini connection + aiplatform.user IAM binding
- Policy tag taxonomy in Data Catalog
- Dataform repository linked to GitHub + release config + workflow configs
- Dataplex lake + 3 zones + data quality scan configs
- Cloud Workflows: `delta-ingest-workflow` + `daily-refresh-workflow` deployed
- Eventarc trigger: GCS object.finalize -> Cloud Workflows
- Cloud Scheduler: daily_refresh cron
- Cloud Build triggers: PR validation + main branch deploy
- Cloud Monitoring: budget alert (80%/100%) + pipeline failure alert + data freshness SLA
- Secret Manager: GitHub token secret

**Time to first data in gold layer: approximately 15 minutes after `terraform apply`.**

### CI/CD (Cloud Build)

```
Developer pushes to feature branch
  -> Cloud Build trigger: cloudbuild-validate.yaml
     1. npm install -g @dataform/cli
     2. dataform compile (syntax + dependency check)
     Result: Pass/fail on PR

Merge to main
  -> Cloud Build trigger: cloudbuild-deploy.yaml
     1. dataform compile --git-commitish=main
     2. Dataform Release Config picks up new snapshot
     3. Next Workflow Config run uses updated code automatically
```

### Teardown

```bash
cd terraform
terraform destroy -auto-approve
```

---

## 11. Consumption Layer

### Tool Selection Guide

| Tool | Audience | Use Case | Access |
|------|---------|---------|--------|
| **Looker Studio** | CCO, CPO, CTO, Board | Always-on operational dashboards; board presentation PDF | Shared link, browser, no login |
| **BigQuery Data Agent** | Any C-suite | Ad-hoc plain-English questions; agent writes SQL, returns chart + table | BigQuery Console -> Data Agent panel |
| **BigQuery Canvas** | CCO, CPO, CTO | Live exploratory analysis; board prep; Gemini "explain this" on each cell | BigQuery Console -> Canvas |
| **Vertex AI Agent Builder** | Technical / CTO | Complex multi-step reasoning, custom tool orchestration | Chat interface or embedded app |
| **Dataplex Console** | CTO, Data Engineering | Data quality scorecards, lineage explorer, policy tag coverage | GCP Console -> Dataplex |

### Stakeholder Time-to-Insight Matrix

| Stakeholder | Question | Before | After | Tool |
|------------|---------|--------|-------|------|
| CCO | "Revenue vs target this month?" | 2 days (manual) | < 3 seconds | Looker Studio tile |
| CCO | "Why is Customer X churning?" | 1 week analyst | Instant | Gemini persona in customer_concierge |
| CCO | "12-month cohort retention?" | 3 days | < 5 seconds | Pre-computed gold layer |
| CPO | "Fastest growing product category?" | 3 days | < 5 seconds | CPO Looker Studio dashboard |
| CPO | "Upsell strategies for top products?" | Never done | Instant | Gemini upsell tile from product_upsell |
| CPO | "New vs repeat buyer split?" | 1 week | < 5 seconds | rpt_cpo_dashboard |
| CTO | "How many queries hit our AI views?" | Unknown | Real-time | INFORMATION_SCHEMA tile |
| CTO | "Governance compliance score?" | Manual audit 1 week | Live % | Dataplex + policy tag coverage |
| CTO | "Is the delta pipeline healthy?" | Manual check | Real-time | rpt_cto_dashboard |
| Any | Question not on a dashboard | Days (analyst ticket) | < 1 minute | BigQuery Data Agent |
| Any | Board prep exploratory analysis | Days (PowerPoint) | Minutes | BigQuery Canvas |

### BigQuery Data Agent Configuration

```yaml
# data_agent/agent_config.yaml
agent_name: intelia-data-agent
data_sources:
  - dataset: gold
    tables: [dim_customers, dim_products, fct_orders, mart_revenue_summary, mart_executive_summary]
  - dataset: ai
    tables: [customer_concierge, ai_enriched_profiles, product_upsell, mart_executive_summary_enriched]
  - dataset: governance
    tables: [batch_audit_log, business_glossary]
sample_questions:
  - "What was our revenue last month vs the month before?"
  - "Which customers have the highest churn risk?"
  - "Show me top 10 products by revenue in the last quarter"
  - "What percentage of customers made a repeat purchase?"
  - "Which customer segment has the highest average order value?"
```

---

## 12. Team / Agent Roles

| Role | Owner | Workstream |
|------|-------|-----------|
| Principal Architect | Architect Agent | Overall design, integration, board narrative |
| Infrastructure Engineer | Infra Agent | Terraform modules, IAM, GCS lifecycle, APIs |
| Data Engineer | Data Agent | Dataform Bronze/Silver/Gold + Delta MERGE |
| AI/ML Engineer | AI Agent | BQML ML.GENERATE_TEXT, chunked inference, JSON extraction |
| BI Engineer | BI Agent | Looker Studio dashboards, BigQuery Canvas |
| Governance Lead | Governance Agent | Dataplex, policy tags, lineage, compliance score, model governance |

---

## 13. File and Folder Structure

```
GenAI2/                                    <- repository root
|
+-- definitions/                           <- ACTIVE Dataform pipeline (V2)
|   +-- bronze/
|   |   +-- ext_customers.sqlx             <- External table (query-in-place)
|   |   +-- ext_orders.sqlx
|   |   +-- ext_order_items.sqlx
|   |   +-- ext_products.sqlx
|   |   +-- ext_customers_delta.sqlx       <- LOAD DATA OVERWRITE (autodetect)
|   |   +-- ext_orders_delta.sqlx
|   |   +-- ext_order_items_delta.sqlx
|   |   +-- ext_products_delta.sqlx
|   +-- silver/
|   |   +-- stg_customers.sqlx
|   |   +-- stg_orders.sqlx
|   |   +-- stg_order_items.sqlx
|   |   +-- stg_products.sqlx
|   +-- gold/
|   |   +-- dim_customers.sqlx             <- PII policy tags applied here
|   |   +-- dim_customers_analyst.sqlx     <- PII-masked analyst-safe table
|   |   +-- dim_products.sqlx
|   |   +-- fct_orders.sqlx
|   |   +-- mart_revenue_summary.sqlx
|   |   +-- mart_executive_summary.sqlx
|   |   +-- rpt_cco_dashboard.sqlx         <- Materialized table for CCO Looker Studio
|   |   +-- rpt_cpo_dashboard.sqlx         <- Materialized table for CPO Looker Studio
|   +-- delta/
|   |   +-- delta_customers.sqlx           <- Schema evolution + MERGE + audit log
|   |   +-- delta_orders.sqlx
|   |   +-- delta_order_items.sqlx
|   |   +-- delta_products.sqlx
|   +-- ai/
|   |   +-- bqml_model.sqlx               <- gemini-2.5-flash remote model
|   |   +-- customer_ai_1.sqlx            <- Shard 1: ML.GENERATE_TEXT customer batch
|   |   +-- customer_ai_2.sqlx
|   |   +-- customer_ai_3.sqlx
|   |   +-- customer_ai_4.sqlx
|   |   +-- customer_concierge.sqlx       <- Union + post_operations drop shards
|   |   +-- product_ai_1.sqlx             <- Shard 1: ML.GENERATE_TEXT product batch
|   |   +-- product_ai_2.sqlx
|   |   +-- product_ai_3.sqlx
|   |   +-- product_ai_4.sqlx
|   |   +-- product_upsell.sqlx           <- Union + post_operations drop shards
|   |   +-- ai_enriched_profiles.sqlx     <- Full customer enrichment table
|   |   +-- mart_executive_summary_enriched.sqlx
|   +-- governance/
|       +-- batch_audit_log.sqlx          <- Idempotency + run tracking
|       +-- schema_change_log.sqlx        <- Column evolution events
|       +-- business_glossary.sqlx        <- Authoritative term definitions
|       +-- rpt_cto_dashboard.sqlx        <- Materialized pipeline history for CTO
|
+-- includes/                             <- Dataform JS helpers
|   +-- governance_tags.js               <- PII + financial tag helpers
|   +-- schema_evolution.js              <- Schema version mapping
|
+-- terraform/
|   +-- main.tf                          <- 15-module orchestrator
|   +-- variables.tf
|   +-- terraform.tfvars                 <- CHANGE ONLY THIS PER CLIENT (4 values)
|   +-- outputs.tf
|   +-- modules/
|       +-- project_services/            <- 22 APIs enabled, all others off
|       +-- iam/                         <- SA per workload, least-privilege bindings
|       +-- secret_manager/              <- GitHub token, no plaintext credentials
|       +-- storage/                     <- GCS bucket + lifecycle + Pub/Sub notification
|       +-- bigquery/                    <- Datasets + Gemini remote connection
|       +-- data_catalog/               <- Policy tag taxonomy + BQ audit logging
|       +-- dataform/                    <- Repo + release config + workflow configs
|       +-- vertex_ai/                   <- aiplatform API validation + connection IAM
|       +-- pubsub/                      <- delta-arrivals topic + subscription
|       +-- eventarc/                    <- GCS finalize -> Cloud Workflows trigger
|       +-- cloud_workflows/             <- delta-ingest-workflow.yaml + daily-refresh-workflow.yaml
|       +-- cloud_scheduler/             <- Daily cron (00:00 AEDT)
|       +-- dataplex/                    <- Lake + 3 zones + DQ scan configs
|       +-- monitoring/                  <- Budget + pipeline failure + freshness alerts
|       +-- cloud_build/                <- CI/CD triggers (PR validate + main deploy)
|
+-- data_agent/
|   +-- agent_config.yaml               <- Native BQ Data Agent configuration
|
+-- ai/
|   +-- vertex_ai_studio/
|   |   +-- prompt_templates.json       <- Versioned prompts for model governance
|   +-- evaluation/
|       +-- usage_stats.sql             <- Gemini call volume, latency, cost via INFORMATION_SCHEMA
|
+-- bigquery_canvas/
|   +-- executive_canvas.json           <- Pre-built canvas for C-suite exploration
|
+-- looker_studio/
|   +-- board_report_template.json      <- Looker Studio template
|
+-- monitoring/
|   +-- pipeline_alerts.tf              <- Cloud Monitoring alert policies (enhanced)
|   +-- budget_alert.tf                 <- Budget alert resource
|
+-- cloudbuild-validate.yaml            <- PR validation (dataform compile)
+-- cloudbuild-deploy.yaml              <- Main branch deploy
+-- workflow_settings.yaml              <- Dataform workspace settings
+-- environments.json                   <- Dataform dev/staging/prod compilation overrides
+-- package.json                        <- Dataform JS dependencies
+-- docs/
    +-- schema_registry/
        +-- customers_schema.json       <- Canonical schema per entity
        +-- orders_schema.json
        +-- order_items_schema.json
        +-- products_schema.json
```

> **Note**: The `dataform/` subfolder at root was V1 and is being removed. The active pipeline is the root-level `definitions/` folder, read directly by Dataform from the repository root.

---

## 14. Key Design Decisions

### No Views — All Materialized Tables

Every output in the pipeline is a materialized table, including the AI layer and dashboard sources. This is a deliberate, non-negotiable design decision:

- **Performance**: Looker Studio queries complete in < 3 seconds regardless of dataset size. No view fan-out, no repeated ML.GENERATE_TEXT calls at query time.
- **Cost control**: ML.GENERATE_TEXT runs once per daily refresh cycle, not on every dashboard load.
- **Reliability**: Dashboard tiles never fail due to upstream view resolution errors.
- **Lineage clarity**: BigQuery lineage graph shows clean table-to-table edges; view chains obscure lineage.

The only exception is `dim_customers_analyst`, which is technically still a table but serves the function a view would — it is materialized daily.

### Chunked AI Inference

ML.GENERATE_TEXT has per-invocation row limits. The 4-shard pattern (customer_ai_1 through customer_ai_4, product_ai_1 through product_ai_4) splits the population into deterministic, stable chunks using FARM_FINGERPRINT modulo. Shards are created as materialized tables, unioned by the final table, then dropped via post_operations. This pattern:

- Stays within BQML per-query limits
- Is fully idempotent (re-runnable)
- Is parallelisable (Dataform can run shards concurrently)
- Produces clean, stable output in the final table

### Idempotent Delta Pipeline

Every delta operation begins with a `batch_audit_log` check. If a `batch_id` matching today's date already has `status = 'COMPLETED'`, the entire operation is skipped. This means:

- Files can be re-uploaded to GCS without double-processing
- Cloud Workflows can retry without producing duplicate data
- The 4-hourly Cloud Scheduler fallback is safe to leave on permanently

### Schema Evolution Without Breaking Pipelines

New columns in incoming CSV files are handled automatically:
1. `LOAD DATA OVERWRITE` with `autodetect=true` absorbs new columns in the Bronze delta table
2. Delta MERGE operations query `INFORMATION_SCHEMA.COLUMNS` to detect columns present in the delta table but absent from the Gold table
3. `EXECUTE IMMEDIATE ALTER TABLE ... ADD COLUMN IF NOT EXISTS` adds them as STRING
4. A second dynamic MERGE populates the new columns for matched rows
5. The event is logged to `schema_change_log`

This means new data fields never break the pipeline — they flow through automatically and are tracked for downstream schema review.

### Google-Native, Zero Python

V2 eliminates all Python from the operational path:

- No Python orchestration scripts
- No OAuth2 token refresh code
- No polling loops
- No Cloud Functions or Cloud Run
- No Reasoning Engine agent deployment scripts

Everything is Terraform (infrastructure), YAML (workflows), SQL (transformations), and Google-managed services. The only remaining non-SQL artifacts are Dataform JS helpers (`includes/`), agent YAML configs, and prompt JSON files.

### Single-Point Client Onboarding

Exactly four values change between clients: `project_id`, `region`, `billing_account_id`, `github_app_installation_id`. Everything else — dataset names, connection names, workflow names, policy tag structure, Dataform repo layout — is templated and transferable. Target: new client live in under 30 minutes from `terraform apply`.

---

## 15. Monitoring and Alerting

### Cloud Monitoring Alert Policies (Terraform-Managed)

| Alert | Trigger | Notification |
|-------|---------|-------------|
| Delta Pipeline Failed | Custom metric `delta_pipeline_result = FAILED` emitted by Cloud Workflows | Email |
| Dataform Invocation Failed | Dataform workflow in FAILED state | Email |
| Data Quality Score Below 95% | Dataplex `data_quality_score` metric < 95 | Email |
| BigQuery Slot Usage High | `bigquery.googleapis.com/slot_utilization` > 80% | Email |
| Budget Alert 80% | Monthly spend reaches 80% of cap | Email |
| Budget Alert 100% | Monthly spend reaches 100% of cap | Email + Pub/Sub |

### CTO Operational SQL (Pre-built for Looker Studio / Data Agent)

```sql
-- Pipeline health: last 7 days
SELECT entity, status, COUNT(*) AS runs,
  AVG(DATETIME_DIFF(completed_at, started_at, SECOND)) AS avg_duration_sec,
  MAX(rows_merged) AS max_rows_merged
FROM `PROJECT.governance.batch_audit_log`
WHERE started_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY 1, 2 ORDER BY entity, status;

-- Gemini AI usage + cost proxy (last 30 days)
SELECT DATE(creation_time) AS day, COUNT(*) AS ml_generate_text_calls,
  ROUND(SUM(total_bytes_billed) / POW(10, 9), 4) AS total_gb_billed,
  ROUND(AVG(TIMESTAMP_DIFF(end_time, start_time, MILLISECOND)) / 1000, 2) AS avg_latency_secs
FROM `PROJECT`.`region-australia-southeast1`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  AND query LIKE '%ML.GENERATE_TEXT%'
GROUP BY 1 ORDER BY 1;

-- Policy tag compliance score
SELECT c.table_schema AS dataset, c.table_name,
  COUNT(*) AS total_columns,
  COUNTIF(p.policy_tags IS NOT NULL) AS tagged_columns,
  ROUND(COUNTIF(p.policy_tags IS NOT NULL) / COUNT(*) * 100, 1) AS compliance_pct
FROM `PROJECT`.INFORMATION_SCHEMA.COLUMN_FIELD_PATHS c
LEFT JOIN `PROJECT`.INFORMATION_SCHEMA.COLUMNS p
  USING (table_schema, table_name, column_name)
WHERE c.table_schema IN ('gold', 'silver', 'ai')
GROUP BY 1, 2 ORDER BY compliance_pct ASC;
```
