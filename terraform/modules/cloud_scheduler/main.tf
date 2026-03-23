# ---------------------------------------------------------------------------
# Cloud Scheduler — daily full-refresh trigger.
# Fires at midnight AEDT (14:00 UTC) every day, invokes the
# daily-refresh Cloud Workflow via HTTP POST to the Workflows executions API.
# ---------------------------------------------------------------------------

resource "google_cloud_scheduler_job" "daily_refresh" {
  project     = var.project_id
  region      = var.region
  name        = "daily-refresh-trigger"
  description = "Triggers the daily-refresh Cloud Workflow at midnight AEDT."
  schedule    = "0 14 * * *"  # 14:00 UTC = midnight AEDT (UTC+10)
  time_zone   = "Australia/Sydney"

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/projects/${var.project_id}/locations/${var.region}/workflows/${var.workflow_name}/executions"

    body = base64encode(jsonencode({
      argument = jsonencode({ source = "cloud-scheduler" })
    }))

    headers = {
      "Content-Type" = "application/json"
    }

    oauth_token {
      service_account_email = var.scheduler_sa_email
    }
  }
}
