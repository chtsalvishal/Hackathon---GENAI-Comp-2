- dashboard: cco_revenue_retention
  title: "CCO — Revenue & Customer Retention"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Chief Customer Officer dashboard: revenue vs target, AI-enriched customer profiles, 12-month cohort retention"

  filters:
  - name: date_range
    title: "Date Range"
    type: date_filter
    default_value: "12 months"

  - name: customer_segment
    title: "Customer Segment"
    type: field_filter
    explore: customers
    field: customers.customer_segment
    default_value: ""

  - name: country
    title: "Country"
    type: field_filter
    explore: customers
    field: customers.country
    default_value: ""

  elements:

  # TILE 1: Gross Revenue vs Target (monthly bar chart)
  - title: "Gross Revenue vs Target (Monthly)"
    name: gross_revenue_vs_target
    model: intelia_warehouse
    explore: orders
    type: looker_column
    fields: [orders.order_date_month, orders.total_revenue]
    fill_fields: [orders.order_date_month]
    sorts: [orders.order_date_month asc]
    limit: 12
    dynamic_fields:
    - measure: monthly_target
      label: "Monthly Target"
      type: number
      sql: 500000
    color_application:
      collection_id: intelia
      palette_id: intelia-main
    series_colors:
      orders.total_revenue: "#1A73E8"
      monthly_target: "#EA4335"
    reference_lines:
    - reference_type: line
      line_value: 500000
      label: "Target"
      color: "#EA4335"
    row: 0
    col: 0
    width: 24
    height: 8

  # TILE 2: Customer Profiles — Raw Data + Gemini Insights (side-by-side table)
  - title: "Customer Profiles — Raw Data & Gemini AI Insights"
    name: customer_profiles_gemini
    model: intelia_warehouse
    explore: customers
    type: looker_grid
    fields:
    - customers.customer_name
    - customers.customer_segment
    - customers.churn_risk
    - customer_concierge.raw_ltv
    - customer_concierge.raw_order_count
    - customers.days_since_last_purchase
    - customer_concierge.gemini_persona_and_strategy
    sorts: [customer_concierge.raw_ltv desc]
    limit: 50
    column_order:
    - customers.customer_name
    - customers.customer_segment
    - customers.churn_risk
    - customer_concierge.raw_ltv
    - customer_concierge.raw_order_count
    - customers.days_since_last_purchase
    - customer_concierge.gemini_persona_and_strategy
    header_background_color: "#1A73E8"
    header_font_color: "#FFFFFF"
    conditional_column_formatting:
    - column: customers.churn_risk
      palette:
        positive_color: "#4CAF50"
        negative_color: "#F44336"
    row: 8
    col: 0
    width: 24
    height: 10

  # TILE 3: 12-Month Cohort Retention Heatmap
  - title: "12-Month Customer Cohort Retention"
    name: cohort_retention
    model: intelia_warehouse
    explore: orders
    type: looker_grid
    fields: [orders.order_date_month, customers.created_month]
    pivots: [orders.order_date_month]
    sorts: [customers.created_month asc]
    dynamic_fields:
    - measure: retention_rate
      label: "Retention Rate"
      type: number
      sql: COUNT(DISTINCT ${orders.customer_id}) / NULLIF(MAX(COUNT(DISTINCT ${orders.customer_id})) OVER (PARTITION BY ${customers.created_month}), 0)
    limit: 12
    row: 18
    col: 0
    width: 24
    height: 10
