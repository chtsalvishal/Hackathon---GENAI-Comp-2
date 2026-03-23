output "job_name" {
  description = "Name of the Cloud Scheduler daily-refresh job."
  value       = google_cloud_scheduler_job.daily_refresh.name
}
