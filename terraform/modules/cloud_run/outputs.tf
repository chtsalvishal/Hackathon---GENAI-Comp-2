output "service_url" {
  description = "HTTPS URL of the deployed Cloud Run customer-ai-processor service."
  value       = google_cloud_run_v2_service.customer_ai.uri
}
