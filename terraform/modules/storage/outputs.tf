output "bucket_name" {
  description = "The name of the GCS delta-staging bucket."
  value       = google_storage_bucket.delta_staging.name
}

output "bucket_url" {
  description = "The gs:// URL of the GCS delta-staging bucket."
  value       = google_storage_bucket.delta_staging.url
}
