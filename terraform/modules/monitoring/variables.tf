variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "billing_account_id" {
  description = "The billing account ID for budget alerts."
  type        = string
}

variable "alert_email" {
  description = "Email address to receive all monitoring alerts."
  type        = string
}

variable "monthly_budget_aud" {
  description = "Monthly spend budget in AUD. Alerts fire at 80% and 100%."
  type        = number
  default     = 500
}
