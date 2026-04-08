locals {
  # Taxonomies must be located in the same region as the BigQuery dataset they secure.
  datacatalog_region = var.region
}

resource "google_data_catalog_taxonomy" "data_sensitivity" {
  provider     = google-beta
  project      = var.project_id
  region       = local.datacatalog_region
  display_name = "Data Sensitivity taxonomy"
  description  = "Taxonomy for defining data sensitivity levels in the PoC"

  activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]

  depends_on = [google_project_service.required_apis]
}

resource "google_data_catalog_policy_tag" "high_sensitivity" {
  provider     = google-beta
  taxonomy     = google_data_catalog_taxonomy.data_sensitivity.id
  display_name = "High Sensitivity"
  description  = "Highly sensitive PII data like SSN and Credit Card numbers"

  depends_on = [google_project_service.required_apis]
}

resource "google_bigquery_datapolicy_data_policy" "default_masking" {
  provider         = google-beta
  project          = var.project_id
  location         = local.datacatalog_region
  data_policy_id   = "default_masking_policy"
  policy_tag       = google_data_catalog_policy_tag.high_sensitivity.name
  data_policy_type = "DATA_MASKING_POLICY"

  data_masking_policy {
    # Masks the content fully (e.g. replacing chars with X)
    predefined_expression = "ALWAYS_NULL"
  }

  depends_on = [google_project_service.required_apis]
}

resource "google_bigquery_datapolicy_data_policy_iam_member" "masked_reader" {
  provider       = google-beta
  project        = var.project_id
  location       = local.datacatalog_region
  data_policy_id = google_bigquery_datapolicy_data_policy.default_masking.data_policy_id
  role           = "roles/bigquerydatapolicy.maskedReader"
  member         = "user:${var.allowed_user_identity}"
}

# Grant the user the right to query the table at all
resource "google_data_catalog_taxonomy_iam_member" "query_reader" {
  provider = google-beta
  taxonomy = google_data_catalog_taxonomy.data_sensitivity.id
  role     = "roles/datacatalog.categoryFineGrainedReader"
  member   = "user:${var.allowed_user_identity}"
}
