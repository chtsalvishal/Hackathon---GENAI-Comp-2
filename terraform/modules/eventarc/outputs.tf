output "trigger_name" {
  description = "Name of the Eventarc delta-ingest trigger."
  value       = google_eventarc_trigger.delta_ingest.name
}

output "trigger_id" {
  description = "Full resource ID of the Eventarc delta-ingest trigger."
  value       = google_eventarc_trigger.delta_ingest.id
}
