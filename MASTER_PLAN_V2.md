# Business-in-a-Box: Google-Native Architecture — Master Plan V2
**Project**: vishal-sandpit-474523 | **Region**: australia-southeast1 | **Updated**: 2026-03-24
**Status**: V1 built and running → V2 removes all Python spaghetti, replaces with managed Google products

---

## What Changes in V2

| V1 (Python Spaghetti) | V2 (Google-Native) |
|-----------------------|--------------------|
| Python scripts calling Dataform REST API manually | Dataform Release + Workflow Configurations (built-in scheduling) |
| Python OAuth2 token refresh + polling loops | Eliminated entirely — no Python orchestration |
| `trigger_delta_pipeline.sh` shell script | GCS → Pub/Sub → Eventarc → Cloud Workflows (fully event-driven) |
| Manual `bq` / `gcloud` CLI calls | Terraform manages all resources declaratively |
| Dataform assertions only | Dataplex Data Quality scans + scorecards |
| Undocumented lineage | BigQuery native lineage + Dataplex lineage |
| Manual connection creation | Terraform `google_bigquery_connection` resource |
| `scripts/bootstrap.sh` | `terraform apply` from cold start |
| No CI/CD pipeline | Cloud Build Triggers on GitHub push |
| No structured monitoring | Cloud Monitoring dashboards + Dataplex quality alerts |

---

## Full Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│  DATA SOURCES                                                       │
│  Source Systems → GCS  gs://PROJECT-warehouse-files/               │
│                        ├── batch_0*_customers_delta.csv            │
│                        ├── batch_0*_orders_delta.csv               │
│                        ├── batch_0*_order_items_delta.csv          │
│                        └── batch_0*_products_delta.csv             │
└───────────────────────────────┬─────────────────────────────────────┘
                                │  GCS Object Finalize notification
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│  EVENT-DRIVEN TRIGGER LAYER                                         │
│  Cloud Pub/Sub topic: warehouse-delta-arrivals                      │
│       ↓                                                             │
│  Eventarc trigger (object.finalize on GCS bucket)                  │
│       ↓                                                             │
│  Cloud Workflows: delta-ingest-workflow                             │
│    1. Extract entity from filename via regex                        │
│    2. Idempotency check → governance.batch_audit_log in BQ         │
│    3. Call Dataform API: compile from main + invoke [delta] tag    │
│    4. Poll Dataform until SUCCEEDED / FAILED                        │
│    5. Write result to batch_audit_log                               │
│    6. Emit custom Cloud Monitoring metric                           │
│  ─────────────────────────────────────────────────────────────────  │
│  Cloud Scheduler (fallback): 0 */4 * * * → delta tag (catch-up)   │
│  Cloud Scheduler (daily):    0 3 * * *   → daily_refresh tag       │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│  DATAFORM — TRANSFORMATION PIPELINE (Git: main branch)             │
│                                                                     │
│  BRONZE (tag: bronze)                                               │
│  ├── ext_customers / orders / order_items / products                │
│  │     External tables → GCS (query-in-place, no copy)             │
│  └── ext_*_delta  (LOAD DATA OVERWRITE, autodetect=true)           │
│       Captures new columns automatically on every run              │
│                                                                     │
│  SILVER (tag: silver)                                               │
│  ├── stg_customers   TRIM / lowercase / date parse                 │
│  ├── stg_orders      TRIM / date parse / amount cast               │
│  ├── stg_order_items TRIM / subtotal computation                   │
│  └── stg_products    TRIM / price cast / date parse                │
│                                                                     │
│  GOLD (tag: gold)                                                   │
│  ├── dim_customers   SCD-ready dimension                           │
│  ├── dim_products    Product catalogue                             │
│  ├── fct_orders      Fact table, partitioned by order_date         │
│  └── mart_revenue_summary  Pre-aggregated for dashboards           │
│                                                                     │
│  DELTA (tag: delta)  ← event-driven, triggered per file arrival    │
│  ├── delta_customers  LOAD DATA + schema evolution + MERGE         │
│  ├── delta_orders     LOAD DATA + schema evolution + MERGE         │
│  ├── delta_order_items                                              │
│  └── delta_products                                                 │
│                                                                     │
│  AI (tag: ai)                                                       │
│  ├── bqml_model          gemini-2.5-flash REMOTE MODEL             │
│  ├── customer_concierge  ML.GENERATE_TEXT bulk inference           │
│  ├── product_upsell      ML.GENERATE_TEXT bulk inference           │
│  └── ai_enriched_profiles  joined enrichment view                 │
│                                                                     │
│  GOVERNANCE                                                         │
│  ├── batch_audit_log     idempotency + pipeline tracking           │
│  └── schema_change_log   new column detections                     │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│  BIGQUERY DATA GOVERNANCE (Dataplex)                                │
│                                                                     │
│  Dataplex Lake: intelia-warehouse                                   │
│  ├── Zone: raw      → maps to bronze dataset                       │
│  ├── Zone: curated  → maps to silver + gold datasets               │
│  └── Zone: product  → maps to ai + governance datasets             │
│                                                                     │
│  Data Quality Scans (replaces Dataform assertions)                 │
│  ├── dim_customers:  customer_id NOT NULL, email regex valid       │
│  ├── fct_orders:     order_date NOT NULL, total_amount > 0         │
│  ├── dim_products:   unit_price > 0, product_id NOT NULL           │
│  └── Scorecards visible in Dataplex console + alerting             │
│                                                                     │
│  Data Lineage (auto-captured by BigQuery)                           │
│  Bronze → Silver → Gold → AI  fully visible in BQ UI              │
│                                                                     │
│  Policy Tag Taxonomy (PII / Sensitive Financial)                    │
│  ├── email, phone, customer_name  → PII tag → masked for analysts  │
│  └── total_amount, unit_price     → Sensitive Financial tag        │
│                                                                     │
│  Data Catalog                                                       │
│  └── All tables auto-discovered + business glossary entries        │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│  BI & AI CONSUMPTION LAYER                                          │
│                                                                     │
│  Looker Studio  (embedded dashboards, no infra required)           │
│  ├── CCO Board: Revenue trend, cohort retention, churn risk        │
│  ├── CPO Board: Product performance, upsell strategies (Gemini)    │
│  └── CTO Board: Pipeline health, data quality scores, slot usage   │
│                                                                     │
│  BigQuery Canvas  (C-suite ad-hoc exploration)                     │
│  └── Pre-built canvas with Gemini "explain this chart" buttons     │
│                                                                     │
│  BigQuery Data Agent  (natural language → SQL, no code needed)     │
│  └── Ask "Which customers have highest churn risk this month?"     │
│                                                                     │
│  Vertex AI Agent Builder  (custom agentic workflows)               │
│  └── Connects to gold + ai datasets, tools for BQ queries          │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 1. Infrastructure — Terraform (Lift-and-Shift Ready)

**Single file to change per client**: `terraform.tfvars`
```hcl
project_id      = "NEW-CLIENT-PROJECT-ID"
region          = "australia-southeast1"
gcs_bucket_name = "NEW-CLIENT-warehouse-files"
billing_account = "XXXXX-XXXXX-XXXXX"
```

### Module Map

| Module | Resources Created | Replaces |
|--------|-------------------|----------|
| `project_services` | Enable 14 APIs | Manual API enablement |
| `iam` | Service accounts, IAM bindings | Manual IAM setup |
| `storage` | GCS bucket + lifecycle rules + Pub/Sub notification | Manual bucket creation |
| `pubsub` | Topic + subscription for delta arrival events | — (new) |
| `eventarc` | Trigger: GCS → Cloud Workflows | Manual trigger setup |
| `cloud_workflows` | `delta-ingest-workflow.yaml` deployed | `trigger_delta_pipeline.sh` |
| `cloud_scheduler` | Daily refresh cron + 4-hourly delta fallback cron | Cron-in-Python |
| `bigquery` | Datasets (bronze/silver/gold/ai/governance) + remote connection | Manual `bq mk` calls |
| `dataform` | Repository + workspace + release config + workflow config | Python API calls |
| `dataplex` | Lake + zones + data quality scan configs | Dataform assertions only |
| `vertex_ai` | Gemini connection IAM binding | Manual IAM binding |
| `secret_manager` | Service account key storage | Plaintext credentials |
| `monitoring` | Alert policies + budget alert + dashboard | `monitoring/*.tf` enhanced |

### APIs to Enable
```hcl
# terraform/modules/project_services/main.tf
locals {
  apis = [
    "bigquery.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "bigquerydatapolicy.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "dataform.googleapis.com",
    "dataplex.googleapis.com",
    "datacatalog.googleapis.com",
    "aiplatform.googleapis.com",
    "storage.googleapis.com",
    "pubsub.googleapis.com",
    "eventarc.googleapis.com",
    "workflows.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudbuild.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ]
}
```

### Dataform — Release + Workflow Configurations via Terraform
These replace ALL Python Dataform API calls permanently:
```hcl
# terraform/modules/dataform/main.tf

resource "google_dataform_release_config" "production" {
  project    = var.project_id
  location   = var.region
  repository = google_dataform_repository.warehouse.name
  name       = "production"
  git_commitish = "main"
  # Recompiles from main branch on every scheduled workflow run
}

resource "google_dataform_workflow_config" "daily_refresh" {
  project         = var.project_id
  location        = var.region
  repository      = google_dataform_repository.warehouse.name
  name            = "daily-refresh"
  release_config  = google_dataform_release_config.production.id
  cron_schedule   = "0 3 * * *"   # 03:00 AEST daily
  time_zone       = "Australia/Sydney"
  invocation_config {
    included_tags                          = ["daily_refresh"]
    transitive_dependencies_included       = true
    transitive_dependents_included         = false
    fully_refresh_incremental_tables_enabled = false
  }
}

resource "google_dataform_workflow_config" "delta_catchup" {
  project         = var.project_id
  location        = var.region
  repository      = google_dataform_repository.warehouse.name
  name            = "delta-catchup"
  release_config  = google_dataform_release_config.production.id
  cron_schedule   = "0 */4 * * *"   # Every 4 hours as safety net
  invocation_config {
    included_tags = ["delta"]
    transitive_dependencies_included = true
  }
}
```

---

## 2. Event-Driven Delta Auto-Ingest

This replaces `trigger_delta_pipeline.sh` and all Python polling. Any new file
landing in GCS automatically triggers the correct delta pipeline with zero manual
intervention.

### Flow
```
New file: gs://PROJECT-warehouse-files/batch_02_orders_delta.csv
    │
    ├── GCS emits Pub/Sub notification on object.finalize
    │
    ├── Eventarc routes to Cloud Workflows: delta-ingest-workflow
    │
    └── Workflow steps:
        1. Parse filename → extract entity (orders)
        2. Check governance.batch_audit_log — skip if already COMPLETED
        3. POST to Dataform compilationResults API (gitCommitish: main)
        4. POST to Dataform workflowInvocations (includedTags: ["delta"])
        5. Poll workflowInvocations until SUCCEEDED or FAILED (30s intervals)
        6. Write final status to governance.batch_audit_log via BQ jobs API
        7. log_custom_metric to Cloud Monitoring (delta_pipeline_result)
```

### Cloud Workflows YAML
```yaml
# terraform/modules/cloud_workflows/delta-ingest-workflow.yaml
main:
  params: [event]
  steps:
    - extract_filename:
        assign:
          - bucket: ${event.data.bucket}
          - filename: ${event.data.name}
          - entity: ${text.replace_all(
              text.replace_all(
                text.replace_all(filename, "batch_", ""),
                "_delta.csv", ""),
              text.find_all(filename, r"batch_[0-9]+_")[0], "")}

    - check_idempotency:
        call: googleapis.bigquery.v2.jobs.query
        args:
          projectId: ${sys.get_env("GOOGLE_CLOUD_PROJECT_ID")}
          body:
            query: >
              SELECT COUNT(*) > 0 AS already_done
              FROM `${sys.get_env("GOOGLE_CLOUD_PROJECT_ID")}.governance.batch_audit_log`
              WHERE batch_id = CONCAT('delta_', '${entity}', '_', FORMAT_DATE('%Y%m%d', CURRENT_DATE()))
                AND status = 'COMPLETED'
            useLegacySql: false
        result: idempotency_response
    - skip_if_done:
        switch:
          - condition: ${idempotency_response.rows[0].f[0].v == "true"}
            next: end

    - compile_dataform:
        call: http.post
        args:
          url: ${"https://dataform.googleapis.com/v1beta1/projects/"
                 + sys.get_env("GOOGLE_CLOUD_PROJECT_ID")
                 + "/locations/${var.region}/repositories/${var.dataform_repo}/compilationResults"}
          auth:
            type: OAuth2
          body:
            gitCommitish: main
        result: compile_result

    - invoke_delta:
        call: http.post
        args:
          url: ${"https://dataform.googleapis.com/v1beta1/"
                 + compile_result.body.name.split("/compilationResults/")[0]
                 + "/workflowInvocations"}
          auth:
            type: OAuth2
          body:
            compilationResult: ${compile_result.body.name}
            invocationConfig:
              includedTags: ["delta"]
              transitiveDependenciesIncluded: true
        result: invocation

    - poll_loop:
        steps:
          - check_state:
              call: http.get
              args:
                url: ${"https://dataform.googleapis.com/v1beta1/" + invocation.body.name}
                auth:
                  type: OAuth2
              result: poll_result
          - evaluate_state:
              switch:
                - condition: ${poll_result.body.state == "SUCCEEDED"}
                  next: log_success
                - condition: ${poll_result.body.state == "FAILED"}
                  next: log_failure
          - wait:
              call: sys.sleep
              args:
                seconds: 30
              next: check_state

    - log_success:
        call: googleapis.bigquery.v2.jobs.insert
        args:
          projectId: ${sys.get_env("GOOGLE_CLOUD_PROJECT_ID")}
          body:
            configuration:
              query:
                query: >
                  UPDATE `governance.batch_audit_log`
                  SET status = 'COMPLETED', completed_at = CURRENT_TIMESTAMP()
                  WHERE batch_id = CONCAT('delta_', '${entity}', '_', FORMAT_DATE('%Y%m%d', CURRENT_DATE()))
                useLegacySql: false
        next: end

    - log_failure:
        raise: ${"Delta pipeline FAILED for entity: " + entity}

    - end:
        return: "done"
```

### Eventarc + Pub/Sub Terraform
```hcl
# GCS bucket sends notifications to Pub/Sub on any new file
resource "google_storage_notification" "delta_arrival" {
  bucket         = google_storage_bucket.warehouse.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.delta_arrivals.id
  event_types    = ["OBJECT_FINALIZE"]
  object_name_prefix = "batch_"   # Only batch files trigger the workflow
}

resource "google_eventarc_trigger" "delta_ingest" {
  name     = "delta-ingest-trigger"
  location = var.region
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }
  destination {
    workflow = google_workflows_workflow.delta_ingest.id
  }
  transport {
    pubsub {
      topic = google_pubsub_topic.delta_arrivals.id
    }
  }
  service_account = google_service_account.eventarc_sa.email
}
```

---

## 3. Data Quality — Dataplex (Replaces Dataform Assertions)

Dataplex Data Quality provides managed, scheduled scans with pass/fail scorecards
visible in the GCP console — no custom SQL assertions to maintain.

### Dataplex Lake Structure
```
Dataplex Lake: intelia-warehouse
├── Zone: raw-zone         (STORAGE type) → GCS bucket
├── Zone: curated-zone     (BIGQUERY type) → bronze, silver, gold datasets
└── Zone: product-zone     (BIGQUERY type) → ai, governance datasets
```

### Data Quality Scan Configs (Terraform)
```hcl
resource "google_dataplex_datascan" "dim_customers_quality" {
  location     = var.region
  data_scan_id = "dim-customers-quality"
  data {
    resource = "//bigquery.googleapis.com/projects/${var.project_id}/datasets/gold/tables/dim_customers"
  }
  execution_spec {
    trigger { schedule { cron = "30 3 * * *" } }  # 30 min after daily Dataform run
  }
  data_quality_spec {
    rules {
      column      = "customer_id"
      dimension   = "COMPLETENESS"
      non_null_expectation {}
    }
    rules {
      column    = "email"
      dimension = "VALIDITY"
      regex_expectation { regex = "^[^@]+@[^@]+\\.[^@]+$" }
    }
    rules {
      column    = "total_lifetime_value"
      dimension = "VALIDITY"
      range_expectation { min_value = "0" }
    }
    rules {
      dimension             = "FRESHNESS"
      table_condition_expectation {
        # Table must have been updated within the last 25 hours
        sql_expression = "MAX(updated_at) > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 25 HOUR)"
      }
    }
  }
}

resource "google_dataplex_datascan" "fct_orders_quality" {
  location     = var.region
  data_scan_id = "fct-orders-quality"
  data {
    resource = "//bigquery.googleapis.com/projects/${var.project_id}/datasets/gold/tables/fct_orders"
  }
  execution_spec {
    trigger { schedule { cron = "30 3 * * *" } }
  }
  data_quality_spec {
    rules {
      column    = "order_date"
      dimension = "COMPLETENESS"
      non_null_expectation {}
    }
    rules {
      column    = "total_amount"
      dimension = "VALIDITY"
      range_expectation { min_value = "0" max_value = "1000000" }
    }
    rules {
      dimension = "UNIQUENESS"
      column    = "order_id"
      uniqueness_expectation {}
    }
  }
}
```

### Dataplex Quality Alerts → Cloud Monitoring
```hcl
resource "google_monitoring_alert_policy" "dataplex_quality_failure" {
  display_name = "Dataplex Data Quality Failure"
  combiner     = "OR"
  conditions {
    display_name = "Quality scan score below 95%"
    condition_threshold {
      filter          = "metric.type=\"dataplex.googleapis.com/datascan/data_quality_score\""
      comparison      = "COMPARISON_LT"
      threshold_value = 95
      duration        = "0s"
    }
  }
  notification_channels = [google_monitoring_notification_channel.email.id]
}
```

---

## 4. Data Lineage (Automatic — Zero Config)

BigQuery automatically captures job-level lineage for all Dataform-run jobs.
No code needed. Lineage is visible in the BigQuery UI under each table's
"Data Lineage" tab, showing the complete Bronze → Silver → Gold → AI graph.

**What you see in BigQuery UI automatically:**
```
gs://bucket/customers.csv
    → bronze.ext_customers        (LOAD DATA)
    → silver.stg_customers        (CREATE OR REPLACE TABLE AS SELECT)
    → gold.dim_customers          (MERGE)
    → ai.customer_concierge       (CREATE OR REPLACE VIEW)
    → ai.ai_enriched_profiles     (CREATE OR REPLACE VIEW)
```

**Dataplex Lineage** (richer, cross-service) captures GCS → BigQuery ingestion.
Enable in `terraform/modules/dataplex/main.tf`:
```hcl
resource "google_dataplex_lake" "warehouse" {
  name     = "intelia-warehouse"
  location = var.region
  metastore { service = "" }   # Optional: connect Dataproc Metastore
}
```

---

## 5. AI Layer — BigQuery ML + Vertex AI

### BigQuery ML Remote Model (Working — gemini-2.5-flash)
```sql
-- definitions/ai/bqml_model.sqlx
CREATE OR REPLACE MODEL `PROJECT.ai.gemini_pro_model`
REMOTE WITH CONNECTION `PROJECT.australia-southeast1.gemini-pro-connection`
OPTIONS (endpoint = 'gemini-2.5-flash');
```

### AI Views — Bulk Inference Pattern (No Python)
All AI enrichment runs inside BigQuery SQL via `ML.GENERATE_TEXT`.
No Python, no Cloud Functions, no external calls needed.

- `customer_concierge` — Gemini persona + retention strategy per customer
- `product_upsell` — Cross-sell and upsell strategies per product
- `ai_enriched_profiles` — Joined enrichment view for dashboards

### BigQuery Data Agent (Native, No Code)
Configure directly in the BigQuery console or via the API:
```yaml
# ai/bq_data_agent/agent_config.yaml
agent_name: intelia-data-agent
data_sources:
  - dataset: gold
    tables: [dim_customers, dim_products, fct_orders, mart_revenue_summary]
  - dataset: ai
    tables: [customer_concierge, ai_enriched_profiles, product_upsell]
sample_questions:
  - "What was our revenue last month vs the month before?"
  - "Which customers have the highest churn risk right now?"
  - "Show me top 10 products by revenue in the last quarter"
  - "What percentage of customers made a repeat purchase?"
  - "Which customer segment has the highest average order value?"
```
C-suite ask questions in plain English → Data Agent writes SQL → returns chart + table.
No code path, no Python, fully managed by Google.

### Vertex AI Agent Builder (Custom Agents — Optional Upgrade)
For clients that need more sophisticated agentic workflows beyond the native Data Agent:
```
Vertex AI Agent Builder
├── Agent: "Intelia Revenue Analyst"
│   Tools:
│   ├── bigquery_query_tool     (runs SQL against gold dataset)
│   ├── gemini_insights_tool    (reads ai.customer_concierge)
│   └── pipeline_status_tool    (reads governance.batch_audit_log)
└── Grounding: BigQuery Enterprise tables
```
Deployed via Vertex AI console — no Python deployment scripts needed.

---

## 6. BI Layer — Looker Studio + BigQuery Canvas

### Looker Studio (Zero Infrastructure — Connect Directly to BigQuery)
Three dashboards, one per executive stakeholder:

| Dashboard | Primary Tables | Key Charts |
|-----------|---------------|------------|
| **CCO**: Revenue & Retention | `fct_orders`, `dim_customers`, `customer_concierge` | MoM revenue, cohort retention, Gemini churn insights |
| **CPO**: Product Performance | `dim_products`, `fct_orders`, `stg_order_items`, `product_upsell` | Category revenue, margin trend, Gemini upsell strategies |
| **CTO**: Platform & Governance | `batch_audit_log`, Dataplex quality scores, `INFORMATION_SCHEMA` | Pipeline health, quality scores, slot usage, AI call volume |

Looker Studio connects natively to BigQuery — no extra infrastructure, no credentials to manage.
Dashboards are parameterised by `project_id` so they transfer to new clients by changing the BQ data source.

### BigQuery Canvas (Executive Ad-Hoc)
Pre-built canvas at `bigquery_canvas/executive_canvas.json`:
- Revenue trend cell → `mart_revenue_summary`
- Customer segment map → `dim_customers`
- Gemini insights explorer → `ai.customer_concierge`
- Pipeline status → `governance.batch_audit_log`
- Each cell has Gemini "Explain this result" button — built into Canvas natively

---

## 7. CI/CD — Cloud Build (Replaces Manual Git + Python Triggers)

```
Developer pushes to GitHub: chtsalvishal/Hackathon---GENAI-Comp-2
        │
        ├── Push to feature branch
        │       ↓
        │   Cloud Build trigger: validate
        │   Steps:
        │   1. dataform compile (check SQL syntax)
        │   2. dataform run --tag=all --dry-run (validate dependencies)
        │   Result: Pass/fail shown on PR
        │
        └── Merge to main
                ↓
            Cloud Build trigger: deploy-production
            Steps:
            1. dataform compile --git-commitish=main
            2. Create Dataform Release Configuration snapshot
            3. Dataform Workflow Configuration picks up new release automatically
            Result: New code in prod on next scheduled run
```

```hcl
# terraform/modules/cloud_build/main.tf
resource "google_cloudbuild_trigger" "validate_pr" {
  name     = "dataform-validate-pr"
  filename = "cloudbuild-validate.yaml"
  github {
    owner = "chtsalvishal"
    name  = "Hackathon---GENAI-Comp-2"
    pull_request { branch = ".*" }
  }
}

resource "google_cloudbuild_trigger" "deploy_main" {
  name     = "dataform-deploy-main"
  filename = "cloudbuild-deploy.yaml"
  github {
    owner = "chtsalvishal"
    name  = "Hackathon---GENAI-Comp-2"
    push { branch = "^main$" }
  }
}
```

`cloudbuild-validate.yaml`:
```yaml
steps:
  - name: 'node:18'
    entrypoint: 'npm'
    args: ['install', '-g', '@dataform/cli']
  - name: 'node:18'
    entrypoint: 'dataform'
    args: ['compile']
    dir: '.'
```

---

## 8. Monitoring & Alerting

### Cloud Monitoring Dashboard
```hcl
# monitoring/pipeline_alerts.tf (enhanced)
resource "google_monitoring_alert_policy" "delta_pipeline_failure" {
  display_name = "Delta Pipeline Failed"
  conditions {
    display_name = "Custom metric: delta_pipeline_result = FAILED"
    condition_threshold {
      filter = "metric.type=\"custom.googleapis.com/delta_pipeline_result\""
      # Emitted by Cloud Workflows on each run
    }
  }
  notification_channels = [google_monitoring_notification_channel.email.id]
}

resource "google_monitoring_alert_policy" "dataform_invocation_failure" {
  display_name = "Dataform Invocation Failed"
  conditions {
    display_name = "Dataform workflow in FAILED state"
    condition_threshold {
      filter = "resource.type=\"dataform.googleapis.com/WorkflowInvocation\""
    }
  }
}

resource "google_monitoring_alert_policy" "bq_slot_overrun" {
  display_name = "BigQuery Slot Usage High"
  conditions {
    condition_threshold {
      filter          = "metric.type=\"bigquery.googleapis.com/slot_utilization\""
      threshold_value = 80
    }
  }
}
```

### CTO Operational Visibility SQL (Pre-built Looker Studio tiles)
```sql
-- Pipeline health: last 7 days
SELECT
  entity,
  status,
  COUNT(*) AS runs,
  AVG(TIMESTAMP_DIFF(completed_at, started_at, SECOND)) AS avg_duration_sec,
  MAX(rows_merged) AS max_rows_merged
FROM `PROJECT.governance.batch_audit_log`
WHERE started_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY 1, 2
ORDER BY entity, status;

-- Gemini AI usage + cost proxy
SELECT
  DATE(creation_time) AS day,
  COUNT(*) AS ml_generate_text_calls,
  SUM(total_bytes_billed) / POW(10, 9) AS total_gb_billed
FROM `PROJECT`.`region-australia-southeast1`.INFORMATION_SCHEMA.JOBS
WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  AND query LIKE '%ML.GENERATE_TEXT%'
GROUP BY 1 ORDER BY 1;

-- Data quality scores over time (from Dataplex)
SELECT
  datascan_id,
  DATE(end_time) AS scan_date,
  data_quality_result.score AS quality_score,
  data_quality_result.passed AS passed
FROM `PROJECT`.`region-australia-southeast1`.INFORMATION_SCHEMA.DATA_SCANS
ORDER BY scan_date DESC;
```

---

## 9. IAM Design — Principle of Least Privilege

| Service Account | Purpose | Roles |
|----------------|---------|-------|
| `dataform-sa` | Runs all Dataform jobs | `bigquery.dataEditor`, `bigquery.jobUser`, `dataform.serviceAgent` |
| `workflows-sa` | Executes Cloud Workflows | `dataform.editor`, `bigquery.jobUser`, `workflows.invoker` |
| `eventarc-sa` | Routes GCS events to Workflows | `eventarc.eventReceiver`, `workflows.invoker` |
| `scheduler-sa` | Triggers Cloud Workflows on schedule | `workflows.invoker` |
| `gemini-connection-sa` | BigQuery ML → Vertex AI | `aiplatform.user` |
| `dataplex-sa` | Runs data quality scans | `bigquery.dataViewer`, `dataplex.viewer` |
| `cloudbuild-sa` | Validates + deploys Dataform | `dataform.editor`, `source.reader` |

**No user credentials in any pipeline.** All operations use service accounts.
Personal credentials (`gcloud auth application-default login`) are only for local development.

---

## 10. Lift-and-Shift Deployment Checklist

Deploy to a brand-new GCP project by running:
```bash
# 1. Clone repo
git clone https://github.com/chtsalvishal/Hackathon---GENAI-Comp-2.git
cd Hackathon---GENAI-Comp-2

# 2. Edit the ONE file that changes per client
vim terraform/terraform.tfvars
#   project_id      = "new-client-project-id"
#   region          = "australia-southeast1"
#   gcs_bucket_name = "new-client-warehouse-files"

# 3. Deploy all infrastructure
cd terraform
terraform init
terraform apply -auto-approve

# 4. Upload source data to GCS (one-time)
gsutil -m cp data/*.csv gs://new-client-warehouse-files/

# 5. Push code — Cloud Build validates, Dataform deploys automatically
git push origin main

# 6. Dataform Workflow Configurations run on their cron schedule
#    OR manually trigger via GCP console → Dataform → Workflows
```

**What terraform apply creates:**
- All GCS buckets with lifecycle policies
- All BigQuery datasets + remote Gemini connection + IAM bindings
- Dataform repository linked to GitHub + release + workflow configs
- Dataplex lake + zones + data quality scan configs
- Cloud Workflows delta-ingest-workflow deployed
- Eventarc trigger: GCS → Workflows (event-driven delta auto-ingest)
- Cloud Scheduler: daily_refresh cron + 4-hourly delta fallback
- Cloud Build triggers on GitHub repo
- Cloud Monitoring alert policies + budget alert
- Looker Studio data source connections (manual step: open template URL)

**Time to first data in gold layer: ~15 minutes after `terraform apply`**

---

---

## Non-Negotiables Compliance

Each non-negotiable from the brief, and exactly how V2 satisfies it:

| # | Non-Negotiable | How V2 Delivers It |
|---|---------------|-------------------|
| 1 | Vertex AI, BigQuery ML.GENERATE_TEXT, Dataform | `bqml_model.sqlx` creates Gemini remote model. `customer_concierge`, `product_upsell`, `ai_enriched_profiles` use `ML.GENERATE_TEXT` inside BigQuery — data never leaves the warehouse. Dataform manages all Bronze→Silver→Gold→AI transformations with full dependency DAG. |
| 2 | Agentic workflows | **BigQuery Data Agent** (native, no-code) answers C-suite questions in plain English. **Vertex AI Agent Builder** provides custom multi-tool agent with BQ query tools, Gemini insights tools, and pipeline status tools. Cloud Workflows handles the event-driven delta orchestration as an agentic pipeline. |
| 3 | Data governance: lineage, catalogue, model governance | **BigQuery native lineage** auto-captures Bronze→Silver→Gold→AI. **Dataplex** provides lake/zone organisation, data quality scorecards, and data discovery. **Data Catalog policy tags** enforce column-level PII and financial data masking. Prompt versions tracked in `prompt_templates.json`. Gemini usage statistics via `INFORMATION_SCHEMA.JOBS`. |
| 4 | Answer CCO, CPO, CTO specific needs — show how easy it was | See full Stakeholder Insight Matrix below. Every C-suite question has a named tool, a query, and a before/after time-to-answer. |
| 5 | Clean sellable architecture — `terraform apply` to new project | Single `terraform.tfvars` change. All 19 modules deploy in one `terraform apply`. Delta auto-ingest, Dataform scheduling, Dataplex governance, Cloud Build CI/CD all come with it. Target: new client live in under 30 minutes. |
| 6 | Turn off unused services, no permission leaks, security | Only 19 explicitly listed APIs enabled — all others remain off. Separate service accounts per workload. No personal credentials in any pipeline. Column-level PII masking enforced. VPC-SC ready. Budget alerts at 80%/100%. |

---

## Stakeholder Insight Matrix

### CCO — Chief Customer Officer
**Needs**: Revenue performance, customer profiles, retention, churn risk

| Question | Answer Tool | Time Before | Time After | Where |
|----------|------------|-------------|-----------|-------|
| "What is our revenue vs target this month?" | Looker Studio — Revenue tile | 2 days (manual extract) | **< 3 seconds** | CCO dashboard, auto-refreshed daily |
| "Why is Customer X at churn risk?" | `ai.customer_concierge` Gemini persona tile | 1 week (analyst) | **Instant** | Gemini insight column in customer table |
| "Show me 12-month cohort retention" | Looker Studio — Cohort tile | 3 days | **< 5 seconds** | Pre-computed from `gold.fct_orders` |
| "Which customers have highest lifetime value?" | Looker Studio — LTV ranking | 3 days | **< 3 seconds** | `gold.dim_customers` sorted by `total_lifetime_value` |
| "What's the retention rate for our premium segment?" | BigQuery Data Agent (NL query) | Days (analyst ticket) | **< 1 minute** | Ask in plain English — agent writes the SQL |
| "Prepare me for the board meeting on customer health" | BigQuery Canvas live workspace | Days (PowerPoint) | **Minutes** | Canvas with Gemini "explain this" on each cell |

**CCO Dashboard Tiles (Looker Studio):**
```sql
-- Tile 1: Gross Revenue vs Monthly Target
SELECT
  DATE_TRUNC(order_date, MONTH)           AS month,
  SUM(total_amount)                       AS gross_revenue,
  10000000                                AS monthly_target,
  ROUND(SUM(total_amount) / 10000000 * 100, 1) AS pct_of_target
FROM `PROJECT.gold.fct_orders`
GROUP BY 1 ORDER BY 1;

-- Tile 2: Customer Profiles with Gemini Persona (side-by-side raw + AI)
SELECT
  customer_id,
  customer_name,
  total_lifetime_value      AS "LTV (Raw Data)",
  order_count               AS "Total Orders (Raw)",
  churn_risk                AS "Churn Risk (Raw)",
  gemini_persona_and_strategy AS "Gemini AI Insight"
FROM `PROJECT.ai.customer_concierge`
ORDER BY total_lifetime_value DESC
LIMIT 100;

-- Tile 3: 12-Month Cohort Retention
SELECT
  cohort_month,
  months_since_first_purchase,
  COUNT(DISTINCT customer_id) AS active_customers,
  ROUND(COUNT(DISTINCT customer_id) /
    FIRST_VALUE(COUNT(DISTINCT customer_id))
      OVER (PARTITION BY cohort_month ORDER BY months_since_first_purchase) * 100, 1)
    AS retention_rate_pct
FROM (
  SELECT
    c.customer_id,
    DATE_TRUNC(MIN(o.order_date) OVER (PARTITION BY c.customer_id), MONTH) AS cohort_month,
    DATE_DIFF(DATE_TRUNC(o.order_date, MONTH),
      MIN(o.order_date) OVER (PARTITION BY c.customer_id), MONTH) AS months_since_first_purchase
  FROM `PROJECT.gold.fct_orders` o
  JOIN `PROJECT.gold.dim_customers` c USING (customer_id)
)
GROUP BY 1, 2 ORDER BY 1, 2;
```

---

### CPO — Chief Product Officer
**Needs**: Product performance, category growth, upsell opportunity, new vs repeat buyer mix

| Question | Answer Tool | Time Before | Time After | Where |
|----------|------------|-------------|-----------|-------|
| "Which product category is growing fastest?" | Looker Studio — Category revenue tile | 3 days (analyst) | **< 5 seconds** | CPO dashboard, pre-aggregated from gold |
| "What upsell strategies work for our top products?" | `ai.product_upsell` Gemini tile | Never done | **Instant** | Gemini upsell strategy column per product |
| "Are new or repeat buyers driving revenue?" | Looker Studio — New vs Repeat tile | 1 week | **< 5 seconds** | Computed from `fct_orders` with order rank |
| "What's the revenue share by category this quarter?" | Looker Studio — Revenue share % | 3 days | **< 3 seconds** | `dim_products` + `stg_order_items` join |
| "Which products have the highest margin?" | BigQuery Data Agent (NL query) | Days | **< 1 minute** | Ask: "Show margin by product ranked highest first" |
| "What should we bundle together?" | `ai.product_upsell` cross-sell column | Never done | **Instant** | Gemini cross-sell recommendation per product |

**CPO Dashboard Tiles (Looker Studio):**
```sql
-- Tile 1: Product Revenue by Category (last 90 days of data)
SELECT
  p.category,
  p.product_name,
  SUM(oi.quantity)                          AS units_sold,
  SUM(oi.subtotal)                          AS category_revenue,
  ROUND(SUM(oi.subtotal) /
    SUM(SUM(oi.subtotal)) OVER () * 100, 1) AS revenue_share_pct
FROM `PROJECT.gold.fct_orders` o
JOIN `PROJECT.silver.stg_order_items` oi USING (order_id)
JOIN `PROJECT.gold.dim_products` p USING (product_id)
WHERE o.order_date >= DATE_SUB((SELECT MAX(order_date) FROM `PROJECT.gold.fct_orders`), INTERVAL 90 DAY)
GROUP BY 1, 2 ORDER BY category_revenue DESC;

-- Tile 2: Gemini Upsell Strategies
SELECT
  product_name, category, brand,
  unique_buyers, total_revenue,
  gemini_upsell_strategy AS "Gemini Upsell & Cross-sell Strategy"
FROM `PROJECT.ai.product_upsell`
ORDER BY total_revenue DESC
LIMIT 50;

-- Tile 3: New vs Repeat Buyer Ratio by Product
SELECT
  p.product_name,
  COUNTIF(order_rank = 1) AS new_buyer_orders,
  COUNTIF(order_rank > 1) AS repeat_buyer_orders,
  ROUND(COUNTIF(order_rank > 1) / COUNT(*) * 100, 1) AS repeat_buyer_pct
FROM (
  SELECT
    oi.product_id,
    RANK() OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS order_rank
  FROM `PROJECT.gold.fct_orders` o
  JOIN `PROJECT.silver.stg_order_items` oi USING (order_id)
)
JOIN `PROJECT.gold.dim_products` p USING (product_id)
GROUP BY p.product_name ORDER BY repeat_buyer_pct DESC;
```

---

### CTO — Chief Technology Officer
**Needs**: Platform health, AI adoption, query performance, governance compliance, cost

| Question | Answer Tool | Time Before | Time After | Where |
|----------|------------|-------------|-----------|-------|
| "How many queries are using our AI views?" | CTO dashboard — AI adoption tile | Unknown | **Real-time** | `INFORMATION_SCHEMA.JOBS` |
| "Are we compliant with data governance?" | CTO dashboard — Policy tag coverage % | Manual audit (1 week) | **Live score** | Dataplex quality scorecard + column tag coverage |
| "What's our slot consumption trend?" | CTO dashboard — Slot utilisation chart | Not measured | **30-day chart** | `INFORMATION_SCHEMA.JOBS` |
| "Is the delta pipeline healthy?" | CTO dashboard — Pipeline status tile | Manual check | **Real-time** | `governance.batch_audit_log` |
| "What's the cost per Gemini insight?" | CTO dashboard — AI cost proxy | Not measured | **Daily metric** | `total_bytes_billed` from `INFORMATION_SCHEMA` |
| "When was the gold layer last refreshed?" | Dataplex freshness scan | Not measured | **Instant** | Dataplex Data Quality — freshness rule |
| "Which tables have the lowest data quality?" | Dataplex scorecard | Manual SQL | **Live dashboard** | Dataplex console quality scores |

**CTO Dashboard Tiles (Looker Studio):**
```sql
-- Tile 1: AI Adoption Rate (% of queries hitting AI views)
SELECT
  DATE(creation_time) AS query_date,
  COUNTIF(query LIKE '%ai.customer_concierge%'
       OR query LIKE '%ai.product_upsell%'
       OR query LIKE '%ai.ai_enriched%') AS ai_queries,
  COUNT(*) AS total_queries,
  ROUND(COUNTIF(query LIKE '%ai.%') / COUNT(*) * 100, 1) AS ai_adoption_pct
FROM `PROJECT`.`region-australia-southeast1`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE DATE(creation_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1 ORDER BY 1;

-- Tile 2: Query Performance & Slot Utilisation
SELECT
  DATE(creation_time) AS query_date,
  ROUND(AVG(total_slot_ms /
    TIMESTAMP_DIFF(end_time, start_time, MILLISECOND)), 1) AS avg_slots_used,
  ROUND(AVG(TIMESTAMP_DIFF(end_time, start_time, MILLISECOND)) / 1000, 2) AS avg_exec_secs,
  ROUND(AVG(total_bytes_processed) / POW(1024,3), 2) AS avg_gb_processed
FROM `PROJECT`.`region-australia-southeast1`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE state = 'DONE'
  AND DATE(creation_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1 ORDER BY 1;

-- Tile 3: Governance Compliance Score (policy tag coverage)
SELECT
  c.table_schema AS dataset,
  c.table_name,
  COUNT(*) AS total_columns,
  COUNTIF(p.policy_tags IS NOT NULL) AS tagged_columns,
  ROUND(COUNTIF(p.policy_tags IS NOT NULL) / COUNT(*) * 100, 1) AS compliance_pct
FROM `PROJECT`.INFORMATION_SCHEMA.COLUMN_FIELD_PATHS c
LEFT JOIN `PROJECT`.INFORMATION_SCHEMA.COLUMNS p
  USING (table_schema, table_name, column_name)
WHERE c.table_schema IN ('gold', 'silver', 'ai')
GROUP BY 1, 2 ORDER BY compliance_pct ASC;

-- Tile 4: Delta Pipeline Health (last 7 days)
SELECT
  entity,
  status,
  COUNT(*) AS runs,
  AVG(TIMESTAMP_DIFF(completed_at, started_at, SECOND)) AS avg_duration_sec,
  MAX(rows_merged) AS max_rows_merged
FROM `PROJECT.governance.batch_audit_log`
WHERE started_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY 1, 2 ORDER BY entity, status;

-- Tile 5: Gemini AI Cost Proxy
SELECT
  DATE(creation_time) AS day,
  COUNT(*) AS ml_generate_text_calls,
  ROUND(SUM(total_bytes_billed) / POW(1024,3), 4) AS total_gb_billed,
  ROUND(AVG(TIMESTAMP_DIFF(end_time, start_time, MILLISECOND)) / 1000, 2) AS avg_latency_secs
FROM `PROJECT`.`region-australia-southeast1`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE DATE(creation_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND query LIKE '%ML.GENERATE_TEXT%'
GROUP BY 1 ORDER BY 1;
```

---

## Analytics Tool Selection Guide

No overlap, no confusion — every tool has a defined audience and purpose:

| Tool | Audience | Use Case | How They Access It |
|------|---------|---------|-------------------|
| **Looker Studio** | CCO, CPO, CTO, Board | Always-on operational dashboards; board presentation PDF | Shared link, opens in browser — no login needed |
| **BigQuery Data Agent** | Any C-suite | Ad-hoc plain-English questions not on a dashboard — agent writes SQL and returns chart | BigQuery console → "Data Agent" panel |
| **BigQuery Canvas** | CCO, CPO, CTO | Live exploratory "what-if" analysis, board meeting prep, interactive cells with Gemini explain | BigQuery console → Canvas — shared notebook |
| **Vertex AI Agent Builder** | Technical / CTO | Complex multi-step reasoning, cross-dataset queries, custom tool orchestration | Chat interface or embedded app |
| **Vertex AI Studio** | AI/ML team | Prompt design, testing, version approval before production deployment | Vertex AI console → Studio |
| **Dataplex Console** | CTO, Data Engineering | Data quality scorecards, lineage explorer, data discovery, policy tag coverage | GCP console → Dataplex |

---

## Data Governance Overlay

### Policy Tag Taxonomy
```
Intelia Data Taxonomy (Dataplex)
├── PII
│   ├── customer_email     → masked for Analyst role
│   ├── customer_phone     → masked for Analyst role
│   └── customer_name      → masked for Analyst role
├── Sensitive Financial
│   ├── total_amount       → masked for Analyst role
│   ├── unit_price         → masked for Analyst role
│   └── total_lifetime_value
└── Internal Use Only
    └── cost_price
```

### Row-Level Security (Authorized Views)
```sql
-- Regional managers see only their region; CCO sees all
CREATE OR REPLACE VIEW `PROJECT.gold.dim_customers_authorised` AS
SELECT * FROM `PROJECT.gold.dim_customers`
WHERE country = SESSION_USER_COUNTRY()  -- mapped via IAM attribute
   OR SESSION_USER() IN (SELECT email FROM `governance.cco_access_list`);
```

### AI Model Governance
| Artefact | Storage | Purpose |
|---------|---------|---------|
| Prompt templates | `ai/vertex_ai_studio/prompt_templates.json` (versioned v1, v2…) | Reproducibility — pinned version deployed to prod |
| Model version in use | Data Catalog entry on `ai.gemini_pro_model` | Which Gemini model endpoint is active |
| Usage statistics | `INFORMATION_SCHEMA.JOBS` (CTO tile 5) | Call volume, latency, GB billed per day |
| Cost per insight | Derived from usage stats | $/customer-insight reported to CTO monthly |
| Quality scan results | Dataplex scan history | Pass/fail trends per table over time |

---

## Board Presentation Narrative

### The Problem
C-suite at any organisation waited **days for data insights**. Analysts manually extracted CSVs. No AI enrichment. Zero governance. Every board question required a 3-day analyst ticket.

### The Solution
A fully automated, governed, AI-first BigQuery warehouse deployable in under 30 minutes to any GCP project:

| Stakeholder | Question | Before | After | Tool |
|------------|---------|--------|-------|------|
| CCO | "Revenue vs target this month?" | 2 days manual | **< 3 seconds** | Looker Studio tile |
| CCO | "Why is Customer X churning?" | 1 week analyst | **Instant** | Gemini persona in dashboard |
| CCO | "12-month cohort retention?" | 3 days | **< 5 seconds** | Pre-computed gold layer |
| CPO | "Fastest growing product category?" | 3 days analyst | **< 5 seconds** | CPO Looker dashboard |
| CPO | "Upsell strategies for top products?" | Never done | **Instant** | Gemini upsell tile |
| CPO | "New vs repeat buyer split?" | 1 week | **< 5 seconds** | CPO repeat buyer tile |
| CTO | "How many queries hit our AI views?" | Unknown | **Real-time** | INFORMATION_SCHEMA tile |
| CTO | "Governance compliance score?" | Manual audit 1 week | **Live %** | Dataplex + policy tag coverage |
| CTO | "Is the delta pipeline healthy?" | Manual check | **Real-time** | `batch_audit_log` tile |
| Any | Question not on a dashboard | Days (analyst ticket) | **< 1 minute** | BigQuery Data Agent |
| Any | Board prep exploratory analysis | Days (PowerPoint) | **Minutes** | BigQuery Canvas |

### Client Pitch
> "We deploy a production-grade AI data warehouse in your GCP project in under 30 minutes.
> Your C-suite gets live answers to revenue, retention, and platform questions — enriched by Gemini 2.5 —
> from a single dashboard. No analysts in the loop. Full governance. Fully automated.
> Change two lines in one file. Run terraform apply. Done."

---

## V2 Sprint Plan (No Python — Google Products Only)

### Sprint 1 — Infrastructure (Day 1)
- [ ] Terraform: `project_services` module — enable exactly 19 APIs, all others off
- [ ] Terraform: `iam` module — separate SA per workload (dataform, workflows, eventarc, scheduler, gemini, dataplex, cloudbuild)
- [ ] Terraform: `bigquery` module — datasets + remote Gemini connection + policy tag taxonomy
- [ ] Terraform: `storage` module — GCS bucket + lifecycle (Coldline 90d, Delete 365d) + Pub/Sub notification
- [ ] Terraform: `pubsub` module — delta-arrivals topic + subscription
- [ ] Terraform: `secret_manager` module — any client secrets (no plaintext anywhere)
- [ ] Terraform: `monitoring` module — budget alert 80%/100%, pipeline failure alert, data freshness SLA alert

### Sprint 2 — Data Pipeline (Day 1–2)
- [ ] Terraform: `dataform` module — repository + release config (main branch) + workflow configs (daily_refresh cron, delta catchup cron)
- [ ] Dataform: Bronze external tables (4 entities, `ignore_unknown_values = true`)
- [ ] Dataform: Bronze delta tables (`LOAD DATA OVERWRITE`, `autodetect = true`)
- [ ] Dataform: Silver layer (type casting, date normalisation, PII/revenue tagging)
- [ ] Dataform: Gold layer (dims + facts + mart, partition + cluster strategy)
- [ ] Dataform: Delta MERGE operations (schema evolution + idempotency check)
- [ ] Dataform: governance tables (`batch_audit_log`, `schema_change_log`)

### Sprint 3 — Event-Driven Auto-Ingest (Day 2)
- [ ] Terraform: `eventarc` module — trigger on GCS object.finalize → Cloud Workflows
- [ ] Terraform: `cloud_workflows` module — deploy `delta-ingest-workflow.yaml`
- [ ] Terraform: `cloud_scheduler` module — daily_refresh cron + 4-hourly delta fallback cron
- [ ] Test: upload a new `batch_0*` file to GCS → confirm workflow fires → confirms Dataform delta runs → `batch_audit_log` updated
- [ ] Remove: `scripts/trigger_delta_pipeline.sh` (replaced entirely)

### Sprint 4 — AI Layer (Day 2)
- [ ] Terraform: `vertex_ai` module — Gemini connection SA → `roles/aiplatform.user`
- [ ] Dataform: `bqml_model.sqlx` — `gemini-2.5-flash` remote model
- [ ] Dataform: `customer_concierge.sqlx` — bulk `ML.GENERATE_TEXT` inference
- [ ] Dataform: `product_upsell.sqlx` — bulk `ML.GENERATE_TEXT` with relative date window
- [ ] Dataform: `ai_enriched_profiles.sqlx` — joined enrichment view
- [ ] Vertex AI Agent Builder: configure intelia-data-agent with BQ data sources + sample questions
- [ ] BigQuery Data Agent: configure in BQ console with gold + ai dataset access
- [ ] Vertex AI Studio: version and store prompt templates in `ai/vertex_ai_studio/prompt_templates.json`
- [ ] BigQuery Canvas: finalise `executive_canvas.json` with 5 pre-built cells

### Sprint 5 — Governance (Day 2–3)
- [ ] Terraform: `dataplex` module — lake + 3 zones (raw/curated/product)
- [ ] Terraform: Dataplex data quality scans — `dim_customers`, `fct_orders`, `dim_products` rules
- [ ] Terraform: Policy tag taxonomy — PII + Sensitive Financial tags applied via Terraform
- [ ] Terraform: Authorized views — row-level security per stakeholder role
- [ ] BigQuery native lineage: verify Bronze→Silver→Gold→AI lineage visible in BQ UI
- [ ] Data Catalog: verify all tables auto-discovered + add business glossary entries for key fields

### Sprint 6 — Dashboards & CI/CD (Day 3)
- [ ] Looker Studio: CCO dashboard (revenue vs target, Gemini profiles, cohort retention)
- [ ] Looker Studio: CPO dashboard (category revenue, Gemini upsell tile, new vs repeat buyer)
- [ ] Looker Studio: CTO dashboard (AI adoption %, slot usage, compliance score, pipeline health, Gemini cost)
- [ ] Cloud Build: `cloudbuild-validate.yaml` — validate Dataform on PR
- [ ] Cloud Build: `cloudbuild-deploy.yaml` — deploy on merge to main
- [ ] Terraform: `cloud_build` module — Cloud Build triggers on GitHub repo
- [ ] Remove: `scripts/bootstrap.sh` → replaced by `terraform apply`
- [ ] Remove: `scripts/load_initial_data.sh` → replaced by `gsutil cp` + Dataform workflow config
- [ ] End-to-end smoke test: fresh project → `terraform apply` → upload data → assert pipeline runs → check all dashboard tiles → confirm Gemini insights appear

---

## What This Eliminates Permanently

| Eliminated | Replaced By |
|-----------|-------------|
| `scripts/bootstrap.sh` | `terraform apply` |
| `scripts/trigger_delta_pipeline.sh` | GCS → Eventarc → Cloud Workflows |
| `scripts/load_initial_data.sh` | `gsutil cp` + Dataform Workflow Config |
| All Python REST API scripts | Cloud Workflows YAML |
| Manual `gcloud auth` token refresh | Service account auth (automatic) |
| Python polling loops (wait for job) | Cloud Workflows built-in `sys.sleep` + retry |
| Dataform assertions for data quality | Dataplex Data Quality scans + scorecards |
| Manual BigQuery connection creation | Terraform `google_bigquery_connection` |
| Manual IAM binding for Gemini SA | Terraform `google_project_iam_member` |
| `gcloud` / `bq` CLI calls in code | Terraform state + Google APIs via Workflows |

---

## V2 Work Remaining (Priority Order)

| # | Item | Google Product | Effort |
|---|------|---------------|--------|
| 1 | Cloud Workflows YAML for delta-ingest | Cloud Workflows | Medium |
| 2 | Terraform: add `pubsub`, `eventarc`, `workflows`, `scheduler` modules | Terraform | Medium |
| 3 | Terraform: add Dataform release + workflow configurations | Terraform | Small |
| 4 | Dataplex lake + data quality scan configs | Terraform + Dataplex | Medium |
| 5 | Cloud Build `cloudbuild-validate.yaml` + `cloudbuild-deploy.yaml` | Cloud Build | Small |
| 6 | Looker Studio: finalise CCO/CPO/CTO dashboard templates | Looker Studio | Medium |
| 7 | BigQuery Data Agent: configure sample questions + access | BQ Console | Small |
| 8 | BigQuery Canvas: finalise executive canvas JSON | BQ Canvas | Small |
| 9 | Terraform: Secret Manager for any client secrets | Secret Manager | Small |
| 10 | Remove `scripts/` directory — all replaced by above | — | Small |
