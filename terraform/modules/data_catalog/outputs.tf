output "taxonomy_id" {
  description = "The resource name of the Intelia Knowledge Catalog policy tag taxonomy (Dataplex Universal Catalog)."
  value       = google_data_catalog_taxonomy.intelia.id
}

output "pii_policy_tag_id" {
  description = "Resource name of the PII parent policy tag."
  value       = google_data_catalog_policy_tag.pii.id
}

output "sensitive_financial_policy_tag_id" {
  description = "Resource name of the Sensitive Financial parent policy tag."
  value       = google_data_catalog_policy_tag.sensitive_financial.id
}

output "internal_use_only_policy_tag_id" {
  description = "Resource name of the Internal Use Only parent policy tag."
  value       = google_data_catalog_policy_tag.internal_use_only.id
}
