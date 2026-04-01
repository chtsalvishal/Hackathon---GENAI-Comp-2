variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "Region to deploy the Cloud Run service."
  type        = string
}

variable "cloud_run_sa_email" {
  description = "Service account email the Cloud Run container runs as."
  type        = string
}

variable "workflows_sa_email" {
  description = "Cloud Workflows SA email — granted roles/run.invoker on this service."
  type        = string
}
