# Intelia Business-in-a-Box — AI Data Warehouse

A production-grade, fully automated, AI-enriched BigQuery data warehouse deployable to any GCP project by changing four values in `terraform/terraform.tfvars` and running `terraform apply`.

**GCP Project**: `vishal-sandpit-474523` | **Region**: `australia-southeast1`  
**GitHub**: `chtsalvishal/Hackathon---GENAI-Comp-2`

---

## What It Does

Transforms raw CSV data landing in Google Cloud Storage into governed, AI-enriched, executive-ready insights — with zero analyst intervention and full data lineage — in under 30 minutes from cold start.

Every customer gets a Gemini 2.5 Flash-generated **persona** and **retention strategy**. Every product gets an AI-generated **upsell recommendation**. C-suite dashboards are refreshed automatically every day.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  DATA SOURCES                                                │
│  Source CSVs → GCS  gs://{project}-delta-staging/           │
│    batch_*_customers_delta.csv                               │
│    batch_*_orders_delta.csv                                  │
│    batch_*_order_items_delta.csv                             │
│    batch_*_products_delta.csv                                │
└─────────────────────┬────────────────────────────────────────┘
                      │ GCS object.finalize event
                      ▼
┌──────────────────────────────────────────────────────────────┐
│  EVENT-DRIVEN TRIGGER LAYER                                  │
│                                                              │
│  GCS → Pub/Sub (delta-arrivals topic)                        │
│       → Eventarc trigger                                     │
│       → Cloud Workflows: delta-ingest-workflow               │
│            Compiles Dataform → runs [delta] tag only         │
│            MERGE into gold dims, idempotency via audit log   │
│                                                              │
│  Daily (manual trigger): daily-refresh-workflow              │
└─────────────────────┬────────────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────────────┐
│  DATAFORM PIPELINE  (definitions/  on GitHub main branch)    │
│                                                              │
│  BRONZE  — External tables query-in-place over GCS CSVs      │
│  SILVER  — Typed, cleaned, normalised staging tables         │
│  GOLD    — Business dims, facts, executive mart tables       │
│  DELTA   — Event-driven MERGE operations (same norms)        │
│  AI      — Gemini enrichment (customer + product)            │
│  GOVERNANCE — Audit log, schema change log, glossary         │
└─────────────────────┬────────────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────────────┐
│  DAILY REFRESH — 3-PHASE WORKFLOW                            │
│                                                              │
│  Phase 1  tag=daily_refresh                                  │
│    bronze → silver → gold                                    │
│    + product_ai_1-4 (BQ ML shards) → product_upsell         │
│                                                              │
│  Phase 2  Cloud Run: customer-ai-processor                   │
│    Reads gold.dim_customers_analyst                          │
│    200 concurrent Gemini 2.5 Flash calls (async Python)      │
│    Writes ai.customer_ai_raw (WRITE_TRUNCATE)                │
│                                                              │
│  Phase 3  tag=ai_aggregate                                   │
│    customer_concierge  (reads customer_ai_raw, then          │
│                         DROP TABLE customer_ai_raw)          │
│    ai_enriched_profiles                                      │
│    mart_executive_summary_enriched                           │
└─────────────────────┬────────────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────────────┐
│  CONSUMPTION LAYER                                           │
│                                                              │
│  Looker Studio dashboards (direct BQ connector)              │
│    CCO Dashboard → rpt_cco_dashboard                         │
│    CPO Dashboard → rpt_cpo_dashboard                         │
│    CTO Dashboard → rpt_cto_dashboard                         │
│                                                              │
│  BigQuery Data Agent  (natural language → SQL)               │
│  BigQuery Canvas      (Gemini-assisted ad-hoc exploration)   │
│  Vertex AI Agent Builder  (custom agentic workflows)         │
└──────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

### GCP Services

| Service | Role |
|---------|------|
| **BigQuery** | Central data warehouse — all datasets (bronze/silver/gold/ai/governance), BQ ML for product AI inference |
| **Dataform** | SQL pipeline orchestration — git-backed, tag-based invocations, all tables materialised |
| **Cloud Run** | Async Python Gemini processor — 200 concurrent calls, fire-and-forget, replaces BQ ML for customer AI |
| **Cloud Workflows** | Pipeline orchestration — 3-phase daily refresh + event-driven delta ingestion |
| **Eventarc** | GCS `object.finalize` → Cloud Workflow trigger for delta ingestion |
| **Cloud Pub/Sub** | Event bus between GCS notifications and Eventarc |
| **Cloud Storage** | Delta staging bucket — source of truth for incoming CSV files |
| **Vertex AI** | Gemini 2.5 Flash model endpoint — called by Cloud Run customer AI processor |
| **Dataplex** | Data governance — lake/zone definitions, data quality scans, lineage |
| **Data Catalog** | Policy tag taxonomy — PII, Sensitive Financial, Internal Use Only column-level security |
| **Cloud Build** | CI/CD — validates Terraform + Dataform on PR, applies on merge to main |
| **Secret Manager** | GitHub token for Dataform repository connection |
| **Cloud Monitoring** | Budget alerts, workflow failure alerts, data freshness SLA |

### Application Stack

| Component | Technology |
|-----------|------------|
| Infrastructure-as-Code | Terraform >= 1.4, `hashicorp/google ~> 5.0` |
| SQL Pipeline | Dataform SQLX (BigQuery Standard SQL) |
| Customer AI service | Python 3.12, Flask, `google-cloud-aiplatform`, asyncio + ThreadPoolExecutor |
| Container runtime | Cloud Run v2, gunicorn, single instance |
| CI/CD config | Cloud Build YAML (`cloudbuild-validate.yaml`, `cloudbuild-deploy.yaml`) |

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
| `customer_concierge` | `customer_ai_raw` | Reads raw, drops temp table on completion |
| `ai_enriched_profiles` | `dim_customers` + `customer_concierge` | Full enrichment join |
| `mart_executive_summary_enriched` | `mart_executive_summary` + `customer_concierge` | AI-enhanced executive view |

### Governance
- `batch_audit_log` — idempotency check + pipeline run tracking
- `schema_change_log` — new column detection on delta arrivals
- `business_glossary` — queryable term definitions
- `rpt_cto_dashboard` — pipeline run history for Looker Studio

---

## AI Pipeline Detail

### Product AI (BigQuery ML)
Uses BQ ML `ML.GENERATE_TEXT` with `gemini-2.5-flash` remote model. Customers are sharded into 4 groups via `FARM_FINGERPRINT(product_id) MOD 4` to run in parallel, then unioned into `product_upsell`.

### Customer AI (Cloud Run async)
Replaced BQ ML for customer AI to overcome the 6 RPS quota ceiling:

1. Cloud Workflow sends `POST /process` — returns **202 immediately**
2. Background thread launches 200 concurrent async Gemini 2.5 Flash calls
3. Workflow polls `GET /status` every 30 seconds
4. On completion, results are written to `ai.customer_ai_raw` via **WRITE_TRUNCATE** load job (atomic, no duplicates)
5. Dataform builds `customer_concierge` from `customer_ai_raw`, then **drops** `customer_ai_raw` via `post_operations`

**Throughput**: ~200 RPS sustained vs BQ ML's ~6 RPS — 33× faster.

---

## Governance & Security

- **Column-level security**: Data Catalog policy tags on PII columns (`email`, `phone`, `customer_name`) and financial columns (`total_lifetime_value`, `unit_price`) — enforced at query time
- **BigQuery native lineage**: Auto-captured, visible in BQ UI — GCS → bronze → silver → gold → ai
- **Dataplex data quality scans**: Scheduled scans on `dim_customers`, `fct_orders`, `dim_products` with scorecards visible in Cloud Monitoring
- **Budget alerts**: 80% + 100% spend threshold alerts via Cloud Monitoring

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
│   ├── terraform.tfvars      # Single config file — edit 4 values to redeploy
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
│       └── cloud_scheduler/  # (empty — no scheduled full-refresh)
├── cloudbuild-validate.yaml  # PR: fmt-check + validate + dataform compile
├── cloudbuild-deploy.yaml    # Merge: terraform apply + trigger workflow
├── dataform.json             # Dataform project config (defaultDatabase, etc.)
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
# Edit the four required values
vim terraform/terraform.tfvars
# project_id, region, billing_account_id, github_app_installation_id
```

**2. Build the Cloud Run image**
```bash
gcloud builds submit \
  --tag gcr.io/{project_id}/customer-ai-processor:latest \
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
# After terraform apply, populate the secret value
echo -n "ghp_yourtoken" | gcloud secrets versions add github-token --data-file=-
```

**5. First pipeline run**
```bash
# Trigger the daily refresh manually
gcloud workflows run daily-refresh-workflow \
  --location=australia-southeast1 \
  --data='{}'
```

### Ongoing

- **Delta ingestion**: Automatic on CSV file drop to GCS bucket
- **Daily refresh**: Trigger manually or set up Cloud Scheduler (module is wired, schedule intentionally left empty)
- **Code changes**: Push to GitHub — Cloud Build validates on PR, applies on merge

### CI/CD

| Event | Cloud Build trigger | What runs |
|-------|-------------------|-----------|
| PR to `main` | `cloudbuild-validate.yaml` | `terraform fmt -check`, `terraform validate`, `dataform compile` |
| Merge to `main` | `cloudbuild-deploy.yaml` | `terraform apply` → triggers `daily-refresh-workflow` |

---

## Key Design Decisions

**All tables, no views** — Every Dataform output is `type: "table"`. No views anywhere. Ensures consistent query performance and lineage tracking.

**Fire-and-forget customer AI** — Cloud Workflows has a 1800s synchronous HTTP timeout. The Cloud Run `/process` endpoint returns 202 immediately; the workflow polls `/status` every 30s. Eliminates any risk of timeout regardless of dataset size.

**BQ ML for products, Cloud Run for customers** — Product AI (4 shards, BQ ML) is fast enough at <2 min. Customer AI at scale hit BQ ML's 6 RPS quota ceiling; Cloud Run async delivers 200 RPS sustained.

**WRITE_TRUNCATE for customer_ai_raw** — The Cloud Run load job atomically replaces the entire table each run. No stale data, no duplicates, no explicit DELETE needed.

**`customer_ai_raw` is a temp table** — It exists only between Phase 2 (Cloud Run write) and Phase 3 (Dataform `customer_concierge` build). A `post_operations` DROP TABLE removes it after `customer_concierge` is successfully built.

**Single config file** — `terraform/terraform.tfvars` is the only file a new deployment needs to change. Everything else is computed or defaulted.
