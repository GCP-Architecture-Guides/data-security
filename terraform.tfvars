# PoC data project (BigQuery, GCS, DLP, etc.)
project_id            = "sf-data-secv1"
organization_id       = "873180247571"
folder_id             = "902476244767"
allowed_user_identity = "mgaur@manishkgaur.altostrat.com"

# Create a new org-level Access Context Manager policy for this PoC.
create_access_policy = true
access_policy_id     = ""

# Greenfield: omit vpc_sc_name_suffix so Access Level / Perimeter names match random_id (buckets/datasets).
