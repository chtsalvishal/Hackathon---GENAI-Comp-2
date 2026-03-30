locals {
  # Exactly these APIs enabled — all others remain off (non-negotiable #6)
  apis = toset([
    "bigquery.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "bigquerydatapolicy.googleapis.com",
    "aiplatform.googleapis.com",
    "dataform.googleapis.com",
    "dataplex.googleapis.com",
    "datacatalog.googleapis.com",
    "storage.googleapis.com",
    "pubsub.googleapis.com",
    "eventarc.googleapis.com",
    "workflows.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudaicompanion.googleapis.com",      # Gemini for BigQuery / Data Agent
    "discoveryengine.googleapis.com",       # Vertex AI Agent Builder
    "billingbudgets.googleapis.com",        # Budget alerts
  ])
}

resource "google_project_service" "apis" {
  for_each = local.apis

  project                    = var.project_id
  service                    = each.value
  disable_on_destroy         = true   # Turns off unused APIs on terraform destroy
  disable_dependent_services = false
}
