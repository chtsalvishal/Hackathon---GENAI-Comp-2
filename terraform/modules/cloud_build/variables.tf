variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The GCP region for Cloud Build triggers and repository connections."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in owner/name format (e.g. 'chtsalvishal/Hackathon---GENAI-Comp-2')."
  type        = string
}

variable "cloudbuild_sa_email" {
  description = "Email of the Cloud Build service account."
  type        = string
}

variable "github_app_installation_id" {
  description = "GitHub App installation ID for the Cloud Build GitHub connection. Set after connecting the repository in Cloud Console."
  type        = number
  default     = 0
}
