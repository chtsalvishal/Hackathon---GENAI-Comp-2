view: products {
  sql_table_name: `vishal-sandpit-474523.gold.dim_products` ;;

  dimension: product_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.product_id ;;
    label: "Product ID"
  }

  dimension: product_name {
    type: string
    sql: ${TABLE}.product_name ;;
    label: "Product Name"
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
    description: "Gross margin percentage: (unit_price - cost_price) / unit_price"
    html: {% if value >= 50 %}<span style="color:green;font-weight:bold">{{ rendered_value }}</span>
          {% elsif value >= 25 %}<span style="color:#DAA520;font-weight:bold">{{ rendered_value }}</span>
          {% else %}<span style="color:red;font-weight:bold">{{ rendered_value }}</span>
          {% endif %} ;;
  }

  dimension: is_active {
    type: yesno
    sql: ${TABLE}.is_active ;;
    label: "Is Active?"
    description: "Whether the product is currently available for sale"
  }

  dimension: sku {
    type: string
    sql: ${TABLE}.sku ;;
    label: "SKU"
  }

  dimension: supplier {
    type: string
    sql: ${TABLE}.supplier ;;
    label: "Supplier"
  }

  dimension: weight_kg {
    type: number
    sql: ${TABLE}.weight_kg ;;
    label: "Weight (kg)"
    value_format: "0.00"
  }

  dimension: stock_quantity {
    type: number
    sql: ${TABLE}.stock_quantity ;;
    label: "Stock Quantity"
  }

  dimension: reorder_level {
    type: number
    sql: ${TABLE}.reorder_level ;;
    label: "Reorder Level"
  }

  dimension: is_low_stock {
    type: yesno
    sql: ${TABLE}.stock_quantity <= ${TABLE}.reorder_level ;;
    label: "Is Low Stock?"
    description: "TRUE when stock quantity is at or below the reorder level"
  }

  dimension_group: created {
    type: time
    timeframes: [date, month, year]
    sql: ${TABLE}.created_date ;;
    label: "Created"
    datatype: date
  }

  # ── Measures ──────────────────────────────────────────────────────────────

  measure: count {
    type: count
    label: "Product Count"
    drill_fields: [product_id, product_name, category, sub_category, brand, unit_price]
  }

  measure: active_product_count {
    type: count
    filters: [is_active: "yes"]
    label: "Active Products"
  }

  measure: avg_price {
    type: average
    sql: ${TABLE}.unit_price ;;
    label: "Avg Unit Price"
    value_format_name: usd
  }

  measure: avg_cost_price {
    type: average
    sql: ${TABLE}.cost_price ;;
    label: "Avg Cost Price"
    value_format_name: usd
  }

  measure: avg_margin_pct {
    type: average
    sql: ${TABLE}.margin_pct ;;
    label: "Avg Margin %"
    value_format: "0.0\%"
  }

  measure: max_price {
    type: max
    sql: ${TABLE}.unit_price ;;
    label: "Max Unit Price"
    value_format_name: usd
  }

  measure: min_price {
    type: min
    sql: ${TABLE}.unit_price ;;
    label: "Min Unit Price"
    value_format_name: usd
  }

  measure: total_stock_value {
    type: number
    sql: SUM(${TABLE}.unit_price * ${TABLE}.stock_quantity) ;;
    label: "Total Stock Value"
    value_format_name: usd
    description: "Current inventory value at unit price"
  }

  measure: low_stock_count {
    type: count
    filters: [is_low_stock: "yes"]
    label: "Low Stock Products"
  }

  # total_revenue is computed by joining to the orders/order_items fact
  # and is surfaced here as a reference measure for cross-explore use.
  measure: total_revenue {
    type: sum
    sql: ${TABLE}.unit_price ;;
    label: "Total Revenue (est. from price)"
    value_format_name: usd
    description: "Estimated from unit price * quantity; use product_performance explore for accurate revenue."
    hidden: yes
  }
}
