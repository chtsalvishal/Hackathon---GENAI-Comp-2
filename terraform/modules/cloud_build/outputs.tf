output "validate_trigger_name" {
  description = "Name of the PR validation Cloud Build trigger."
  value       = google_cloudbuild_trigger.validate.name
}

output "deploy_trigger_name" {
  description = "Name of the main-branch deploy Cloud Build trigger."
  value       = google_cloudbuild_trigger.deploy.name
}
