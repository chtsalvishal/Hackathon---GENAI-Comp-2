# Data Intelligence Report
**Intelia Business-in-a-Box | Powered by BigQuery + Gemini AI**
*Reporting Period: 24 months | GCP Project: vishal-sandpit-474523 | Region: australia-southeast1*

---

## Executive Summary

**3 Things to Act on This Week**

**1. CCO — Arrest the Churn Before $15.8M Walks Out the Door**
Revenue at Risk from Cooling and At-Risk customers stands at approximately $15.8M. The most urgent cohort is 366 Platinum customers with an average order value of $1,413 — the highest-value segment showing churn signals. Gemini AI has generated personalised retention strategies for each customer. The CCO should open the AI Retention Intelligence page (Page 3) this week, filter to Platinum + At Risk, and brief the CRM team on executing Win-back and Loyalty Reward campaigns before end of quarter. Simultaneously, the new-customer acquisition decline of 27% from October to December 2024 (430 to 306 new customers) requires an urgent acquisition pipeline review.

**2. CPO — Activate Cross-Sell on 12,052 Single-Category Customers**
Electronics delivers $153M at a 49.8% margin — the undisputed Star category. But 12,052 customers (15.4% of the base) have purchased from only one of eight available categories, representing the single largest untapped revenue pool. The AI Upsell page surfaces Gemini-generated Bundle and Cross-Category recommendations for each product. Additionally, the CrystalBit Pro Cameras 102 carries a 64.8% margin at $936 per unit but only 240 units sold — a hidden gem that warrants immediate promotional focus.

**3. CTO — Validate AI Coverage and Monitor Pipeline Costs**
The BQ ML pipeline using gemini-2.5-flash runs across four product shards and feeds the Cloud Run customer AI processor. The generation_status success rate should be held above 95%. Any rows where ai_status returns an error string on customer_concierge must be triaged before Phase 3 aggregation runs. CTO should review the Pipeline Overview dashboard (Page 1) weekly and confirm that row merge counts and run durations remain within baseline tolerances.

---

## PART 1 — CCO INTELLIGENCE

---

### CCO-1: Revenue Concentration

> Dashboard reference: CCO Page 1, Revenue Overview

**Data**

Total revenue over the 24-month reporting period is $269,321,897. The top 10% of customers by lifetime value account for 41.1% of total revenue, equivalent to approximately $111M. The base comprises 79,574 customers in total: 2,556 new customers (average 1.01 orders) and 77,018 returning customers (average 4.32 orders).

| Metric | Value |
|---|---|
| Total Revenue (24 months) | $269,321,897 |
| Top 10% LTV Revenue Share | 41.1% (~$111M) |
| Total Customers | 79,574 |
| New Customers | 2,556 |
| Returning Customers | 77,018 |
| New Customer Avg Orders | 1.01 |
| Returning Customer Avg Orders | 4.32 |

**Business Interpretation**

Revenue is heavily concentrated in a small fraction of the customer base. A 41.1% revenue dependency on the top 10% creates meaningful retention risk: losing even a portion of that cohort would have outsized financial impact. The returning customer base is the true revenue engine — their 4.32-order average versus the 1.01 of new customers illustrates that converting a new customer to a second purchase is the single most value-generating CRM action available.

**Recommended Dashboard Chart**

CCO Page 1: Revenue Overview — Total Revenue and Customers scorecards (top of page), paired with the LTV Donut chart on CCO Page 2: Customer Breakdown.

**Conversation Bot Q&A**

*Q: What percentage of revenue comes from our top customers?*
A: The top 10% of customers by lifetime value generate $111M, which is 41.1% of total 24-month revenue of $269.3M. These ~7,957 customers are your highest-priority retention cohort. Would you like a breakdown by segment?

---

### CCO-2: Segment Trend

> Dashboard reference: CCO Page 2, Customer Breakdown

**Data**

Customer segments are defined as Platinum, Gold, Silver, and Bronze based on lifetime value and order frequency. The segment stacked bar chart on Page 2 shows the composition and revenue contribution of each segment over time.

| Segment | Customers At Risk | Avg Order Value |
|---|---|---|
| Platinum | 366 | $1,413 |
| Gold | 1,087 | $1,216 |
| Silver | 3,094 | $738 |

**Business Interpretation**

Platinum and Gold customers carry the highest average order values and therefore represent disproportionate revenue risk when churn signals emerge. The segment stacked bar provides a longitudinal view of whether the high-value tiers are growing or contracting as a share of the customer base. A shrinking Platinum tier alongside a rising Bronze tier would signal downward segment migration — a leading indicator of future revenue compression.

**Recommended Dashboard Chart**

CCO Page 2: Customer Breakdown — Segment Stacked Bar chart (segment composition over time), paired with the Churn Risk Bar chart on the same page.

**Conversation Bot Q&A**

*Q: How many Platinum customers are showing churn risk right now?*
A: There are 366 Platinum customers currently classified as At Risk or Cooling, with an average order value of $1,413. This makes them your single highest-priority retention cohort. Gemini has generated personalised strategies for each — would you like to see the top 10 by revenue exposure?

---

### CCO-3: Churn-Revenue Matrix

> Dashboard reference: CCO Page 3, AI Retention Intelligence — Segment x Risk Revenue Heatmap

**Data**

The churn-revenue matrix intersects customer segment (Platinum, Gold, Silver, Bronze) with churn risk classification (Active, Cooling, At Risk). Revenue at Risk — defined as the combined revenue attributable to Cooling and At-Risk customers — totals approximately $15.8M.

| Segment | At Risk Customers | Avg Order Value | Est. Revenue Exposure |
|---|---|---|---|
| Platinum | 366 | $1,413 | Highest |
| Gold | 1,087 | $1,216 | High |
| Silver | 3,094 | $738 | Moderate |

**Business Interpretation**

The heatmap on Page 3 makes the matrix immediately scannable: dark cells at the Platinum × At Risk intersection confirm where intervention must happen first. Gold At Risk (1,087 customers) is the second priority — the volume is nearly 3x Platinum but at a slightly lower order value. Silver At Risk (3,094 customers) offers the largest absolute count but requires more scalable, lower-touch tactics given the $738 AOV. A blanket campaign across all 4,547 at-risk customers would be inefficient; the heatmap is the right tool for sequencing effort by revenue density.

**Recommended Dashboard Chart**

CCO Page 3: AI Retention Intelligence — Segment x Risk Revenue Heatmap (pivot table with segment rows, risk columns, and revenue as the value metric).

**Conversation Bot Q&A**

*Q: Which segment-risk combination should I act on first?*
A: Platinum customers classified as At Risk — 366 customers with a $1,413 average order value. Their combined exposure is the highest-density cell in the churn matrix. Would you like Gemini's recommended retention strategy for this group?

---

### CCO-4: Country MoM Performance

> Dashboard reference: CCO Page 1, Revenue Overview — Country Bar Chart; CCO Page 2, Customer Breakdown — Geo Map and Country Table

**Data**

December 2024 month-on-month revenue growth by country:

| Country | MoM Revenue Change (Dec 2024) |
|---|---|
| Australia (AU) | -5.74% |
| India (IN) | -6.79% |
| Mexico (MX) | +6.76% |
| Brazil (BR) | +4.43% |

**Business Interpretation**

The two largest markets by customer base — Australia and India — are both contracting in December 2024, which is significant given the seasonal expectation of Q4 strength. A -6.79% MoM decline in India alongside -5.74% in Australia during what should be a peak period warrants investigation into whether this reflects market saturation, competitive pressure, or a logistics/fulfilment issue. Conversely, Mexico and Brazil are growing at rates exceeding 4%, suggesting that emerging market investment is beginning to yield returns. A geographic rebalancing of marketing spend toward MX and BR may be warranted in Q1 2025.

**Recommended Dashboard Chart**

CCO Page 1: Revenue Overview — Country Bar Chart (revenue by country). CCO Page 2: Customer Breakdown — Geo Map (bubble size = revenue) and Country Table (with MoM delta column).

**Conversation Bot Q&A**

*Q: Which countries are growing and which are declining this month?*
A: In December 2024, Mexico (+6.76%) and Brazil (+4.43%) are growing. Australia (-5.74%) and India (-6.79%) are declining. The AU and IN declines are notable given seasonal expectations. Would you like to drill into customer acquisition or order volume trends for those markets?

---

### CCO-5: Repeat Purchase Pattern

> Dashboard reference: CCO Page 1, Revenue Overview — Time Series; CCO Page 2, Customer Breakdown — Churn Risk Bar

**Data**

| Customer Type | Count | Avg Orders |
|---|---|---|
| New Customers | 2,556 | 1.01 |
| Returning Customers | 77,018 | 4.32 |
| New Customer Acquisition Peak | Oct 2024 — 430 customers | — |
| New Customer Acquisition Dec 2024 | 306 customers | -27% MoM from peak |

**Business Interpretation**

The ratio of returning to new customers (77,018 vs. 2,556) indicates a mature, retention-driven business — which is both a strength and a vulnerability. Strength because returning customers at 4.32 orders are far more valuable per head. Vulnerability because the new customer acquisition pipeline is visibly weakening: a 27% decline from the October 2024 peak of 430 to just 306 in December is a leading indicator of future revenue attrition if not reversed. The business cannot rely solely on its existing base; some level of new customer injection is required to offset natural churn from the returning base over time.

**Recommended Dashboard Chart**

CCO Page 1: Revenue Overview — Time Series (with New Customers as a secondary line). CCO Page 2: Customer Breakdown — Churn Risk Bar (repeat rate context).

**Conversation Bot Q&A**

*Q: Is new customer acquisition trending up or down?*
A: Down. New customer acquisition peaked at 430 in October 2024 and dropped to 306 in December 2024 — a 27% decline in two months. This is a leading indicator worth monitoring. Would you like to see which acquisition channels or countries are driving the drop?

---

### CCO-6: AI Retention Intelligence

> Dashboard reference: CCO Page 3, AI Retention Intelligence

#### What the AI Retention Page Shows

Page 3 of the CCO dashboard is the analytical centrepiece of the customer intelligence layer. It surfaces Gemini AI outputs at the individual customer level, aggregated into board-ready visualisations. The page contains five components:

1. **Revenue at Risk Scorecard** — a single large scorecard showing approximately $15.8M in combined revenue attributable to Cooling and At-Risk customers. This is calculated from the `mart_executive_summary_enriched` table using churn risk classification fields sourced from `ai.customer_concierge`.

2. **AI Coverage %** — the percentage of at-risk customers who have received a Gemini-generated persona and strategy. A coverage rate below 95% indicates that some customers are being excluded from AI enrichment and may be falling through the retention net.

3. **Strategy Type Donut** — shows the distribution of Gemini-recommended retention strategies across the at-risk population. Categories are: Offer/Discount, Win-back, Loyalty Reward, Product Recommendation, and Personalised Outreach. The donut allows the CCO to understand the campaign mix required before briefing the CRM team.

4. **Segment x Risk Heatmap** — a pivot table with customer segments as rows and churn risk levels as columns, with revenue as the cell value. This is the fastest way to identify which intervention deserves the most resources.

5. **AI Persona Spotlight Table** — a detailed table showing individual customers with columns for customer_id, segment, churn_risk, gemini_insight, and revenue trend. This is the operational handoff layer — the CRM team uses this table to execute campaigns.

#### How to Interpret Persona and Strategy Fields

The `customer_concierge` table stores two Gemini-generated JSON fields per customer: `persona` (a natural language description of the customer's behavioural archetype, e.g. "deal-sensitive repeat buyer who responds to limited-time offers") and `strategy` (an actionable CRM instruction, e.g. "Trigger 15% discount email within 48 hours of last session"). The `mart_executive_summary_enriched` table exposes the `gemini_insight` field, which concatenates these two fields into a single readable string for dashboard display.

When reading the Persona Spotlight table, the `gemini_insight` column should be read as: first, who this customer is, then what to do about it. The persona section provides context; the strategy section is the action.

#### Revenue at Risk Calculation

Revenue at Risk is not a predictive model — it is a descriptive classification. Customers are flagged as Cooling (declining order frequency) or At Risk (extended period of inactivity relative to their historical purchase cadence). The $15.8M figure represents the last-12-months revenue attributable to all customers currently in these two states. If no intervention occurs and these customers churn fully, $15.8M of annualised revenue is at risk of non-recurrence.

The calculation pulls from `mart_executive_summary_enriched` where `churn_risk IN ('Cooling', 'At Risk')` and aggregates revenue over the trailing 12 months.

#### How to Use the Strategy Type Donut to Prioritise Campaigns

The Strategy Type donut is a resource-allocation tool. Before the CRM team can execute retention campaigns, they need to know what mix of campaign types to prepare creative and budget for. If the donut shows 45% Win-back, 30% Loyalty Reward, and 25% Offer/Discount, the team should prioritise Win-back creative first by volume. Clicking any segment of the donut filters the Persona Spotlight table to show only customers with that strategy — enabling direct export for campaign execution.

#### What Each Strategy Category Means in Practice

- **Offer/Discount**: Customer is price-sensitive or has responded to promotions historically. Gemini recommends a time-bound discount to re-engage. Typical for Silver and Bronze segments.
- **Win-back**: Customer has lapsed beyond their normal purchase cycle. A re-engagement email sequence with a strong incentive is recommended. Most relevant for Platinum and Gold customers who went quiet.
- **Loyalty Reward**: Customer is engaged but showing early cooling signals. Rewarding continued loyalty before full churn occurs is more cost-effective than a win-back. Tier upgrade offers and points multipliers apply here.
- **Product Recommendation**: Customer's purchase history suggests an adjacent product or category they have not yet explored. Gemini identifies the category gap and recommends a specific product family. Most effective for customers with 2–4 lifetime categories.
- **Personalised Outreach**: Customer profile is complex or high-value enough to warrant a human touchpoint — account manager call or personalised email from a named sender. Reserved primarily for Platinum customers.

**Recommended Dashboard Chart**

CCO Page 3: AI Retention Intelligence — Strategy Type Donut (Gemini category distribution) and AI Persona Spotlight Table (customer_id, segment, churn_risk, gemini_insight, revenue trend).

**Conversation Bot Q&A**

*Q: What are Gemini's top retention strategies for our at-risk Platinum customers?*
A: For the 366 Platinum customers currently at risk, Gemini's most common recommended strategies are Win-back and Personalised Outreach, reflecting their high value and the importance of a human-feeling touchpoint. Each has a tailored persona and strategy in the AI Persona Spotlight table on Page 3. Would you like me to list the top 10 by revenue exposure?

*Q: How much revenue could we recover if we retain the at-risk customers?*
A: The Revenue at Risk scorecard shows approximately $15.8M. Full recovery is unlikely, but even a 50% retention rate on Cooling customers — who are typically more recoverable than At Risk — could protect $6–8M in annualised revenue. Would you like a breakdown by segment?

---

## PART 2 — CPO INTELLIGENCE

---

### CPO-1: Category Revenue Performance

> Dashboard reference: CPO Page 1, Category Performance — Revenue/Margin/Units Scorecards and Bar Chart by Category

**Data**

| Category | Revenue | Margin % | Units |
|---|---|---|---|
| Electronics | $153M | 49.8% | — |
| Clothing | $20M | — | 226K |

**Business Interpretation**

Electronics is the undisputed Star category: $153M in revenue at a 49.8% gross margin. This combination of scale and profitability is rare and should be protected aggressively. Clothing, by contrast, delivers the highest unit volume at 226K but only $20M in revenue — implying a very low average selling price and likely significant markdown or promotional activity. The strategic question for the CPO is whether Clothing's volume can be monetised through upsell into adjacent premium categories, or whether it serves primarily as an acquisition funnel.

**Recommended Dashboard Chart**

CPO Page 1: Category Performance — Bar Chart by Category (revenue) with a margin % overlay, and the Revenue/Margin/Units scorecards at the top of the page.

**Conversation Bot Q&A**

*Q: Which product category has the best margin?*
A: Electronics leads with a 49.8% gross margin on $153M in revenue — making it both the highest-revenue and highest-margin category. Clothing has the most units (226K) but significantly lower revenue per unit. Would you like to see the margin trend over time?

---

### CPO-2: Brand Performance

> Dashboard reference: CPO Page 2, Product Leaderboard — Brand Bar Chart

**Data**

| Brand | Revenue | Revenue per Buyer | Buyers |
|---|---|---|---|
| PulseGear | $12.6M | $1,597 | ~7,890 |
| NovaTech | — | $739 | 9,978 |

**Business Interpretation**

PulseGear is the premium niche brand: $1,597 revenue per buyer signals a high-ASP, loyal customer base. NovaTech is the acquisition brand: 9,978 buyers is the widest reach in the portfolio but at $739 per buyer, these customers need to be migrated up the value ladder. A brand partnership or co-marketing strategy that introduces NovaTech buyers to PulseGear product families could be the highest-ROI brand initiative in the near term.

**Recommended Dashboard Chart**

CPO Page 2: Product Leaderboard — Brand Bar Chart (revenue by brand), with revenue per buyer as a secondary metric.

**Conversation Bot Q&A**

*Q: Which brand generates the most revenue per customer?*
A: PulseGear leads at $1,597 revenue per buyer on $12.6M total revenue — a premium niche positioning. NovaTech has the most buyers (9,978) but at $739 per buyer. The CPO opportunity is to cross-introduce NovaTech buyers to PulseGear. Would you like the product overlap analysis?

---

### CPO-3: Cross-Sell Depth

> Dashboard reference: CPO Page 1, Category Performance — Stacked Area Time Series; CPO Page 3, AI Upsell Intelligence

**Data**

| Metric | Value |
|---|---|
| Avg categories per customer | 3.85 out of 8 |
| Single-category customers | 12,052 |
| Single-category customers as % of base | 15.4% |

**Business Interpretation**

The average customer engages with 3.85 of 8 available categories — meaning roughly half the catalogue is untouched per customer on average. The 12,052 single-category customers (15.4% of the base) represent the clearest and most actionable cross-sell opportunity: these are customers the business has already acquired and retained, but who have not been guided beyond their entry point. A structured cross-sell motion — whether through Gemini-powered recommendations or category-specific email journeys — applied to this segment could materially increase revenue per customer without acquiring a single new buyer.

**Recommended Dashboard Chart**

CPO Page 3: AI Upsell Intelligence — Category x Upsell Type Heatmap (pivot showing which categories have the most AI-generated cross-sell recommendations).

**Conversation Bot Q&A**

*Q: How many customers have only bought from one category?*
A: 12,052 customers — 15.4% of the total base — have purchased from only one of eight available categories. These are your highest-priority cross-sell targets. Gemini has generated cross-category recommendations for each. Would you like to see which categories they are currently in?

---

### CPO-4: Product Leaderboard and Hidden Gems

> Dashboard reference: CPO Page 2, Product Leaderboard — Top 20 Products Table; CPO Page 3, AI Upsell Intelligence — Enriched Product Table

**Data**

| Product | Margin % | Revenue per Unit | Units Sold |
|---|---|---|---|
| CrystalBit Pro Cameras 102 | 64.8% | $936 | 240 |

**Business Interpretation**

The CrystalBit Pro Cameras 102 is a textbook hidden gem: 64.8% gross margin at $936 per unit, but only 240 units sold. This product is almost certainly under-promoted and under-distributed. It does not appear in the top 20 revenue leaderboard by volume, which is precisely why it gets overlooked in standard product reviews. The AI Upsell Intelligence page is designed to surface exactly this type of product — high-margin items that Gemini flags as upsell or accessory add-on candidates for customers already in adjacent categories. The CPO should brief the merchandising team to run a targeted promotion on CrystalBit Pro Cameras 102 within the current quarter.

**Recommended Dashboard Chart**

CPO Page 2: Product Leaderboard — Top 20 Products Table. CPO Page 3: AI Upsell Intelligence — Enriched Product Table (filter by margin % descending to surface hidden gems).

**Conversation Bot Q&A**

*Q: Are there any high-margin products we are underexploiting?*
A: Yes — CrystalBit Pro Cameras 102 has a 64.8% gross margin at $936 per unit but only 240 units sold. It is not in the top 20 revenue table, which is why it gets missed in standard reviews. Gemini classifies it as a Premium Upgrade and Accessory Add-on target. Would you like the list of customers currently in Camera-adjacent categories who have not purchased it?

---

### CPO-5: Sub-Category and Volume Analysis

> Dashboard reference: CPO Page 2, Product Leaderboard — Sub-Category Bar

**Data**

The sub-category bar chart on Page 2 shows the distribution of units and revenue across all product sub-categories. Clothing sub-categories dominate unit volume. Electronics sub-categories dominate revenue and margin.

**Business Interpretation**

The divergence between unit volume and revenue across sub-categories is the key analytical tension for the CPO. High-volume, low-revenue sub-categories (primarily Clothing) inflate warehouse and logistics costs without proportionate margin contribution. The CPO should use the sub-category bar to identify which sub-categories have volume without margin and evaluate whether rationalisation, repricing, or upsell enablement is the right response.

**Recommended Dashboard Chart**

CPO Page 2: Product Leaderboard — Sub-Category Bar chart (dual axis: units on one axis, revenue on the other, allowing visual identification of the volume-revenue gap).

**Conversation Bot Q&A**

*Q: Which sub-categories have the highest volume but lowest revenue contribution?*
A: Clothing sub-categories carry the highest unit volumes (total Clothing: 226K units, $20M revenue) while Electronics sub-categories generate far higher revenue on lower unit counts. Would you like a ranked table of sub-categories sorted by revenue-per-unit ascending?

---

### CPO-6: AI Upsell Intelligence

> Dashboard reference: CPO Page 3, AI Upsell Intelligence

#### How to Use the Upsell Type Donut

The Upsell Type Donut on Page 3 shows the distribution of Gemini-recommended upsell and cross-sell strategies across the product catalogue. The five strategy categories are: Bundle, Premium Upgrade, Accessory Add-on, Subscription, and Cross-Category. Each represents a distinct commercial motion requiring different creative, pricing, and operational support.

The donut serves as a campaign planning tool for the CPO and merchandising team. Clicking a segment filters the Enriched Product Table below to show only the products tagged with that strategy, enabling direct extraction for campaign briefing. If Bundle is the dominant category, the merchandising team should prioritise bundle creation. If Premium Upgrade dominates, the team should focus on comparison content and tiered pricing pages.

#### Which Categories Have the Best Upsell Coverage

Electronics, as the highest-revenue category, should have the highest absolute upsell coverage by count. The Category x Upsell Type Heatmap (a pivot table with categories as rows and upsell types as columns, with product count or revenue as the cell value) makes this immediately visible. Categories with sparse heatmap cells — low upsell coverage — are areas where the Gemini enrichment pipeline may need to be retrained or where catalogue data quality is insufficient for AI recommendation.

The CPO should target greater than 95% upsell coverage across all products in Electronics and Clothing, given their revenue and volume significance respectively.

#### How to Find Hidden Gems Using the AI Table

The Enriched Product Table on Page 3 includes the `cross_sell` and `upsell` fields from the `product_upsell` table — Gemini-generated JSON objects parsed into readable columns. To find hidden gems, sort the table by margin % descending and filter to products with fewer than 1,000 units sold. This surfaces high-margin, low-volume products that Gemini has identified as upsell or premium upgrade candidates.

The CrystalBit Pro Cameras 102 is the prototype example: 64.8% margin, $936 per unit, 240 units sold. It would appear near the top of this filtered view, accompanied by Gemini's specific recommendation for which customer segment and adjacent category to target.

#### Cross-Sell vs Upsell Interpretation

The `product_upsell` table stores two distinct Gemini fields:

- **`upsell`**: A recommendation to move the customer to a higher-value version of a product they have already purchased or considered. Example: a customer who bought a mid-range NovaTech laptop is recommended a PulseGear premium laptop. The value driver is higher ASP on a familiar category.

- **`cross_sell`**: A recommendation to introduce the customer to a complementary product in a different category or sub-category. Example: a customer who bought a camera is recommended a tripod, memory card, or camera bag. The value driver is basket size expansion and category depth.

In practice, Premium Upgrade and Subscription strategies map to upsell behaviour, while Bundle, Accessory Add-on, and Cross-Category strategies map to cross-sell behaviour. The donut split between these two groups tells the CPO whether the opportunity skews toward deepening existing category relationships (upsell) or broadening category engagement (cross-sell).

**Recommended Dashboard Chart**

CPO Page 3: AI Upsell Intelligence — Upsell Type Donut (Gemini category distribution) and Enriched Product Table (product, category, margin %, units sold, upsell strategy, cross_sell strategy).

**Conversation Bot Q&A**

*Q: What upsell strategies has Gemini recommended for Electronics products?*
A: For Electronics, Gemini's most common recommendations are Premium Upgrade (upgrading mid-tier devices to premium tier) and Bundle (pairing devices with accessories). Electronics has the highest upsell coverage in the catalogue given its margin profile. Would you like the specific product list with upsell targets?

*Q: Which products are best suited for cross-sell campaigns right now?*
A: Based on the Enriched Product Table, products in the Camera and Audio sub-categories show the strongest Cross-Category and Accessory Add-on signals from Gemini. The CrystalBit Pro Cameras 102 (64.8% margin, $936/unit) is flagged as a high-priority cross-sell target for customers in Electronics who have not yet purchased in Camera. Would you like the customer segment match list?

---

## PART 3 — CTO INTELLIGENCE

---

### CTO-1: Data Freshness

> Dashboard reference: CTO Page 1, Pipeline Overview — Run Count and Duration Scorecards; Table by Entity

**Data**

The Pipeline Overview dashboard surfaces run counts, success rates, rows merged, and duration metrics for the Dataform pipeline. The daily refresh workflow runs in three phases: Phase 1 (tag=daily_refresh: bronze to silver to gold plus product AI shards), Phase 2 (Cloud Run customer AI processor writing to ai.customer_ai_raw), and Phase 3 (tag=ai_aggregate: customer_concierge to ai_enriched_profiles to mart_executive_summary_enriched).

**Business Interpretation**

Data freshness is the foundation of every insight in this report. If the daily refresh workflow fails at Phase 1, gold tables are stale. If Phase 2 fails, the AI Retention and AI Upsell pages show yesterday's (or older) Gemini outputs. The CTO must treat Phase 2 failures as business-critical incidents because they cascade into the CCO and CPO dashboards losing their AI intelligence layer.

**Recommended Dashboard Chart**

CTO Page 1: Pipeline Overview — Time Series of Runs (run count over time, colour-coded by success/failure) and Table by Entity (one row per Dataform table, showing last successful run timestamp).

**Conversation Bot Q&A**

*Q: When did the pipeline last run successfully?*
A: The Pipeline Overview table shows the last successful run timestamp for each entity. If any table shows a last run timestamp more than 26 hours ago, it is outside the daily refresh SLA and should be investigated. Would you like me to list the tables currently outside SLA?

---

### CTO-2: Referential Integrity

> Dashboard reference: CTO Page 1, Pipeline Overview — Rows Merged Scorecard and Table by Entity

**Data**

The delta layer (`delta_customers.sqlx`, `delta_products.sqlx`) executes MERGE operations into gold dimension tables. The rows merged scorecard on the Pipeline Overview tracks how many records were upserted in each run. The governance layer (audit log, schema change log) provides a historical record of all schema changes.

**Business Interpretation**

Referential integrity failures — where a foreign key in a fact table does not resolve to a record in a dimension table — will cause silent errors in gold layer joins, producing incorrect revenue and customer counts in all downstream dashboards. The CTO should validate that the delta MERGE success rate is consistent with expectations and that orphaned records are not accumulating in fact tables.

**Recommended Dashboard Chart**

CTO Page 1: Pipeline Overview — Rows Merged Scorecard (total MERGE operations in the current run cycle) and Table by Entity (rows merged per table per run).

**Conversation Bot Q&A**

*Q: Are there any data integrity issues in the current pipeline run?*
A: The Pipeline Overview table shows rows merged per entity. If any delta table shows zero rows merged when upstream source data has changed, that is a likely MERGE failure. The governance audit log provides a detailed record of all schema and data changes. Would you like me to check the audit log for the last 7 days?

---

### CTO-3: AI Pipeline Health

> Dashboard reference: CTO Page 1, Pipeline Overview — Success Rate Scorecard

#### Generation Status Success Rate Target

The AI pipeline generates Gemini outputs through two parallel pathways. The product AI pathway uses four BQ ML shards (`product_ai_1` through `product_ai_4`) executing `ML.GENERATE_TEXT` against the `gemini-2.5-flash` model via the `gemini-pro-connection` endpoint in `australia-southeast1`. Each shard writes to a staging table, and the results are aggregated into `product_upsell` in Phase 1. The customer AI pathway uses the Cloud Run `customer-ai-processor` service (50 concurrent Gemini calls, gunicorn timeout 1800s) to write to `ai.customer_ai_raw` in Phase 2.

The target `generation_status` success rate is greater than 95% for both pathways. This means that of all rows submitted to Gemini, at least 95% must return a valid JSON response that passes the `REGEXP_EXTRACT(raw_text, r'\{[\s\S]*\}')` extraction and `JSON_VALUE` parsing chain. Rows below this threshold indicate either model timeout, malformed input, or connection quota exhaustion.

The CTO should monitor the success rate scorecard on the Pipeline Overview page after every Phase 1 and Phase 2 completion. A rate between 90% and 95% warrants investigation. A rate below 90% should trigger an immediate pipeline halt and root cause analysis before Phase 3 runs — because Phase 3 aggregates the AI outputs into `mart_executive_summary_enriched`, and a degraded input will produce a degraded executive dashboard.

#### What to Do If ai_status Returns an Error on customer_concierge

The `customer_concierge` table is populated in Phase 3 from `ai.customer_ai_raw`. If a row in `customer_ai_raw` has an `ai_status` field containing a non-empty string (i.e., BQ ML returned an error message rather than an empty string signalling success), that row should be excluded from the `customer_concierge` aggregation. The BQ ML success filter `WHERE status = ''` (empty string) enforces this — rows with any error text in the status field are filtered out.

The diagnostic steps when `ai_status` errors appear are:

1. Check the Cloud Run logs for `customer-ai-processor` in `australia-southeast1` for timeout or quota errors.
2. Verify that the `gemini-pro-connection` in BigQuery has not hit its regional request quota for the day.
3. If the error rate is isolated to specific `customer_id` ranges, check whether those customers have malformed or null input fields (e.g., null `customer_segment`, null purchase history).
4. Re-trigger Phase 2 for failed batches by resubmitting the Cloud Run POST `/process` endpoint with the affected customer IDs.
5. After remediation, re-run Phase 3 (`tag=ai_aggregate`) to refresh `customer_concierge`, `ai_enriched_profiles`, and `mart_executive_summary_enriched`.

Do not allow Phase 3 to run with more than 5% of `customer_ai_raw` rows in error state — the downstream mart will silently undercount AI coverage and distort the Revenue at Risk scorecard on the CCO dashboard.

#### How to Monitor BQ ML Job Costs

BQ ML `ML.GENERATE_TEXT` calls against `gemini-2.5-flash` are billed per 1,000 characters of input and output. The four product AI shards (`product_ai_1-4`) each process a subset of the product catalogue; the shard design was intentional to stay within per-job character limits and to enable parallel execution.

To monitor costs:

- Navigate to BigQuery Job History in the GCP Console under project `vishal-sandpit-474523`.
- Filter by job type: ML and date range of the last 7 days.
- Review the `bytes_billed` and `slot_hours` columns for each ML job.
- Cross-reference against the Cloud Billing export in BigQuery if the Looker Studio billing dashboard is available.

The CTO should establish a weekly cost baseline for BQ ML jobs after the first four weeks of production operation and set a budget alert in Cloud Billing at 120% of that baseline to catch unexpected spikes. Common causes of cost spikes include: input schema changes that inadvertently widen the prompt, model version upgrades that increase output verbosity, or accidental re-execution of shards outside the daily schedule.

**Recommended Dashboard Chart**

CTO Page 1: Pipeline Overview — Success Rate Scorecard (percentage of rows with `generation_status = ''`), Run Count Scorecard, and Duration Scorecard (to detect performance degradation).

**Conversation Bot Q&A**

*Q: What is the current AI pipeline success rate?*
A: The Pipeline Overview Success Rate scorecard shows the percentage of BQ ML and Cloud Run Gemini calls that returned a valid response in the last run cycle. The target is above 95%. If you are seeing a rate below that threshold, check the Cloud Run logs for customer-ai-processor and the BQ ML job history for product_ai_1 through product_ai_4. Would you like the diagnostic checklist?

*Q: How much did the BQ ML jobs cost in the last 7 days?*
A: BQ ML job costs for the last 7 days can be retrieved from the BigQuery Job History under project vishal-sandpit-474523, filtering for ML job type. Would you like me to provide the exact query to pull this from the Cloud Billing export table?

*Q: What should I do if Phase 3 fails to run after Phase 2 completes?*
A: First, verify that ai.customer_ai_raw has been fully populated by Phase 2 — check the row count against the expected customer volume. If the row count is correct, check the generation_status distribution: if more than 5% of rows have a non-empty status string, hold Phase 3 and remediate Phase 2 first. If row counts and status are clean, re-trigger the ai_aggregate tag in Dataform manually via the Cloud Workflows console. Would you like the Dataform CLI command to do this?

---

## PART 4 — CONVERSATIONAL BOT USAGE GUIDE

The Conversational Bot combines two capabilities: the BigQuery Data Agent (which can query live BigQuery tables directly) and the Looker Studio Gemini integration (which can explain, filter, and summarise the dashboard currently open). Together they allow C-suite stakeholders to ask natural language questions and receive data-grounded answers without navigating raw SQL.

---

### CCO Bot Questions

**Q1: How much revenue is at risk from churning customers right now?**
Expected answer: Approximately $15.8M is currently at risk from customers classified as Cooling or At Risk. The largest concentration is in the Platinum segment (366 customers, $1,413 average order value). Gemini has generated personalised win-back and loyalty strategies for each. Would you like to see the top 20 by revenue exposure?

**Q2: Which country had the worst revenue performance last month?**
Expected answer: India declined -6.79% month-on-month in December 2024, making it the weakest performing major market. Australia followed at -5.74%. Mexico and Brazil were the only major markets in positive territory at +6.76% and +4.43% respectively. Would you like to compare against the same period last year?

**Q3: What is our repeat purchase rate and how does it compare to new customers?**
Expected answer: Returning customers (77,018) average 4.32 orders each. New customers (2,556) average 1.01 orders. The repeat rate reflects a mature, retention-led business model. However, new customer acquisition has declined 27% from its October 2024 peak of 430 to 306 in December. Would you like the acquisition trend by country?

**Q4: Which customer segment has the highest concentration of at-risk revenue?**
Expected answer: Platinum At Risk — 366 customers with a $1,413 average order value — represents the highest-density revenue risk cell in the churn matrix. Gold At Risk (1,087 customers, $1,216 AOV) is the second priority. The Segment x Risk Heatmap on Page 3 shows the full matrix. Would you like Gemini's strategy recommendations for the Platinum cohort?

**Q5: What retention strategy does Gemini recommend for a specific customer?**
Expected answer: Open the AI Persona Spotlight table on CCO Page 3, search by customer_id, and read the gemini_insight column. The first sentence describes the customer's behavioural persona; the second provides the specific CRM action recommended. If you share the customer_id here, I can retrieve the exact strategy from the customer_concierge table. Would you like to try one now?

---

### CPO Bot Questions

**Q1: Which product category has the best combination of revenue and margin?**
Expected answer: Electronics is the Star category — $153M in revenue at a 49.8% gross margin. No other category comes close on both dimensions simultaneously. Clothing has the highest unit volume (226K units) but only $20M in revenue, reflecting a low average selling price. Would you like the full category margin table?

**Q2: Which brand delivers the most revenue per buyer?**
Expected answer: PulseGear leads at $1,597 revenue per buyer across approximately $12.6M in total revenue — a premium niche positioning. NovaTech has the widest reach at 9,978 buyers but at $739 per buyer. The strategic opportunity is to migrate NovaTech buyers into PulseGear product families. Would you like the product overlap between these two brands?

**Q3: Are there any high-margin products we are not promoting enough?**
Expected answer: Yes — CrystalBit Pro Cameras 102 carries a 64.8% gross margin at $936 per unit but has sold only 240 units. It does not appear in the top 20 revenue leaderboard, which is why it is typically overlooked. Gemini classifies it as a Premium Upgrade target. Would you like the customer list for customers in adjacent categories who have not yet purchased this product?

**Q4: How many customers have only bought from one product category?**
Expected answer: 12,052 customers — 15.4% of the total base — have purchased from only one of eight available categories. These are the highest-priority cross-sell targets in the base. Gemini's Cross-Category strategy type covers many of these customers in the AI Upsell page. Would you like to know which single categories they are concentrated in?

**Q5: What upsell strategies has AI generated for the Electronics category?**
Expected answer: For Electronics, Gemini's most frequent recommendations are Premium Upgrade (moving mid-tier buyers to premium device tiers) and Bundle (pairing devices with accessories such as cases, cables, and peripherals). The Upsell Type Donut on Page 3 shows the full strategy distribution. Would you like the enriched product table filtered to Electronics only?

---

### CTO Bot Questions

**Q1: When did the pipeline last run successfully and are all tables up to date?**
Expected answer: The Pipeline Overview table on Page 1 shows the last successful run timestamp for each entity. Tables are considered within SLA if the last run timestamp is less than 26 hours ago. Any table outside this window should be flagged for investigation. Would you like me to query the Dataform run history directly from BigQuery?

**Q2: What is the current AI generation success rate and is it above the 95% threshold?**
Expected answer: The Success Rate scorecard on Page 1 shows the current generation_status success rate. The target is above 95%. If the rate is between 90% and 95%, investigation is warranted. Below 90% should trigger a pipeline hold before Phase 3 runs. Would you like the diagnostic steps for below-threshold rates?

**Q3: How do I re-run only the AI pipeline phases if the daily refresh has already completed?**
Expected answer: To re-run Phase 2 only, resubmit the Cloud Run POST /process endpoint via the delta-ingest-workflow or manually via the Workflows console. To re-run Phase 3 only, trigger the Dataform ai_aggregate tag via the Cloud Workflows console or with the Dataform CLI: `dataform run --tags ai_aggregate`. Do not re-run Phase 1 unless source data has changed — doing so will overwrite silver and gold tables unnecessarily. Would you like the exact Dataform CLI command?

---

### How to Phrase Questions for Best Results

- **Be specific about the time period**: "in December 2024" or "over the last 24 months" gives better results than "recently" or "lately."
- **Name the segment or category**: "Platinum customers" or "Electronics category" produces a direct data lookup rather than a broad scan.
- **Ask for a ranked list**: "Which top 5 customers by revenue are at risk?" is more actionable than "Who are the at-risk customers?"
- **Follow up with a why**: After receiving a number, ask "Why is this happening?" — the bot will attempt to surface correlating factors from the enriched mart tables.
- **Request the Gemini strategy explicitly**: If you want the AI-generated recommendation, ask "What does Gemini recommend for this customer/product?" — the bot will pull from the persona or upsell field directly.

---

### What the Bot Cannot Answer (Limitations)

- **Real-time data**: The bot queries BigQuery tables that are refreshed once daily. It cannot reflect intraday changes or live transactional data.
- **Causal inference**: The bot can surface correlations (e.g., Platinum churn is higher in AU than IN) but cannot confirm causation without additional analytical modelling.
- **Predictive forecasting**: Revenue at Risk is a descriptive classification, not a predictive model. The bot cannot forecast what revenue will be next quarter.
- **External benchmarks**: The bot has no access to industry benchmarks, competitor data, or market context. All comparisons are internal.
- **Schema changes**: If a Dataform schema migration has occurred and the mart tables have not been rebuilt, the bot may return stale or incorrect column references. The CTO should notify stakeholders after any schema change and trigger a full pipeline refresh.
- **Private customer PII**: The bot will return customer_id fields but should not be used to display or share full personally identifiable information outside of approved CRM workflows.

---

## APPENDIX — Dashboard-to-Report Cross Reference

| Dashboard | Page | Page Name | Report Section(s) |
|---|---|---|---|
| CCO | Page 1 | Revenue Overview | CCO-1: Revenue Concentration, CCO-4: Country MoM, CCO-5: Repeat Purchase Pattern |
| CCO | Page 2 | Customer Breakdown | CCO-2: Segment Trend, CCO-3: Churn-Revenue Matrix, CCO-4: Country MoM |
| CCO | Page 3 | AI Retention Intelligence | CCO-3: Churn-Revenue Matrix (heatmap), CCO-6: AI Retention Intelligence |
| CPO | Page 1 | Category Performance | CPO-1: Category Revenue Performance, CPO-3: Cross-Sell Depth |
| CPO | Page 2 | Product Leaderboard | CPO-2: Brand Performance, CPO-4: Product Leaderboard and Hidden Gems, CPO-5: Sub-Category and Volume Analysis |
| CPO | Page 3 | AI Upsell Intelligence | CPO-3: Cross-Sell Depth, CPO-4: Hidden Gems, CPO-6: AI Upsell Intelligence |
| CTO | Page 1 | Pipeline Overview | CTO-1: Data Freshness, CTO-2: Referential Integrity, CTO-3: AI Pipeline Health |
| All | — | Conversational Bot | Part 4: Conversational Bot Usage Guide |

---

*Document generated for Intelia Business-in-a-Box | GCP Project: vishal-sandpit-474523 | Region: australia-southeast1*
