variable "project_id" {
  description = "The GCP project ID where all resources will be deployed."
  type        = string
}

variable "region" {
  description = "The GCP region for resource deployment."
  type        = string
  default     = "australia-southeast1"
}

variable "billing_account_id" {
  description = "The billing account ID linked to the GCP project, used for budget alerts."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in owner/name format (e.g. 'chtsalvishal/Hackathon---GENAI-Comp-2')."
  type        = string
  default     = "chtsalvishal/Hackathon---GENAI-Comp-2"
}

variable "github_app_installation_id" {
  description = "GitHub App installation ID for the Cloud Build GitHub connection."
  type        = number
  default     = 0
}
