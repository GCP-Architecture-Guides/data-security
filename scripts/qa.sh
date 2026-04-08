#!/bin/bash
# Local QA: formatting, Terraform validation, optional shellcheck.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== terraform fmt (check) =="
terraform fmt -check -recursive
echo "OK"

echo "== terraform init =="
terraform init -input=false -no-color
echo "OK"

echo "== terraform validate =="
terraform validate -no-color
echo "OK"

if command -v shellcheck >/dev/null 2>&1; then
  echo "== shellcheck =="
  shellcheck scripts/setup_demo_data.sh scripts/qa.sh
  echo "OK"
else
  echo "== shellcheck (skipped; install shellcheck for script lint) =="
fi

echo "All QA checks passed."
