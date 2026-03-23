/**
 * schema_evolution.js
 *
 * Canonical column registry per entity, version history, and rename mappings.
 *
 * Used by silver transforms to:
 *   1. Detect columns added or removed between source batches and the canonical schema.
 *   2. Apply rename mappings before downstream processing.
 *   3. Emit entries into governance.schema_change_log when deviations are found.
 */

// ---------------------------------------------------------------------------
// Canonical schema versions per entity
// Each version lists the expected column names in order.
// ---------------------------------------------------------------------------
const SCHEMA_VERSIONS = {
  customers: {
    v1: [
      "customer_id",
      "first_name",
      "last_name",
      "email",
      "phone",
      "address",
      "city",
      "state",
      "country",
      "postcode",
      "created_date"
    ],
    v2: [
      "customer_id",
      "first_name",
      "last_name",
      "email",
      "phone",
      "address",
      "city",
      "state",
      "country",
      "postcode",
      "created_date",
      "loyalty_tier"        // new column added in v2
    ]
  },
  orders: {
    v1: [
      "order_id",
      "customer_id",
      "order_date",
      "status",
      "shipping_address",
      "shipping_city",
      "shipping_state",
      "shipping_country",
      "total_amount",
      "created_at"
    ]
  },
  order_items: {
    v1: [
      "order_item_id",
      "order_id",
      "product_id",
      "quantity",
      "unit_price",
      "discount",
      "subtotal"
    ]
  },
  products: {
    v1: [
      "product_id",
      "product_name",
      "category",
      "sub_category",
      "brand",
      "unit_price",
      "cost_price",
      "stock_quantity",
      "created_at"
    ]
  }
};

// ---------------------------------------------------------------------------
// Column rename mappings
// Keys are legacy / non-canonical names; values are the canonical target names.
// Applied during silver transformation to normalise incoming column names.
// ---------------------------------------------------------------------------
const COLUMN_RENAMES = {
  customers: {
    customer_email: "email",
    cust_id:        "customer_id",
    fname:          "first_name",
    lname:          "last_name"
  },
  orders: {
    order_total:   "total_amount",
    ship_city:     "shipping_city",
    ship_country:  "shipping_country"
  },
  order_items: {
    item_id:       "order_item_id",
    qty:           "quantity",
    price:         "unit_price",
    line_total:    "subtotal"
  },
  products: {
    price:         "unit_price",
    cost:          "cost_price",
    prod_id:       "product_id",
    prod_name:     "product_name",
    stock:         "stock_quantity"
  }
};

// ---------------------------------------------------------------------------
// Helper: resolve the latest schema version for a given entity
// ---------------------------------------------------------------------------
function latestVersion(entity) {
  const versions = Object.keys(SCHEMA_VERSIONS[entity] || {});
  if (versions.length === 0) return null;
  // Sort semantically: "v2" > "v1"
  versions.sort((a, b) => {
    const numA = parseInt(a.replace("v", ""), 10);
    const numB = parseInt(b.replace("v", ""), 10);
    return numB - numA;
  });
  return versions[0];
}

// ---------------------------------------------------------------------------
// Helper: compare an incoming column list against the canonical schema
// Returns { newColumns, removedColumns } arrays.
// ---------------------------------------------------------------------------
function diffColumns(entity, incomingColumns) {
  const version = latestVersion(entity);
  if (!version) return { newColumns: [], removedColumns: [] };

  const canonical = new Set(SCHEMA_VERSIONS[entity][version]);
  const incoming  = new Set(incomingColumns);

  const newColumns     = incomingColumns.filter(c => !canonical.has(c));
  const removedColumns = SCHEMA_VERSIONS[entity][version].filter(c => !incoming.has(c));

  return { newColumns, removedColumns };
}

// ---------------------------------------------------------------------------
// Helper: apply rename mappings to an incoming column name
// Returns the canonical name if a mapping exists, otherwise the original.
// ---------------------------------------------------------------------------
function resolveColumnName(entity, columnName) {
  const renames = COLUMN_RENAMES[entity] || {};
  return renames[columnName] || columnName;
}

module.exports = {
  SCHEMA_VERSIONS,
  COLUMN_RENAMES,
  latestVersion,
  diffColumns,
  resolveColumnName
};
