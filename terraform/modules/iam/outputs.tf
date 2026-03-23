output "data_analyst_sa_email" {
  description = "Email of the Data Analyst service account."
  value       = google_service_account.data_analyst.email
}

output "ai_developer_sa_email" {
  description = "Email of the AI Developer service account."
  value       = google_service_account.ai_developer.email
}

output "data_engineer_sa_email" {
  description = "Email of the Data Engineer service account."
  value       = google_service_account.data_engineer.email
}

output "governance_sa_email" {
  description = "Email of the Governance service account."
  value       = google_service_account.governance.email
}

output "dataform_sa_email" {
  description = "Email of the Dataform service account. Consumed by secret_manager and dataform modules."
  value       = google_service_account.dataform.email
}

output "workflows_sa_email" {
  description = "Email of the Cloud Workflows service account."
  value       = google_service_account.workflows.email
}

output "eventarc_sa_email" {
  description = "Email of the Eventarc service account."
  value       = google_service_account.eventarc.email
}

output "scheduler_sa_email" {
  description = "Email of the Cloud Scheduler service account."
  value       = google_service_account.scheduler.email
}

output "dataplex_sa_email" {
  description = "Email of the Dataplex service account."
  value       = google_service_account.dataplex.email
}

output "cloudbuild_sa_email" {
  description = "Email of the Cloud Build service account."
  value       = google_service_account.cloudbuild.email
}
