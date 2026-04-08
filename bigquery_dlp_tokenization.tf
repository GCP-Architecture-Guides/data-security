# BigQuery-native DLP deterministic encryption (AES-SIV) for SSN and credit_card columns.
# This is separate from the Cloud DLP de-identify template in dlp.tf (character masking for API jobs).
# See: https://cloud.google.com/bigquery/docs/reference/standard-sql/dlp_functions

resource "random_bytes" "dlp_dek" {
  length = 32
}

resource "google_kms_key_ring" "dlp_bq" {
  name     = "dlp-bq-${random_id.suffix.hex}"
  location = var.region
  project  = var.project_id

  depends_on = [google_project_service.required_apis]
}

resource "google_kms_crypto_key" "dlp_bq" {
  name            = "dlp-bq-tokenization"
  key_ring        = google_kms_key_ring.dlp_bq.id
  rotation_period = "7776000s"
  purpose         = "ENCRYPT_DECRYPT"

  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }
}

# Wrapped data encryption key (encrypted by KMS) required by DLP_KEY_CHAIN in BigQuery SQL.
resource "google_kms_secret_ciphertext" "dlp_dek_wrapped" {
  crypto_key = google_kms_crypto_key.dlp_bq.id
  plaintext  = random_bytes.dlp_dek.base64
}

locals {
  dlp_kms_gcp_uri = "gcp-kms://${google_kms_crypto_key.dlp_bq.id}"
}

# BigQuery views require DLP_KEY_CHAIN's wrapped key as a BYTES literal (not FROM_BASE64).
data "external" "dlp_bq_wrapped_bytes_literal" {
  program = ["python3", "${path.module}/scripts/dlp_wrapped_ciphertext_to_bq_bytes_literal.py"]

  query = {
    ciphertext = google_kms_secret_ciphertext.dlp_dek_wrapped.ciphertext
  }
}

# Invokers of the view (and the underlying DLP SQL functions) need encrypt/decrypt on this key.
resource "google_kms_crypto_key_iam_member" "dlp_bq_tokenization_user" {
  crypto_key_id = google_kms_crypto_key.dlp_bq.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "user:${var.allowed_user_identity}"
}

resource "google_bigquery_table" "pii_dlp_tokenized" {
  dataset_id = google_bigquery_dataset.secure_data_warehouse.dataset_id
  table_id   = "pii_dlp_tokenized"

  deletion_protection = var.bigquery_deletion_protection

  view {
    use_legacy_sql = false
    query          = <<-SQL
SELECT
  id,
  first_name,
  last_name,
  email,
  CASE
    WHEN ssn IS NULL THEN NULL
    ELSE DLP_DETERMINISTIC_ENCRYPT(
      DLP_KEY_CHAIN('${local.dlp_kms_gcp_uri}', ${data.external.dlp_bq_wrapped_bytes_literal.result.bq_bytes_literal}),
      CAST(ssn AS STRING),
      '',
      'poc-ssn-v1'
    )
  END
    AS ssn_tokenized,
  CASE
    WHEN credit_card IS NULL THEN NULL
    ELSE DLP_DETERMINISTIC_ENCRYPT(
      DLP_KEY_CHAIN('${local.dlp_kms_gcp_uri}', ${data.external.dlp_bq_wrapped_bytes_literal.result.bq_bytes_literal}),
      CAST(credit_card AS STRING),
      '',
      'poc-cc-v1'
    )
  END
    AS credit_card_tokenized
FROM
  `${var.project_id}.${google_bigquery_dataset.secure_data_warehouse.dataset_id}.pii_dataset`
SQL
  }

  depends_on = [
    google_bigquery_table.pii_dataset,
    google_kms_crypto_key_iam_member.dlp_bq_tokenization_user,
    google_kms_secret_ciphertext.dlp_dek_wrapped,
    data.external.dlp_bq_wrapped_bytes_literal,
  ]
}
