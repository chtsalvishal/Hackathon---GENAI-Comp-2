locals {
  apis = toset([
    "bigquery.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "aiplatform.googleapis.com",
    "dataform.googleapis.com",
    "storage.googleapis.com",
    "datacatalog.googleapis.com",
    "looker.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "secretmanager.googleapis.com",
    "workflows.googleapis.com",
    "eventarc.googleapis.com",
    "pubsub.googleapis.com",
  ])
}

resource "google_project_service" "apis" {
  for_each = local.apis

  project                    = var.project_id
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false
}
