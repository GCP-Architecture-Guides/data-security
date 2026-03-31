# KMS Autokey configuration requires a folder where projects will inherit.
# We will create it if folder_id is provided.

resource "google_kms_autokey_config" "autokey" {
  count       = var.folder_id != null ? 1 : 0
  folder      = "folders/${var.folder_id}"
  key_project = "projects/${var.project_id}"

  depends_on = [google_project_service.required_apis]
}

data "google_project" "project" {
  project_id = var.project_id
}

# The Autokey service agent will automatically receive necessary roles from GCP,
# or can be granted roles manually after the first key request generates the service account.
