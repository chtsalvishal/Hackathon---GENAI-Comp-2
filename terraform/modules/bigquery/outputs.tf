output "bigquery_connection_id" {
  description = "Fully qualified ID of the BigQuery remote connection for Gemini."
  value       = google_bigquery_connection.gemini_connection.id
}

output "bronze_dataset_id" {
  description = "Dataset ID for the Bronze layer."
  value       = google_bigquery_dataset.bronze.dataset_id
}

output "silver_dataset_id" {
  description = "Dataset ID for the Silver layer."
  value       = google_bigquery_dataset.silver.dataset_id
}

output "gold_dataset_id" {
  description = "Dataset ID for the Gold layer."
  value       = google_bigquery_dataset.gold.dataset_id
}

output "ai_dataset_id" {
  description = "Dataset ID for the AI layer."
  value       = google_bigquery_dataset.ai.dataset_id
}

output "governance_dataset_id" {
  description = "Dataset ID for the Governance layer."
  value       = google_bigquery_dataset.governance.dataset_id
}
