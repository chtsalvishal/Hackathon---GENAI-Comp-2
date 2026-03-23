#!/usr/bin/env bash
# =============================================================================
# Intelia Warehouse — Bootstrap Script
# Deploys the entire solution to a brand-new GCP project.
# Usage: ./scripts/bootstrap.sh
# Prerequisites: gcloud auth login && gcloud auth application-default login
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colours
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()     { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ---------------------------------------------------------------------------
# 1. Read config from terraform.tfvars
# ---------------------------------------------------------------------------
TFVARS="$PROJECT_ROOT/terraform/terraform.tfvars"
[[ -f "$TFVARS" ]] || error "terraform.tfvars not found at $TFVARS"

PROJECT_ID=$(grep 'project_id' "$TFVARS" | sed 's/.*= *"\(.*\)"/\1/')
REGION=$(grep 'region' "$TFVARS" | sed 's/.*= *"\(.*\)"/\1/')

log "Project : $PROJECT_ID"
log "Region  : $REGION"

# ---------------------------------------------------------------------------
# 2. Validate gcloud auth
# ---------------------------------------------------------------------------
log "Checking gcloud authentication..."
gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q @ \
  || error "No active gcloud account. Run: gcloud auth login"

gcloud config set project "$PROJECT_ID"
success "gcloud configured for $PROJECT_ID"

# ---------------------------------------------------------------------------
# 3. Terraform — init + apply
# ---------------------------------------------------------------------------
log "Initialising Terraform..."
cd "$PROJECT_ROOT/terraform"
terraform init -upgrade -input=false

log "Validating Terraform configuration..."
terraform validate

log "Applying Terraform (this may take 5-10 minutes)..."
terraform apply -auto-approve -input=false \
  -var="project_id=$PROJECT_ID" \
  -var="region=$REGION"

success "Terraform apply complete"

# Capture outputs
DATAFORM_REPO=$(terraform output -raw dataform_repository_id 2>/dev/null || echo "")
BQ_CONNECTION=$(terraform output -raw bigquery_connection_id 2>/dev/null || echo "")
log "Dataform repo : $DATAFORM_REPO"
log "BQ connection : $BQ_CONNECTION"

cd "$PROJECT_ROOT"

# ---------------------------------------------------------------------------
# 4. Create BigQuery BQML remote model
# ---------------------------------------------------------------------------
log "Creating BigQuery ML remote model for Gemini..."
bq query --project_id="$PROJECT_ID" --use_legacy_sql=false \
  "CREATE OR REPLACE MODEL \`${PROJECT_ID}.ai.gemini_pro_model\`
   REMOTE WITH CONNECTION \`${PROJECT_ID}.${REGION}.gemini-pro-connection\`
   OPTIONS (endpoint = 'gemini-1.5-pro');"
success "BQML remote model created"

# ---------------------------------------------------------------------------
# 5. Push Dataform repository code
# ---------------------------------------------------------------------------
log "Pushing Dataform definitions to GCP..."
if command -v dataform &>/dev/null; then
  cd "$PROJECT_ROOT/dataform"
  dataform init-creds bigquery --project-id="$PROJECT_ID" --location="$REGION" 2>/dev/null || true
  dataform compile
  success "Dataform compiled successfully"
  cd "$PROJECT_ROOT"
else
  warn "Dataform CLI not found — skipping local compile. Code will compile in GCP Dataform UI."
  warn "Push the dataform/ folder contents to the Dataform repository in the GCP console."
fi

# ---------------------------------------------------------------------------
# 6. Load initial core data
# ---------------------------------------------------------------------------
log "Loading initial core data..."
bash "$SCRIPT_DIR/load_initial_data.sh"
success "Initial data load complete"

# ---------------------------------------------------------------------------
# 7. Deploy Vertex AI Reasoning Engine agent
# ---------------------------------------------------------------------------
log "Deploying Vertex AI Reasoning Engine agent..."
if command -v python3 &>/dev/null; then
  cd "$PROJECT_ROOT/ai/reasoning_engine"
  pip install -r requirements.txt -q
  PROJECT_ID="$PROJECT_ID" REGION="$REGION" python3 agent.py
  success "Reasoning Engine agent deployed"
  cd "$PROJECT_ROOT"
else
  warn "Python3 not found — skipping Reasoning Engine deployment."
  warn "Run manually: cd ai/reasoning_engine && python3 agent.py"
fi

# ---------------------------------------------------------------------------
# 8. Verify key resources
# ---------------------------------------------------------------------------
log "Running verification checks..."
PASS=0; FAIL=0

check() {
  local label="$1"; local cmd="$2"
  if eval "$cmd" &>/dev/null; then
    success "  $label"
    ((PASS++))
  else
    warn "  FAIL: $label"
    ((FAIL++))
  fi
}

check "BQ dataset: bronze"     "bq show --project_id=$PROJECT_ID bronze"
check "BQ dataset: silver"     "bq show --project_id=$PROJECT_ID silver"
check "BQ dataset: gold"       "bq show --project_id=$PROJECT_ID gold"
check "BQ dataset: ai"         "bq show --project_id=$PROJECT_ID ai"
check "BQ dataset: governance" "bq show --project_id=$PROJECT_ID governance"
check "BQ connection"          "bq show --connection --project_id=$PROJECT_ID --location=$REGION gemini-pro-connection"
check "GCS bucket"             "gcloud storage buckets describe gs://${PROJECT_ID}-delta-staging"

echo ""
echo "=================================================="
echo -e "${GREEN}Bootstrap complete!${NC}  Passed: $PASS  Failed: $FAIL"
echo "=================================================="
if [[ $FAIL -gt 0 ]]; then
  warn "$FAIL check(s) failed — review above and re-run failed steps manually."
fi
echo ""
echo "Next steps:"
echo "  1. Open BigQuery console and run Dataform pipeline"
echo "  2. Access Looker at your Looker instance URL"
echo "  3. Open BigQuery Canvas: bigquery_canvas/executive_canvas.json"
echo "  4. Test Data Agent in BigQuery console → Data Agent panel"
