/**
 * governance_tags.js
 *
 * BigQuery Data Catalog policy tag resource IDs.
 * Taxonomy and tag IDs populated after `terraform apply` on 2026-03-23.
 * to create the taxonomy in australia-southeast1.
 *
 * Usage in SQLX column config:
 *   bigqueryPolicyTags: [POLICY_TAGS.PII]
 */

const TAXONOMY_BASE =
  "projects/vishal-sandpit-474523/locations/australia-southeast1/taxonomies/7638949646360194197";

const POLICY_TAGS = {
  /**
   * PII — personally identifiable information.
   * Applied to: customer_id, email, phone, first_name, last_name
   */
  PII: `${TAXONOMY_BASE}/policyTags/7825657596165317938`,

  /**
   * SENSITIVE_REVENUE — commercial / financial figures.
   * Applied to: total_amount, unit_price, cost_price, subtotal
   */
  SENSITIVE_REVENUE: `${TAXONOMY_BASE}/policyTags/4390288473413043579`,

  /**
   * INTERNAL_USE_ONLY — data not for external sharing.
   * Applied to: margin_pct, cost_price, avg_order_value
   */
  INTERNAL_USE_ONLY: `${TAXONOMY_BASE}/policyTags/1242558832035299244`
};

module.exports = { POLICY_TAGS };
