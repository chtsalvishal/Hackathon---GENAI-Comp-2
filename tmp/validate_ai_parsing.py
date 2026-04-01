"""
Validates the optimized AI inference parsing logic against real Gemini response formats.

Simulates the SQL pipeline:
  ml_generate_text_llm_result (raw_text)
      → REGEXP_EXTRACT(raw_text, r'\{[\s\S]*\}')   → json_payload
      → JSON_VALUE(json_payload, '$.persona')        → persona
      → JSON_VALUE(json_payload, '$.strategy')       → strategy

Tests 9 real-world response variants Gemini may return:
  1. Clean JSON object
  2. JSON wrapped in markdown code block
  3. JSON with extra text before/after
  4. JSON with newlines inside values
  5. Array format (old prompt format - should fail gracefully)
  6. Empty / None response
  7. Plain text (no JSON)
  8. JSON object with nested braces in values
  9. JSON with whitespace padding
"""

import re
import json
import sys

FALLBACK_PERSONA  = "Valued customer"
FALLBACK_STRATEGY = "Monitor engagement"
FALLBACK_CROSS    = "No cross-sell strategy"
FALLBACK_UPSELL   = "Basic upsell"

# BQ ML status behaviour with flatten_json_output=TRUE:
#   success → status = '' (empty string)
#   failure → status = 'error message string' (non-empty)
BQ_ML_SUCCESS_STATUS = ''


def regexp_extract(text, pattern):
    """Mimics BigQuery REGEXP_EXTRACT — returns first match group or None."""
    if text is None:
        return None
    m = re.search(pattern, text, re.DOTALL)
    return m.group(0) if m else None


def json_value(json_str, path):
    """Mimics BigQuery JSON_VALUE — extracts scalar from a JSON string."""
    if json_str is None:
        return None
    try:
        obj = json.loads(json_str)
    except (json.JSONDecodeError, ValueError):
        return None
    # Only supports simple paths like '$.key' or '$[0].key'
    keys = re.findall(r'\[(\d+)\]|\.([^.\[]+)', path.replace('$', ''))
    for match in keys:
        idx, key = match
        if isinstance(obj, list):
            obj = obj[int(idx)] if idx else None
        elif isinstance(obj, dict):
            obj = obj.get(key) if key else None
        else:
            return None
        if obj is None:
            return None
    return str(obj) if obj is not None else None


def parse_customer(raw_text):
    """Replicates the optimised customer_ai SQL parsing chain."""
    json_payload = regexp_extract(raw_text, r'\{[\s\S]*\}')
    persona  = json_value(json_payload, '$.persona')  or FALLBACK_PERSONA
    strategy = json_value(json_payload, '$.strategy') or FALLBACK_STRATEGY
    return persona, strategy


def parse_product(raw_text):
    """Replicates the optimised product_ai SQL parsing chain."""
    json_payload = regexp_extract(raw_text, r'\{[\s\S]*\}')
    cross_sell = json_value(json_payload, '$.cross_sell') or FALLBACK_CROSS
    upsell     = json_value(json_payload, '$.upsell')     or FALLBACK_UPSELL
    return cross_sell, upsell


# ─── TEST CASES ──────────────────────────────────────────────────────────────

CUSTOMER_CASES = [
    (
        "1. Clean JSON object",
        '{"persona":"High-value Platinum customer with consistent purchasing behaviour.","strategy":"Offer exclusive early access to new product launches."}',
        True,
    ),
    (
        "2. JSON in markdown code block",
        '```json\n{"persona":"Active Gold customer who shops monthly.","strategy":"Send personalised loyalty reward."}\n```',
        True,
    ),
    (
        "3. JSON with extra text before and after",
        'Here is the analysis:\n{"persona":"At-risk customer showing cooling behaviour.","strategy":"Send win-back email with 15% discount."}\nHope that helps!',
        True,
    ),
    (
        "4. JSON with newlines inside values",
        '{"persona":"Long-standing Silver customer.\\nPurchases electronics regularly.","strategy":"Upsell to Gold tier with bundled offer."}',
        True,
    ),
    (
        "5. Old array format — regex extracts inner object (robust)",
        '[{"customer_id":"C001","persona":"Active buyer","strategy":"Loyalty reward"}]',
        True,   # regex extracts inner {..} from array, persona+strategy still parsed correctly
    ),
    (
        "6. Empty / None response",
        None,
        False,
    ),
    (
        "7. Plain text — no JSON",
        "I cannot generate a persona for this customer.",
        False,
    ),
    (
        "8. JSON with braces in string values",
        '{"persona":"Customer {premium} who orders {weekly}.","strategy":"Enrol in VIP {rewards} programme."}',
        True,
    ),
    (
        "9. JSON with whitespace padding",
        '  \n  { "persona" : "Occasional buyer." , "strategy" : "Send re-engagement campaign." }  \n  ',
        True,
    ),
]

PRODUCT_CASES = [
    (
        "1. Clean JSON object",
        '{"cross_sell":"Pair with wireless mouse and keyboard","upsell":"Upgrade to Pro model with 32GB RAM"}',
        True,
    ),
    (
        "2. JSON in markdown code block",
        '```json\n{"cross_sell":"Add laptop stand and USB hub","upsell":"Consider the RTX 4090 edition"}\n```',
        True,
    ),
    (
        "3. JSON with extra surrounding text",
        'Based on the product data:\n{"cross_sell":"Running socks and water bottle","upsell":"Premium trail running shoe model"}\nEnd of response.',
        True,
    ),
    (
        "4. None response",
        None,
        False,
    ),
    (
        "5. Old prompt format with persona/strategy keys (wrong keys)",
        '{"persona":"Budget product","strategy":"Discount bundling"}',
        False,  # keys are wrong — should use fallback
    ),
]


# ─── RUN TESTS ───────────────────────────────────────────────────────────────

def run_tests():
    passed = 0
    failed = 0

    print("=" * 70)
    print("CUSTOMER AI PARSING TESTS")
    print("=" * 70)

    for name, raw_text, expect_real_output in CUSTOMER_CASES:
        persona, strategy = parse_customer(raw_text)
        is_fallback_persona  = persona  == FALLBACK_PERSONA
        is_fallback_strategy = strategy == FALLBACK_STRATEGY
        got_real = not is_fallback_persona and not is_fallback_strategy

        if got_real == expect_real_output:
            status = "PASS"
            passed += 1
        else:
            status = "FAIL"
            failed += 1

        print(f"\n[{status}] {name}")
        print(f"  persona  : {persona[:80]}{'...' if len(persona) > 80 else ''}")
        print(f"  strategy : {strategy[:80]}{'...' if len(strategy) > 80 else ''}")
        if status == "FAIL":
            print(f"  Expected real output: {expect_real_output}, Got real: {got_real}")

    print("\n" + "=" * 70)
    print("PRODUCT AI PARSING TESTS")
    print("=" * 70)

    for name, raw_text, expect_real_output in PRODUCT_CASES:
        cross_sell, upsell = parse_product(raw_text)
        is_fallback_cross  = cross_sell == FALLBACK_CROSS
        is_fallback_upsell = upsell     == FALLBACK_UPSELL
        got_real = not is_fallback_cross and not is_fallback_upsell

        if got_real == expect_real_output:
            status = "PASS"
            passed += 1
        else:
            status = "FAIL"
            failed += 1

        print(f"\n[{status}] {name}")
        print(f"  cross_sell : {cross_sell[:80]}{'...' if len(cross_sell) > 80 else ''}")
        print(f"  upsell     : {upsell[:80]}{'...' if len(upsell) > 80 else ''}")
        if status == "FAIL":
            print(f"  Expected real output: {expect_real_output}, Got real: {got_real}")

    print("\n" + "=" * 70)
    print(f"RESULT: {passed}/{passed + failed} tests passed")
    print("=" * 70)

    return failed == 0


def run_status_filter_tests():
    """
    Validates the WHERE status = '' filter behaviour.
    Simulates what BQ ML returns on success vs failure.
    """
    print("\n" + "=" * 70)
    print("STATUS FILTER TESTS  (WHERE status = '')")
    print("=" * 70)

    cases = [
        ("Success row (status='')",         '',                               True),
        ("Quota error (status=error msg)",  'RESOURCE_EXHAUSTED: quota',      False),
        ("Model error (status=error msg)",  'INVALID_ARGUMENT: prompt too long', False),
        ("Null status (should not happen)", None,                             False),
        ("Empty prompt error",              'INVALID_ARGUMENT',               False),
    ]

    passed = failed = 0
    for name, status, expect_included in cases:
        included = (status == BQ_ML_SUCCESS_STATUS)
        ok = (included == expect_included)
        result = "PASS" if ok else "FAIL"
        if ok:
            passed += 1
        else:
            failed += 1
        print(f"\n[{result}] {name}")
        print(f"  status={repr(status)} -> included={included} (expected {expect_included})")

    return passed, failed


def run_null_prompt_tests():
    """
    Validates that NULL segment/risk/product_name/category are handled.
    In BigQuery, CONCAT with NULL returns NULL (prompt becomes NULL → Gemini fails).
    Our WHERE filters guard against this before the CONCAT.
    """
    print("\n" + "=" * 70)
    print("NULL PROMPT INPUT GUARD TESTS")
    print("=" * 70)

    def build_customer_prompt(segment, churn_risk):
        """Mimics BigQuery CONCAT — returns None if any arg is None."""
        if segment is None or churn_risk is None:
            return None
        return f"Respond with ONLY a JSON object...\nSegment:{segment} Risk:{churn_risk}"

    def build_product_prompt(product_name, category):
        if product_name is None or category is None:
            return None
        return f"Respond with ONLY a JSON object...\nProduct:{product_name} Category:{category}"

    cases = [
        ("Customer: both fields present",   build_customer_prompt('Gold', 'Active'),   True),
        ("Customer: segment is NULL",        build_customer_prompt(None, 'Active'),    False),
        ("Customer: churn_risk is NULL",     build_customer_prompt('Gold', None),      False),
        ("Customer: both NULL",              build_customer_prompt(None, None),        False),
        ("Product: both fields present",     build_product_prompt('Laptop', 'Electronics'), True),
        ("Product: product_name is NULL",    build_product_prompt(None, 'Electronics'), False),
        ("Product: category is NULL",        build_product_prompt('Laptop', None),     False),
    ]

    passed = failed = 0
    for name, prompt, expect_valid in cases:
        is_valid = prompt is not None
        ok = (is_valid == expect_valid)
        result = "PASS" if ok else "FAIL"
        if ok:
            passed += 1
        else:
            failed += 1
        print(f"\n[{result}] {name}")
        print(f"  prompt={'<valid>' if is_valid else 'NULL'} (expected {'valid' if expect_valid else 'NULL/filtered'})")

    return passed, failed


if __name__ == "__main__":
    ok = run_tests()

    sp, sf = run_status_filter_tests()
    np_, nf = run_null_prompt_tests()

    total_passed = (14 if ok else 0) + sp + np_
    total_failed = (0 if ok else 14) + sf + nf

    print("\n" + "=" * 70)
    print(f"GRAND TOTAL: {total_passed}/{total_passed + total_failed} tests passed")
    print("=" * 70)

    sys.exit(0 if total_failed == 0 else 1)
