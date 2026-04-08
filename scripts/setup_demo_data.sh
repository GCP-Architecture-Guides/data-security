#!/bin/bash
set -e

# Optional: regenerate 100 random rows and re-upload / reload (after VPC-SC is on, use allowed identity).
# Baseline demo data is applied automatically by Terraform (demo_seed.tf + fixtures/) before VPC-SC.

# Run from the Terraform root (same directory as *.tf). Works with local or remote state after terraform init.
if ! terraform output -raw project_id >/dev/null 2>&1; then
    echo "Error: cannot read Terraform outputs. Run from the module root after 'terraform init' and a successful apply (or use -state=...)."
    exit 1
fi

echo "1. Generating Dummy PII Data..."
python3 scripts/generate_dummy_data.py 100

echo "2. Extracting resource names from Terraform state..."
RAW_BUCKET=$(terraform output -raw raw_ingestion_bucket)
PUBLIC_BUCKET=$(terraform output -raw public_permissive_bucket)
PROJECT_ID=$(terraform output -raw project_id)
PUBLIC_DEMO=$(terraform output -raw enable_public_exposure_demo 2>/dev/null || echo "true")

if [ -z "$RAW_BUCKET" ] || [ -z "$PUBLIC_BUCKET" ] || [ -z "$PROJECT_ID" ]; then
    echo "Error: Could not extract resource names from Terraform state."
    exit 1
fi

echo "Uploading files to Cloud Storage..."
gsutil cp sample_pii_data.txt "gs://$RAW_BUCKET/pii/"
if [ "$PUBLIC_DEMO" = "true" ]; then
    gsutil cp sample_pii_data.txt "gs://$PUBLIC_BUCKET/exposed/"
else
    echo "Skipping public bucket upload (enable_public_exposure_demo is false)."
fi

echo "Uploading files to BigQuery Secure Data Warehouse..."
# Find the dataset prefix
BQ_DATASET=$(terraform output -raw bigquery_dataset_id)

# Load from GCS (not the local file). VPC-SC often blocks local-file loads because staging
# leaves the perimeter; the raw bucket is already inside the same project/perimeter.
bq load \
    --source_format=CSV \
    --skip_leading_rows=1 \
    --replace=true \
    --project_id="$PROJECT_ID" \
    "$PROJECT_ID:$BQ_DATASET.pii_dataset" \
    "gs://$RAW_BUCKET/pii/sample_pii_data.txt"

echo ""
echo "====================================="
echo "Demo environment successfully seeded!"
echo "Raw Upload Bucket: gs://$RAW_BUCKET/pii/"
if [ "$PUBLIC_DEMO" = "true" ]; then
  echo "Exposed (Public) Bucket: gs://$PUBLIC_BUCKET/exposed/"
else
  echo "Public demo path skipped (enable_public_exposure_demo is false)."
fi
echo "BigQuery Table: $PROJECT_ID.$BQ_DATASET.pii_dataset"
echo "====================================="
