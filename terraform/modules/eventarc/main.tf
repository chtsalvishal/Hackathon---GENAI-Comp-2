# ---------------------------------------------------------------------------
# Eventarc trigger — GCS object.finalize → Cloud Workflow (delta-ingest).
# When a new file lands in the delta-staging bucket the trigger fires,
# passes the event payload to the workflow, and the workflow runs Dataform
# with the "delta" tag so only affected tables are refreshed.
# ---------------------------------------------------------------------------

resource "google_eventarc_trigger" "delta_ingest" {
  project  = var.project_id
  location = var.region
  name     = "delta-ingest-trigger"

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }

  matching_criteria {
    attribute = "bucket"
    value     = var.bucket_name
  }

  destination {
    workflow = "projects/${var.project_id}/locations/${var.region}/workflows/${var.workflow_name}"
  }

  service_account = var.eventarc_sa_email

  labels = {
    workload = "delta-pipeline"
  }
}
