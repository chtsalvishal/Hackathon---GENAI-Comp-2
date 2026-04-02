# ---------------------------------------------------------------------------
# Cloud Workflows — two workflow definitions:
#   1. delta-ingest-workflow  — triggered by Eventarc on new GCS file arrival,
#      compiles Dataform and runs only tables tagged "delta".
#   2. daily-refresh-workflow — triggered by Cloud Scheduler at midnight AEDT,
#      compiles Dataform and runs all tables (full warehouse refresh).
# ---------------------------------------------------------------------------

resource "google_workflows_workflow" "delta_ingest" {
  project         = var.project_id
  region          = var.region
  name            = "delta-ingest-workflow"
  description     = "Compiles Dataform and invokes only delta-tagged tables when a new file lands in GCS."
  service_account = var.workflows_sa_email

  source_contents = file("${path.module}/delta-ingest-workflow.yaml")

  labels = {
    workload = "delta-pipeline"
  }
}

resource "google_workflows_workflow" "daily_refresh" {
  project         = var.project_id
  region          = var.region
  name            = "daily-refresh-workflow"
  description     = "Full warehouse refresh — compiles Dataform and runs all tables on a daily schedule."
  service_account = var.workflows_sa_email

  source_contents = replace(
    file("${path.module}/daily-refresh-workflow.yaml"),
    "__CUSTOMER_AI_SERVICE_URL__",
    var.customer_ai_service_url
  )

  labels = {
    workload = "daily-refresh"
  }
}
