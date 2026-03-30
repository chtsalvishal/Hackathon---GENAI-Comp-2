terraform {
  required_version = ">= 1.4.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# ---------------------------------------------------------------------------
# 1. Project Services — must run first; all other modules depend on APIs being
#    enabled before their respective resources are created.
# ---------------------------------------------------------------------------
module "project_services" {
  source     = "./modules/project_services"
  project_id = var.project_id
}

# ---------------------------------------------------------------------------
# 2. IAM — service accounts and role bindings for all workload identities.
# ---------------------------------------------------------------------------
module "iam" {
  source     = "./modules/iam"
  project_id = var.project_id

  depends_on = [module.project_services]
}

# ---------------------------------------------------------------------------
# 3. Secret Manager — creates secret resources; values are filled post-deploy.
#    Needs IAM outputs for SA email bindings.
# ---------------------------------------------------------------------------
module "secret_manager" {
  source              = "./modules/secret_manager"
  project_id          = var.project_id
  dataform_sa_email   = module.iam.dataform_sa_email
  cloudbuild_sa_email = module.iam.cloudbuild_sa_email

  depends_on = [module.project_services, module.iam]
}

# ---------------------------------------------------------------------------
# 4. Storage — GCS staging bucket for Delta pipeline ingestion.
# ---------------------------------------------------------------------------
module "storage" {
  source     = "./modules/storage"
  project_id = var.project_id
  region     = var.region

  depends_on = [module.project_services]
}

# ---------------------------------------------------------------------------
# 5. BigQuery — datasets (bronze/silver/gold/ai/governance) + Gemini remote
#    connection.
# ---------------------------------------------------------------------------
module "bigquery" {
  source     = "./modules/bigquery"
  project_id = var.project_id
  region     = var.region

  depends_on = [module.project_services]
}

# ---------------------------------------------------------------------------
# 6. Data Catalog — policy tag taxonomy and BigQuery audit logging.
# ---------------------------------------------------------------------------
module "data_catalog" {
  source     = "./modules/data_catalog"
  project_id = var.project_id
  region     = var.region

  depends_on = [module.project_services]
}

# ---------------------------------------------------------------------------
# 7. Dataform — repository wired to GitHub, workspace compilation overrides,
#    release configuration, and scheduled workflow invocations.
# ---------------------------------------------------------------------------
module "dataform" {
  source                   = "./modules/dataform"
  project_id               = var.project_id
  region                   = var.region
  github_token_secret_name = module.secret_manager.github_token_secret_name
  github_token_secret_id   = module.secret_manager.github_token_secret_id
  dataform_sa_email        = module.iam.dataform_sa_email

  depends_on = [module.project_services, module.secret_manager, module.iam]
}

# ---------------------------------------------------------------------------
# 8. Vertex AI — metadata store that validates aiplatform API is active.
#    BigQuery ML uses the aiplatform API for ML.GENERATE_TEXT (Gemini).
# ---------------------------------------------------------------------------
module "vertex_ai" {
  source     = "./modules/vertex_ai"
  project_id = var.project_id
  region     = var.region

  depends_on = [module.project_services]
}

# ---------------------------------------------------------------------------
# 9. Pub/Sub — topic that receives GCS object.finalize notifications for
#    event-driven delta ingestion.
# ---------------------------------------------------------------------------
module "pubsub" {
  source     = "./modules/pubsub"
  project_id = var.project_id
  bucket_name = module.storage.bucket_name

  depends_on = [module.project_services, module.storage]
}

# ---------------------------------------------------------------------------
# 10. Eventarc — trigger: GCS object.finalize → Cloud Workflow (delta-ingest).
# ---------------------------------------------------------------------------
module "eventarc" {
  source           = "./modules/eventarc"
  project_id       = var.project_id
  region           = var.region
  bucket_name      = module.storage.bucket_name
  workflow_name    = module.cloud_workflows.workflow_name
  eventarc_sa_email = module.iam.eventarc_sa_email

  depends_on = [module.project_services, module.pubsub, module.cloud_workflows, module.iam]
}

# ---------------------------------------------------------------------------
# 11. Cloud Workflows — delta-ingest and daily-refresh workflow definitions.
# ---------------------------------------------------------------------------
module "cloud_workflows" {
  source            = "./modules/cloud_workflows"
  project_id        = var.project_id
  region            = var.region
  workflows_sa_email = module.iam.workflows_sa_email

  depends_on = [module.project_services, module.iam]
}

# ---------------------------------------------------------------------------
# 12. Cloud Scheduler — daily full-refresh trigger (00:00 AEDT).
# ---------------------------------------------------------------------------
module "cloud_scheduler" {
  source             = "./modules/cloud_scheduler"
  project_id         = var.project_id
  region             = var.region
  workflow_name      = module.cloud_workflows.daily_workflow_name
  scheduler_sa_email = module.iam.scheduler_sa_email

  depends_on = [module.project_services, module.cloud_workflows, module.iam]
}

# ---------------------------------------------------------------------------
# 13. Dataplex — lake, zones, and data quality scans for governance.
# ---------------------------------------------------------------------------
module "dataplex" {
  source          = "./modules/dataplex"
  project_id      = var.project_id
  region          = var.region
  dataplex_sa_email = module.iam.dataplex_sa_email

  depends_on = [module.project_services, module.bigquery, module.iam]
}

# ---------------------------------------------------------------------------
# 14. Monitoring — budget alerts, workflow failure alerts, data freshness SLA.
# ---------------------------------------------------------------------------
module "monitoring" {
  source             = "./modules/monitoring"
  project_id         = var.project_id
  billing_account_id = var.billing_account_id
  alert_email        = var.alert_email
  monthly_budget_aud = var.monthly_budget_aud

  depends_on = [module.project_services]
}

# ---------------------------------------------------------------------------
# 15. Cloud Build — CI/CD triggers wired to the GitHub repository.
# ---------------------------------------------------------------------------
module "cloud_build" {
  source                     = "./modules/cloud_build"
  project_id                 = var.project_id
  region                     = var.region
  github_repo                = var.github_repo
  cloudbuild_sa_email        = module.iam.cloudbuild_sa_email
  github_app_installation_id = var.github_app_installation_id

  depends_on = [module.project_services, module.iam, module.secret_manager]
}
