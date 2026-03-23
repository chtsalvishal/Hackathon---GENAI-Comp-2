variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The GCP region where Cloud Workflows will be deployed."
  type        = string
}

variable "workflows_sa_email" {
  description = "Email of the service account that Cloud Workflows runs as."
  type        = string
}
