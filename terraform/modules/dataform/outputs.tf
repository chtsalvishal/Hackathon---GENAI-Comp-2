output "dataform_repository_id" {
  description = "The resource name of the Dataform repository."
  value       = google_dataform_repository.main.id
}

output "dataform_repository_name" {
  description = "The short name of the Dataform repository."
  value       = google_dataform_repository.main.name
}
