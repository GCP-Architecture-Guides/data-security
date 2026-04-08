terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0, < 8.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.0.0, < 8.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}

provider "google" {
  project               = var.project_id
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
}

provider "google-beta" {
  project               = var.project_id
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
}

# Enable Required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "dlp.googleapis.com",
    "cloudkms.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "accesscontextmanager.googleapis.com",
    "cloudasset.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "datacatalog.googleapis.com"
  ])

  project = var.project_id
  service = each.value

  disable_on_destroy         = false
  disable_dependent_services = false
}

resource "random_id" "suffix" {
  byte_length = 4
  keepers = {
    project_id = var.project_id
  }
}

check "access_policy_id_when_reusing_policy" {
  assert {
    condition     = var.create_access_policy || length(trimspace(var.access_policy_id)) > 0
    error_message = "When create_access_policy is false, set access_policy_id to your numeric Access Context Manager policy ID."
  }
}
