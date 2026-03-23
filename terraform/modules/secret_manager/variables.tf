variable "project_id" {
  description = "The GCP project ID in which secrets will be created."
  type        = string
}

variable "dataform_sa_email" {
  description = "Email of the Dataform service account that requires access to the github-token secret."
  type        = string
}

variable "cloudbuild_sa_email" {
  description = "Email of the Cloud Build service account that requires access to the github-token secret for CI/CD."
  type        = string
}
