view: customer_concierge {
  sql_table_name: `vishal-sandpit-474523.ai.customer_concierge` ;;

  dimension: customer_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.customer_id ;;
    label: "Customer ID"
  }

  dimension: customer_name {
    type: string
    sql: ${TABLE}.customer_name ;;
    label: "Customer Name"
  }

  dimension: customer_segment {
    type: string
    sql: ${TABLE}.customer_segment ;;
    label: "Segment (Raw)"
  }

  dimension: churn_risk {
    type: string
    sql: ${TABLE}.churn_risk ;;
    label: "Churn Risk (Raw)"
  }

  dimension: raw_ltv {
    type: number
    sql: ${TABLE}.raw_ltv ;;
    label: "LTV — Raw Data"
    value_format_name: usd
  }

  dimension: raw_order_count {
    type: number
    sql: ${TABLE}.raw_order_count ;;
    label: "Order Count — Raw Data"
  }

  dimension: days_since_last_purchase {
    type: number
    sql: ${TABLE}.days_since_last_purchase ;;
    label: "Days Inactive"
  }

  # THE KEY COLUMN: Gemini-generated insight
  dimension: gemini_persona_and_strategy {
    type: string
    sql: ${TABLE}.gemini_persona_and_strategy ;;
    label: "Gemini AI Insight"
    description: "Gemini-generated customer persona and retention strategy"
    html: <div style="max-width:400px;font-size:12px;line-height:1.4">{{ value }}</div> ;;
  }

  dimension: generation_status {
    type: string
    sql: ${TABLE}.generation_status ;;
    label: "AI Generation Status"
    hidden: yes
  }

  dimension_group: generated {
    type: time
    timeframes: [time, date]
    sql: ${TABLE}.generated_at ;;
    label: "AI Generated At"
    hidden: yes
  }

  measure: count {
    type: count
    label: "AI-Enriched Profiles Count"
  }

  measure: successful_generations {
    type: count
    filters: [generation_status: "success"]
    label: "Successful AI Generations"
  }

  measure: generation_success_rate {
    type: number
    sql: ${successful_generations} / NULLIF(${count}, 0) ;;
    label: "AI Generation Success Rate"
    value_format_name: percent_1
  }
}
