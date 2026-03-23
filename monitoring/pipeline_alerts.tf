terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
}

# ---------------------------------------------------------------------------
# Email notification channel
# ---------------------------------------------------------------------------

resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "Pipeline Alerts Email"
  type         = "email"

  labels = {
    email_address = "admin@intelia.com.au"
  }

  force_delete = false
}

# ---------------------------------------------------------------------------
# Log-based metric — Dataform pipeline failure
# ---------------------------------------------------------------------------

resource "google_logging_metric" "dataform_failure" {
  project = var.project_id
  name    = "dataform_pipeline_failure"
  filter  = "resource.type=\"dataform.googleapis.com/Repository\" severity=ERROR"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
    display_name = "Dataform Pipeline Failure Count"
  }
}

# ---------------------------------------------------------------------------
# Alert policy — Dataform pipeline failure
# ---------------------------------------------------------------------------

resource "google_monitoring_alert_policy" "dataform_pipeline_failure" {
  project      = var.project_id
  display_name = "Dataform Pipeline Failure"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Pipeline error detected"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/dataform_pipeline_failure\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_COUNT"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  alert_strategy {
    auto_close = "604800s"
  }

  documentation {
    content   = "A Dataform repository emitted an ERROR-severity log entry. Investigate the Dataform execution logs in the GCP Console under Dataform > Workflow Invocations."
    mime_type = "text/markdown"
  }

  depends_on = [google_logging_metric.dataform_failure]
}

# ---------------------------------------------------------------------------
# Log-based metric — BigQuery job failure
# ---------------------------------------------------------------------------

resource "google_logging_metric" "bigquery_job_failure" {
  project = var.project_id
  name    = "bigquery_job_failure"
  filter  = "resource.type=\"bigquery_resource\" protoPayload.status.code!=\"0\" severity=ERROR"

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "BigQuery Job Failure Count"
  }
}

resource "google_monitoring_alert_policy" "bigquery_job_failure" {
  project      = var.project_id
  display_name = "BigQuery Job Failure"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "BigQuery job error detected"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/bigquery_job_failure\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_COUNT"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  alert_strategy {
    auto_close = "604800s"
  }

  documentation {
    content   = "A BigQuery job failed. Check the BigQuery job history in the GCP Console for details on the failed query or load job."
    mime_type = "text/markdown"
  }

  depends_on = [google_logging_metric.bigquery_job_failure]
}
