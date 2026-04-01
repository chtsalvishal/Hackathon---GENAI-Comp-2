# Looker Studio: Stakeholder Insight Dashboard & Conversational Agent Build Guide
**Project**: `vishal-sandpit-474523`  
**Data Sources**: `gold.rpt_cco_dashboard`, `gold.rpt_cpo_dashboard`, `governance.rpt_cto_dashboard`

This guide shows you how to bring your **Master Plan V2** stakeholder matrix to life visually in Looker Studio, and uniquely—how to embed your Vertex AI Conversational Agent directly into the reporting canvas so stakeholders can chat with their data natively.

---

## Part 1: Connect your BigQuery Data Models

1. Open [Looker Studio](https://lookerstudio.google.com/) and create a **Blank Report**.
2. When prompted to **Add data to report**, select **BigQuery**.
3. Authorise Looker Studio if needed, then navigate to your project:
   - `vishal-sandpit-474523` > `gold` > `rpt_cco_dashboard`
   - Click **Add**.
4. To add the other two models (CPO & CTO), click **Resource > Manage added data sources > Add a Data Source** and repeat for:
   - `gold.rpt_cpo_dashboard`
   - `governance.rpt_cto_dashboard`

---

## Part 2: Build the Stakeholder Pages (The Matrix)

Use the "Add Page" menu on the left to create three distinct views for your C-Suite.

### Page 1: CCO (Chief Customer Officer)
**Goal:** Revenue performance, customer profiles, retention, churn risk.
**Data Source:** `rpt_cco_dashboard`

- **Time Series Chart (Revenue vs Target)**: 
  - Dimension: `order_date_month`
  - Metrics: `gross_revenue`, `monthly_target`
  - *Styling*: Make target a distinct red line against the revenue bars.
- **Table with Heatmap (Gemini Customer Insights)**:
  - Dimensions: `customer_name`
  - Metrics: `total_lifetime_value`, `order_count`, `churn_risk` 
  - Add text dimension: `gemini_persona_and_strategy`
  - *Magic*: Executives can now read exactly *why* a customer is churning based on AI analysis.
- **Pivot Table (12-Month Cohort Retention)**:
  - Row Dimension: `cohort_month`
  - Column Dimension: `months_since_first_purchase`
  - Metric: `retention_rate_pct` (Set styling to colour scale/heatmap).

### Page 2: CPO (Chief Product Officer)
**Goal:** Category growth, upsell strategies, repeat buyer mix.
**Data Source:** `rpt_cpo_dashboard`

- **Pie/Donut Chart (Revenue Share)**:
  - Dimension: `category`
  - Metric: `revenue_share_pct` (Sum or Average).
- **Bar Chart (New vs Repeat Buyer Ratio)**:
  - Dimension: `product_name`
  - Metrics: `new_buyer_orders`, `repeat_buyer_orders`
  - *Styling*: Use stacked bars to easily see the mix.
- **Table (Gemini Upsell Strategies)**:
  - Dimensions: `product_name`, `category`
  - Metric: `total_revenue`, `gemini_upsell_strategy`
  - *Magic*: Clear instructions provided by AI on exactly which related items to cross-sell.

### Page 3: CTO (Chief Technology Officer)
**Goal:** Platform health, AI adoption, governance, Gemini cost proxy.
**Data Source:** `rpt_cto_dashboard`

- **Scorecard (Governance Compliance Score)**:
  - Metric: `compliance_pct`
  - Add conditional formatting: if < 90%, turn red.
- **Line Chart (AI Adoption & Pipeline Health)**:
  - Dimension: `query_date`
  - Metrics: `ai_adoption_pct`, `avg_slots_used`
- **Table (Gemini Cost Proxy)**:
  - Dimension: `day`
  - Metrics: `ml_generate_text_calls`, `total_gb_billed`

---

## Part 3: Embed the Conversational Vertex AI Agent!

This is the key to creating a truly "Agentic" dashboard. Instead of making stakeholders switch tabs to ask questions, we will embed the Vertex Agent right next to the charts!

1. **Deploy your Agent**: In the GCP Console, go to **Vertex AI > Agent Builder**. Ensure your Data Agent or custom Agent is published. If you exported it to a Cloud Run hosted web app or a Dialogflow Messenger integration URL, copy that public URL.
2. **Add to Looker Studio**:
   - Go to any Page (e.g. create a 4th "Agent Chat" page, or put it on a sidebar on the CCO page).
   - In the top Looker Studio toolbar, click **Add a control > URL embed** (the `</>` icon).
   - Draw a tall, chat-window sized box on your canvas.
3. **Configure the Embed**:
   - In the right-hand properties panel under **DATA**, paste your Vertex AI Agent URL into the **External Content URL** field.
   - Looker Studio will render the interactive chat window directly inline.
4. **The Experience**:
   - Your executives can look at the "12-Month Cohort Retention" chart on the left, click into the chat box on the right, and type: *"Which segment of users churned the most in July, and what was their average lifetime value?"*
   - The Agent will hit its BigQuery tools via your [bq_tool_handler](file:///c:/Users/VishalPattabiraman/OneDrive%20-%20INTELIA%20PTY%20LTD/Documents/GenAI2/vertex_agent/bq_tool_handler/main.py#83-122), formulate the SQL, run it, and answer them **immediately**, inside the dashboard!

> [!TIP]
> **Aesthetic Polish**: Give your Data and Agent the "wow factor". In Looker Studio, go to **Theme and Layout**. Select a dark, sleek theme (like "Constellation"). Use rounded corners on your charts, and enable subtle shadows under the Agent URL embed box. Do not use generic Google colours; use rich, branded HSL colour palettes.
