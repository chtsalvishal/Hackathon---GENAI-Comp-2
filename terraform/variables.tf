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
