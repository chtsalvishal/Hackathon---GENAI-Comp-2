# ---------------------------------------------------------------------------
# Notification Channel — email alerts sent to the configured address
# ---------------------------------------------------------------------------

resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "Intelia Warehouse Alerts"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }
}

# ---------------------------------------------------------------------------
# Budget Alert — fires at 80% and 100% of monthly spend forecast
# ---------------------------------------------------------------------------

resource "google_billing_budget" "monthly" {
  billing_account = var.billing_account_id
  display_name    = "intelia-warehouse-monthly-budget"

  budget_filter {
    projects = ["projects/160702508047"]
  }

  amount {
    specified_amount {
      currency_code = "AUD"
      units         = var.monthly_budget_aud
    }
  }

  threshold_rules {
    threshold_percent = 0.8
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = [google_monitoring_notification_channel.email.id]
    disable_default_iam_recipients   = false
  }
}

# ---------------------------------------------------------------------------
# Alert: Cloud Workflows execution FAILED
# Fires within 5 minutes of any failed delta-ingest or daily-refresh run.
# ---------------------------------------------------------------------------

resource "google_monitoring_alert_policy" "workflow_failed" {
  project      = var.project_id
  display_name = "Cloud Workflow Execution Failed"
  combiner     = "OR"

  conditions {
    display_name = "Workflow finished with FAILED state"

    condition_threshold {
      filter          = <<-EOT
        resource.type = "workflows.googleapis.com/Workflow"
        AND metric.type = "workflows.googleapis.com/finished_execution_count"
        AND metric.labels.status = "FAILED"
      EOT
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "A Cloud Workflow (delta-ingest-workflow or daily-refresh-workflow) has failed. Check Cloud Workflows console for execution details and logs."
    mime_type = "text/markdown"
  }
}

# ---------------------------------------------------------------------------
# Alert: No successful workflow run in 26 hours (data freshness SLA)
# Guards against the daily refresh silently not running.
# ---------------------------------------------------------------------------

resource "google_monitoring_alert_policy" "data_freshness_sla" {
  project      = var.project_id
  display_name = "Data Freshness SLA Breach — No Successful Workflow in 26h"
  combiner     = "OR"

  conditions {
    display_name = "Successful workflow executions dropped to zero"

    condition_threshold {
      filter          = <<-EOT
        resource.type = "workflows.googleapis.com/Workflow"
        AND metric.type = "workflows.googleapis.com/finished_execution_count"
        AND metric.labels.status = "SUCCEEDED"
      EOT
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      duration        = "93600s" # 26 hours

      aggregations {
        alignment_period   = "93600s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "86400s"
  }

  documentation {
    content   = "No Cloud Workflow has completed successfully in the last 26 hours. The gold layer may be stale. Check Cloud Scheduler and Cloud Workflows for missed executions."
    mime_type = "text/markdown"
  }
}

# ---------------------------------------------------------------------------
# Alert: BigQuery slot utilisation > 80%
# Early warning before queries start queuing.
# ---------------------------------------------------------------------------

resource "google_monitoring_alert_policy" "bq_slot_high" {
  project      = var.project_id
  display_name = "BigQuery Slot Utilisation High (>80%)"
  combiner     = "OR"

  conditions {
    display_name = "BQ slot utilisation above 80%"

    condition_threshold {
      filter          = <<-EOT
        resource.type = "bigquery_project"
        AND metric.type = "bigquery.googleapis.com/storage/table_count"
      EOT
      comparison      = "COMPARISON_GT"
      threshold_value = 80
      duration        = "300s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "BigQuery slot utilisation has exceeded 80%. Consider reviewing concurrent query patterns or upgrading slot capacity."
    mime_type = "text/markdown"
  }
}
