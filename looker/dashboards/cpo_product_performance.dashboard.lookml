- dashboard: cpo_product_performance
  title: "CPO — Product Performance & AI Strategies"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Chief Product Officer dashboard: product revenue by category, Gemini upsell strategies, new vs repeat buyer analysis"

  filters:
  - name: date_range
    title: "Date Range"
    type: date_filter
    default_value: "90 days"

  - name: category
    title: "Product Category"
    type: field_filter
    explore: product_performance
    field: product_performance.category
    default_value: ""

  elements:

  # TILE 1: Revenue by Category (horizontal bar chart)
  - title: "Revenue by Product Category"
    name: revenue_by_category
    model: intelia_warehouse
    explore: product_performance
    type: looker_bar
    fields: [product_performance.category, product_performance.total_revenue, product_performance.units_sold, product_performance.unique_buyers]
    sorts: [product_performance.total_revenue desc]
    limit: 20
    color_application:
      collection_id: intelia
      palette_id: intelia-categorical
    row: 0
    col: 0
    width: 12
    height: 8

  # TILE 2: Gemini Upsell Strategies Table
  - title: "Product Upsell Strategies — Powered by Gemini AI"
    name: product_upsell_strategies
    model: intelia_warehouse
    explore: product_performance
    type: looker_grid
    fields:
    - product_performance.product_name
    - product_performance.category
    - product_performance.total_revenue
    - product_performance.unique_buyers
    - product_performance.unit_price
    - product_performance.gemini_upsell_strategy
    sorts: [product_performance.total_revenue desc]
    limit: 30
    header_background_color: "#34A853"
    header_font_color: "#FFFFFF"
    row: 8
    col: 0
    width: 24
    height: 10

  # TILE 3: New vs Repeat Buyer Ratio
  - title: "New vs Repeat Buyer Ratio by Category"
    name: new_vs_repeat_buyers
    model: intelia_warehouse
    explore: product_performance
    type: looker_column
    fields: [product_performance.category, product_performance.new_buyers, product_performance.repeat_buyers, product_performance.repeat_buyer_pct]
    sorts: [product_performance.total_revenue desc]
    limit: 15
    stacking: normal
    series_colors:
      product_performance.new_buyers: "#4285F4"
      product_performance.repeat_buyers: "#34A853"
    row: 0
    col: 12
    width: 12
    height: 8
