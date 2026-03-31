variable "project_id" {
  type        = string
  description = "The GCP Project ID where resources will be deployed. Required; set in terraform.tfvars or -var."
}

variable "region" {
  type        = string
  description = "The default GCP region for resources."
  default     = "us-central1"
}

variable "organization_id" {
  type        = string
  description = "The GCP Organization ID for Access Context Manager and VPC Service Controls."
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
}

variable "folder_id" {
  type        = string
  description = "The GCP Folder ID where KMS Autokey should be enabled (Optional). Required for CMEK Autokey."
  default     = null
}
