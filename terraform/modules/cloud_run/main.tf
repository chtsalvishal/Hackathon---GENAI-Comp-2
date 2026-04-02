# ---------------------------------------------------------------------------
# Cloud Run — Customer AI Processor
# Deploys the Python async Gemini service that replaces the 4 Dataform
# customer_ai shard tables. Called by the daily-refresh Cloud Workflow
# after the main pipeline completes and before the ai_aggregate step.
# ---------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "customer_ai" {
  provider = google-beta
  project  = var.project_id
  location = var.region
  name     = "customer-ai-processor"

  template {
    service_account = var.cloud_run_sa_email

    # /process and /status both return quickly (<5 s); 300 s is generous
    timeout = "300s"

    containers {
      image = "gcr.io/${var.project_id}/customer-ai-processor:latest"

      resources {
        limits = {
          cpu    = "2"
          memory = "4Gi"
        }
        # CPU always allocated — no cold-start penalty during workflow execution
        cpu_idle = false
      }

      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = var.project_id
      }
      env {
        name  = "LOCATION"
        value = var.region
      }
      env {
        name  = "CONCURRENCY"
        value = "30"
      }
    }

    scaling {
      min_instance_count = 1   # Keep alive so background thread isn't killed between polls
      max_instance_count = 1   # Single instance — batch job, not a web service
    }
  }

  # Prevent public access — only the Workflows SA may invoke
  ingress = "INGRESS_TRAFFIC_ALL"
}

# ---------------------------------------------------------------------------
# IAM — only the Cloud Workflows SA may call this service
# ---------------------------------------------------------------------------
resource "google_cloud_run_v2_service_iam_member" "workflows_invoker" {
  provider = google-beta
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.customer_ai.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.workflows_sa_email}"
}
