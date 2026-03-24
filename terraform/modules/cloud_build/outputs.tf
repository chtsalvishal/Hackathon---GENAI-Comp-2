output "validate_trigger_name" {
  description = "Name of the PR validation Cloud Build trigger (empty until GitHub App is connected)."
  value       = length(google_cloudbuild_trigger.validate) > 0 ? google_cloudbuild_trigger.validate[0].name : ""
}

output "deploy_trigger_name" {
  description = "Name of the main-branch deploy Cloud Build trigger (empty until GitHub App is connected)."
  value       = length(google_cloudbuild_trigger.deploy) > 0 ? google_cloudbuild_trigger.deploy[0].name : ""
}
