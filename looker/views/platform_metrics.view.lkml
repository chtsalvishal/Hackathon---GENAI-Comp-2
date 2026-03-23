view: platform_metrics {
  derived_table: {
    sql:
      SELECT
        DATE(creation_time)   AS metric_date,
        COUNT(*)              AS total_queries,
        COUNTIF(query LIKE '%ai.%' OR query LIKE '%ML.GENERATE_TEXT%' OR query LIKE '%gemini%') AS ai_queries,
        ROUND(
          COUNTIF(query LIKE '%ai.%' OR query LIKE '%ML.GENERATE_TEXT%' OR query LIKE '%gemini%')
          / NULLIF(COUNT(*), 0) * 100, 1
        )                     AS ai_adoption_pct,
        ROUND(AVG(TIMESTAMP_DIFF(end_time, start_time, MILLISECOND)) / 1000, 2) AS avg_exec_secs,
        ROUND(
          AVG(total_slot_ms / NULLIF(TIMESTAMP_DIFF(end_time, start_time, MILLISECOND), 0)), 1
        )                     AS avg_slots_used,
        ROUND(AVG(total_bytes_processed) / POW(1024, 3), 3) AS avg_gb_processed,
        COUNTIF(error_result IS NOT NULL) AS failed_queries
      FROM `region-australia-southeast1`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
      WHERE state = 'DONE'
        AND job_type = 'QUERY'
        AND DATE(creation_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
      GROUP BY 1
      ORDER BY 1 DESC
    ;;
  }

  dimension_group: metric {
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.metric_date ;;
    label: "Metric"
    datatype: date
  }

  dimension: ai_adoption_pct {
    type: number
    sql: ${TABLE}.ai_adoption_pct ;;
    label: "AI Adoption % (Raw)"
  }

  measure: avg_ai_adoption_pct {
    type: average
    sql: ${TABLE}.ai_adoption_pct ;;
    label: "Avg AI Adoption %"
    value_format: "0.0\%"
  }

  measure: total_queries {
    type: sum
    sql: ${TABLE}.total_queries ;;
    label: "Total Queries"
  }

  measure: total_ai_queries {
    type: sum
    sql: ${TABLE}.ai_queries ;;
    label: "AI-Enriched Queries"
  }

  measure: avg_exec_secs {
    type: average
    sql: ${TABLE}.avg_exec_secs ;;
    label: "Avg Query Execution (secs)"
    value_format: "0.00"
  }

  measure: avg_slots_used {
    type: average
    sql: ${TABLE}.avg_slots_used ;;
    label: "Avg Slots Used"
    value_format: "0.0"
  }

  measure: avg_gb_processed {
    type: average
    sql: ${TABLE}.avg_gb_processed ;;
    label: "Avg GB Processed"
    value_format: "0.000"
  }

  measure: total_failed_queries {
    type: sum
    sql: ${TABLE}.failed_queries ;;
    label: "Failed Queries"
  }
}
