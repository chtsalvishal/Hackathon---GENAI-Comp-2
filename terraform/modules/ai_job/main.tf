resource "google_cloud_run_v2_job" "ai_engine" {
  name     = "ai-engine-job"
  location = var.region
  project  = var.project_id

  template {
    template {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/ai-repository/ai-engine:latest"
        env {
          name  = "PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "LOCATION"
          value = var.region
        }
        resources {
          limits = {
            cpu    = "2"
            memory = "4Gi"
          }
        }
      }
      service_account = var.service_account_email
      timeout         = "3600s"
    }
  }

  lifecycle {
    ignore_changes = [template[0].template[0].containers[0].image]
  }
}

resource "google_artifact_registry_repository" "ai_repo" {
  location      = var.region
  repository_id = "ai-repository"
  description   = "Docker repository for AI Engine"
  format        = "DOCKER"
  project       = var.project_id
}
