output "reasoning_engine_sa_email" {
  description = "Email of the Reasoning Engine service account."
  value       = data.google_service_account.reasoning_engine.email
}

output "metadata_store_id" {
  description = "Resource name of the default Vertex AI Metadata Store."
  value       = google_vertex_ai_metadata_store.default.id
}
