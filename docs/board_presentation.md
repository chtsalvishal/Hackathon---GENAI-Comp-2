# Intelia Warehouse — Board Presentation
## "From Raw Data to AI-Powered Decisions in Minutes"
**Date**: March 2026 | **Project**: vishal-sandpit-474523 | **Prepared for**: Board of Directors

---

## The Problem We Solved

> Before this solution, answering a single C-suite question required:
> - A data analyst spending **2–5 days** pulling, cleaning, and formatting CSVs
> - No AI enrichment — decisions made on raw numbers with no contextual insight
> - Zero governance — no one knew what data was PII, what was sensitive, or whether it was fresh
> - Every new client deployment required **weeks of manual setup**

---

## What We Built

A **production-grade, AI-first data warehouse** on Google Cloud that:
- Ingests raw retail data from Google Cloud Storage automatically
- Transforms it through a governed Bronze → Silver → Gold pipeline
- Enriches every customer and product record with **Gemini AI insights**
- Delivers answers to C-suite questions **in seconds, not days**
- Deploys to any new GCP project in **under 30 minutes** by changing 2 lines of config

---

## Architecture at a Glance

```
GCS Source Data                 BigQuery Medallion               AI Enrichment
─────────────────               ─────────────────────            ──────────────
customers.csv        ──►  Bronze (External Tables)
orders.csv           ──►  │  Schema-on-read, no copy    ──►  Silver (Cleaned)
order_items.csv      ──►  │  batch_0* delta detection         │  Type-safe, PII tagged
products.csv         ──►  └─ Idempotent MERGE engine           │  Data quality asserted
                                                               ▼
                                                         Gold (Business-Ready)
                                                         dim_customers, fct_orders
                                                         mart_revenue_summary
                                                               │
                                                               ▼
                                                    ML.GENERATE_TEXT (Gemini 1.5 Pro)
                                                    ┌──────────────────────────────┐
                                                    │  Customer Concierge View     │
                                                    │  → Persona + Retention Plan  │
                                                    │  Product Upsell View         │
                                                    │  → Cross-sell Strategies     │
                                                    └──────────────────────────────┘
                                                               │
                              ┌────────────────────────────────┼──────────────────────┐
                              ▼                                ▼                      ▼
                        Looker Dashboards            BQ Data Agent           BQ Canvas
                        CCO / CPO / CTO              Plain English Q&A       Live Exploration
```

---

## Time-to-Insight: Before vs After

| Stakeholder | Question | Before | After | Tool |
|------------|---------|--------|-------|------|
| **CCO** | "What is revenue vs target this month?" | 2 days (manual) | **< 3 seconds** | Looker CCO Dashboard |
| **CCO** | "Why is Customer X at risk of churning?" | 1 week (analyst) | **Instant** | Gemini AI Insight column |
| **CCO** | "Show 12-month retention by customer cohort" | 3 days | **< 5 seconds** | Pre-computed Gold layer |
| **CPO** | "Which product category is growing fastest?" | 3 days (analyst) | **< 5 seconds** | Looker CPO Dashboard |
| **CPO** | "What upsell strategies should we run on Product X?" | Never attempted | **Instant** | Gemini Product Upsell tile |
| **CPO** | "Are repeat or new buyers driving this category?" | 1 week | **< 5 seconds** | New vs Repeat Buyer tile |
| **CTO** | "What % of queries are hitting our AI views?" | Unknown | **Real-time** | INFORMATION_SCHEMA tile |
| **CTO** | "Are we compliant with data governance policy?" | Manual audit (1 week) | **Live score** | Policy tag coverage % |
| **CTO** | "What is our slot consumption trend?" | Not measured | **30-day chart** | Slot Utilization tile |
| **Any** | Ad-hoc question not on a dashboard | Days (analyst ticket) | **< 1 minute** | BigQuery Data Agent |
| **Any** | Board meeting exploratory analysis | Days (PowerPoint) | **Minutes** | BigQuery Canvas |

---

## Stakeholder Value by Role

### Chief Customer Officer (CCO)
**What they get:**
- **Live Revenue Dashboard**: Gross sales vs configurable monthly target — updated with every pipeline run
- **AI Customer Profiles**: Side-by-side table where one column shows raw metrics and the next shows a Gemini-generated 2-sentence persona + specific retention strategy — for every customer
- **12-Month Cohort Retention**: Heatmap showing what % of customers from each monthly cohort are still purchasing — instantly identifies drop-off points

**The "wow" moment**: Clicking on a churning Platinum customer and seeing Gemini's retention strategy in the same row as their LTV data — no analyst required.

---

### Chief Product Officer (CPO)
**What they get:**
- **Product Revenue by Category**: Which categories are driving revenue, down to individual product level
- **Gemini Upsell Strategies**: For every product, Gemini generates two specific strategies — a cross-sell recommendation and an upsell play — powered by that product's actual sales data
- **New vs Repeat Buyer Ratio**: Which categories have loyal repeat buyers vs which are acquisition-dependent

**The "wow" moment**: Seeing Gemini recommend a specific bundle strategy for a product, grounded in real buyer data from the warehouse.

---

### Chief Technology Officer (CTO)
**What they get:**
- **AI Adoption Rate**: Real-time % of queries touching AI-enriched views — proof that the AI investment is being used
- **Query Performance**: Average execution time and slot utilization trends over 30 days — identify performance regressions before they become incidents
- **Governance Compliance Score**: Live % of columns in Gold/Silver/AI datasets that have Data Catalog policy tags applied — a single number that answers "are we compliant?"
- **Pipeline Health**: Every delta batch run is logged with status, row counts, and timing — full audit trail

**The "wow" moment**: A live compliance score that goes up as the team applies policy tags — governance as a measurable KPI, not a checkbox.

---

## Non-Negotiables Delivered

| Requirement | How Delivered |
|-------------|--------------|
| **Vertex AI + ML.GENERATE_TEXT + Dataform** | Dataform manages the full pipeline; ML.GENERATE_TEXT runs Gemini inside BigQuery for customer personas and product strategies |
| **Agentic workflows** | Vertex AI Reasoning Engine agent + native BigQuery Data Agent — both deployed and configured |
| **Data governance: lineage, catalogue, more** | Dataform lineage DAG, Data Catalog policy tag taxonomy (PII + revenue), column-level security, audit logging, model evaluation log, usage statistics |
| **CCO + CPO + CTO questions answered** | Three dedicated dashboards; every question from the brief answered with a named tile and SQL |
| **Terraform automation / clean architecture** | Single `terraform.tfvars` change deploys the entire stack to any new GCP project |
| **Security: no permission leaks, unused services off** | 13 APIs enabled only; separate SAs per workload; no `bigquery.admin` for non-infra; PII masking via policy tags; Secret Manager for all credentials |

---

## Security & Governance Summary

| Control | Implementation |
|---------|---------------|
| Principle of least privilege | 4 separate service accounts with minimum-viable IAM roles |
| PII protection | Column-level security via Data Catalog policy tags — Analysts cannot see raw PII |
| Row-level security | Authorized views restrict regional data access per stakeholder role |
| Credential security | All secrets in Secret Manager — never in code or environment variables |
| Audit trail | BigQuery DATA_READ/DATA_WRITE/ADMIN_READ audit logs enabled |
| Cost governance | Budget alerts at 50%, 80%, 100% with email + Pub/Sub notification |
| Data freshness SLA | Cloud Monitoring alert fires if Gold layer not refreshed within 6 hours |
| Model governance | Weekly eval scores Gemini output quality; results in `ai.model_evaluation_log` |
| Schema evolution | Registry-based: new columns auto-added, renames mapped, type changes logged |
| Delta idempotency | Every batch checked against `governance.batch_audit_log` before running |

---

## Client Pitch

> **"We deploy a production-grade AI data warehouse in your GCP project in under 30 minutes.**
>
> Your C-suite gets live answers to revenue, retention, product, and platform questions —
> enriched by Gemini AI — from a single dashboard.
>
> No analysts in the loop. No data engineering sprints. No permission leaks.
> Full governance. Fully automated.
>
> Change two lines. Deploy. Done."**

---

## Deployment: 5 Steps, ~30 Minutes

```bash
# 1. Clone the repository
git clone https://github.com/chtsalvishal/Hackathon---GENAI-Comp-2
cd Hackathon---GENAI-Comp-2

# 2. Set your project (the ONLY file you change)
vim terraform/terraform.tfvars
# → project_id = "your-client-project"
# → region     = "your-region"

# 3. Authenticate to GCP
gcloud auth login
gcloud auth application-default login

# 4. Deploy everything
./scripts/bootstrap.sh

# 5. Open dashboards
# Looker: your-looker-instance.cloud.looker.com
# BigQuery Canvas: Console → BigQuery → Canvas
# Data Agent: Console → BigQuery → Data Agent panel
```

---

*Architecture: BigQuery Medallion (Bronze/Silver/Gold) + Gemini 1.5 Pro (ML.GENERATE_TEXT) + Vertex AI Reasoning Engine + Dataform + Looker + BigQuery Canvas + Data Catalog*
*Infrastructure: Terraform (modular, single-tfvars deployment) | Security: IAM, Secret Manager, Policy Tags, Authorized Views*
