-- Gemini ML.GENERATE_TEXT usage statistics
-- Query this in BigQuery to see model usage trends
-- Used by: CTO dashboard model governance tile

SELECT
  DATE(creation_time)                                                       AS usage_date,
  COUNT(*)                                                                   AS gemini_query_count,
  ROUND(AVG(TIMESTAMP_DIFF(end_time, start_time, MILLISECOND)) / 1000, 3)   AS avg_latency_seconds,
  ROUND(MAX(TIMESTAMP_DIFF(end_time, start_time, MILLISECOND)) / 1000, 3)   AS max_latency_seconds,
  ROUND(SUM(total_bytes_billed) / POW(1024, 3), 6)                          AS total_gb_billed,
  ROUND(SUM(total_bytes_processed) / POW(1024, 3), 6)                       AS total_gb_processed,
  COUNTIF(error_result IS NOT NULL)                                          AS error_count,
  ROUND(COUNTIF(error_result IS NOT NULL) / COUNT(*) * 100, 2)              AS error_rate_pct
FROM `region-australia-southeast1`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE DATE(creation_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND state = 'DONE'
  AND job_type = 'QUERY'
  AND (
    query LIKE '%ML.GENERATE_TEXT%'
    OR query LIKE '%gemini_pro_model%'
    OR query LIKE '%customer_concierge%'
    OR query LIKE '%product_upsell%'
  )
GROUP BY 1
ORDER BY 1 DESC;
