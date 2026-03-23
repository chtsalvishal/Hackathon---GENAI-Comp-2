variable "project_id" {
  description = "The GCP project ID in which BigQuery datasets and connections will be created."
  type        = string
}

variable "region" {
  description = "The GCP region / multi-region location for BigQuery datasets."
  type        = string
}
