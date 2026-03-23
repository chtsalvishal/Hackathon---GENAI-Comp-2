#!/usr/bin/env bash
# =============================================================================
# Intelia Warehouse — Initial Core Data Load
# Creates Bronze external tables pointing to the core CSV files in GCS.
# This is a one-time operation for project setup.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TFVARS="$PROJECT_ROOT/terraform/terraform.tfvars"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
log()     { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }

PROJECT_ID=$(grep 'project_id' "$TFVARS" | sed 's/.*= *"\(.*\)"/\1/')
REGION=$(grep 'region' "$TFVARS"   | sed 's/.*= *"\(.*\)"/\1/')
SOURCE_BUCKET="gs://intelia-hackathon-files"

log "Creating Bronze external tables in project: $PROJECT_ID"

# ---------------------------------------------------------------------------
# Customers external table
# ---------------------------------------------------------------------------
log "Creating bronze.ext_customers..."
bq query --project_id="$PROJECT_ID" --use_legacy_sql=false --location="$REGION" << 'EOF'
CREATE OR REPLACE EXTERNAL TABLE `bronze.ext_customers` (
  customer_id  STRING,
  first_name   STRING,
  last_name    STRING,
  email        STRING,
  phone        STRING,
  address      STRING,
  city         STRING,
  state        STRING,
  country      STRING,
  postcode     STRING,
  created_date STRING
)
OPTIONS (
  format              = 'CSV',
  uris                = ['gs://intelia-hackathon-files/customers.csv',
                         'gs://intelia-hackathon-files/batch_0*_customers_delta.csv'],
  skip_leading_rows   = 1,
  allow_quoted_newlines = true,
  allow_jagged_rows   = true
);
EOF
success "bronze.ext_customers created"

# ---------------------------------------------------------------------------
# Orders external table
# ---------------------------------------------------------------------------
log "Creating bronze.ext_orders..."
bq query --project_id="$PROJECT_ID" --use_legacy_sql=false --location="$REGION" << 'EOF'
CREATE OR REPLACE EXTERNAL TABLE `bronze.ext_orders` (
  order_id          STRING,
  customer_id       STRING,
  order_date        STRING,
  status            STRING,
  shipping_address  STRING,
  shipping_city     STRING,
  shipping_state    STRING,
  shipping_country  STRING,
  total_amount      STRING,
  created_at        STRING
)
OPTIONS (
  format              = 'CSV',
  uris                = ['gs://intelia-hackathon-files/orders.csv',
                         'gs://intelia-hackathon-files/batch_0*_orders_delta.csv'],
  skip_leading_rows   = 1,
  allow_quoted_newlines = true,
  allow_jagged_rows   = true
);
EOF
success "bronze.ext_orders created"

# ---------------------------------------------------------------------------
# Order items external table
# ---------------------------------------------------------------------------
log "Creating bronze.ext_order_items..."
bq query --project_id="$PROJECT_ID" --use_legacy_sql=false --location="$REGION" << 'EOF'
CREATE OR REPLACE EXTERNAL TABLE `bronze.ext_order_items` (
  order_item_id  STRING,
  order_id       STRING,
  product_id     STRING,
  quantity       STRING,
  unit_price     STRING,
  discount       STRING,
  subtotal       STRING
)
OPTIONS (
  format              = 'CSV',
  uris                = ['gs://intelia-hackathon-files/order_items.csv',
                         'gs://intelia-hackathon-files/batch_0*_order_items_delta.csv'],
  skip_leading_rows   = 1,
  allow_quoted_newlines = true,
  allow_jagged_rows   = true
);
EOF
success "bronze.ext_order_items created"

# ---------------------------------------------------------------------------
# Products external table
# ---------------------------------------------------------------------------
log "Creating bronze.ext_products..."
bq query --project_id="$PROJECT_ID" --use_legacy_sql=false --location="$REGION" << 'EOF'
CREATE OR REPLACE EXTERNAL TABLE `bronze.ext_products` (
  product_id      STRING,
  product_name    STRING,
  category        STRING,
  sub_category    STRING,
  brand           STRING,
  unit_price      STRING,
  cost_price      STRING,
  stock_quantity  STRING,
  created_at      STRING
)
OPTIONS (
  format              = 'CSV',
  uris                = ['gs://intelia-hackathon-files/products.csv',
                         'gs://intelia-hackathon-files/batch_0*_products_delta.csv'],
  skip_leading_rows   = 1,
  allow_quoted_newlines = true,
  allow_jagged_rows   = true
);
EOF
success "bronze.ext_products created"

# ---------------------------------------------------------------------------
# Create governance.batch_audit_log table
# ---------------------------------------------------------------------------
log "Creating governance.batch_audit_log..."
bq query --project_id="$PROJECT_ID" --use_legacy_sql=false --location="$REGION" << 'EOF'
CREATE TABLE IF NOT EXISTS `governance.batch_audit_log` (
  batch_id        STRING NOT NULL,
  file_name       STRING NOT NULL,
  entity          STRING NOT NULL,
  status          STRING NOT NULL,
  rows_processed  INT64,
  rows_merged     INT64,
  rows_inserted   INT64,
  error_message   STRING,
  started_at      TIMESTAMP,
  completed_at    TIMESTAMP,
  run_by          STRING
)
PARTITION BY DATE(started_at)
CLUSTER BY entity, status;
EOF
success "governance.batch_audit_log created"

echo ""
success "Initial data load complete. Run Dataform Silver + Gold pipeline next."
echo "  In GCP console: BigQuery → Dataform → intelia-warehouse → Start Execution"
