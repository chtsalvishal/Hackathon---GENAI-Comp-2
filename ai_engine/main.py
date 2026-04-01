import asyncio
import json
import os
import time
from google.cloud import bigquery
from google.cloud import aiplatform
import vertexai
from vertexai.generative_models import GenerativeModel, GenerationConfig

# Configure from environment variables for portability
PROJECT_ID = os.getenv("PROJECT_ID", "vishal-sandpit-474523")
LOCATION = os.getenv("LOCATION", "australia-southeast1")

vertexai.init(project=PROJECT_ID, location=LOCATION)
client = bigquery.Client(project=PROJECT_ID)

# Use System Instruction to force JSON formatting and zero-filler
SYSTEM_INSTRUCTION = (
    "You are a customer success AI. Return ONLY valid JSON array of objects. "
    "Do not include conversational text, markdown blocks like ```json, or signatures. "
    "Structure: [{\"id\": \"id_value\", \"cross_sell\": \"strategy\", \"upsell\": \"action\"}]"
)

model = GenerativeModel(
    "gemini-2.5-flash",
    system_instruction=[SYSTEM_INSTRUCTION]
)

# Concurrency control - stay under Vertex AI RPM limits
semaphore = asyncio.Semaphore(30)

async def generate_batch(batch, prompt_type="product"):
    async with semaphore:
        if prompt_type == "product":
            prompt = "Analyse these products for cross-sell/upsell:\n" + "\n".join([
                f"ID: {r['product_id']}, Name: {r['product_name']}, Category: {r['category']}, Sales: {r['total_revenue']}"
                for r in batch
            ])
        else:
             prompt = "Analyse these customers for retention:\n" + "\n".join([
                f"ID: {r['customer_id']}, Segment: {r['customer_segment']}, Risk: {r['churn_risk']}, LTV: {r['lifetime_value_band']}"
                for r in batch
            ])

        try:
            # response_mime_type forces clean JSON
            config = GenerationConfig(
                response_mime_type="application/json",
                temperature=0.1,
                max_output_tokens=2048
            )
            response = await model.generate_content_async(prompt, generation_config=config)
            return response.text
        except Exception as e:
            print(f"Error processing batch: {e}")
            return None

async def process_all_data():
    # 1. Fetch Product Data
    query = f"SELECT * FROM `{PROJECT_ID}.gold.product_metrics` WHERE total_units_sold > 0"
    rows = list(client.query(query).result())
    
    # 2. Chunking (10 rows per API call for massive speedup)
    batches = [rows[i:i + 10] for i in range(0, len(rows), 10)]
    
    tasks = [generate_batch(batch, "product") for batch in batches]
    results = await asyncio.gather(*tasks)
    
    # 3. Parsing and Flattening
    final_data = []
    for r in results:
        if r:
            try:
                # Clean up potential markdown formatting if Gemini slips up
                clean_r = r.replace("```json", "").replace("```", "").strip()
                final_data.extend(json.loads(clean_r))
            except Exception as e:
                print(f"Failed to parse JSON: {e} | Content: {r[:100]}")

    # 4. Write back to BigQuery
    if final_data:
        table_id = f"{PROJECT_ID}.ai.product_upsell_results"
        job_config = bigquery.LoadJobConfig(write_disposition="WRITE_TRUNCATE")
        load_job = client.load_table_from_json(final_data, table_id, job_config=job_config)
        load_job.result()
        print(f"Successfully wrote {len(final_data)} AI results to BigQuery.")

if __name__ == "__main__":
    asyncio.run(process_all_data())
