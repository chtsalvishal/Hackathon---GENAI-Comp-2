view: product_performance {
  derived_table: {
    sql:
      SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.sub_category,
        p.brand,
        p.unit_price,
        p.cost_price,
        p.margin_pct,
        ai.gemini_upsell_strategy,
        ai.generation_status,
        SUM(oi.quantity)               AS units_sold,
        ROUND(SUM(oi.subtotal), 2)     AS total_revenue,
        COUNT(DISTINCT o.order_id)     AS order_count,
        COUNT(DISTINCT o.customer_id)  AS unique_buyers,
        COUNT(DISTINCT CASE WHEN customer_orders.order_rank > 1 THEN o.customer_id END) AS repeat_buyers,
        COUNT(DISTINCT CASE WHEN customer_orders.order_rank = 1 THEN o.customer_id END) AS new_buyers
      FROM `vishal-sandpit-474523.gold.dim_products` p
      LEFT JOIN `vishal-sandpit-474523.silver.stg_order_items` oi USING (product_id)
      LEFT JOIN `vishal-sandpit-474523.gold.fct_orders` o USING (order_id)
      LEFT JOIN `vishal-sandpit-474523.ai.product_upsell` ai USING (product_id)
      LEFT JOIN (
        SELECT customer_id, order_id,
               RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_rank
        FROM `vishal-sandpit-474523.gold.fct_orders`
      ) customer_orders USING (order_id)
      GROUP BY 1,2,3,4,5,6,7,8,9,10
    ;;
  }

  dimension: product_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.product_id ;;
    label: "Product ID"
  }

  dimension: product_name {
    type: string
    sql: ${TABLE}.product_name ;;
    label: "Product"
  }

  dimension: category {
    type: string
    sql: ${TABLE}.category ;;
    label: "Category"
  }

  dimension: sub_category {
    type: string
    sql: ${TABLE}.sub_category ;;
    label: "Sub-Category"
  }

  dimension: brand {
    type: string
    sql: ${TABLE}.brand ;;
    label: "Brand"
  }

  dimension: unit_price {
    type: number
    sql: ${TABLE}.unit_price ;;
    label: "Unit Price"
    value_format_name: usd
  }

  dimension: cost_price {
    type: number
    sql: ${TABLE}.cost_price ;;
    label: "Cost Price"
    value_format_name: usd
  }

  dimension: margin_pct {
    type: number
    sql: ${TABLE}.margin_pct ;;
    label: "Margin %"
    value_format: "0.0\%"
    html: {% if value >= 50 %}<span style="color:green;font-weight:bold">{{ rendered_value }}</span>
          {% elsif value >= 25 %}<span style="color:#DAA520;font-weight:bold">{{ rendered_value }}</span>
          {% else %}<span style="color:red;font-weight:bold">{{ rendered_value }}</span>
          {% endif %} ;;
  }

  dimension: gemini_upsell_strategy {
    type: string
    sql: ${TABLE}.gemini_upsell_strategy ;;
    label: "Gemini Upsell Strategy"
    description: "Gemini-generated cross-sell and upsell recommendation for this product"
    html: <div style="max-width:400px;font-size:12px;line-height:1.4">{{ value }}</div> ;;
  }

  dimension: generation_status {
    type: string
    sql: ${TABLE}.generation_status ;;
    label: "AI Generation Status"
    hidden: yes
  }

  # ── Measures ──────────────────────────────────────────────────────────────

  measure: total_revenue {
    type: sum
    sql: ${TABLE}.total_revenue ;;
    label: "Total Revenue"
    value_format_name: usd
    drill_fields: [product_id, product_name, category, total_revenue, units_sold]
  }

  measure: units_sold {
    type: sum
    sql: ${TABLE}.units_sold ;;
    label: "Units Sold"
  }

  measure: order_count {
    type: sum
    sql: ${TABLE}.order_count ;;
    label: "Order Count"
  }

  measure: unique_buyers {
    type: sum
    sql: ${TABLE}.unique_buyers ;;
    label: "Unique Buyers"
  }

  measure: repeat_buyers {
    type: sum
    sql: ${TABLE}.repeat_buyers ;;
    label: "Repeat Buyers"
  }

  measure: new_buyers {
    type: sum
    sql: ${TABLE}.new_buyers ;;
    label: "New Buyers"
  }

  measure: repeat_buyer_pct {
    type: number
    sql: ${repeat_buyers} / NULLIF(${unique_buyers}, 0) ;;
    label: "Repeat Buyer %"
    value_format_name: percent_1
  }

  measure: avg_unit_price {
    type: average
    sql: ${TABLE}.unit_price ;;
    label: "Avg Unit Price"
    value_format_name: usd
  }

  measure: avg_margin_pct {
    type: average
    sql: ${TABLE}.margin_pct ;;
    label: "Avg Margin %"
    value_format: "0.0\%"
  }

  measure: revenue_per_buyer {
    type: number
    sql: ${total_revenue} / NULLIF(${unique_buyers}, 0) ;;
    label: "Revenue per Buyer"
    value_format_name: usd
  }
}
