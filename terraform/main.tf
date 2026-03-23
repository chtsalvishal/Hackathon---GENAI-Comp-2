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
  source                    = "./modules/secret_manager"
  project_id                = var.project_id
  dataform_sa_email         = module.iam.dataform_sa_email
  reasoning_engine_sa_email = module.iam.reasoning_engine_sa_email

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
#    and Dataform SA IAM bindings.
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
# 8. Vertex AI — Reasoning Engine service account and IAM; actual agent
#    deployment is performed via Python in Sprint 3.
# ---------------------------------------------------------------------------
module "vertex_ai" {
  source     = "./modules/vertex_ai"
  project_id = var.project_id
  region     = var.region

  depends_on = [module.project_services, module.iam]
}
