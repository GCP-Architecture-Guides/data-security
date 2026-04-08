# SecOps Dashboard: VPC Service Controls Violations Logging

# Create a BigQuery Dataset to house the SecOps Dashboard logs
resource "google_bigquery_dataset" "secops_dashboard" {
  dataset_id    = "secops_dashboard_${random_id.suffix.hex}"
  friendly_name = "SecOps Dashboard"
  description   = "Dataset for storing security logs, specifically VPC Service Controls violations."
  location      = "US"

  dynamic "default_encryption_configuration" {
    for_each = local.autokey_keyhandles_enabled ? [1] : []
    content {
      kms_key_name = google_kms_key_handle.bq_secops_dashboard[0].kms_key
    }
  }

  delete_contents_on_destroy = !var.bigquery_deletion_protection

  labels = {
    goog-terraform-provisioned = "true"
  }

  depends_on = [google_project_service.required_apis]
}

# Create a Log Router Sink to capture VPC-SC violations and send them to the BigQuery dataset
resource "google_logging_project_sink" "vpc_sc_violations" {
  name        = "vpc-sc-violations-sink"
  description = "Routes VPC Service Controls violations to the SecOps BigQuery dataset."
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.secops_dashboard.dataset_id}"

  # Filter specifically for VPC-SC block logs
  filter = "protoPayload.metadata.violationReason=\"VPC_SERVICE_CONTROLS_VIOLATION\""

  # Use a unique writer identity for this sink
  unique_writer_identity = true

  depends_on = [google_project_service.required_apis]
}

# Grant the Log Sink's service account permission to write to BigQuery
resource "google_project_iam_member" "log_writer" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = google_logging_project_sink.vpc_sc_violations.writer_identity
}
