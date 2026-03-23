variable "project_id" {
  description = "The GCP project ID in which the Dataform repository will be created."
  type        = string
}

variable "region" {
  description = "The GCP region where the Dataform repository will reside."
  type        = string
}

variable "github_token_secret_name" {
  description = "The full resource name of the Secret Manager secret VERSION containing the GitHub PAT (e.g. projects/*/secrets/github-token/versions/latest)."
  type        = string
}

variable "github_token_secret_id" {
  description = "The Secret Manager secret ID (short name) for the GitHub token, used for IAM bindings."
  type        = string
  default     = "github-token"
}

variable "dataform_sa_email" {
  description = "Email of the Dataform service account (created in the IAM module)."
  type        = string
  default     = ""
}
