-- ============================================================
-- TEST: Optimized Customer AI Inference (Dummy Data)
-- Run this in BigQuery console to validate BEFORE deploying
-- Replace PROJECT_ID with: vishal-sandpit-474523
-- ============================================================
-- What this validates:
--   1. flatten_json_output=TRUE works with gemini_pro_model
--   2. JSON object prompt produces parseable persona + strategy
--   3. REGEXP_EXTRACT correctly captures the JSON object
--   4. Fallback COALESCE values fire on NULL outputs
-- Expected: all 5 rows return non-null persona + strategy
-- ============================================================

WITH dummy_customers AS (
  SELECT * FROM UNNEST([
    STRUCT('CUST001' AS customer_id, 'Platinum' AS customer_segment, 'Active'   AS churn_risk),
    STRUCT('CUST002',                'Gold',                          'At Risk'          ),
    STRUCT('CUST003',                'Silver',                        'Cooling'          ),
    STRUCT('CUST004',                'Bronze',                        'Churned'          ),
    STRUCT('CUST005',                'Gold',                          'Active'           )
  ])
),

prompts AS (
  SELECT
    customer_id,
    CONCAT(
      'Respond with ONLY a JSON object. No markdown, no code blocks.\n',
      'Format: {"persona":"2-sentence customer profile","strategy":"one specific retention action"}\n',
      'Segment:', customer_segment, ' Risk:', churn_risk
    ) AS prompt
  FROM dummy_customers
),

ai_output AS (
  SELECT
    customer_id,
    ml_generate_text_llm_result AS raw_text,
    ml_generate_text_status     AS status
  FROM ML.GENERATE_TEXT(
    MODEL `PROJECT_ID.ai.gemini_pro_model`,
    (SELECT customer_id, prompt FROM prompts),
    STRUCT(
      0.1  AS temperature,
      150  AS max_output_tokens,
      TRUE AS flatten_json_output
    )
  )
)

SELECT
  customer_id,
  status,
  raw_text,
  REGEXP_EXTRACT(raw_text, r'\{[\s\S]*\}')                                         AS json_payload,
  COALESCE(JSON_VALUE(REGEXP_EXTRACT(raw_text, r'\{[\s\S]*\}'), '$.persona'),
           'Valued customer')                                                        AS persona,
  COALESCE(JSON_VALUE(REGEXP_EXTRACT(raw_text, r'\{[\s\S]*\}'), '$.strategy'),
           'Monitor engagement')                                                     AS strategy,
  -- Validation checks
  CASE
    WHEN JSON_VALUE(REGEXP_EXTRACT(raw_text, r'\{[\s\S]*\}'), '$.persona')   IS NOT NULL
     AND JSON_VALUE(REGEXP_EXTRACT(raw_text, r'\{[\s\S]*\}'), '$.strategy')  IS NOT NULL
    THEN 'PASS'
    ELSE 'FAIL - check raw_text column'
  END AS test_result
FROM ai_output
ORDER BY customer_id;
