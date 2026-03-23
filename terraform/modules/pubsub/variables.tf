variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "bucket_name" {
  description = "Name of the GCS delta-staging bucket that publishes object.finalize events."
  type        = string
}
