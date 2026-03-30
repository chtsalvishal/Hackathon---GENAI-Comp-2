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

variable "alert_email" {
  description = "Email address to receive pipeline failure, budget, and data freshness alerts."
  type        = string
  default     = "vishal.pattabiraman@intelia.com.au"
}

variable "monthly_budget_aud" {
  description = "Monthly GCP spend budget in AUD. Alerts fire at 80% and 100%."
  type        = number
  default     = 200
}
