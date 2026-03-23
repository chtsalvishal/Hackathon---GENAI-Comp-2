# ---------------------------------------------------------------------------
# Dataplex Lake and Zones
# One lake with two zones mirrors the medallion architecture:
#   - raw-zone     → Bronze layer (GCS-backed, unprocessed data)
#   - curated-zone → Silver + Gold + AI layers (BigQuery-backed, analytics-ready)
# ---------------------------------------------------------------------------

resource "google_dataplex_lake" "intelia_warehouse" {
  project      = var.project_id
  location     = var.region
  name         = "intelia-warehouse"
  display_name = "Intelia Warehouse"
  description  = "Dataplex lake governing the Intelia data warehouse — Bronze to AI layers."

  labels = {
    environment = "production"
    workload    = "data-warehouse"
  }
}

resource "google_dataplex_zone" "raw" {
  project      = var.project_id
  location     = var.region
  lake         = google_dataplex_lake.intelia_warehouse.name
  name         = "raw-zone"
  display_name = "Raw Zone (Bronze)"
  description  = "Unprocessed data landed from source systems via GCS."
  type         = "RAW"

  discovery_spec {
    enabled = true
    schedule = "0 * * * *"  # hourly discovery
  }

  resource_spec {
    location_type = "SINGLE_REGION"
  }

  labels = {
    layer = "bronze"
  }
}

resource "google_dataplex_zone" "curated" {
  project      = var.project_id
  location     = var.region
  lake         = google_dataplex_lake.intelia_warehouse.name
  name         = "curated-zone"
  display_name = "Curated Zone (Silver / Gold / AI)"
  description  = "Transformed and analytics-ready BigQuery datasets."
  type         = "CURATED"

  discovery_spec {
    enabled  = true
    schedule = "0 * * * *"  # hourly discovery
  }

  resource_spec {
    location_type = "SINGLE_REGION"
  }

  labels = {
    layer = "silver-gold-ai"
  }
}

# ---------------------------------------------------------------------------
# Data Quality Scans
# Run daily against key Gold-layer tables.
# Results feed the Dataplex data quality scorecard in Cloud Console.
# ---------------------------------------------------------------------------

resource "google_dataplex_datascan" "fct_orders_quality" {
  project      = var.project_id
  location     = var.region
  data_scan_id = "fct-orders-quality"
  display_name = "fct_orders Data Quality"
  description  = "Daily data quality checks on the Gold fct_orders table."

  data {
    resource = "//bigquery.googleapis.com/projects/${var.project_id}/datasets/gold/tables/fct_orders"
  }

  execution_spec {
    trigger {
      schedule {
        cron = "0 2 * * *"  # 02:00 UTC daily (after overnight refresh)
      }
    }
  }

  data_quality_spec {
    rules {
      column      = "order_id"
      dimension   = "COMPLETENESS"
      name        = "order_id_not_null"
      description = "Every order must have a non-null order_id."
      non_null_expectation {}
    }

    rules {
      column      = "order_date"
      dimension   = "VALIDITY"
      name        = "order_date_not_future"
      description = "order_date must not be in the future."
      row_condition_expectation {
        sql_expression = "order_date <= CURRENT_DATE()"
      }
    }

    rules {
      column      = "total_amount"
      dimension   = "VALIDITY"
      name        = "total_amount_positive"
      description = "total_amount must be >= 0."
      range_expectation {
        min_value          = "0"
        strict_min_enabled = false
      }
    }

    rules {
      dimension   = "UNIQUENESS"
      name        = "order_id_unique"
      description = "order_id must be unique across all orders."
      column      = "order_id"
      uniqueness_expectation {}
    }
  }

  labels = {
    table   = "fct_orders"
    layer   = "gold"
    workload = "data-quality"
  }
}

resource "google_dataplex_datascan" "dim_customers_quality" {
  project      = var.project_id
  location     = var.region
  data_scan_id = "dim-customers-quality"
  display_name = "dim_customers Data Quality"
  description  = "Daily data quality checks on the Gold dim_customers table."

  data {
    resource = "//bigquery.googleapis.com/projects/${var.project_id}/datasets/gold/tables/dim_customers"
  }

  execution_spec {
    trigger {
      schedule {
        cron = "0 2 * * *"
      }
    }
  }

  data_quality_spec {
    rules {
      column      = "customer_id"
      dimension   = "COMPLETENESS"
      name        = "customer_id_not_null"
      description = "Every customer must have a non-null customer_id."
      non_null_expectation {}
    }

    rules {
      column      = "customer_id"
      dimension   = "UNIQUENESS"
      name        = "customer_id_unique"
      description = "customer_id must be unique."
      uniqueness_expectation {}
    }

    rules {
      column      = "email"
      dimension   = "VALIDITY"
      name        = "email_format"
      description = "email must contain an @ symbol."
      row_condition_expectation {
        sql_expression = "email LIKE '%@%'"
      }
    }
  }

  labels = {
    table   = "dim_customers"
    layer   = "gold"
    workload = "data-quality"
  }
}

resource "google_dataplex_datascan" "dim_products_quality" {
  project      = var.project_id
  location     = var.region
  data_scan_id = "dim-products-quality"
  display_name = "dim_products Data Quality"
  description  = "Daily data quality checks on the Gold dim_products table."

  data {
    resource = "//bigquery.googleapis.com/projects/${var.project_id}/datasets/gold/tables/dim_products"
  }

  execution_spec {
    trigger {
      schedule {
        cron = "0 2 * * *"
      }
    }
  }

  data_quality_spec {
    rules {
      column      = "product_id"
      dimension   = "COMPLETENESS"
      name        = "product_id_not_null"
      description = "Every product must have a non-null product_id."
      non_null_expectation {}
    }

    rules {
      column      = "unit_price"
      dimension   = "VALIDITY"
      name        = "unit_price_positive"
      description = "unit_price must be > 0."
      range_expectation {
        min_value          = "0"
        strict_min_enabled = true
      }
    }
  }

  labels = {
    table   = "dim_products"
    layer   = "gold"
    workload = "data-quality"
  }
}
