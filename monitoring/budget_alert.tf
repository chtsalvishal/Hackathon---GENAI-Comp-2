terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Pub/Sub topic — receives budget alert notifications from Cloud Billing
# ---------------------------------------------------------------------------

resource "google_pubsub_topic" "budget_alerts" {
  project = var.project_id
  name    = "budget-alerts"

  labels = {
    purpose = "billing-budget-notifications"
  }
}

# ---------------------------------------------------------------------------
# Billing Budget — AUD $500/month with 50 / 80 / 100 % threshold rules
# ---------------------------------------------------------------------------

resource "google_billing_budget" "project_budget" {
  billing_account = var.billing_account_id
  display_name    = "Intelia Warehouse Monthly Budget"

  budget_filter {
    projects = ["projects/${var.project_id}"]
  }

  amount {
    specified_amount {
      currency_code = "AUD"
      units         = "500"
    }
  }

  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.8
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  all_updates_rule {
    pubsub_topic                     = google_pubsub_topic.budget_alerts.id
    schema_version                   = "1.0"
    monitoring_notification_channels = [google_monitoring_notification_channel.email.name]
    disable_default_iam_grants       = false
  }
}
