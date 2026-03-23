variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The GCP region for the Dataplex lake and scans."
  type        = string
}

variable "dataplex_sa_email" {
  description = "Email of the Dataplex service account used to run data quality scans."
  type        = string
}
