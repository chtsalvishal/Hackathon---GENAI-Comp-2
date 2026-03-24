output "metadata_store_id" {
  description = "Resource name of the default Vertex AI Metadata Store."
  value       = google_vertex_ai_metadata_store.default.id
}
