-- ============================================================
-- TEST: Optimized Product AI Inference (Dummy Data)
-- Run this in BigQuery console to validate BEFORE deploying
-- Replace PROJECT_ID with: vishal-sandpit-474523
-- ============================================================
-- What this validates:
--   1. flatten_json_output=TRUE works for product prompts
--   2. JSON object prompt produces parseable cross_sell + upsell
--   3. REGEXP_EXTRACT correctly captures the JSON object
--   4. Fallback COALESCE values fire on NULL outputs
-- Expected: all 5 rows return non-null cross_sell + upsell
-- ============================================================

WITH dummy_products AS (
  SELECT * FROM UNNEST([
    STRUCT('PROD001' AS product_id, 'Gaming Laptop'       AS product_name, 'Electronics'        AS category),
    STRUCT('PROD002',               'Running Shoes',                        'Sports'                        ),
    STRUCT('PROD003',               'Coffee Maker',                         'Kitchen Appliances'            ),
    STRUCT('PROD004',               'Yoga Mat',                             'Sports'                        ),
    STRUCT('PROD005',               'Wireless Headphones',                  'Electronics'                   )
  ])
),

prompts AS (
  SELECT
    product_id,
    CONCAT(
      'Respond with ONLY a JSON object. No markdown, no code blocks.\n',
      'Format: {"cross_sell":"complementary product recommendation","upsell":"premium version or accessory suggestion"}\n',
      'Product:', product_name, ' Category:', category
    ) AS prompt
  FROM dummy_products
),

ai_output AS (
  SELECT
    product_id,
    ml_generate_text_llm_result AS raw_text,
    ml_generate_text_status     AS status
  FROM ML.GENERATE_TEXT(
    MODEL `PROJECT_ID.ai.gemini_pro_model`,
    (SELECT product_id, prompt FROM prompts),
    STRUCT(
      0.1  AS temperature,
      150  AS max_output_tokens,
      TRUE AS flatten_json_output
    )
  )
)

SELECT
  product_id,
  status,
  raw_text,
  REGEXP_EXTRACT(raw_text, r'\{[\s\S]*\}')                                           AS json_payload,
  COALESCE(JSON_VALUE(REGEXP_EXTRACT(raw_text, r'\{[\s\S]*\}'), '$.cross_sell'),
           'No cross-sell strategy')                                                  AS cross_sell,
  COALESCE(JSON_VALUE(REGEXP_EXTRACT(raw_text, r'\{[\s\S]*\}'), '$.upsell'),
           'Basic upsell')                                                            AS upsell,
  -- Validation checks
  CASE
    WHEN JSON_VALUE(REGEXP_EXTRACT(raw_text, r'\{[\s\S]*\}'), '$.cross_sell') IS NOT NULL
     AND JSON_VALUE(REGEXP_EXTRACT(raw_text, r'\{[\s\S]*\}'), '$.upsell')     IS NOT NULL
    THEN 'PASS'
    ELSE 'FAIL - check raw_text column'
  END AS test_result
FROM ai_output
ORDER BY product_id;
