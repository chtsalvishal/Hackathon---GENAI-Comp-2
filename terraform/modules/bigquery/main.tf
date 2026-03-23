# ---------------------------------------------------------------------------
# BigQuery Datasets — Bronze / Silver / Gold / AI / Governance
# ---------------------------------------------------------------------------

resource "google_bigquery_dataset" "bronze" {
  project                    = var.project_id
  dataset_id                 = "bronze"
  friendly_name              = "Bronze"
  description                = "Raw external tables from GCS"
  location                   = var.region
  delete_contents_on_destroy = false

  labels = {
    layer = "bronze"
  }
}

resource "google_bigquery_dataset" "silver" {
  project                    = var.project_id
  dataset_id                 = "silver"
  friendly_name              = "Silver"
  description                = "Cleaned and standardised staging tables"
  location                   = var.region
  delete_contents_on_destroy = false

  labels = {
    layer = "silver"
  }
}

resource "google_bigquery_dataset" "gold" {
  project                    = var.project_id
  dataset_id                 = "gold"
  friendly_name              = "Gold"
  description                = "Business-ready dimension and fact tables"
  location                   = var.region
  delete_contents_on_destroy = false

  labels = {
    layer = "gold"
  }
}

resource "google_bigquery_dataset" "ai" {
  project                    = var.project_id
  dataset_id                 = "ai"
  friendly_name              = "AI"
  description                = "Gemini-enriched views and ML models"
  location                   = var.region
  delete_contents_on_destroy = false

  labels = {
    layer = "ai"
  }
}

resource "google_bigquery_dataset" "governance" {
  project                    = var.project_id
  dataset_id                 = "governance"
  friendly_name              = "Governance"
  description                = "Audit logs, batch tracking, compliance"
  location                   = var.region
  delete_contents_on_destroy = false

  labels = {
    layer = "governance"
  }
}

# ---------------------------------------------------------------------------
# BigQuery Remote Connection — Gemini via Vertex AI
# ---------------------------------------------------------------------------

resource "google_bigquery_connection" "gemini_connection" {
  project       = var.project_id
  connection_id = "gemini-pro-connection"
  location      = var.region

  cloud_resource {}
}

# Grant the connection's auto-generated SA the Vertex AI User role so it can
# invoke Gemini endpoints from within BigQuery remote functions / ML.GENERATE.
resource "google_project_iam_member" "gemini_connection_vertex" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_bigquery_connection.gemini_connection.cloud_resource[0].service_account_id}"
}
