resource "google_bigquery_dataset" "secure_data_warehouse" {
  dataset_id    = "secure_data_warehouse_${random_id.suffix.hex}"
  friendly_name = "Secure Data Warehouse"
  description   = "Restricted Service, Sensitive Analytics Data secured by VPC-SC"
  location      = var.region

  depends_on = [google_project_service.required_apis]
}

resource "google_bigquery_table" "pii_dataset" {
  dataset_id          = google_bigquery_dataset.secure_data_warehouse.dataset_id
  table_id            = "pii_dataset"
  deletion_protection = false

  # We define the schema to explicitly attach Policy Tags for Data Masking
  schema = <<EOF
[
  {
    "name": "id",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "first_name",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "last_name",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "email",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "credit_card",
    "type": "STRING",
    "mode": "NULLABLE",
    "policyTags": {
      "names": [
        "${google_data_catalog_policy_tag.high_sensitivity.name}"
      ]
    }
  },
  {
    "name": "ssn",
    "type": "STRING",
    "mode": "NULLABLE",
    "policyTags": {
      "names": [
        "${google_data_catalog_policy_tag.high_sensitivity.name}"
      ]
    }
  }
]
EOF

  depends_on = [
    google_data_catalog_policy_tag.high_sensitivity
  ]
}
