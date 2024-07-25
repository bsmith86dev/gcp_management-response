provider "google" {
  project = var.project_id
  credentials = file("credentials.json")
  region  = var.region
}

# Variables for the project and region
variable "admin" {}
variable "user" {}

# Enable required APIs
resource "google_project_service" "enabled_apis" {
  for_each = toset([
    "cloudsecuritycenter.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "bigquery.googleapis.com",
  ])
  project = var.project_id
  service = each.key
}

# IAM roles for Security Command Center
resource "google_project_iam_member" "scc_roles" {
  for_each = {
    "roles/securitycenter.admin"        = "var.admin"
    "roles/securitycenter.findingsEditor" = "var.user"
  }
  project = var.project_id
  role    = each.key
  member  = each.value
}

# Cloud Logging Sink to BigQuery
resource "google_logging_project_sink" "log_sink" {
  name        = "my-log-sink"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/logs_dataset"
  filter      = "severity>=ERROR"

  bigquery_options {
    use_partitioned_tables = true
  }
}

# BigQuery Dataset for logs
resource "google_bigquery_dataset" "logs_dataset" {
  dataset_id = "logs_dataset"
  project    = var.project_id
  location   = var.region
}

# Cloud Monitoring Notification Channel (email)
resource "google_monitoring_notification_channel" "email_channel" {
  display_name = "Email Notification Channel"
  type         = "email"
  labels = {
    email_address = "var.admin"
  }
}

# Cloud Monitoring Uptime Check
resource "google_monitoring_uptime_check_config" "uptime_check" {
  display_name = "Uptime Check"
  timeout      = "10s"
  period       = "60s"

  http_check {
    path = "/"
    port = 80
  }

  monitored_resource {
    type   = "uptime_url"
    labels = {
      host = "example.com"
    }
  }
}

# Cloud Monitoring Alert Policy
resource "google_monitoring_alert_policy" "alert_policy" {
  display_name = "High CPU Alert"
  combiner     = "AND"

  conditions {
    display_name = "High CPU Condition"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "60s"
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_channel.name]
}

# Cloud Function for automated response (Placeholder)
resource "google_cloudfunctions_function" "high_cpu_alert_function" {
  name        = "high-cpu-alert"
  runtime     = "python38"
  entry_point = "high_cpu_alert"
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_zip.name
  trigger_http = false
  available_memory_mb = 256

  event_trigger {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource   = google_pubsub_topic.high_cpu_topic.name
  }
}

resource "google_pubsub_topic" "high_cpu_topic" {
  name = "high-cpu-topic"
}

# Storage bucket for Cloud Function source
resource "google_storage_bucket" "function_bucket" {
  name     = "${var.project_id}-function-source"
  location = var.region
}

# Cloud Function source code
resource "google_storage_bucket_object" "function_zip" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = "path/to/function/source.zip"  # Update this with your source code path
}
