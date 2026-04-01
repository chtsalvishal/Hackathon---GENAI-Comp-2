import json
from datetime import datetime

# Mock data
rows = [
    {"customer_id": "C1", "customer_segment": "Gold", "churn_risk": "Low"},
    {"customer_id": "C2", "customer_segment": "Silver", "churn_risk": "High"}
]

project_id = "test-project"
batches = [rows]

def simulate_customer_batch(batch):
    # 1. Build prompt
    prompt_data = "\n".join(["ID: %s, Segment: %s, Risk: %s" % (r["customer_id"], r["customer_segment"], r["churn_risk"]) for r in batch])
    full_prompt = "Return ONLY valid JSON array:\n[{\"customer_id\":\"\",\"persona\":\"\",\"strategy\":\"\"}]\n\nCustomers:\n" + prompt_data
    
    # 2. Simulate SQL generation (Fixing the newline issue)
    sql_prompt = full_prompt.replace('"', '\\"')
    # Use triple quotes for the prompt in SQL
    query = """
    SELECT * FROM ML.GENERATE_TEXT(
      MODEL `%s.ai.gemini_pro_model`,
      (SELECT \"\"\"%s\"\"\" AS prompt),
      STRUCT(0.1 AS temperature)
    )
    """ % (project_id, sql_prompt)
    
    print("--- GENERATED SQL ---")
    print(query)
    
    # 3. Simulate Result Parsing and Timestamp Injection
    mock_ai_res = [
        {"customer_id": "C1", "persona": "Techie", "strategy": "Email"},
        {"customer_id": "C2", "persona": "Saver", "strategy": "SMS"}
    ]
    
    # Injecting timestamp
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    for item in mock_ai_res:
        item['generated_at'] = current_time
    
    print("\n--- FINAL JSON TO LOAD ---")
    print(json.dumps(mock_ai_res, indent=2))

simulate_customer_batch(rows)
