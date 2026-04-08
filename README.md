# Intelia Business-in-a-Box — AI Data Warehouse

A production-grade, fully automated, AI-enriched BigQuery data warehouse deployable to any GCP project by changing four values in `terraform/terraform.tfvars` and running `terraform apply`.

---

## What It Does

Transforms raw CSV data landing in Google Cloud Storage into governed, AI-enriched, executive-ready insights — with zero analyst intervention and full data lineage — in under 30 minutes from cold start.

Every customer gets a Gemini 2.5 Flash-generated **persona** and **retention strategy** — processed via Cloud Run-orchestrated BQ ML chunks. Every product gets an AI-generated **upsell recommendation** via BQ ML sharding. C-suite dashboards are refreshed automatically every day.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│  DATA SOURCES                                                       │
│  Source systems → Cloud Storage (delta staging bucket)              │
│    batch_*_customers_delta.csv  /  batch_*_orders_delta.csv         │
│    batch_*_order_items_delta.csv  /  batch_*_products_delta.csv     │
└──────────────┬──────────────────────────────────────────────────────┘
               │
     ┌─────────┴──────────┐
     │ object.finalize     │ manual / CI-CD trigger
     ▼                     ▼
┌─────────────────────┐   ┌─────────────────────────────────────────────┐
│  EVENT-DRIVEN       │   │  DAILY REFRESH                              │
│  INGESTION          │   │  Cloud Workflows (daily-refresh-workflow)   │
│                     │   │                                             │
│  GCS                │   │  ┌───────────────────────────────────────┐  │
│   │                 │   │  │ PHASE 1  Dataform  [tag: daily_refresh]│  │
│   ▼                 │   │  │                                       │  │
│  Pub/Sub            │   │  │  Cloud Storage                        │  │
│  (delta-arrivals)   │   │  │      │                                │  │
│   │                 │   │  │      ▼                                │  │
│   ▼                 │   │  │  BigQuery (bronze) — External tables  │  │
│  Eventarc trigger   │   │  │      │                                │  │
│   │                 │   │  │      ▼                                │  │
│   ▼                 │   │  │  BigQuery (silver) — Cleaned/typed    │  │
│  Cloud Workflows    │   │  │      │                                │  │
│  delta-ingest-      │   │  │      ▼                                │  │
│  workflow           │   │  │  BigQuery (gold) — Dims/facts/marts   │  │
│   │                 │   │  │      │                                │  │
│   ▼                 │   │  │      ▼                                │  │
│  Dataform           │   │  │  BQ ML → Vertex AI (Gemini 2.5 Flash) │  │
│  [tag: delta]       │   │  │  product_ai_1-4 shards → product_upsell│ │
│   │                 │   │  └───────────────────────────────────────┘  │
│   ▼                 │   │                                             │
│  delta_customers    │   │  ┌───────────────────────────────────────┐  │
│  delta_products     │   │  │ PHASE 2  Cloud Run                    │  │
│  delta_orders       │   │  │         (customer-ai-processor)       │  │
│  delta_order_items  │   │  │                                       │  │
│   │                 │   │  │  POST /process → 202 (fire-and-forget)│  │
│   ▼                 │   │  │      │                                │  │
│  MERGE into         │   │  │      ▼                                │  │
│  gold dim_customers │   │  │  Reads gold.dim_customers_analyst     │  │
│  gold dim_products  │   │  │      │                                │  │
│   │                 │   │  │      ▼                                │  │
│   ▼                 │   │  │  BQ ML (ML.GENERATE_TEXT)             │  │
│  governance.        │   │  │  CHUNK_SIZE=1000, CHUNK_PARALLEL=10   │  │
│  batch_audit_log    │   │  │      │                                │  │
└─────────────────────┘   │  │      ▼                                │  │
                          │  │  ai.customer_ai_raw (WRITE_TRUNCATE)  │  │
                          │  │  Workflow polls GET /status every 30s │  │
                          │  └───────────────────────────────────────┘  │
                          │                                             │
                          │  ┌───────────────────────────────────────┐  │
                          │  │ PHASE 3  Dataform  [tag: ai_aggregate] │  │
                          │  │                                       │  │
                          │  │  customer_concierge                   │  │
                          │  │    (reads + drops customer_ai_raw)    │  │
                          │  │  ai_enriched_profiles                 │  │
                          │  │  mart_executive_summary_enriched      │  │
                          │  └───────────────────────────────────────┘  │
                          └──────────────────────┬──────────────────────┘
                                                 │
                                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│  GOVERNANCE & OBSERVABILITY                                         │
│                                                                     │
│  Dataplex — lake/zone definitions, data quality scans, lineage      │
│  Data Catalog — policy tag taxonomy (PII / Financial / Internal)    │
│  Cloud Monitoring — budget alerts, workflow failure alerts,         │
│                     data freshness SLA                              │
│  BigQuery native lineage — auto-captured end-to-end                 │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  CI/CD                                                              │
│                                                                     │
│  GitHub ──► Cloud Build                                             │
│    PR:    terraform fmt-check + validate + dataform compile         │
│    Merge: terraform apply → trigger daily-refresh-workflow          │
│                                                                     │
│  Secret Manager — GitHub token for Dataform repository connection   │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  CONSUMPTION LAYER                                                  │
│                                                                     │
│  Looker Studio — CCO / CPO / CTO dashboards (direct BQ connector)  │
│  BigQuery Data Agent — natural language → SQL                       │
│  BigQuery Canvas — Gemini-assisted ad-hoc exploration               │
│  Vertex AI Agent Builder — custom agentic workflows                 │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

### GCP Services

| Service | Role |
|---------|------|
| **BigQuery** | Central data warehouse — bronze/silver/gold/ai/governance datasets; BQ ML for product AI inference via `ML.GENERATE_TEXT` |
| **Dataform** | Git-backed SQL pipeline — tag-based invocations, all outputs materialised as tables |
| **Cloud Run** | BQ ML-orchestrated Python processor — splits customers into 1000-row chunks, runs 10 concurrent BQ ML jobs, fire-and-forget architecture, writes customer AI results |
| **Vertex AI** | Gemini 2.5 Flash model endpoint — called by BigQuery ML for both product AI and customer AI |
| **Cloud Workflows** | Pipeline orchestrator — 3-phase daily refresh and event-driven delta ingestion |
| **Eventarc** | Triggers delta-ingest-workflow on GCS `object.finalize` events |
| **Cloud Pub/Sub** | Event bus between GCS file notifications and Eventarc |
| **Cloud Storage** | Delta staging bucket — incoming CSV source of truth |
| **Dataplex** | Data governance — lake/zone definitions, scheduled data quality scans, lineage |
| **Data Catalog** | Policy tag taxonomy — column-level security for PII and financial data |
| **Cloud Build** | CI/CD — validates on PR, applies on merge to main |
| **Secret Manager** | GitHub token for Dataform repository connection |
| **Cloud Monitoring** | Budget alerts, workflow failure alerts, data freshness SLA |
| **Cloud Scheduler** | Module wired but intentionally empty — pipeline triggered via Workflows |
| **IAM** | 10 service accounts with least-privilege role bindings for each workload |

### Application Stack

| Component | Technology |
|-----------|------------|
| Infrastructure-as-Code | Terraform >= 1.4, `hashicorp/google ~> 5.0` |
| SQL Pipeline | Dataform SQLX (BigQuery Standard SQL) |
| Customer AI service | Python 3.12, Flask, `google-cloud-bigquery`, ThreadPoolExecutor (BQ ML chunked approach) |
| Container runtime | Cloud Run v2, gunicorn, always-on single instance |
| CI/CD config | Cloud Build YAML |

---

## Data Layers

### Bronze
External tables over raw GCS CSVs — no data movement, query-in-place. Delta tables use `LOAD DATA OVERWRITE` with `autodetect=true` to absorb new columns automatically.

### Silver
Typed, cleaned, and normalised staging tables. **Only place for data quality normalisation.**
- Categoricals (`customer_segment`, `order_status`): `CASE TRIM(UPPER(...))` explicit mapping
- Freeform text (`category`, `brand`): `INITCAP(TRIM(LOWER(...)))`

### Gold
Business-ready, stakeholder-facing materialized tables:
- `dim_customers` — SCD Type 1 with PII policy tags
- `dim_customers_analyst` — PII-masked (SHA-256 email, truncated phone, initialised name)
- `dim_products`, `fct_orders`, `mart_revenue_summary`, `mart_executive_summary`
- `rpt_cco_dashboard`, `rpt_cpo_dashboard` — flat Looker Studio sources

### Delta
Event-driven MERGE operations that mirror silver normalisation exactly. Triggered per file arrival, not on a schedule.

### AI
| Table | Source | How |
|-------|--------|-----|
| `product_ai_1-4` | `dim_products` | BQ ML `ML.GENERATE_TEXT`, FARM_FINGERPRINT sharding |
| `product_upsell` | product_ai_1-4 | Union of shards |
| `customer_ai_raw` | `dim_customers_analyst` | Cloud Run async Python (temp — dropped after next step) |
| `customer_concierge` | `customer_ai_raw` | Reads raw, drops temp table via `post_operations` |
| `ai_enriched_profiles` | `dim_customers` + `customer_concierge` | Full enrichment join |
| `mart_executive_summary_enriched` | `mart_executive_summary` + `customer_concierge` | AI-enhanced executive view |

### Governance
- `batch_audit_log` — idempotency check + delta MERGE audit rows (`type: "operations"`, `CREATE TABLE IF NOT EXISTS` — Dataform never wipes existing rows)
- `schema_change_log` — new column detection on delta arrivals
- `business_glossary` — queryable term definitions
- `rpt_cto_dashboard` — three sources unioned for the CTO Looker Studio dashboard:
  1. `INFORMATION_SCHEMA.JOBS` — every BQ job run by the Dataform SA (90-day window)
  2. `batch_audit_log` — delta MERGE audit rows with row counts and durations
  3. Live DQ assertion checks — `dim_customers`, `fct_orders`, `dim_products`, `mart_revenue_summary` violation counts

---

## AI Pipeline Detail

### Product AI (BigQuery ML)
BQ ML `ML.GENERATE_TEXT` with Gemini 2.5 Flash remote model. Products sharded into 4 groups via `FARM_FINGERPRINT(product_id) MOD 4` to run in parallel, then unioned into `product_upsell`.

### Customer AI (Cloud Run + BQ ML chunked)
Cloud Run orchestrates BQ ML `ML.GENERATE_TEXT` in parallel chunks to bypass single-query row limits:

1. Cloud Workflow sends `POST /process` — returns **202 immediately**
2. Background thread reads all customers from `dim_customers_analyst`, splits into `CHUNK_SIZE=1000` row chunks
3. `CHUNK_PARALLEL=10` chunks processed concurrently via `ThreadPoolExecutor` — each BQ ML job handles its own internal parallelism
4. Workflow polls `GET /status` every 30 seconds
5. All results written atomically to `ai.customer_ai_raw` via **WRITE_TRUNCATE** load job (no duplicates)
6. Dataform builds `customer_concierge`, then drops `customer_ai_raw` via `post_operations`
7. Legacy `customer_ai_1-4` shard tables are dropped automatically post-run

---

## Governance & Security

- **Column-level security**: Data Catalog policy tags on PII columns (`email`, `phone`, `customer_name`) and financial columns (`total_lifetime_value`, `unit_price`) — enforced at query time
- **BigQuery native lineage**: Auto-captured — GCS → bronze → silver → gold → ai
- **Dataplex data quality scans**: Scheduled scans on `dim_customers`, `fct_orders`, `dim_products` with scorecards in Cloud Monitoring
- **Budget alerts**: 80% + 100% spend threshold alerts

---

## Directory Structure

```
.
├── definitions/              # Dataform SQLX pipeline
│   ├── bronze/               # External + delta load tables
│   ├── silver/               # Staging (stg_*) tables
│   ├── gold/                 # Dims, facts, marts, reports
│   ├── delta/                # Event-driven MERGE tables
│   ├── ai/                   # Gemini enrichment tables
│   └── governance/           # Audit, lineage, glossary
├── cloudrun/
│   └── customer_ai/
│       ├── main.py           # Flask + async Gemini processor
│       ├── Dockerfile
│       └── requirements.txt
├── terraform/
│   ├── main.tf               # Module wiring (16 modules)
│   ├── terraform.tfvars      # Single config file — edit to redeploy
│   └── modules/
│       ├── project_services/ # API enablement
│       ├── iam/              # Service accounts + role bindings
│       ├── bigquery/         # Datasets + Gemini remote connection
│       ├── storage/          # Delta staging GCS bucket
│       ├── dataform/         # Repository, release config, workflow
│       ├── cloud_run/        # customer-ai-processor service
│       ├── cloud_workflows/  # delta-ingest + daily-refresh workflows
│       ├── pubsub/           # delta-arrivals topic + GCS notification
│       ├── eventarc/         # GCS → Workflows trigger
│       ├── secret_manager/   # GitHub token secret
│       ├── data_catalog/     # Policy tag taxonomy
│       ├── dataplex/         # Lake, zones, DQ scans
│       ├── monitoring/       # Budget + alert policies
│       ├── vertex_ai/        # Metadata store (validates aiplatform API)
│       ├── cloud_build/      # CI/CD triggers
│       └── cloud_scheduler/  # (intentionally empty — no scheduled refresh)
├── looker_studio/
│   └── build_guide.md        # Step-by-step guide to build CCO/CPO/CTO dashboards in Looker Studio
├── cloudbuild-validate.yaml  # PR: fmt-check + validate + dataform compile
├── cloudbuild-deploy.yaml    # Merge: terraform apply + trigger workflow
├── dataform.json             # Dataform project config
└── environments.json         # Dataform environments (schedules intentionally empty)
```

---

## Deployment

### Prerequisites
- GCP project with billing enabled
- Terraform >= 1.4 installed
- `gcloud` CLI authenticated (`gcloud auth application-default login`)
- GitHub App installed on the repository (for Cloud Build + Dataform)

### One-time setup

**1. Configure**
```bash
# Edit the four required values in terraform/terraform.tfvars:
# project_id, region, billing_account_id, github_app_installation_id
```

**2. Build the Cloud Run image**
```bash
gcloud builds submit \
  --tag gcr.io/{YOUR_PROJECT_ID}/customer-ai-processor:latest \
  cloudrun/customer_ai/
```

**3. Deploy infrastructure**
```bash
cd terraform
terraform init
terraform apply
```

**4. Set GitHub token secret**
```bash
echo -n "ghp_yourtoken" | gcloud secrets versions add github-token --data-file=-
```

**5. First pipeline run**
```bash
gcloud workflows run daily-refresh-workflow \
  --location={YOUR_REGION} \
  --data='{}'
```

### Ongoing

- **Delta ingestion**: Automatic on CSV file drop to the GCS staging bucket
- **Daily refresh**: Trigger manually or configure Cloud Scheduler (module is wired, schedule intentionally left empty)
- **Code changes**: Push to GitHub — Cloud Build validates on PR, applies on merge

### CI/CD

| Event | Trigger | What runs |
|-------|---------|-----------|
| PR to `main` | `cloudbuild-validate.yaml` | `terraform fmt -check`, `terraform validate`, `dataform compile` |
| Merge to `main` | `cloudbuild-deploy.yaml` | `terraform apply` → triggers `daily-refresh-workflow` |

---

## Key Design Decisions

**All tables, no views** — Every Dataform output is `type: "table"`. Ensures consistent query performance and lineage tracking.

**Fire-and-forget customer AI** — Cloud Workflows has a hard 1800s synchronous HTTP timeout. The Cloud Run `/process` endpoint returns 202 immediately; the workflow polls `/status` every 30s. Eliminates any timeout risk regardless of dataset size.

**BQ ML for both products and customers, Cloud Run for orchestration** — Product AI runs 4 BQ ML shards directly in Dataform (Phase 1). Customer AI uses Cloud Run to split the full customer table into 1000-row chunks and run up to 10 BQ ML jobs concurrently — bypassing single-query row limits while keeping all inference inside BigQuery ML.

**WRITE_TRUNCATE for customer_ai_raw** — The Cloud Run load job atomically replaces the entire table each run. No stale data, no duplicates, no explicit DELETE needed.

**`customer_ai_raw` is a temp table** — Exists only between Phase 2 (Cloud Run) and Phase 3 (Dataform). Dropped automatically via `post_operations` after `customer_concierge` is built.

**Single config file** — `terraform/terraform.tfvars` is the only file a new deployment needs to change. Everything else is computed or defaulted.
