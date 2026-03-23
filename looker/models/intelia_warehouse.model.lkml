connection: "vishal_sandpit_bigquery"

include: "/looker/views/*.view.lkml"
include: "/looker/dashboards/*.dashboard.lookml"

label: "Intelia Warehouse"

explore: orders {
  label: "Orders & Revenue"
  description: "Order facts joined to customer and product dimensions"

  join: customers {
    type: left_outer
    sql_on: ${orders.customer_id} = ${customers.customer_id} ;;
    relationship: many_to_one
  }

  join: customer_concierge {
    type: left_outer
    sql_on: ${orders.customer_id} = ${customer_concierge.customer_id} ;;
    relationship: many_to_one
  }
}

explore: customers {
  label: "Customers & AI Insights"
  description: "Customer profiles with Gemini-generated insights"

  join: customer_concierge {
    type: left_outer
    sql_on: ${customers.customer_id} = ${customer_concierge.customer_id} ;;
    relationship: one_to_one
  }
}

explore: product_performance {
  label: "Product Performance"
  description: "Product metrics and Gemini upsell strategies for CPO"
}

explore: platform_metrics {
  label: "Platform & Governance"
  description: "CTO metrics: query performance, AI adoption, compliance"
}
