# ---------------------------------------------------------------------------
# Vertex AI Module
#
# Sprint 1 scope: provision the Reasoning Engine service account and its IAM
# bindings. Actual Reasoning Engine / agent deployment is performed via Python
# SDK in Sprint 3.
#
# The service account itself is created in modules/iam/main.tf (reasoning-engine).
# This module wires any Vertex AI-specific project-level IAM that is logically
# owned here, and creates the Vertex AI Workbench / metadata store resources
# needed to validate the aiplatform API is active before Sprint 3 deployment.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Vertex AI Metadata Store — lightweight resource that validates the
# aiplatform API is enabled and gives the Reasoning Engine SA a concrete
# resource to interact with during Sprint 3 pipeline runs.
# ---------------------------------------------------------------------------

resource "google_vertex_ai_metadata_store" "default" {
  provider    = google-beta
  project     = var.project_id
  region      = var.region
  name        = "default"
  description = "Default Vertex AI Metadata Store for the Intelia warehouse pipeline."
}

# ---------------------------------------------------------------------------
# Reasoning Engine Service Account — created here so that the vertex_ai module
# is self-contained if the IAM module is not used. A data source is used to
# look up the SA by email so there is no duplicate resource conflict when both
# modules are active.
# ---------------------------------------------------------------------------

data "google_service_account" "reasoning_engine" {
  project    = var.project_id
  account_id = "reasoning-engine"
}

# ---------------------------------------------------------------------------
# IAM bindings scoped to this module's concerns
# (project-level bindings that are logically "Vertex AI" rather than generic)
# ---------------------------------------------------------------------------

resource "google_project_iam_member" "reasoning_engine_aiplatform_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${data.google_service_account.reasoning_engine.email}"
}

resource "google_project_iam_member" "reasoning_engine_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${data.google_service_account.reasoning_engine.email}"
}

resource "google_project_iam_member" "reasoning_engine_bq_viewer" {
  project = var.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${data.google_service_account.reasoning_engine.email}"
}
