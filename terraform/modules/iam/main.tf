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

resource "google_service_account" "workflows" {
  project      = var.project_id
  account_id   = "workflows-sa"
  display_name = "Cloud Workflows Service Account"
  description  = "SA that Cloud Workflows runs as — calls Dataform API and BigQuery."
}

resource "google_service_account" "eventarc" {
  project      = var.project_id
  account_id   = "eventarc-sa"
  display_name = "Eventarc Service Account"
  description  = "Receives GCS object.finalize events and invokes the delta-ingest Cloud Workflow."
}

resource "google_service_account" "scheduler" {
  project      = var.project_id
  account_id   = "scheduler-sa"
  display_name = "Cloud Scheduler Service Account"
  description  = "Invokes Cloud Workflows on a daily schedule for full-refresh runs."
}

resource "google_service_account" "dataplex" {
  project      = var.project_id
  account_id   = "dataplex-sa"
  display_name = "Dataplex Service Account"
  description  = "Runs Dataplex data quality scans against BigQuery datasets."
}

resource "google_service_account" "cloudbuild" {
  project      = var.project_id
  account_id   = "cloudbuild-sa"
  display_name = "Cloud Build Service Account"
  description  = "CI/CD SA — validates and deploys Terraform and Dataform on GitHub push events."
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

resource "google_project_iam_member" "ai_developer_cloudaicompanion" {
  project = var.project_id
  role    = "roles/cloudaicompanion.user"
  member  = "serviceAccount:${google_service_account.ai_developer.email}"
}

# Grant all authenticated users Gemini for BigQuery access (enables Data Agent in console)
resource "google_project_iam_member" "all_users_cloudaicompanion" {
  project = var.project_id
  role    = "roles/cloudaicompanion.user"
  member  = "domain:intelia.com.au"
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

# Grant Dataform the authority to attach Data Catalog Policy Tags (Column-level security)
resource "google_project_iam_member" "dataform_sa_data_owner" {
  project = var.project_id
  role    = "roles/bigquery.dataOwner"
  member  = "serviceAccount:${google_service_account.dataform.email}"
}

resource "google_project_iam_member" "dataform_sa_catalog_tag_editor" {
  project = var.project_id
  role    = "roles/datacatalog.tagEditor"
  member  = "serviceAccount:${google_service_account.dataform.email}"
}

# ---------------------------------------------------------------------------
# Cloud Workflows SA IAM bindings
# ---------------------------------------------------------------------------

resource "google_project_iam_member" "workflows_sa_dataform_editor" {
  project = var.project_id
  role    = "roles/dataform.editor"
  member  = "serviceAccount:${google_service_account.workflows.email}"
}

resource "google_project_iam_member" "workflows_sa_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.workflows.email}"
}

resource "google_project_iam_member" "workflows_sa_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.workflows.email}"
}

# Grant Workflows SA the ability to explicitly 'Act As' the Dataform SA
resource "google_project_iam_member" "workflows_sa_act_as" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.workflows.email}"
}

resource "google_project_iam_member" "workflows_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.workflows.email}"
}

# ---------------------------------------------------------------------------
# Eventarc SA IAM bindings
# ---------------------------------------------------------------------------

resource "google_project_iam_member" "eventarc_sa_event_receiver" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.eventarc.email}"
}

resource "google_project_iam_member" "eventarc_sa_workflows_invoker" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.eventarc.email}"
}

# ---------------------------------------------------------------------------
# Cloud Scheduler SA IAM bindings
# ---------------------------------------------------------------------------

resource "google_project_iam_member" "scheduler_sa_workflows_invoker" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.scheduler.email}"
}

# ---------------------------------------------------------------------------
# Dataplex SA IAM bindings
# ---------------------------------------------------------------------------

resource "google_project_iam_member" "dataplex_sa_dataplex_editor" {
  project = var.project_id
  role    = "roles/dataplex.editor"
  member  = "serviceAccount:${google_service_account.dataplex.email}"
}

resource "google_project_iam_member" "dataplex_sa_bq_data_viewer" {
  project = var.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${google_service_account.dataplex.email}"
}

resource "google_project_iam_member" "dataplex_sa_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dataplex.email}"
}

# ---------------------------------------------------------------------------
# Cloud Build SA IAM bindings
# ---------------------------------------------------------------------------

resource "google_project_iam_member" "cloudbuild_sa_builds_editor" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}

resource "google_project_iam_member" "cloudbuild_sa_dataform_editor" {
  project = var.project_id
  role    = "roles/dataform.editor"
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}

resource "google_project_iam_member" "cloudbuild_sa_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}

resource "google_project_iam_member" "cloudbuild_sa_storage_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}

resource "google_project_iam_member" "cloudbuild_sa_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}
