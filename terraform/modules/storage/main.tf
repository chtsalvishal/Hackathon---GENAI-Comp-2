resource "google_storage_bucket" "delta_staging" {
  project                     = var.project_id
  name                        = "${var.project_id}-delta-staging"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = false

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
    condition {
      age = 90
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }

  labels = {
    environment = "production"
    workload    = "delta-pipeline"
  }
}
