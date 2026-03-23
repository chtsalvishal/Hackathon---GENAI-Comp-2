output "topic_id" {
  description = "Full resource ID of the delta-ingest Pub/Sub topic."
  value       = google_pubsub_topic.delta_ingest.id
}

output "topic_name" {
  description = "Short name of the delta-ingest Pub/Sub topic."
  value       = google_pubsub_topic.delta_ingest.name
}
