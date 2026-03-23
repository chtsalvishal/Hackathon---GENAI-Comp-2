variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The GCP region for the Eventarc trigger."
  type        = string
}

variable "bucket_name" {
  description = "Name of the GCS bucket to watch for object.finalize events."
  type        = string
}

variable "workflow_name" {
  description = "Short name of the Cloud Workflow to invoke when a new file arrives."
  type        = string
}

variable "eventarc_sa_email" {
  description = "Email of the Eventarc service account used to invoke the workflow."
  type        = string
}
