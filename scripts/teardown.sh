#!/usr/bin/env bash
# =============================================================================
# Intelia Warehouse — Teardown Script
# Removes ALL deployed resources from the GCP project.
# WARNING: This is destructive and irreversible. Use only for demo/dev cleanup.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TFVARS="$PROJECT_ROOT/terraform/terraform.tfvars"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()     { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

PROJECT_ID=$(grep 'project_id' "$TFVARS" | sed 's/.*= *"\(.*\)"/\1/')

# Safety confirmation
echo -e "${RED}===========================================================${NC}"
echo -e "${RED}  WARNING: This will DESTROY all resources in: $PROJECT_ID  ${NC}"
echo -e "${RED}  BigQuery datasets, GCS buckets, IAM, Dataform repo, etc.  ${NC}"
echo -e "${RED}===========================================================${NC}"
echo ""
read -r -p "Type the project ID to confirm destruction: " CONFIRM
[[ "$CONFIRM" == "$PROJECT_ID" ]] || error "Project ID mismatch. Teardown cancelled."

echo ""
read -r -p "Are you ABSOLUTELY SURE? (yes/no): " SURE
[[ "$SURE" == "yes" ]] || error "Teardown cancelled."

# ---------------------------------------------------------------------------
# 1. Terraform destroy
# ---------------------------------------------------------------------------
log "Running terraform destroy..."
cd "$PROJECT_ROOT/terraform"
terraform destroy -auto-approve -input=false || warn "Terraform destroy encountered errors — continuing manual cleanup."
cd "$PROJECT_ROOT"
success "Terraform destroy complete"

# ---------------------------------------------------------------------------
# 2. Delete BigQuery datasets (in case Terraform missed any)
# ---------------------------------------------------------------------------
log "Deleting BigQuery datasets..."
for dataset in bronze silver gold ai governance; do
  if bq show --project_id="$PROJECT_ID" "$dataset" &>/dev/null; then
    bq rm -r -f --project_id="$PROJECT_ID" "$dataset"
    success "Deleted dataset: $dataset"
  fi
done

# ---------------------------------------------------------------------------
# 3. Delete GCS staging bucket
# ---------------------------------------------------------------------------
log "Deleting GCS staging bucket..."
BUCKET="gs://${PROJECT_ID}-delta-staging"
if gcloud storage buckets describe "$BUCKET" &>/dev/null; then
  gcloud storage rm -r "$BUCKET" --quiet
  success "Deleted bucket: $BUCKET"
fi

# ---------------------------------------------------------------------------
# 4. Delete Dataform repository
# ---------------------------------------------------------------------------
log "Deleting Dataform repository..."
REGION=$(grep 'region' "$TFVARS" | sed 's/.*= *"\(.*\)"/\1/')
gcloud dataform repositories delete intelia-warehouse \
  --region="$REGION" --project="$PROJECT_ID" --quiet 2>/dev/null \
  && success "Deleted Dataform repository" || warn "Dataform repo already deleted or not found"

echo ""
success "Teardown complete for project: $PROJECT_ID"
warn "APIs remain enabled — disable them manually in GCP Console if needed."
