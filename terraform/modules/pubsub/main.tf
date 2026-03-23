# ---------------------------------------------------------------------------
# Pub/Sub topic — receives GCS object.finalize notifications from the
# delta-staging bucket. Eventarc uses this topic as its transport channel.
# ---------------------------------------------------------------------------

resource "google_pubsub_topic" "delta_ingest" {
  project = var.project_id
  name    = "delta-ingest-events"

  labels = {
    workload = "delta-pipeline"
  }

  message_retention_duration = "86600s" # 24 hours
}

# GCS needs publish rights on the topic to send bucket notifications
data "google_storage_project_service_account" "gcs_sa" {
  project = var.project_id
}

resource "google_pubsub_topic_iam_member" "gcs_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.delta_ingest.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_sa.email_address}"
}

# GCS bucket notification — fires on every new object in the staging bucket
resource "google_storage_notification" "delta_ingest" {
  bucket         = var.bucket_name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.delta_ingest.id
  event_types    = ["OBJECT_FINALIZE"]

  depends_on = [google_pubsub_topic_iam_member.gcs_publisher]
}
