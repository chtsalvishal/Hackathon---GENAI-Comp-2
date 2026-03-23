#!/usr/bin/env bash
# =============================================================================
# Intelia Warehouse — Delta Pipeline Trigger
# Manually triggers the delta MERGE pipeline for one or all entities.
# Usage:
#   ./scripts/trigger_delta_pipeline.sh                  # all entities
#   ./scripts/trigger_delta_pipeline.sh customers        # single entity
#   ./scripts/trigger_delta_pipeline.sh --check-only     # idempotency check only
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TFVARS="$PROJECT_ROOT/terraform/terraform.tfvars"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()     { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }

PROJECT_ID=$(grep 'project_id' "$TFVARS" | sed 's/.*= *"\(.*\)"/\1/')
REGION=$(grep 'region' "$TFVARS"   | sed 's/.*= *"\(.*\)"/\1/')

ENTITY="${1:-all}"
TODAY=$(date +%Y%m%d)

# ---------------------------------------------------------------------------
# Idempotency check — skip already-completed batches
# ---------------------------------------------------------------------------
check_idempotency() {
  local entity="$1"
  local batch_id="delta_${entity}_${TODAY}"
  local result
  result=$(bq query --project_id="$PROJECT_ID" --use_legacy_sql=false \
    --format=csv --quiet \
    "SELECT COUNT(*) FROM \`${PROJECT_ID}.governance.batch_audit_log\`
     WHERE batch_id = '${batch_id}' AND status = 'COMPLETED'" 2>/dev/null | tail -1)
  [[ "$result" == "1" ]]
}

# ---------------------------------------------------------------------------
# Run MERGE for a single entity via Dataform API
# ---------------------------------------------------------------------------
run_delta() {
  local entity="$1"
  local batch_id="delta_${entity}_${TODAY}"

  if check_idempotency "$entity"; then
    warn "Batch $batch_id already completed — skipping (idempotent)"
    return
  fi

  log "Running delta MERGE for: $entity (batch: $batch_id)"

  # Log batch start
  bq query --project_id="$PROJECT_ID" --use_legacy_sql=false --quiet << EOF
INSERT INTO \`${PROJECT_ID}.governance.batch_audit_log\`
  (batch_id, file_name, entity, status, started_at, run_by)
VALUES (
  '${batch_id}',
  'gs://intelia-hackathon-files/batch_0*_${entity}_delta.csv',
  '${entity}',
  'RUNNING',
  CURRENT_TIMESTAMP(),
  '${USER:-manual-trigger}'
);
EOF

  # Trigger Dataform execution via gcloud (runs delta tag only)
  if gcloud dataform compilations create \
    --repository=intelia-warehouse \
    --region="$REGION" \
    --project="$PROJECT_ID" \
    --tag="delta" 2>/dev/null; then
    success "Dataform delta execution triggered for $entity"
  else
    warn "Could not trigger via gcloud Dataform API — ensure Dataform is connected to GitHub."
    warn "Manual: GCP Console → BigQuery → Dataform → intelia-warehouse → Start Execution (tag: delta)"
  fi
}

# ---------------------------------------------------------------------------
# Check-only mode
# ---------------------------------------------------------------------------
if [[ "${ENTITY}" == "--check-only" ]]; then
  log "Idempotency status for today ($TODAY):"
  bq query --project_id="$PROJECT_ID" --use_legacy_sql=false \
    "SELECT batch_id, entity, status, rows_processed, started_at, completed_at
     FROM \`${PROJECT_ID}.governance.batch_audit_log\`
     WHERE DATE(started_at) = CURRENT_DATE()
     ORDER BY started_at DESC"
  exit 0
fi

# ---------------------------------------------------------------------------
# Run for specified entity or all
# ---------------------------------------------------------------------------
ENTITIES=("customers" "orders" "order_items" "products")

if [[ "$ENTITY" == "all" ]]; then
  log "Running delta pipeline for ALL entities..."
  for e in "${ENTITIES[@]}"; do
    run_delta "$e"
  done
else
  # Validate entity name
  valid=false
  for e in "${ENTITIES[@]}"; do [[ "$e" == "$ENTITY" ]] && valid=true; done
  [[ "$valid" == "true" ]] || { echo "Unknown entity: $ENTITY. Valid: ${ENTITIES[*]}"; exit 1; }
  run_delta "$ENTITY"
fi

echo ""
success "Delta pipeline trigger complete."
echo "Monitor status: ./scripts/trigger_delta_pipeline.sh --check-only"
