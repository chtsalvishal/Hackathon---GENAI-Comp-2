output "workflow_name" {
  description = "Short name of the delta-ingest Cloud Workflow (used by Eventarc trigger)."
  value       = google_workflows_workflow.delta_ingest.name
}

output "daily_workflow_name" {
  description = "Short name of the daily-refresh Cloud Workflow (used by Cloud Scheduler)."
  value       = google_workflows_workflow.daily_refresh.name
}

output "delta_workflow_id" {
  description = "Full resource ID of the delta-ingest workflow."
  value       = google_workflows_workflow.delta_ingest.id
}

output "daily_workflow_id" {
  description = "Full resource ID of the daily-refresh workflow."
  value       = google_workflows_workflow.daily_refresh.id
}
