- dashboard: cto_platform_governance
  title: "CTO — Platform Performance & Governance"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Chief Technology Officer dashboard: AI adoption trends, query performance, slot utilization, data governance compliance score"

  filters:
  - name: date_range
    title: "Date Range"
    type: date_filter
    default_value: "30 days"

  elements:

  # TILE 1: AI Adoption % Trend
  - title: "AI Query Adoption Rate (30 Days)"
    name: ai_adoption_trend
    model: intelia_warehouse
    explore: platform_metrics
    type: looker_line
    fields: [platform_metrics.metric_date, platform_metrics.avg_ai_adoption_pct, platform_metrics.total_queries, platform_metrics.total_ai_queries]
    sorts: [platform_metrics.metric_date asc]
    limit: 30
    series_colors:
      platform_metrics.avg_ai_adoption_pct: "#34A853"
    reference_lines:
    - reference_type: line
      line_value: 20
      label: "Target (20%)"
      color: "#EA4335"
    row: 0
    col: 0
    width: 12
    height: 8

  # TILE 2: Avg Query Execution Time
  - title: "Average Query Execution Time (secs)"
    name: query_execution_time
    model: intelia_warehouse
    explore: platform_metrics
    type: looker_line
    fields: [platform_metrics.metric_date, platform_metrics.avg_exec_secs, platform_metrics.total_failed_queries]
    sorts: [platform_metrics.metric_date asc]
    limit: 30
    series_colors:
      platform_metrics.avg_exec_secs: "#1A73E8"
      platform_metrics.total_failed_queries: "#EA4335"
    row: 0
    col: 12
    width: 12
    height: 8

  # TILE 3: Slot Utilization
  - title: "BigQuery Slot Utilization"
    name: slot_utilization
    model: intelia_warehouse
    explore: platform_metrics
    type: looker_column
    fields: [platform_metrics.metric_date, platform_metrics.avg_slots_used, platform_metrics.avg_gb_processed]
    sorts: [platform_metrics.metric_date asc]
    limit: 30
    series_colors:
      platform_metrics.avg_slots_used: "#FBBC04"
    row: 8
    col: 0
    width: 12
    height: 8

  # TILE 4: Governance Compliance Score (policy tag coverage %)
  - title: "Data Governance Compliance Score"
    name: governance_compliance
    model: intelia_warehouse
    explore: platform_metrics
    type: looker_single_value
    derived_table_sql: |
      SELECT
        table_schema AS dataset,
        table_name,
        COUNT(*) AS total_columns,
        COUNTIF(policy_tags IS NOT NULL) AS tagged_columns,
        ROUND(COUNTIF(policy_tags IS NOT NULL) / COUNT(*) * 100, 1) AS compliance_pct
      FROM `vishal-sandpit-474523`.INFORMATION_SCHEMA.COLUMN_FIELD_PATHS
      WHERE table_schema IN ('gold', 'silver', 'ai')
      GROUP BY 1, 2
    ;;
    fields: []
    dynamic_fields:
    - measure: overall_compliance
      label: "Overall Compliance Score"
      type: average
      sql: compliance_pct
    comparison_type: value
    comparison_reverse_colors: false
    show_comparison_label: true
    conditional_formatting:
    - type: greater_than_or_equal_to
      value: 80
      background_color: "#34A853"
      font_color: "#FFFFFF"
    - type: less_than
      value: 50
      background_color: "#EA4335"
      font_color: "#FFFFFF"
    row: 8
    col: 12
    width: 12
    height: 8
