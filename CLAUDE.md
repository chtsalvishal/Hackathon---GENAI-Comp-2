# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Intelia Business-in-a-Box** — a Google-native data warehouse using BigQuery + Gemini AI + Dataform + Terraform. GCP project: `vishal-sandpit-474523`, region: `australia-southeast1`, GitHub: `chtsalvishal/Hackathon---GENAI-Comp-2`.

## Commands

```bash
# Dataform — compile and validate SQL pipeline
npm install -g @dataform/cli@3
dataform compile

# Terraform — format and validate (no backend needed for validation)
terraform fmt -recursive terraform/
cd terraform && terraform init -backend=false && terraform validate

# Python — run AI parsing test suite (26 tests, no GCP credentials needed)
python tmp/validate_ai_parsing.py

# Python — benchmark Gemini async pathway (requires ADC or --api-key)
python tmp/test_python_gemini_pathway.py --concurrency 5

# Cloud Run — build and push image (run before terraform apply on first deploy)
gcloud builds submit --tag gcr.io/vishal-sandpit-474523/customer-ai-processor:latest cloudrun/customer_ai/
```

## CI/CD

- **PR → main**: `cloudbuild-validate.yaml` — terraform fmt-check + validate, dataform compile
- **Merge to main**: `cloudbuild-deploy.yaml` — terraform apply → triggers `daily-refresh-workflow`
- All scheduled executions in `environments.json` are intentionally empty — schedules are managed by Terraform/Cloud Workflows only

## Architecture

### Medallion layers (`definitions/`)

| Layer | Tag | Pattern | Notes |
|---|---|---|---|
| `bronze/` | — | `ext_*.sqlx` external tables on GCS CSVs | Source of truth; never modified |
| `silver/` | `silver`, `daily_refresh` | `stg_*.sqlx` typed + cleaned tables | **Only place for DQ normalization** |
| `gold/` | `daily_refresh` | `dim_*`, `fct_*`, `rpt_*`, `mart_*` | Business-ready, all `type: "table"` |
| `delta/` | `delta` | `delta_*.sqlx` MERGE operations | Event-driven, mirrors silver normalization |
| `ai/` | `ai`, `daily_refresh`, `ai_aggregate` | Gemini enrichment | See AI pipeline below |
| `governance/` | — | Audit log, schema change log | — |

### Daily refresh workflow (3 phases)

```
Phase 1  tag=daily_refresh    bronze → silver → gold + product_ai_1-4 + product_upsell
Phase 2  Cloud Run            POST /process → ai.customer_ai_raw  (50 concurrent Gemini calls)
Phase 3  tag=ai_aggregate     customer_concierge → ai_enriched_profiles → mart_executive_summary_enriched
```

### Delta (event-driven)

GCS file drop → Eventarc → `delta-ingest-workflow` → Dataform `delta` tag only → MERGE into gold dims.

### AI pipeline

- **Product AI**: 4 BQ ML shards (`product_ai_1-4`, tag `daily_refresh`) → `product_upsell` (Phase 1)
- **Customer AI**: Cloud Run `customer-ai-processor` (Phase 2) writes `ai.customer_ai_raw` → `customer_concierge` reads it (Phase 3)
- `customer_ai_1-4.sqlx` kept with tag `["ai"]` only — manual BQ ML fallback, not in daily schedule

## Critical SQLX rules

- **All tables must be `type: "table"`** — no views anywhere
- **Config blocks use JavaScript syntax** — never use `--` SQL comments inside `config {}`, use `//`
- **No cross-shard dependencies** — `customer_ai_1` must not depend on `customer_ai_2`, etc.
- **BQ ML success filter**: `WHERE status = ''` (empty string), not `IS NOT NULL` — BQ ML returns error message string on failure
- **BQ ML response parsing**: always use `REGEXP_EXTRACT(raw_text, r'\{[\s\S]*\}')` (greedy) then `JSON_VALUE`
- **`flatten_json_output=TRUE`** required — result column is `ml_generate_text_llm_result`
- **No `PROJECT_ID` placeholders** in committed code — use `vishal-sandpit-474523` or `${database()}`

## DQ normalization (silver layer)

- **Categoricals** (`customer_segment`, `account_status`, `order_status`): `CASE TRIM(UPPER(...))` explicit mapping
- **Freeform text** (`category`, `sub_category`, `brand`): `INITCAP(TRIM(LOWER(...)))`
- **Delta layer** (`delta_customers.sqlx`, `delta_products.sqlx`) must mirror silver normalization identically

## Terraform

Single-point config: `terraform/terraform.tfvars`. Module order in `terraform/main.tf` reflects dependency chain (project_services → iam → everything else). The `cloud_scheduler` module is intentionally empty — no automated full-refresh schedules exist.

## Cloud Run service

- `cloudrun/customer_ai/main.py` — Flask + vertexai SDK + asyncio, `CONCURRENCY=50`
- SA: `cloud-run-customer-ai-sa@vishal-sandpit-474523.iam.gserviceaccount.com`
- Only `workflows-sa` can invoke it (IAM enforced in `terraform/modules/cloud_run/main.tf`)
- Writes to `ai.customer_ai_raw`; gunicorn timeout 1800s (Workflow 1800s max limit)
