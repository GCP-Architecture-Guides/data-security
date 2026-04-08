# KMS Autokey: delegated (same-project) model when folder_id is set.
#
# key_project_resolution_mode = RESOURCE_PROJECT omits key_project; Autokey creates keys in the
# same project as each protected resource (Preview). Then google_kms_key_handle resources request
# CMEK for BigQuery datasets and GCS buckets in project_id.
# https://cloud.google.com/kms/docs/enable-autokey#delegated_key_management_with_terraform
# https://cloud.google.com/kms/docs/create-resource-with-autokey

locals {
  autokey_folder_enabled     = var.folder_id != null
  autokey_keyhandles_enabled = local.autokey_folder_enabled
}

resource "google_kms_autokey_config" "autokey" {
  count = local.autokey_folder_enabled ? 1 : 0

  folder                      = "folders/${var.folder_id}"
  key_project_resolution_mode = "RESOURCE_PROJECT"

  # Intentionally not gated on the VPC-SC perimeter so Autokey + KeyHandles + BQ seed can run first.
  depends_on = [google_project_service.required_apis]
}

data "google_project" "project" {
  project_id = var.project_id
}
