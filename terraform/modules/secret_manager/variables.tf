variable "project_id" {
  description = "The GCP project ID in which secrets will be created."
  type        = string
}

variable "dataform_sa_email" {
  description = "Email of the Dataform service account that requires access to the github-token secret."
  type        = string
}

variable "reasoning_engine_sa_email" {
  description = "Email of the Reasoning Engine service account that requires access to the gemini-api-key secret."
  type        = string
}
