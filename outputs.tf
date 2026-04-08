output "project_id" {
  description = "The GCP Project ID"
  value       = data.google_project.project.project_id
}

output "raw_ingestion_bucket" {
  description = "The name of the raw ingestion bucket for DLP"
  value       = google_storage_bucket.raw_ingestion.name
}

output "public_permissive_bucket" {
  description = "The name of the intentionally public bucket"
  value       = google_storage_bucket.public_permissive.name
}

output "bigquery_dataset_id" {
  description = "The BigQuery dataset ID"
  value       = google_bigquery_dataset.secure_data_warehouse.dataset_id
}

output "bigquery_dlp_tokenized_view" {
  description = "Saved view that tokenizes SSN and credit_card via BigQuery DLP_DETERMINISTIC_ENCRYPT (run SELECT * in the console; no SQL to paste)"
  value       = "${var.project_id}.${google_bigquery_dataset.secure_data_warehouse.dataset_id}.${google_bigquery_table.pii_dlp_tokenized.table_id}"
}

output "kms_dlp_tokenization_key" {
  description = "Cloud KMS key used by DLP_KEY_CHAIN in the pii_dlp_tokenized view (same region as BigQuery)"
  value       = google_kms_crypto_key.dlp_bq.id
}

output "enable_public_exposure_demo" {
  description = "Whether intentional public bucket IAM, org policy relaxation, and anonymous US/CA access level were applied"
  value       = var.enable_public_exposure_demo
}
