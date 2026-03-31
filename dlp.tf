resource "google_data_loss_prevention_inspect_template" "pii_template" {
  parent       = "projects/${var.project_id}/locations/${var.region}"
  description  = "DLP Inspect Template for PII, Email, and Credit Card"
  display_name = "Secure Data PoC PII Template"

  inspect_config {
    info_types {
      name = "EMAIL_ADDRESS"
    }
    info_types {
      name = "CREDIT_CARD_NUMBER"
    }
    info_types {
      name = "PERSON_NAME"
    }
    info_types {
      name = "PHONE_NUMBER"
    }
    info_types {
      name = "US_SOCIAL_SECURITY_NUMBER"
    }

    min_likelihood = "LIKELY"

    rule_set {
      info_types {
        name = "EMAIL_ADDRESS"
      }
      rules {
        exclusion_rule {
          dictionary {
            word_list {
              words = ["example@example.com"]
            }
          }
          matching_type = "MATCHING_TYPE_FULL_MATCH"
        }
      }
    }
  }

  depends_on = [google_project_service.required_apis]
}

# The reusable DLP Tokenization/Masking template to obscure PII
resource "google_data_loss_prevention_deidentify_template" "mask_sensitive_data" {
  parent       = "projects/${var.project_id}/locations/${var.region}"
  display_name = "Secure Data PoC De-identify Template"
  description  = "Standardized template for masking SSNs and Credit Cards."

  deidentify_config {
    info_type_transformations {
      transformations {
        info_types {
          name = "US_SOCIAL_SECURITY_NUMBER"
        }
        info_types {
          name = "CREDIT_CARD_NUMBER"
        }
        primitive_transformation {
          character_mask_config {
            masking_character = "*"
            number_to_mask    = 0 # 0 means mask everything
            reverse_order     = false
          }
        }
      }
    }
  }

  depends_on = [google_project_service.required_apis]
}
