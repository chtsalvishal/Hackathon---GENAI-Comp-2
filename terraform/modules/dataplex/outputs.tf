output "lake_name" {
  description = "Name of the Dataplex lake."
  value       = google_dataplex_lake.intelia_warehouse.name
}

output "raw_zone_name" {
  description = "Name of the Dataplex raw zone (Bronze layer)."
  value       = google_dataplex_zone.raw.name
}

output "curated_zone_name" {
  description = "Name of the Dataplex curated zone (Silver/Gold/AI layers)."
  value       = google_dataplex_zone.curated.name
}
