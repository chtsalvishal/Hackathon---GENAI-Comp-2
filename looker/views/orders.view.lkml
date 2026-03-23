view: orders {
  sql_table_name: `vishal-sandpit-474523.gold.fct_orders` ;;

  dimension: order_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.order_id ;;
    label: "Order ID"
  }

  dimension: customer_id {
    type: string
    sql: ${TABLE}.customer_id ;;
    label: "Customer ID"
    tags: ["pii"]
  }

  dimension_group: order_date {
    type: time
    timeframes: [date, week, month, quarter, year]
    sql: ${TABLE}.order_date ;;
    label: "Order Date"
    datatype: date
  }

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
    label: "Order Status"
    html: {% if value == 'Cancelled' %}<span style="color:red;font-weight:bold">{{ value }}</span>
          {% elsif value == 'Returned' %}<span style="color:orange;font-weight:bold">{{ value }}</span>
          {% elsif value == 'Completed' %}<span style="color:green;font-weight:bold">{{ value }}</span>
          {% elsif value == 'Processing' %}<span style="color:#1A73E8">{{ value }}</span>
          {% elsif value == 'Shipped' %}<span style="color:#34A853">{{ value }}</span>
          {% else %}<span>{{ value }}</span>
          {% endif %} ;;
  }

  dimension: total_amount {
    type: number
    sql: ${TABLE}.total_amount ;;
    label: "Order Total"
    value_format_name: usd
  }

  dimension: shipping_country {
    type: string
    sql: ${TABLE}.shipping_country ;;
    label: "Shipping Country"
    map_layer_name: countries
  }

  dimension: is_first_order {
    type: yesno
    sql: ${TABLE}.is_first_order ;;
    label: "Is First Order?"
    description: "TRUE when this is the customer's first-ever order"
  }

  dimension: shipping_city {
    type: string
    sql: ${TABLE}.shipping_city ;;
    label: "Shipping City"
  }

  dimension: payment_method {
    type: string
    sql: ${TABLE}.payment_method ;;
    label: "Payment Method"
  }

  dimension: discount_amount {
    type: number
    sql: ${TABLE}.discount_amount ;;
    label: "Discount Amount"
    value_format_name: usd
  }

  dimension: item_count {
    type: number
    sql: ${TABLE}.item_count ;;
    label: "Items in Order"
  }

  # ── Measures ──────────────────────────────────────────────────────────────

  measure: count {
    type: count
    label: "Order Count"
    drill_fields: [order_id, customer_id, order_date_date, status, total_amount]
  }

  measure: total_revenue {
    type: sum
    sql: ${TABLE}.total_amount ;;
    label: "Total Revenue"
    value_format_name: usd
    drill_fields: [order_id, customer_id, order_date_date, status, total_amount]
  }

  measure: avg_order_value {
    type: average
    sql: ${TABLE}.total_amount ;;
    label: "Avg Order Value"
    value_format_name: usd
  }

  measure: completed_orders {
    type: count
    filters: [status: "Completed"]
    label: "Completed Orders"
  }

  measure: cancelled_orders {
    type: count
    filters: [status: "Cancelled"]
    label: "Cancelled Orders"
  }

  measure: returned_orders {
    type: count
    filters: [status: "Returned"]
    label: "Returned Orders"
  }

  measure: processing_orders {
    type: count
    filters: [status: "Processing"]
    label: "Processing Orders"
  }

  measure: shipped_orders {
    type: count
    filters: [status: "Shipped"]
    label: "Shipped Orders"
  }

  measure: cancellation_rate {
    type: number
    sql: ${cancelled_orders} / NULLIF(${count}, 0) ;;
    label: "Cancellation Rate"
    value_format_name: percent_1
  }

  measure: return_rate {
    type: number
    sql: ${returned_orders} / NULLIF(${count}, 0) ;;
    label: "Return Rate"
    value_format_name: percent_1
  }

  measure: first_order_count {
    type: count
    filters: [is_first_order: "yes"]
    label: "First Orders (New Customers)"
  }

  measure: total_discount_given {
    type: sum
    sql: ${TABLE}.discount_amount ;;
    label: "Total Discounts Given"
    value_format_name: usd
  }

  measure: unique_customers {
    type: count_distinct
    sql: ${TABLE}.customer_id ;;
    label: "Unique Customers"
  }
}
