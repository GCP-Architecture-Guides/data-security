# Synthetic PII sample: uploaded and loaded during apply *before* the VPC-SC perimeter exists
# (see depends_on on google_access_context_manager_service_perimeter in vpc_sc.tf).

resource "google_storage_bucket_object" "demo_pii_raw" {
  name   = "pii/sample_pii_data.txt"
  bucket = google_storage_bucket.raw_ingestion.name
  source = "${path.module}/fixtures/sample_pii_data.csv"

  depends_on = [google_storage_bucket.raw_ingestion]
}

# Always uploaded so apply order before VPC-SC stays a static graph; without allUsers the object is not world-readable.
resource "google_storage_bucket_object" "demo_pii_public" {
  name   = "exposed/sample_pii_data.txt"
  bucket = google_storage_bucket.public_permissive.name
  source = "${path.module}/fixtures/sample_pii_data.csv"

  depends_on = [google_storage_bucket.public_permissive]
}

resource "google_bigquery_job" "demo_seed_pii" {
  job_id   = "demo-seed-pii-${random_id.suffix.hex}"
  project  = var.project_id
  location = var.region

  load {
    source_uris = [
      "gs://${google_storage_bucket.raw_ingestion.name}/${google_storage_bucket_object.demo_pii_raw.name}",
    ]
    source_format     = "CSV"
    skip_leading_rows = 1
    write_disposition = "WRITE_TRUNCATE"

    destination_table {
      project_id = var.project_id
      dataset_id = google_bigquery_dataset.secure_data_warehouse.dataset_id
      table_id   = google_bigquery_table.pii_dataset.table_id
    }
  }

  depends_on = [
    google_bigquery_table.pii_dataset,
    google_storage_bucket_object.demo_pii_raw,
  ]
}
