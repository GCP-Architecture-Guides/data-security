variable "project_id" {
  type        = string
  description = "GCP project for all PoC resources. With folder_id set, Autokey uses delegated mode (keys in this project via RESOURCE_PROJECT)."

  validation {
    condition     = length(trimspace(var.project_id)) > 0
    error_message = "project_id must be a non-empty string."
  }
}

variable "region" {
  type        = string
  description = "The default GCP region for resources."
  default     = "us-central1"
}

variable "organization_id" {
  type        = string
  description = "The GCP Organization ID for Access Context Manager and VPC Service Controls."

  validation {
    condition     = can(regex("^[0-9]+$", trimspace(var.organization_id)))
    error_message = "organization_id must be a numeric organization ID (digits only)."
  }
}

variable "create_access_policy" {
  type        = bool
  description = "Whether to create a new organization-level Access Policy for the PoC."
  default     = true
}

variable "access_policy_id" {
  type        = string
  description = "The ID of the Access Context Manager policy. Usually provided at the org level. Required if create_access_policy is false."
  default     = ""
}

variable "billing_account_id" {
  type        = string
  description = "The Billing Account ID to associate with the project."
  default     = null
}

variable "allowed_user_identity" {
  type        = string
  description = "The GCP user identity (e.g., user@example.com) allowed to bypass the VPC Service Controls perimeter from anywhere."

  validation {
    condition = (
      length(trimspace(var.allowed_user_identity)) > 0
      && can(regex("@", var.allowed_user_identity))
      && !can(regex("^user:", var.allowed_user_identity))
    )
    error_message = "allowed_user_identity must be an email (e.g. alice@example.com) without a user: prefix."
  }
}

variable "folder_id" {
  type        = string
  description = "Folder ID for google_kms_autokey_config (delegated RESOURCE_PROJECT + KeyHandles on BQ/GCS when set). Use null to skip Autokey and KeyHandles."
  default     = null
}

variable "vpc_sc_name_suffix" {
  type        = string
  description = "Optional suffix for Access Level and Service Perimeter resource names (e.g. a7aa3883). Defaults to random_id.suffix.hex so names match buckets/datasets. Set if importing existing VPC-SC objects that use a different suffix."
  default     = null
}

variable "enable_public_exposure_demo" {
  type        = bool
  description = "When true (default), relaxes iam.allowedPolicyMemberDomains for the project, grants allUsers on the demo bucket, seeds the public object, and adds a US/CA anonymous region clause to the access level. Set false for a perimeter without intentional public exposure (still keeps the demo bucket, but private)."
  default     = true
}

variable "bucket_force_destroy" {
  type        = bool
  description = "When true (default PoC), Terraform can destroy buckets that still contain objects. Set false for environments where destroy should be blocked until buckets are emptied manually."
  default     = true
}

variable "bigquery_deletion_protection" {
  type        = bool
  description = "When true, sets deletion protection on BigQuery tables pii_dataset and pii_dlp_tokenized. Datasets use delete_contents_on_destroy toggling on SecOps only; for stronger dataset retention use org policy or Terraform >= 1.7 lifecycle.prevent_destroy locally."
  default     = false
}
