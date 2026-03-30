# ---------------------------------------------------------------------------
# Data Catalog Policy Tag Taxonomy — "Intelia Data Taxonomy"
# ---------------------------------------------------------------------------

resource "google_data_catalog_taxonomy" "intelia" {
  project                = var.project_id
  region                 = var.region
  display_name           = "Intelia Data Taxonomy"
  description            = "Enterprise policy tag taxonomy governing PII, sensitive financial, and internal data classifications."
  activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]
}

# ---------------------------------------------------------------------------
# PII — parent tag
# ---------------------------------------------------------------------------

resource "google_data_catalog_policy_tag" "pii" {
  taxonomy     = google_data_catalog_taxonomy.intelia.id
  display_name = "PII"
  description  = "Personally Identifiable Information that must be masked or restricted."
}

resource "google_data_catalog_policy_tag" "customer_email" {
  taxonomy          = google_data_catalog_taxonomy.intelia.id
  display_name      = "customer_email"
  description       = "Customer email address — PII."
  parent_policy_tag = google_data_catalog_policy_tag.pii.id
}

resource "google_data_catalog_policy_tag" "customer_phone" {
  taxonomy          = google_data_catalog_taxonomy.intelia.id
  display_name      = "customer_phone"
  description       = "Customer phone number — PII."
  parent_policy_tag = google_data_catalog_policy_tag.pii.id
}

resource "google_data_catalog_policy_tag" "customer_name" {
  taxonomy          = google_data_catalog_taxonomy.intelia.id
  display_name      = "customer_name"
  description       = "Customer full name — PII."
  parent_policy_tag = google_data_catalog_policy_tag.pii.id
}

# ---------------------------------------------------------------------------
# Sensitive Financial — parent tag
# ---------------------------------------------------------------------------

resource "google_data_catalog_policy_tag" "sensitive_financial" {
  taxonomy     = google_data_catalog_taxonomy.intelia.id
  display_name = "Sensitive Financial"
  description  = "Financially sensitive fields restricted to authorised finance principals."
}

resource "google_data_catalog_policy_tag" "order_total" {
  taxonomy          = google_data_catalog_taxonomy.intelia.id
  display_name      = "order_total"
  description       = "Total monetary value of an order — Sensitive Financial."
  parent_policy_tag = google_data_catalog_policy_tag.sensitive_financial.id
}

resource "google_data_catalog_policy_tag" "unit_price" {
  taxonomy          = google_data_catalog_taxonomy.intelia.id
  display_name      = "unit_price"
  description       = "Unit price of a product — Sensitive Financial."
  parent_policy_tag = google_data_catalog_policy_tag.sensitive_financial.id
}

resource "google_data_catalog_policy_tag" "lifetime_value" {
  taxonomy          = google_data_catalog_taxonomy.intelia.id
  display_name      = "lifetime_value"
  description       = "Customer lifetime value — Sensitive Financial."
  parent_policy_tag = google_data_catalog_policy_tag.sensitive_financial.id
}

# ---------------------------------------------------------------------------
# Internal Use Only — parent tag
# ---------------------------------------------------------------------------

resource "google_data_catalog_policy_tag" "internal_use_only" {
  taxonomy     = google_data_catalog_taxonomy.intelia.id
  display_name = "Internal Use Only"
  description  = "Data classified for internal use only; not to be shared externally."
}

resource "google_data_catalog_policy_tag" "internal_cost" {
  taxonomy          = google_data_catalog_taxonomy.intelia.id
  display_name      = "internal_cost"
  description       = "Internal cost data — Internal Use Only."
  parent_policy_tag = google_data_catalog_policy_tag.internal_use_only.id
}

# ---------------------------------------------------------------------------
# Business Glossary — implemented as governance.business_glossary in Dataform
# (Data Catalog tag templates deprecated; Dataplex Catalog is the successor)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------

# BigQuery Audit Logging
# ---------------------------------------------------------------------------

resource "google_project_iam_audit_config" "bigquery_audit" {
  project = var.project_id
  service = "bigquery.googleapis.com"

  audit_log_config {
    log_type = "DATA_READ"
  }

  audit_log_config {
    log_type = "DATA_WRITE"
  }

  audit_log_config {
    log_type = "ADMIN_READ"
  }
}
