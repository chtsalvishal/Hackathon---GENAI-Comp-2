# ---------------------------------------------------------------------------
# Vertex AI Metadata Store — validates aiplatform API is active.
# BigQuery ML (ML.GENERATE_TEXT via the remote Gemini connection) uses this
# API; the store provides a concrete anchor for any future Vertex AI tooling.
# ---------------------------------------------------------------------------

resource "google_vertex_ai_metadata_store" "default" {
  provider    = google-beta
  project     = var.project_id
  region      = var.region
  name        = "default"
  description = "Default Vertex AI Metadata Store for the Intelia warehouse pipeline."
}
