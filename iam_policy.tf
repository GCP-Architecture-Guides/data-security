# To demonstrate the vulnerability, we need to temporarily disable the Domain Restricted Sharing policy.
# Otherwise, we cannot grant `allUsers` access to the bucket.

resource "google_project_organization_policy" "domain_restricted_sharing" {
  project    = var.project_id
  constraint = "constraints/iam.allowedPolicyMemberDomains"

  list_policy {
    allow {
      all = true
    }
  }

  depends_on = [google_project_service.required_apis]
}
