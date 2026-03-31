# Optionally create a new Access Policy
resource "google_access_context_manager_access_policy" "poc_policy" {
  count  = var.create_access_policy ? 1 : 0
  parent = "organizations/${var.organization_id}"
  title  = "Secure Data PoC Policy"

  depends_on = [google_project_service.required_apis]
}

locals {
  # Use the newly created policy ID or fallback to the provided existing one
  policy_id = var.create_access_policy ? "accessPolicies/${google_access_context_manager_access_policy.poc_policy[0].name}" : "accessPolicies/${var.access_policy_id}"
}

# Define an Access Level that permits specific user identity
resource "google_access_context_manager_access_level" "corporate_network" {
  parent      = local.policy_id
  name        = "${local.policy_id}/accessLevels/corporate_network_${random_id.suffix.hex}"
  title       = "Authorized User Identity"
  description = "Access Level to allow traffic from a specific authorized identity."

  basic {
    combining_function = "OR"

    # Condition 1: Allow the authorized identity from ANYWHERE.
    conditions {
      members = [
        "user:${var.allowed_user_identity}"
      ]
    }

    # Condition 2: Allow anyone (even anonymous browser clicks) if they are in the US or CA.
    conditions {
      regions = [
        "US",
        "CA"
      ]
    }
  }

  depends_on = [google_project_service.required_apis]
}

# The VPC Service Controls Perimeter
resource "google_access_context_manager_service_perimeter" "invisible_boundary" {
  parent         = local.policy_id
  name           = "${local.policy_id}/servicePerimeters/secure_data_perimeter_${random_id.suffix.hex}"
  title          = "Secure Data - The Invisible Boundary"
  description    = "VPC Service Controls Perimeter securing BigQuery, Cloud Storage, KMS, and DLP."
  perimeter_type = "PERIMETER_TYPE_REGULAR"

  status {
    restricted_services = [
      "bigquery.googleapis.com",
      "storage.googleapis.com",
      "cloudkms.googleapis.com",
      "dlp.googleapis.com"
    ]

    resources = [
      "projects/${data.google_project.project.number}"
    ]

    access_levels = [
      google_access_context_manager_access_level.corporate_network.name
    ]

    # Explicitly allow the authorized user identity to access all protected services from anywhere
    ingress_policies {
      ingress_from {
        identities = [
          "user:${var.allowed_user_identity}"
        ]
        sources {
          access_level = "*"
        }
      }
      ingress_to {
        resources = ["*"]
        operations {
          service_name = "*"
        }
      }
    }
  }

  # For the PoC we enforce the block to show the 403 Forbidden
  use_explicit_dry_run_spec = false

  depends_on = [
    google_project_service.required_apis,
    google_access_context_manager_access_level.corporate_network
  ]
}
