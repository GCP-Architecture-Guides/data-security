# PoC data project (BigQuery, GCS, DLP, etc.)
project_id            = "XXXXXX"
organization_id       = "XXXXXXX"
folder_id             = "XXXXXX"
allowed_user_identity = "your_emaill_address"

# Create a new org-level Access Context Manager policy for this PoC.
create_access_policy = true
access_policy_id     = ""

# Greenfield: omit vpc_sc_name_suffix so Access Level / Perimeter names match random_id (buckets/datasets).
