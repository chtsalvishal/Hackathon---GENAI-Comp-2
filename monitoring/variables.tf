variable "project_id" {
  description = "The GCP project ID in which monitoring resources will be created."
  type        = string
  default     = "vishal-sandpit-474523"
}

variable "billing_account_id" {
  description = "The billing account ID linked to the GCP project, used for budget alerts."
  type        = string
  default     = "REPLACE_WITH_BILLING_ACCOUNT_ID"
}
