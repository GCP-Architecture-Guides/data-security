resource "google_storage_bucket" "raw_ingestion" {
  name                        = "raw-unclassified-ingest-${random_id.suffix.hex}"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  depends_on = [
    google_project_service.required_apis
  ]
}

# The intentionally public-permissive bucket
resource "google_storage_bucket" "public_permissive" {
  name                        = "public-permissive-demo-${random_id.suffix.hex}"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  # KMS Autokey config is handled automatically if enabled.
  depends_on = [
    google_project_service.required_apis
  ]
}

# Misconfigure it to be publicly readable to demonstrate VPC-SC block
resource "google_storage_bucket_iam_member" "all_users_viewers" {
  bucket = google_storage_bucket.public_permissive.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"

  depends_on = [google_project_organization_policy.domain_restricted_sharing]
}
