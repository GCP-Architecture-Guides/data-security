#!/bin/bash
set -e

# Execute from the root of the terraform directory where state exists
if [ ! -f "terraform.tfstate" ]; then
    echo "Error: terraform.tfstate not found. Please run this script from the directory where you ran 'terraform apply'."
    exit 1
fi

echo "1. Generating Dummy PII Data..."
python3 scripts/generate_dummy_data.py 100

echo "2. Extracting resource names from Terraform state..."
RAW_BUCKET=$(terraform output -raw raw_ingestion_bucket)
PUBLIC_BUCKET=$(terraform output -raw public_permissive_bucket)
PROJECT_ID=$(terraform output -raw project_id)

if [ -z "$RAW_BUCKET" ] || [ -z "$PUBLIC_BUCKET" ] || [ -z "$PROJECT_ID" ]; then
    echo "Error: Could not extract resource names from Terraform state."
    exit 1
fi

echo "Uploading files to Cloud Storage..."
gsutil cp sample_pii_data.txt "gs://$RAW_BUCKET/pii/"
gsutil cp sample_pii_data.txt "gs://$PUBLIC_BUCKET/exposed/"

echo "Uploading files to BigQuery Secure Data Warehouse..."
# Find the dataset prefix
BQ_DATASET=$(terraform output -raw bigquery_dataset_id)

bq load \
    --source_format=CSV \
    --skip_leading_rows=1 \
    --replace=true \
    "$PROJECT_ID:$BQ_DATASET.pii_dataset" \
    sample_pii_data.txt

echo ""
echo "====================================="
echo "Demo environment successfully seeded!"
echo "Raw Upload Bucket: gs://$RAW_BUCKET/pii/"
echo "Exposed (Public) Bucket: gs://$PUBLIC_BUCKET/exposed/"
echo "BigQuery Table: $PROJECT_ID.$BQ_DATASET.pii_dataset"
echo "====================================="
