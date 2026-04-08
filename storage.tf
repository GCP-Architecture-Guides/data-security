resource "google_storage_bucket" "raw_ingestion" {
  name                        = "raw-unclassified-ingest-${random_id.suffix.hex}"
  location                    = var.region
  force_destroy               = var.bucket_force_destroy
  uniform_bucket_level_access = true

  dynamic "encryption" {
    for_each = local.autokey_keyhandles_enabled ? [1] : []
    content {
      default_kms_key_name = google_kms_key_handle.gcs_raw_ingestion[0].kms_key
    }
  }

  depends_on = [
    google_project_service.required_apis
  ]
}

# The intentionally public-permissive bucket
resource "google_storage_bucket" "public_permissive" {
  name                        = "public-permissive-demo-${random_id.suffix.hex}"
  location                    = var.region
  force_destroy               = var.bucket_force_destroy
  uniform_bucket_level_access = true

  dynamic "encryption" {
    for_each = local.autokey_keyhandles_enabled ? [1] : []
    content {
      default_kms_key_name = google_kms_key_handle.gcs_public_permissive[0].kms_key
    }
  }

  depends_on = [
    google_project_service.required_apis
  ]
}

# Misconfigure it to be publicly readable to demonstrate VPC-SC block
resource "google_storage_bucket_iam_member" "all_users_viewers" {
  count = var.enable_public_exposure_demo ? 1 : 0

  bucket = google_storage_bucket.public_permissive.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"

  depends_on = [google_project_organization_policy.domain_restricted_sharing]
}
