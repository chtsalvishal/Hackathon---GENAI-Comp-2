# ---------------------------------------------------------------------------
# Service Accounts
# ---------------------------------------------------------------------------

resource "google_service_account" "data_analyst" {
  project      = var.project_id
  account_id   = "data-analyst"
  display_name = "Data Analyst Service Account"
  description  = "Read-only access to BigQuery datasets for analytics workloads."
}

resource "google_service_account" "ai_developer" {
  project      = var.project_id
  account_id   = "ai-developer"
  display_name = "AI Developer Service Account"
  description  = "BigQuery data editor and Vertex AI user for ML/AI development."
}

resource "google_service_account" "data_engineer" {
  project      = var.project_id
  account_id   = "data-engineer"
  display_name = "Data Engineer Service Account"
  description  = "Dataform editor, BigQuery data editor, and GCS object viewer for pipeline development."
}

resource "google_service_account" "governance" {
  project      = var.project_id
  account_id   = "governance"
  display_name = "Governance Service Account"
  description  = "Data Catalog tag editor and BigQuery metadata viewer for data governance."
}

resource "google_service_account" "dataform" {
  project      = var.project_id
  account_id   = "dataform-sa"
  display_name = "Dataform Service Account"
  description  = "Service account used by Dataform repository to run BigQuery jobs."
}

resource "google_service_account" "reasoning_engine" {
  project      = var.project_id
  account_id   = "reasoning-engine"
  display_name = "Reasoning Engine Service Account"
  description  = "Service account for Vertex AI Reasoning Engine (Sprint 3 agent deployment)."
}

# ---------------------------------------------------------------------------
# Data Analyst IAM bindings
# ---------------------------------------------------------------------------

resource "google_project_iam_member" "data_analyst_bq_viewer" {
  project = var.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${google_service_account.data_analyst.email}"
}

resource "google_project_iam_member" "data_analyst_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.data_analyst.email}"
}

# ---------------------------------------------------------------------------
# AI Developer IAM bindings
# ---------------------------------------------------------------------------

resource "google_project_iam_member" "ai_developer_bq_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.ai_developer.email}"
}

resource "google_project_iam_member" "ai_developer_aiplatform_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.ai_developer.email}"
}

resource "google_project_iam_member" "ai_developer_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.ai_developer.email}"
}

# ---------------------------------------------------------------------------
# Data Engineer IAM bindings
# ---------------------------------------------------------------------------

resource "google_project_iam_member" "data_engineer_dataform_editor" {
  project = var.project_id
  role    = "roles/dataform.editor"
  member  = "serviceAccount:${google_service_account.data_engineer.email}"
}

resource "google_project_iam_member" "data_engineer_bq_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.data_engineer.email}"
}

resource "google_project_iam_member" "data_engineer_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.data_engineer.email}"
}

resource "google_project_iam_member" "data_engineer_storage_object_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.data_engineer.email}"
}

# ---------------------------------------------------------------------------
# Governance IAM bindings
# ---------------------------------------------------------------------------

resource "google_project_iam_member" "governance_catalog_tag_editor" {
  project = var.project_id
  role    = "roles/datacatalog.tagEditor"
  member  = "serviceAccount:${google_service_account.governance.email}"
}

resource "google_project_iam_member" "governance_bq_metadata_viewer" {
  project = var.project_id
  role    = "roles/bigquery.metadataViewer"
  member  = "serviceAccount:${google_service_account.governance.email}"
}

# ---------------------------------------------------------------------------
# Dataform SA IAM bindings
# ---------------------------------------------------------------------------

resource "google_project_iam_member" "dataform_sa_bq_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.dataform.email}"
}

resource "google_project_iam_member" "dataform_sa_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dataform.email}"
}

# ---------------------------------------------------------------------------
# Reasoning Engine SA IAM bindings
# ---------------------------------------------------------------------------

resource "google_project_iam_member" "reasoning_engine_aiplatform_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.reasoning_engine.email}"
}

resource "google_project_iam_member" "reasoning_engine_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.reasoning_engine.email}"
}

resource "google_project_iam_member" "reasoning_engine_bq_viewer" {
  project = var.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${google_service_account.reasoning_engine.email}"
}
