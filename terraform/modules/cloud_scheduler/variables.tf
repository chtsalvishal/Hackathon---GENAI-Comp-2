variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The GCP region for the Cloud Scheduler job."
  type        = string
}

variable "workflow_name" {
  description = "Short name of the daily-refresh Cloud Workflow to invoke."
  type        = string
}

variable "scheduler_sa_email" {
  description = "Email of the Cloud Scheduler service account used to authenticate the HTTP call."
  type        = string
}
