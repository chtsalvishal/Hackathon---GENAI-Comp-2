#!/usr/bin/env bash
# =============================================================================
# Intelia Warehouse — Teardown
# Removes all Terraform-managed resources from the GCP project.
# Usage: ./scripts/teardown.sh
# =============================================================================
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../terraform"
echo "Destroying all Terraform-managed resources..."
terraform destroy -auto-approve -input=false
echo "Done."
