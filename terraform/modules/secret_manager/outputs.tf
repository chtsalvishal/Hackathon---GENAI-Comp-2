output "github_token_secret_name" {
  description = "Full resource name of the latest version of the github-token secret. Pass this to the Dataform module."
  value       = google_secret_manager_secret_version.github_token_placeholder.name
}

output "github_token_secret_id" {
  description = "Short secret ID of the github-token secret, used for IAM binding references."
  value       = google_secret_manager_secret.github_token.secret_id
}

output "looker_api_key_secret_name" {
  description = "Full resource name of the latest version of the looker-api-key secret."
  value       = google_secret_manager_secret_version.looker_api_key_placeholder.name
}

output "gemini_api_key_secret_name" {
  description = "Full resource name of the latest version of the gemini-api-key secret."
  value       = google_secret_manager_secret_version.gemini_api_key_placeholder.name
}
