output "bigquery_connection_id" {
  description = "The fully qualified ID of the BigQuery remote connection used for Gemini."
  value       = module.bigquery.bigquery_connection_id
}

output "dataform_repository_id" {
  description = "The resource name of the Dataform repository."
  value       = module.dataform.dataform_repository_id
}

output "gemini_model_id" {
  description = "The Vertex AI model ID used for Gemini integration via BigQuery remote connection."
  value       = "gemini-pro"
}

output "data_catalog_taxonomy_id" {
  description = "The resource name of the Data Catalog policy tag taxonomy."
  value       = module.data_catalog.taxonomy_id
}

output "gcs_bucket_name" {
  description = "The name of the GCS staging bucket for the delta pipeline."
  value       = module.storage.bucket_name
}
