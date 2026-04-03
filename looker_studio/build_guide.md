# Intelia Looker Studio — Dashboard Construction Guide

**Data verified:** 2026-03-25
**Author:** Generated from dashboards.yaml + live BQ verification
**Signed-in account:** vishal@intelia.com.au
**Target:** Build each dashboard page in ~10 minutes by following these instructions exactly.

---

## Prerequisites

- Signed in to Looker Studio as **vishal@intelia.com.au**
- BigQuery project **vishal-sandpit-474523** is accessible
- Views confirmed live:
  - `vishal-sandpit-474523.gold.rpt_cco_dashboard` — 335K rows
  - `vishal-sandpit-474523.gold.rpt_cpo_dashboard` — 742K rows
  - `vishal-sandpit-474523.governance.rpt_cto_dashboard` — pipeline audit log

### Global Style Settings (apply to all three dashboards)

| Setting | Value |
|---|---|
| Canvas size | 1280 x 900 px (Desktop) |
| Background | `#F8F9FA` (near-white) |
| Header bar | `#1A237E` (dark navy) |
| Primary accent | `#4285F4` (Google Blue) |
| Positive / up | `#34A853` (green) |
| Warning | `#FBBC04` (amber) |
| Danger / down | `#EA4335` (red) |
| Font — titles | Google Sans, 14pt, Bold |
| Font — body | Google Sans, 11pt, Regular |
| Scorecard background | White, 2px border-radius, light drop shadow |

---

---

# DASHBOARD 1 — CCO: Customer Health & Revenue

**Persona:** Chief Customer Officer
**Source table:** `vishal-sandpit-474523.gold.rpt_cco_dashboard`
**Row grain:** One row per order (335K rows, 24-month window)

## Step 1 — Create the Report

Open this URL exactly as written (do not modify it):

```
https://lookerstudio.google.com/c/reporting/create?c.mode=CREATE&ds.connector=BIG_QUERY&ds.type=TABLE&ds.projectId=vishal-sandpit-474523&ds.datasetId=gold&ds.tableId=rpt_cco_dashboard&r.reportName=Intelia+CCO+Dashboard
```

Looker Studio opens a blank canvas already connected to `rpt_cco_dashboard`. Click **Edit** if prompted.

## Step 2 — Configure the Data Source

1. Click **Resource > Manage added data sources > Edit** (pencil icon next to rpt_cco_dashboard).
2. Verify the fields below are auto-detected correctly. Fix type if wrong:

| Field name | Expected type |
|---|---|
| order_id | Text |
| order_date | Date |
| year_month | Text |
| customer_id | Text |
| order_revenue | Number (Currency) |
| item_count | Number |
| avg_item_price | Number (Currency) |
| country | Text (Geo > Country) |
| customer_type | Text |
| customer_segment | Text |
| churn_risk | Text |
| lifetime_value_band | Text |

3. Set **order_date** semantic type to **Date (YYYYMMDD)** if not already set.
4. Set **country** semantic type to **Geo > Country**.
5. Click **Done**.

## Step 3 — Add Calculated Fields

Click **Resource > Manage added data sources > Edit > Add a field** (bottom-left).

**Calculated field 1:**
- Name: `Repeat Rate`
- Formula: `COUNTIF(customer_type = 'Returning') / COUNT(order_id)`
- Default aggregation: Auto
- Format: Percent (0 decimal places)

**Calculated field 2:**
- Name: `Revenue per Customer`
- Formula: `SUM(order_revenue) / COUNT_DISTINCT(customer_id)`
- Default aggregation: Auto
- Format: Currency (AUD)

Click **Save** then **Done**.

## Step 4 — Add the Date Range Control

1. Click **Add a control > Date range control**.
2. Drop it in the top-right corner of the canvas (approx 980,20 px position).
3. In the control properties panel:
   - **Data source:** rpt_cco_dashboard
   - **Period:** Last 12 months (default)
4. This control will apply to all charts on this page that use `order_date`.

## Step 5 — Page 1: "Revenue Overview"

Rename the default page: double-click the page tab at the bottom, type `Revenue Overview`.

### Layout (top row — 6 scorecards)

Place 6 scorecards in a single row across the top of the canvas. Each scorecard: approx **180 x 90 px**, evenly spaced, starting at y=80px.

---

**Scorecard 1 — Total Revenue**

1. Insert > Scorecard.
2. Metric: `order_revenue` — aggregation: **SUM**.
3. Label: `Total Revenue`.
4. Format: Currency, prefix `$`, 0 decimal places.
5. Comparison: **Previous period** — enable "Show comparison".
6. Style tab: background white, font size 22pt for value, label 10pt.
7. Expected value: ~$269M (24 months) or ~$134M (12 months).

**Scorecard 2 — Unique Customers**

1. Insert > Scorecard.
2. Metric: `customer_id` — aggregation: **Count Distinct**.
3. Label: `Unique Customers`.
4. Comparison: **Previous period**.
5. Expected value: ~74K.

**Scorecard 3 — Total Orders**

1. Insert > Scorecard.
2. Metric: `order_id` — aggregation: **Count**.
3. Label: `Total Orders`.
4. Comparison: **Previous period**.
5. Expected value: ~335K.

**Scorecard 4 — Avg Order Value**

1. Insert > Scorecard.
2. Metric: `order_revenue` — aggregation: **Average**.
3. Label: `Avg Order Value`.
4. Format: Currency AUD, 0 decimal places.
5. Comparison: **Previous period**.
6. Expected value: ~$804.

**Scorecard 5 — New Customers**

1. Insert > Scorecard.
2. Metric: Click **+ Add metric > Create field** (inline calculated field):
   - Formula: `COUNTIF(customer_type = 'New')`
   - Name: `New Customers Count`
3. Label: `New Customers`.
4. Comparison: **Previous period**.
5. Expected value: ~1% of orders (~3,350 if 12 months selected).

**Scorecard 6 — Repeat Rate**

1. Insert > Scorecard.
2. Metric: Select the calculated field `Repeat Rate`.
3. Label: `Repeat Rate`.
4. Format: Percent, 1 decimal place.
5. Comparison: **Previous period**.
6. Expected value: ~99%.

---

### Time Series Chart — Revenue & Orders Over Time

Size: **Full width, ~280 px tall**. Place directly below the scorecard row.

1. Insert > Time series chart.
2. **Dimension:** `order_date` — set granularity to **Month**.
3. **Metrics (add 3):**
   - Metric 1: `order_revenue` — SUM — label `Revenue` — color `#4285F4`
   - Metric 2: `order_id` — Count — label `Orders` — color `#34A853`
   - Metric 3: `customer_id` — Count Distinct — label `Customers` — color `#FBBC04`
4. Style tab:
   - Chart type: **Smooth line** (or Area — matches screenshot 1.png where the area fill shows under the revenue line).
   - Enable **data labels**: off (too cluttered for 24 months).
   - Y-axis: left axis for Revenue, right axis for Orders (enable dual Y-axis).
   - Background: white.
5. Notes: Expect seasonal peaks Oct–Dec 2024 (peak $52.7M Dec 2024) and dips Jan–Mar.

---

### Bar Chart — Revenue by Country

Size: **~580 x 260 px**. Place bottom-left of the page.

1. Insert > Bar chart.
2. **Dimension:** `country`.
3. **Metric:** `order_revenue` — SUM.
4. Sort: **Metric descending** (largest bar at top).
5. Style tab:
   - Orientation: **Vertical bars** (column chart).
   - Bar color: `#4285F4`.
   - Show data labels: on.
   - Number of bars to show: 10.
6. Expected order: US ($120.6M), GB ($38.8M), CA ($27.2M), AU ($21M), DE ($20.5M).

---

## Step 6 — Page 2: "Customer Breakdown"

Click the **+** icon next to the page tab at the bottom to add a new page. Name it `Customer Breakdown`.

This page mirrors **screenshot 2.png**: horizontal stacked bar on the left, bar chart in the middle (by channel/churn), geo map on the right.

### Layout overview

```
[Stacked Bar: New vs Returning] | [Bar: Churn Risk]  | [Geo Map: Revenue by Country]
[Scorecard: New] [Scorecard: Ret]| [Pie: LTV Band]   | [Table: Country breakdown]
```

---

**Horizontal Stacked Bar — New vs Returning by Segment**

Size: ~400 x 300 px, left side of canvas.

1. Insert > Bar chart.
2. **Dimension:** `customer_segment`.
3. **Breakdown dimension:** `customer_type`.
4. **Metric:** `customer_id` — Count Distinct.
5. Style tab:
   - Orientation: **Horizontal bars**.
   - Stacking: **Stacked**.
   - Color for `New`: `#4285F4` (blue).
   - Color for `Returning`: `#34A853` (green).
   - Show data labels: on.
   - Legend position: top.
6. Sort: Metric descending.
7. Expected: Platinum bar is longest (~27K customers, nearly all Returning).

---

**Scorecard — New Customers (Page 2)**

Size: ~180 x 90 px, below the stacked bar, left.

1. Insert > Scorecard.
2. Metric: `COUNTIF(customer_type = 'New')` (reuse `New Customers Count` field).
3. Label: `New Customers`.
4. Comparison: Previous period.
5. Style: Blue accent border on left side (`#4285F4`, 4px).

**Scorecard — Returning Customers**

Size: ~180 x 90 px, beside the New Customers scorecard.

1. Insert > Scorecard.
2. Metric: Create inline field `COUNTIF(customer_type = 'Returning')`, name `Returning Customers Count`.
3. Label: `Returning Customers`.
4. Comparison: Previous period.
5. Style: Green accent border (`#34A853`, 4px).

---

**Bar Chart — Customers by Churn Risk**

Size: ~400 x 300 px, centre of canvas.

1. Insert > Bar chart.
2. **Dimension:** `churn_risk`.
3. **Metric:** `customer_id` — Count Distinct.
4. Sort: **Custom sort** — set dimension sort order manually:
   - Click the sort dropdown on the dimension, select **Custom**.
   - Order: `Active`, `Cooling`, `At Risk`, `Churned`.
5. Style tab:
   - Orientation: **Vertical bars**.
   - Individual bar colors (set each manually via "Color by dimension value"):
     - `Active` → `#34A853` (green)
     - `Cooling` → `#FBBC04` (amber)
     - `At Risk` → `#FF6D00` (deep orange)
     - `Churned` → `#EA4335` (red)
   - Show data labels: on.
6. Expected values: Active 64.9K, Cooling 13.7K, At Risk 9.8K, Churned 11.5K.

---

**Geo Map — Revenue by Country**

Size: ~500 x 300 px, right side of canvas.

1. Insert > Geo chart.
2. **Geo dimension:** `country` (should auto-detect as Country since semantic type was set).
3. **Metric:** `order_revenue` — SUM.
4. Style tab:
   - Map type: **World map** (or Regions if country codes need clarification).
   - Color scale: Single color gradient — light blue (`#E3F2FD`) to dark blue (`#1565C0`).
   - Background: transparent.
5. Note: `country` values are ISO 2-letter codes (US, GB, CA, AU, DE, IN, FR, BR, MX) — Looker Studio geo chart accepts these natively.

---

**Table — Country Revenue Breakdown**

Size: ~480 x 220 px, bottom-right, below the geo map.

1. Insert > Table.
2. **Dimensions:** `country`.
3. **Metrics (add 3):**
   - `order_revenue` — SUM — label `Revenue` — format Currency AUD.
   - `customer_id` — Count Distinct — label `Customers`.
   - `order_id` — Count — label `Orders`.
4. Sort: `Revenue` descending.
5. Style tab:
   - Row numbers: on.
   - Alternating row colors: `#FFFFFF` / `#F5F5F5`.
   - Header background: `#1A237E`, text white.
   - Rows per page: 10.

---

**Pie Chart — Customers by Lifetime Value Band**

Size: ~280 x 280 px, bottom-centre.

1. Insert > Pie chart.
2. **Dimension:** `lifetime_value_band`.
3. **Metric:** `customer_id` — Count Distinct.
4. Style tab:
   - Donut style: on (inner radius 40%).
   - Slice colors (assign in order):
     - `0-999` → `#CFD8DC`
     - `1000-4999` → `#90CAF9`
     - `5000-9999` → `#42A5F5`
     - `10000+` → `#1565C0`
   - Show labels: on (percentage + label).
5. Expected: `1000-4999` band largest (~37K customers).

---

## Step 7 — Page 3: "AI Retention Intelligence"

Click **+** to add page 3. Name it `AI Retention Intelligence`.

### Page Layout Map

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  AI Retention Intelligence — Powered by Gemini 2.5 Flash          [Header Bar]  │
├─────────────────────────────────────────────────────────────────────────────────┤
│  [Churn Risk ▼]  [Segment ▼]  [LTV Band ▼]                    [Filter Bar]     │
├───────────────────────┬───────────────────────┬────────────────────────────────┤
│  Revenue at Risk      │  AI Coverage %        │  Avg Rev / At-Risk Customer    │
│  (Scorecard)          │  (Scorecard)          │  (Scorecard)                   │
├───────────────────────┴───────────────────────┴────────────────────────────────┤
│  Segment × Churn Risk Heatmap (Pivot Table, 60%)  │  Strategy Donut (35%)      │
├───────────────────────────────────────────────────┴────────────────────────────┤
│  AI-Powered Customer Profiles — Action Required (Full-Width Table)             │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Step 7.1 — Add Data Sources

This page uses two data sources. Add both before building charts.

**Data Source A — `mart_executive_summary_enriched`**

1. Click **Resource → Manage added data sources → Add a data source**.
2. Select **BigQuery** → Project `vishal-sandpit-474523` → Dataset `ai` → Table `mart_executive_summary_enriched`.
3. Click **Connect → Add to report**. Rename it `DS: AI Executive Summary`.

**Data Source B — `customer_concierge`**

1. Repeat above. Dataset `ai` → Table `customer_concierge`.
2. Rename it `DS: Customer Concierge`.

### Step 7.2 — Page Header Bar

1. Insert → Rectangle. Position: X=0, Y=0. Size: **1280 × 50 px**. Fill: `#1A237E`. Border: none.
2. Insert → Text: `AI Retention Intelligence — Powered by Gemini 2.5 Flash`. Font: Google Sans, 16pt, Bold, White. Position: X=24, Y=12.

### Step 7.3 — Filter Bar

1. Insert → Rectangle. Position: X=0, Y=50. Size: **1280 × 50 px**. Fill: `#F5F5F5`. Border: 1px `#E0E0E0`.

**Filter Control 1 — Churn Risk** (X=16, Y=58, 240 × 32 px)
1. Insert → Filter control. Data source: `DS: AI Executive Summary`. Control field: `churn_risk`.
2. Default selection: `At Risk`, `Cooling`. Multi-select: ON.

**Filter Control 2 — Segment** (X=272, Y=58, 220 × 32 px)
1. Insert → Filter control. Control field: `customer_segment`. Default: All. Multi-select: ON.

**Filter Control 3 — LTV Band** (X=508, Y=58, 220 × 32 px)
1. Insert → Filter control. Control field: `lifetime_value_band`. Default: All.

### Step 7.4 — Scorecard Row (Y=110–210)

Three scorecards, each **300 × 100 px**, starting at X=100, spaced 40px apart.

**Scorecard 1 — Revenue at Risk** (X=100, Y=110)

1. Insert → Scorecard. Data source: `DS: AI Executive Summary`.
2. Create calculated field:
   - Name: `Revenue at Risk`
   - Formula: `SUM(CASE WHEN churn_risk IN ('Cooling', 'At Risk') THEN revenue_last_month ELSE 0 END)`
   - Type: Currency AUD. Save.
3. Style: Google Sans 28pt Bold, colour `#EA4335`. Label: `Revenue at Risk`.
4. Add text box below (X=100, Y=185): `Across Cooling + At Risk customers` — 10pt, grey italic.

**Scorecard 2 — AI Coverage %** (X=440, Y=110)

1. Insert → Scorecard. Data source: `DS: AI Executive Summary`.
2. Create calculated field:
   - Name: `AI Coverage %`
   - Formula: `COUNT(CASE WHEN ai_status = 'success' THEN customer_id END) / COUNT(customer_id)`
   - Type: Percent, 1 decimal. Save.
3. Style: Google Sans 28pt Bold. Conditional colour: > 90% = `#34A853`, 80–90% = `#FBBC04`, < 80% = `#EA4335`.
4. Label: `Customers with AI Insights`.

**Scorecard 3 — Avg Revenue / At-Risk Customer** (X=780, Y=110)

1. Insert → Scorecard. Data source: `DS: AI Executive Summary`.
2. Create calculated field:
   - Name: `Avg Rev / At-Risk Customer`
   - Formula: `SUM(CASE WHEN churn_risk = 'At Risk' THEN revenue_last_month ELSE 0 END) / COUNT(CASE WHEN churn_risk = 'At Risk' THEN customer_id END)`
   - Type: Currency AUD. Save.
3. Style: Google Sans 28pt Bold, colour `#1A237E`. Label: `Avg Revenue / At-Risk Customer`.

### Step 7.5 — Segment × Churn Risk Revenue Heatmap (Pivot Table)

> Looker Studio has no native heatmap. Use a Pivot Table with conditional formatting to simulate one.

1. Insert → **Pivot table**. Data source: `DS: AI Executive Summary`. Position: X=16, Y=220. Size: **620 × 280 px**.
2. Row dimension: `customer_segment`. Column dimension: `churn_risk`.
3. Metric 1: SUM `revenue_last_month` → rename `Revenue (Last Month)` → Currency AUD.
4. Metric 2: COUNT `customer_id` → rename `Customers`.
5. Add filter: `churn_risk` IN `At Risk, Cooling`.
6. Row sort: Custom — drag order to Platinum, Gold, Silver, Bronze.
7. Style tab:
   - Header: `#1A237E` background, white text.
   - Conditional formatting on `Revenue (Last Month)`: Color scale, Min `#FFFFFF` → Max `#B71C1C` (dark red), apply to Background.

### Step 7.6 — Gemini Strategy Type Donut

1. Add title text box (X=660, Y=220): `What strategies is Gemini recommending?` — Google Sans 13pt Bold navy.
2. Insert → **Pie chart**. Data source: `DS: Customer Concierge`. Position: X=656, Y=246. Size: **380 × 260 px**.
3. Create calculated field:
   - Name: `Strategy Category`
   - Formula:
     ```
     CASE
       WHEN REGEXP_MATCH(strategy, '(?i)offer|discount|voucher|promo') THEN 'Offer/Discount'
       WHEN REGEXP_MATCH(strategy, '(?i)re-engage|re-activation|lapsed|win.back|winback') THEN 'Win-back'
       WHEN REGEXP_MATCH(strategy, '(?i)loyal|reward|tier|vip|exclusive') THEN 'Loyalty Reward'
       WHEN REGEXP_MATCH(strategy, '(?i)product|recommend|suggest|upsell|cross') THEN 'Product Rec'
       ELSE 'Personalised Outreach'
     END
     ```
   - Save.
4. Dimension: `Strategy Category`. Metric: COUNT `customer_id`.
5. Style tab: Donut (hole size 45%), Legend RIGHT, Percentage labels ON.
6. Slice colours: Offer/Discount=`#4285F4`, Win-back=`#EA4335`, Loyalty Reward=`#34A853`, Product Rec=`#FBBC04`, Personalised Outreach=`#9E9E9E`.

### Step 7.7 — AI Persona Spotlight Table

1. Add title text box (X=16, Y=516): `AI-Powered Customer Profiles — Action Required` — Google Sans 14pt Bold navy.
2. Insert → **Table**. Data source: `DS: AI Executive Summary`. Position: X=16, Y=540. Size: **1248 × 340 px**.
3. Dimensions: `customer_id`, `customer_segment`, `churn_risk`, `lifetime_value_band`, `top_category`, `gemini_insight`.
4. Metrics:
   - SUM `revenue_this_month` → `Rev This Month` → Currency AUD.
   - SUM `revenue_last_month` → `Rev Last Month` → Currency AUD.
   - SUM `orders_this_month` → `Orders This Month`.
   - Calculated metric: `Revenue Trend` = `revenue_this_month - revenue_last_month` → Currency AUD.
5. Sort: `revenue_last_month` Descending.
6. Filters: `churn_risk` IN `At Risk, Cooling` AND `ai_status` = `success`.
7. Style tab:
   - Rows per page: 25. Header: `#1A237E` navy, white text.
   - Column widths: `gemini_insight` = **380px**, Wrap text ON, min row height 80px.
   - Conditional formatting `churn_risk`: `At Risk` → background `#FFCCBC`, `Cooling` → `#FFF9C4`.
   - Conditional formatting `Revenue Trend`: < 0 → text `#EA4335` red, > 0 → text `#34A853` green.

---

---

# DASHBOARD 2 — CPO: Product Performance & Upsell

**Persona:** Chief Product Officer
**Source table:** `vishal-sandpit-474523.gold.rpt_cpo_dashboard`
**Row grain:** One row per order item (742K rows, 24-month window)

> **Important margin note:** `margin_pct` is stored as a percentage value (e.g., `49.8` not `0.498`). When formatting in Looker Studio, use **Number** type, not **Percent** type. Display as `49.8%` by appending a `%` suffix in the number format, or divide by 100 and use Percent type — choose one approach and be consistent.

## Step 1 — Create the Report

Open this URL:

```
https://lookerstudio.google.com/c/reporting/create?c.mode=CREATE&ds.connector=BIG_QUERY&ds.type=TABLE&ds.projectId=vishal-sandpit-474523&ds.datasetId=gold&ds.tableId=rpt_cpo_dashboard&r.reportName=Intelia+CPO+Dashboard
```

## Step 2 — Configure the Data Source

Verify field types:

| Field name | Expected type |
|---|---|
| order_item_id | Text |
| order_date | Date |
| year_month | Text |
| customer_id | Text |
| product_id | Text |
| product_name | Text |
| category | Text |
| sub_category | Text |
| brand | Text |
| units_sold | Number |
| unit_price | Number (Currency) |
| discount | Number (Percent) |
| item_revenue | Number (Currency) |
| margin_pct | Number (do NOT set as Percent — value is already %) |
| gemini_upsell_strategy | Text |
| upsell_status | Text |

## Step 3 — Add Calculated Fields

**Calculated field — Revenue Share %**

- Name: `Revenue Share %`
- Formula: `SUM(item_revenue) / SUM(SUM(item_revenue))`
- Format: Percent (1 decimal place)
- Note: This is a table-level percent-of-total. It will only work correctly inside a table or bar chart — not as a standalone scorecard.

## Step 4 — Add Date Range Control

Same as CCO: Insert > Date range control, top-right, default **Last 12 months**, dimension = `order_date`.

---

## Step 5 — Page 1: "Category Performance"

Rename the default page to `Category Performance`.

### Top Row — 4 Scorecards

Approx **260 x 90 px each**, evenly spaced across the top.

**Scorecard 1 — Total Product Revenue**
- Metric: `item_revenue` — SUM.
- Label: `Total Product Revenue`.
- Format: Currency AUD, 0 decimal places.
- Comparison: Previous period.
- Expected: ~$249M (24 months).

**Scorecard 2 — Units Sold**
- Metric: `units_sold` — SUM.
- Label: `Units Sold`.
- Comparison: Previous period.

**Scorecard 3 — Avg Unit Price**
- Metric: `unit_price` — Average.
- Label: `Avg Unit Price`.
- Format: Currency AUD, 2 decimal places.
- Comparison: Previous period.

**Scorecard 4 — Avg Margin %**
- Metric: `margin_pct` — Average.
- Label: `Avg Margin %`.
- Format: Number, 1 decimal place (append `%` suffix manually in format string: `#.#"%"`).
- Comparison: Previous period.
- Expected: ~49.9.

---

### Bar Chart — Revenue by Category

Size: ~520 x 280 px, left of centre.

1. Insert > Bar chart.
2. **Dimension:** `category`.
3. **Metric:** `item_revenue` — SUM.
4. Sort: Metric descending.
5. Style tab:
   - Orientation: **Vertical bars**.
   - Individual bar colors:
     - `Electronics` → `#1565C0`
     - `Sports` → `#2E7D32`
     - `Home & Garden` → `#F57F17`
     - `Clothing` → `#6A1B9A`
     - `Toys` → `#00838F`
     - `Books` → `#4E342E`
   - Show data labels: on.
6. Expected: Electronics $153.1M, Sports $28.1M, Home&Garden $22.7M, Clothing $20.1M.

---

### Stacked Area Time Series — Category Revenue Trend

Size: **Full width, ~260 px tall**. Place below the bar chart.

1. Insert > Time series chart.
2. **Dimension:** `order_date` — granularity: **Month**.
3. **Metric:** `item_revenue` — SUM.
4. **Breakdown dimension:** `category`.
5. Style tab:
   - Chart type: **Stacked area**.
   - Series colors: match the bar chart colors above (Electronics=`#1565C0`, etc.).
   - Show legend: on, position top.
6. Notes: Electronics dominates every month. Seasonal peak Oct–Dec visible.

---

### Bar Chart — Margin % by Category

Size: ~520 x 260 px, right of the Revenue by Category chart.

1. Insert > Bar chart.
2. **Dimension:** `category`.
3. **Metric:** `margin_pct` — Average.
4. Sort: Metric descending.
5. Style tab:
   - Orientation: **Vertical bars**.
   - Bar color: `#00897B` (teal — distinct from revenue charts).
   - Show data labels: on (format: 1 decimal place + `%`).
   - Y-axis range: 45 to 55 (to avoid the bars looking identical; zoom in on the variance).
6. Expected: All categories approx 49–51%; Toys highest ~50.9%.

---

## Step 6 — Page 2: "Product Leaderboard"

Click **+** to add page 2. Name it `Product Leaderboard`.

### Table — Top 20 Products by Revenue

Size: **Left half of canvas, ~600 x 500 px**.

1. Insert > Table.
2. **Dimensions (4):** `product_name`, `category`, `sub_category`, `brand`.
3. **Metrics (4):**
   - `item_revenue` — SUM — label `Revenue` — format Currency AUD.
   - `units_sold` — SUM — label `Units`.
   - `customer_id` — Count Distinct — label `Customers`.
   - `margin_pct` — Average — label `Margin %`.
4. Sort: `Revenue` descending.
5. Rows per page: 20.
6. Style tab:
   - Header: `#1A237E`, white text.
   - Alternating rows: `#FFFFFF` / `#E8EAF6`.
   - Heatmap on `Revenue` column: enable conditional formatting, gradient from white to `#1565C0`.

---

### Bar Chart — Revenue by Brand (Top 10)

Size: ~560 x 300 px, right side.

1. Insert > Bar chart.
2. **Dimension:** `brand`.
3. **Metric:** `item_revenue` — SUM.
4. Sort: Metric descending.
5. Rows to show: **10**.
6. Style tab:
   - Orientation: **Horizontal bars** (easier to read long brand names).
   - Bar color: `#4285F4`.
   - Show data labels: on.
7. Expected top brands: PulseGear $12.6M, EchoSphere $10.5M, VoltEdge $10M, ClearVision $9.3M, InfinityPro $9.1M.

---

### Bar Chart — Units Sold by Sub-Category (Top 15)

Size: ~560 x 300 px, below the brand chart.

1. Insert > Bar chart.
2. **Dimension:** `sub_category`.
3. **Metric:** `units_sold` — SUM.
4. Sort: Metric descending.
5. Rows to show: **15**.
6. Style tab:
   - Orientation: **Horizontal bars**.
   - Bar color: `#34A853`.
   - Show data labels: on.

---

## Step 7 — Page 3: "AI Upsell Intelligence"

Click **+** to add page 3. Name it `AI Upsell Intelligence`.

### Page Layout Map

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  AI Upsell Intelligence — Powered by Gemini 2.5 Flash              [Header Bar] │
├────────────────────────┬─────────────────────────────────┬──────────────────────┤
│  Upsell Coverage %     │  Revenue: AI-Tagged Products    │  Avg Margin %        │
├────────────────────────┴─────────────────────────────────┴──────────────────────┤
│  Strategy Type Donut (40%)  │  Category × Upsell Type Heatmap (Pivot, 55%)     │
├─────────────────────────────┴───────────────────────────────────────────────────┤
│  Products with AI Upsell Strategies — Enriched Table (Full Width)              │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Step 7.1 — Page Header Bar

1. Insert → Rectangle. Position: X=0, Y=0. Size: **1280 × 50 px**. Fill: `#1A237E`. Border: none.
2. Insert → Text: `AI Upsell Intelligence — Powered by Gemini 2.5 Flash`. Font: Google Sans, 16pt, Bold, White. Position: X=24, Y=12.

### Step 7.2 — Scorecard Row (Y=60–160)

Three scorecards, **300 × 100 px** each, starting at X=100, spaced 40px apart.

**Scorecard 1 — Upsell Coverage %** (X=100, Y=60)
- Calculated field: `COUNT(CASE WHEN upsell_status = 'success' THEN product_id END) / COUNT(product_id)` → Percent, 1 decimal.
- Label: `Products with AI Upsell`. Style: `#34A853` green.

**Scorecard 2 — Revenue from AI-Tagged Products** (X=440, Y=60)
- Calculated field: `SUM(CASE WHEN upsell_status = 'success' THEN item_revenue ELSE 0 END)` → Currency AUD.
- Label: `Revenue from AI-Tagged Products`. Style: `#1A237E` navy.

**Scorecard 3 — Avg Margin on AI Products** (X=780, Y=60)
- Calculated field: `AVG(CASE WHEN upsell_status = 'success' THEN margin_pct END)` → Percent, 1 decimal.
- Label: `Avg Margin % (AI Products)`. Style: `#34A853` green.

### Step 7.3 — Upsell Strategy Type Donut

1. Add title text box (X=16, Y=175): `How is Gemini structuring upsell recommendations?` — Google Sans 13pt Bold navy.
2. Insert → **Pie chart**. Data source: `DS: CPO Dashboard`. Position: X=16, Y=200. Size: **440 × 280 px**.
3. Create calculated field:
   - Name: `Upsell Type`
   - Formula:
     ```
     CASE
       WHEN REGEXP_MATCH(gemini_upsell_strategy, '(?i)bundle|pair|combin') THEN 'Bundle'
       WHEN REGEXP_MATCH(gemini_upsell_strategy, '(?i)premium|pro|deluxe|upgrade') THEN 'Premium Upgrade'
       WHEN REGEXP_MATCH(gemini_upsell_strategy, '(?i)accessory|add.on|complement') THEN 'Accessory Add-on'
       WHEN REGEXP_MATCH(gemini_upsell_strategy, '(?i)subscription|plan|renew') THEN 'Subscription'
       ELSE 'Cross-Category'
     END
     ```
   - Save.
4. Dimension: `Upsell Type`. Metric: COUNT `product_id`. Filter: `upsell_status` = `success`.
5. Style: Donut (45% hole), Legend RIGHT, Percentage labels ON.
6. Slice colours: Bundle=`#4285F4`, Premium Upgrade=`#EA4335`, Accessory Add-on=`#34A853`, Subscription=`#FBBC04`, Cross-Category=`#9E9E9E`.

### Step 7.4 — Category × Upsell Type Pivot (Heatmap)

1. Insert → **Pivot table**. Position: X=476, Y=200. Size: **788 × 280 px**.
2. Row dimension: `category`. Column dimension: `Upsell Type` (calculated field from Step 7.3).
3. Metric: COUNT `product_id` → rename `Products`. Filter: `upsell_status` = `success`.
4. Style: Header `#1A237E` navy. Conditional formatting on `Products`: Color scale White → `#1565C0` dark blue, apply to Background.

### Step 7.5 — Enriched Product Upsell Table

1. Add title text box (X=16, Y=496): `Products with AI Upsell Strategies` — Google Sans 14pt Bold navy.
2. Insert → **Table**. Position: X=16, Y=520. Size: **1248 × 360 px**.
3. Dimensions: `product_name`, `category`, `sub_category`, `brand`, `gemini_upsell_strategy`, `upsell_status`.
4. Metrics: SUM `item_revenue` → Currency AUD, SUM `units_sold`, AVG `margin_pct` → Percent 1dp.
5. Sort: `item_revenue` Descending. Filter: `upsell_status` = `success`. Rows per page: 50.
6. Style tab:
   - Header: `#1A237E` navy, white text.
   - `gemini_upsell_strategy` column: **380px wide**, Wrap text ON, min row height 60px.
   - Conditional formatting on `margin_pct`: Color scale White → `#34A853` green, apply to Background.

---

---

# DASHBOARD 3 — CTO: Pipeline Health & Data Quality

**Persona:** Chief Technology Officer
**Source table:** `vishal-sandpit-474523.governance.rpt_cto_dashboard`
**Row grain:** One row per pipeline run attempt (batch audit log)

> **Note on data availability:** `rpt_cto_dashboard` is populated by delta pipeline MERGE runs. If the table is empty during build, add a static text box: "Awaiting first delta pipeline run — data will populate automatically." The dashboard structure is built now regardless.

## Step 1 — Create the Report

Open this URL:

```
https://lookerstudio.google.com/c/reporting/create?c.mode=CREATE&ds.connector=BIG_QUERY&ds.type=TABLE&ds.projectId=vishal-sandpit-474523&ds.datasetId=governance&ds.tableId=rpt_cto_dashboard&r.reportName=Intelia+CTO+Dashboard
```

## Step 2 — Configure the Data Source

Verify field types:

| Field name | Expected type |
|---|---|
| run_date | Date |
| run_ts | Date & Time |
| entity | Text |
| status | Text |
| source_file | Text |
| rows_merged | Number |
| rows_inserted | Number |
| rows_updated | Number |
| error_message | Text |
| duration_secs | Number |

> Note: The YAML spec references `batch_id` in the Success Rate calculated field formula. If this column does not exist in the view, substitute `COUNT(run_ts)` or `COUNT(entity)` instead. Check in BigQuery: `SELECT column_name FROM vishal-sandpit-474523.governance.INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'rpt_cto_dashboard'`.

## Step 3 — Add Calculated Field

**Calculated field — Success Rate**

- Name: `Success Rate`
- Formula (if `batch_id` exists): `COUNTIF(status = 'SUCCESS') / COUNT(batch_id)`
- Formula (if `batch_id` does NOT exist): `COUNTIF(status = 'SUCCESS') / COUNT(run_ts)`
- Format: Percent (1 decimal place)

## Step 4 — Add Date Range Control

Insert > Date range control, top-right, default **Last 30 days**, dimension = `run_date`.

---

## Step 5 — Page 1: "Pipeline Overview"

Rename default page to `Pipeline Overview`.

### Top Row — 4 Scorecards

Approx **240 x 90 px each**.

**Scorecard 1 — Total Pipeline Runs**
- Metric: `run_ts` — Count (or `batch_id` — Count if it exists).
- Label: `Total Pipeline Runs`.
- Comparison: Previous period.

**Scorecard 2 — Success Rate**
- Metric: Select calculated field `Success Rate`.
- Label: `Success Rate`.
- Format: Percent, 1 decimal place.
- Comparison: Previous period.
- Style: Conditional color — if value < 95%, show label in red (`#EA4335`); if >= 95%, show in green (`#34A853`). (Set via scorecard "Comparison metric color" settings.)

**Scorecard 3 — Failed Runs**
- Metric: Inline calculated field `COUNTIF(status = 'FAILED')`, name `Failed Runs Count`.
- Label: `Failed Runs`.
- Comparison: Previous period.
- Style: Value color fixed to `#EA4335` (red) — set in Style tab > "Metric value color" > Custom.

**Scorecard 4 — Total Rows Merged**
- Metric: `rows_merged` — SUM.
- Label: `Total Rows Merged`.
- Format: Number, comma-separated.
- Comparison: Previous period.

---

### Pie Chart — Run Status Distribution

Size: ~280 x 280 px, left side, below scorecard row.

1. Insert > Pie chart.
2. **Dimension:** `status`.
3. **Metric:** `run_ts` — Count (or `batch_id` — Count).
4. Style tab:
   - Donut: on.
   - Slice colors (set per dimension value):
     - `SUCCESS` → `#34A853` (green)
     - `FAILED` → `#EA4335` (red)
     - `RUNNING` → `#FBBC04` (amber)
     - `SKIPPED` → `#9E9E9E` (grey, if present)
   - Show labels: on (value + percent).

---

### Stacked Bar Time Series — Pipeline Runs by Day and Status

Size: **~900 x 260 px**, right of pie chart and spanning across.

1. Insert > Time series chart.
2. **Dimension:** `run_date` — granularity: **Day**.
3. **Metric:** `run_ts` — Count.
4. **Breakdown dimension:** `status`.
5. Style tab:
   - Chart type: **Stacked bars**.
   - Colors: match pie chart (`SUCCESS`=green, `FAILED`=red, `RUNNING`=amber).
   - Show legend: on, top.
   - X-axis: auto-scale to date range control.

---

## Step 6 — Page 2: "Throughput & Latency"

Click **+** to add page 2. Name it `Throughput & Latency`.

### Bar Chart — Rows Merged by Entity

Size: ~520 x 280 px, top-left.

1. Insert > Bar chart.
2. **Dimension:** `entity`.
3. **Metric:** `rows_merged` — SUM.
4. Sort: Metric descending.
5. Style tab:
   - Orientation: **Vertical bars**.
   - Bar color: `#1565C0`.
   - Show data labels: on.
6. Expected entities: `customers`, `orders`, `order_items`, `products`.

---

### Line Chart — Avg Pipeline Duration (seconds)

Size: ~520 x 260 px, top-right.

1. Insert > Time series chart.
2. **Dimension:** `run_date` — granularity: **Day**.
3. **Metric:** `duration_secs` — Average.
4. Style tab:
   - Chart type: **Line** (smooth).
   - Line color: `#FF6D00` (orange — signals latency concern).
   - Add a **reference line**: value = `120`, label = `Alert threshold (120s)`, color = `#EA4335`, style = dashed.
     - To add: Style tab > Reference lines > Add reference line > Type: Constant > Value: 120.
   - Y-axis min: 0.
5. Note: Any spike above 120s indicates a performance issue requiring investigation.

---

### Table — Recent Pipeline Runs (Last 7 Days)

Size: **Full width, ~400 px tall**. Place below the two charts.

1. Insert > Table.
2. **Dimensions (4):**
   - `run_ts` — label `Run Time`.
   - `entity`
   - `status`
   - `source_file`
3. **Metrics (4):**
   - `rows_merged` — SUM.
   - `rows_inserted` — SUM.
   - `rows_updated` — SUM.
   - `duration_secs` — Average — label `Duration (s)`.
4. **Extra column:** Add `error_message` as a dimension (text column).
5. Sort: `run_ts` descending.
6. Add **filter**: `run_date` >= `DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)`.
   - In Looker Studio: chart filter > Add filter condition > `run_date` > Greater than or equal to > use the expression. Since Looker Studio filter UI does not support DATE_SUB directly, instead:
     - Leave this filter off and rely on the **date range control** (set to Last 7 days) to restrict the data.
     - Alternatively add a **page-level filter**: Resource > Manage filters > Add filter > `run_date` relative date > Last 7 days.
7. Rows per page: 50.
8. Style tab:
   - Header: `#1A237E`, white text.
   - Alternating rows: `#FFFFFF` / `#FAFAFA`.
   - Conditional formatting on `status`:
     - `SUCCESS` → text color `#2E7D32` (dark green).
     - `FAILED` → background `#FFEBEE`, text `#C62828` (red).
     - `RUNNING` → background `#FFF8E1` (amber tint).
   - Wrap text: on for `error_message` column (width ~300px).

---

---

# Final Steps — All Three Dashboards

## Add Report-Level Filters (Page Layout)

For each dashboard, add a **filter bar** at the top of every page:

1. Insert > Add a control > Drop-down list.
2. One control per key dimension, placed in a header strip (height ~50px, background `#1A237E`).
3. CCO filters: `country`, `customer_segment`, `churn_risk`.
4. CPO filters: `category`, `brand`, `upsell_status`.
5. CTO filters: `entity`, `status`.

## Add Navigation Between Pages

1. Insert > Image (use a simple text box instead if preferred).
2. Or use the **built-in page navigation**: View > Show page navigation (automatically adds page tabs visible to viewers).
3. Recommended: enable **left-side page navigation panel** via Report settings > Navigation > Left side panel.

## Set Report Sharing

1. Click **Share** (top-right).
2. Share with specific people: add stakeholders by email.
3. Set permission: **Viewer** for end users, **Editor** for the team building the dashboard.
4. Optionally: **Get link > Anyone with the link can view** for board-level distribution.

## Publish / Schedule Refresh

BigQuery-connected reports refresh on-demand (data is live). No scheduled refresh is needed. However:

1. Click **File > Report settings**.
2. Set **Data freshness**: For CCO/CPO, this is live BQ data — no cache needed. Set to **Always** (real-time) or leave default.
3. For CTO (pipeline audit), set a **data freshness** of 15 minutes if runs are frequent.

---

## Quick Troubleshooting Reference

| Symptom | Fix |
|---|---|
| "No data" on all charts | Check BQ table access: run `SELECT COUNT(*) FROM gold.rpt_cco_dashboard` in BQ console |
| Country not showing on geo map | Ensure `country` semantic type = Geo > Country in data source editor |
| `margin_pct` showing as 0.498 instead of 49.8 | Do NOT set field type to Percent — keep as Number; field already contains % value |
| Calculated field `Revenue Share %` shows error | Only works inside table/bar chart, not as standalone scorecard |
| `batch_id` field missing in CTO source | Replace `COUNT(batch_id)` with `COUNT(run_ts)` in Success Rate formula |
| Date range control not affecting a chart | Click the chart, Properties panel > Default date range > uncheck "custom date range" |
| Stacked bar shows only one color | Ensure breakdown dimension is set AND the field has more than one distinct value in the date range |
| Geo chart shows blank for some countries | Country codes must be ISO 3166-1 alpha-2 (e.g. `US` not `United States`) — already correct in source |

---

## Calculated Fields — Paste-Ready Reference

All formulas below are exact Looker Studio syntax. Paste directly into the "Add a field" formula box.

**CCO Dashboard:**
```
Repeat Rate:
COUNTIF(customer_type = 'Returning') / COUNT(order_id)

Revenue per Customer:
SUM(order_revenue) / COUNT_DISTINCT(customer_id)

New Customers Count:
COUNTIF(customer_type = 'New')

Returning Customers Count:
COUNTIF(customer_type = 'Returning')
```

**CPO Dashboard:**
```
Revenue Share %:
SUM(item_revenue) / SUM(SUM(item_revenue))
```

**CTO Dashboard (use whichever applies):**
```
Success Rate (with batch_id):
COUNTIF(status = 'SUCCESS') / COUNT(batch_id)

Success Rate (without batch_id):
COUNTIF(status = 'SUCCESS') / COUNT(run_ts)

Failed Runs Count:
COUNTIF(status = 'FAILED')
```

---

## Color Palette Summary

| Use | Hex |
|---|---|
| Primary blue | `#4285F4` |
| Success / positive | `#34A853` |
| Warning / amber | `#FBBC04` |
| Danger / negative | `#EA4335` |
| Deep orange (alert) | `#FF6D00` |
| Navy header | `#1A237E` |
| Electronics bar | `#1565C0` |
| Sports bar | `#2E7D32` |
| Home & Garden bar | `#F57F17` |
| Clothing bar | `#6A1B9A` |
| Toys bar | `#00838F` |
| Canvas background | `#F8F9FA` |
| Card background | `#FFFFFF` |
| Table alt row | `#F5F5F5` |

---

---

---

# CONVERSATIONAL ANALYTICS BOT — Setup Guide

Three options for adding a natural-language query interface to these dashboards. **Option A is recommended** — zero infrastructure, works today.

---

## Option A: BigQuery Data Agent (Recommended)

A Gemini-powered conversational interface built directly into BigQuery Studio. No additional infrastructure required.

### A.1 — Enable

1. Open [console.cloud.google.com](https://console.cloud.google.com). Confirm project = `vishal-sandpit-474523`.
2. Navigate to **BigQuery → BigQuery Studio**.
3. Click the **Gemini sparkle icon** (top-right toolbar) or look for the **"Ask Gemini"** panel on the right side.
4. If prompted, click **Enable Gemini for Google Cloud API** → Enable.
5. If Gemini is disabled at the org level: **IAM & Admin → Organization Policies** → confirm `constraints/gcp.disableGemini` is not TRUE. Contact your org admin if needed.

### A.2 — Connect to Project Datasets

The agent automatically accesses tables the authenticated user can read. Verify in the **Explorer** panel that `gold` and `ai` datasets are visible under `vishal-sandpit-474523`. If not:
1. Click **+ Add** in Explorer → pin `vishal-sandpit-474523`.
2. Grant viewer access: **BigQuery → Datasets → [dataset] → Sharing → Permissions** → add user with `BigQuery Data Viewer`.

### A.3 — Add Table Descriptions (Improves Answer Quality)

Open each table in BigQuery Studio → click the description pencil icon → paste:

**`gold.rpt_cco_dashboard`:**
```
Order-grain customer churn and revenue table. Each row = one order.
Fields: customer_id, customer_segment (Bronze/Silver/Gold/Platinum),
churn_risk (Active/Cooling/At Risk/Churned), lifetime_value_band,
order_revenue (AUD), order_date, country (ISO 2-letter), customer_type.
Use for revenue analysis, churn distribution, segment breakdowns.
```

**`ai.mart_executive_summary_enriched`:**
```
Customer-grain AI enrichment. One row per customer. Contains
gemini_insight (Gemini-generated text), ai_status ('success' or error),
revenue_this_month and revenue_last_month, churn_risk, customer_segment,
top_category, orders_this_month/last_month. Use for AI retention analysis.
```

**`ai.customer_concierge`:**
```
Customer-grain Gemini persona and strategy. One row per customer.
Fields: persona (customer archetype), strategy (recommended action),
generated_at, generation_status. Use for personalised strategy lookup.
```

**`gold.rpt_cpo_dashboard`:**
```
Order-item-grain product performance. One row per order line.
Fields: product_name, category, sub_category, brand, units_sold,
unit_price, item_revenue (AUD), margin_pct (decimal: 0.35 = 35%),
gemini_upsell_strategy (Gemini text), upsell_status.
```

### A.4 — Test Questions

Paste each into the Gemini chat panel in BigQuery Studio:

1. `How many customers are At Risk or Cooling, broken down by customer_segment?`
2. `What is total revenue_last_month for Cooling and At Risk customers in mart_executive_summary_enriched?`
3. `Show top 5 Platinum customers at risk by revenue_last_month with their gemini_insight.`
4. `What percentage of customers have ai_status = 'success'?`
5. `Which category has the highest avg margin_pct in rpt_cpo_dashboard?`
6. `Show top 10 products by item_revenue where upsell_status is success with their gemini_upsell_strategy.`

### A.5 — Share with Dashboard Users

1. Grant users `roles/bigquery.user` on project `vishal-sandpit-474523` (**IAM & Admin → IAM → Grant Access**).
2. Share this URL: `https://console.cloud.google.com/bigquery?project=vishal-sandpit-474523`
3. Instruct users: open URL → look for the Gemini sparkle icon in BigQuery Studio toolbar.

---

## Option B: Looker Studio Gemini Integration (Built-in, No Setup)

### B.1 — Enable

1. Open your CCO or CPO report in **Edit mode**.
2. Click **File → Report settings** → scroll to **Gemini** → toggle **"Enable Gemini features"** ON → Save.
3. Switch to **View mode**. An **"Ask a question"** input bar appears at the top of each page.

> If the toggle is not visible, your Google Workspace admin must enable **Gemini for Google Workspace** for your domain.

### B.2 — How It Works

- Viewers type a natural-language question. Gemini queries the **data source on the current page** and returns a temporary chart.
- Click **"Add to report"** on any result to pin it permanently (requires Edit mode).

### B.3 — Recommended Setup

Enable on **CCO Page 3 (AI Retention Intelligence)** first — `mart_executive_summary_enriched` has the richest field set (churn_risk, segment, revenue, gemini_insight) and answers the most common executive questions.

### B.4 — Limitations

| Limitation | Detail |
|---|---|
| Page-scoped only | Cannot query data from other pages or dashboards |
| No cross-page context | No awareness of other pages when answering |
| No report-level calculated fields | Cannot use your custom `Revenue at Risk` or `Strategy Category` fields |
| Text field answers may be truncated | `gemini_insight` / `strategy` fields may not render fully in chart form |

### B.5 — Sample Prompts (on CCO Page 3)

- `How many At Risk customers are in each segment?`
- `What is total revenue_last_month for Platinum customers where ai_status is success?`
- `Show average revenue_this_month by customer_segment as a bar chart`
- `Which top_category has the most At Risk customers?`
- `Compare orders_this_month vs orders_last_month by churn_risk`

---

## Option C: Vertex AI Agent Builder (Advanced — Full Custom Bot)

A fully hosted conversational agent grounded in your BigQuery data. Requires GCP configuration. Embedding in Looker Studio requires **Looker Studio Pro**.

### C.1 — Create Data Stores

1. GCP Console → **Vertex AI → Agent Builder** → **Create Data Store**.
2. Source: **BigQuery**. Add each table separately:
   - `vishal-sandpit-474523.gold.rpt_cco_dashboard`
   - `vishal-sandpit-474523.ai.mart_executive_summary_enriched`
   - `vishal-sandpit-474523.ai.customer_concierge`
   - `vishal-sandpit-474523.gold.rpt_cpo_dashboard`
3. For each: paste the table description from Option A, Step A.3. Set sync: **Daily**.
4. Group all four under one Data Store named `intelia-biz-in-a-box`.

### C.2 — Deploy Agent

1. **Agent Builder → Create App** → type: **Search and conversation**. Name: `Intelia Analytics Assistant`. Region: `australia-southeast1`.
2. Select `intelia-biz-in-a-box` as the data store.
3. In the **Agent** tab → **System instructions**, paste:
   ```
   You are an analytics assistant for Intelia Business-in-a-Box.
   Revenue is always in AUD. When asked about "at risk" customers, include
   both 'Cooling' and 'At Risk' churn_risk values. margin_pct is a decimal
   (0.35 = 35%). upsell_status and ai_status = 'success' means Gemini
   processed that record successfully.
   ```
4. Click **Preview** to test. Copy the **Public URL** from the Integration tab.

### C.3 — Embed in Looker Studio (Pro Only)

1. Edit mode → **Insert → URL Embed**. Paste the agent URL.
2. Size: **400 × 500 px**, positioned right side of any dashboard page.
3. Add text label above: `Ask Gemini About This Data` — Google Sans 13pt Bold navy.

**Without Pro licence:** Add the agent URL as a hyperlink text box instead — `Open AI Analytics Assistant →` in `#4285F4` blue.

---

## Pre-Built Question Library

Use these to test your bot and share as a "starter pack" with executives.

### CCO — Retention and Revenue

1. `How many customers are At Risk or Cooling, and what revenue do they represent from last month?`
2. `Break down At Risk customers by segment — Platinum, Gold, Silver, Bronze.`
3. `Which segment has the highest average revenue among At Risk customers?`
4. `What percentage of customers have a successful Gemini AI insight?`
5. `Show the top 5 Platinum customers at risk by revenue_last_month with their gemini_insight.`

### CPO — Product and Upsell

6. `What percentage of products have a successful AI upsell strategy?`
7. `Which categories have the most AI upsell strategies assigned?`
8. `What is avg margin_pct for products where upsell_status is success?`
9. `Which brand has the highest item_revenue among AI-tagged products?`
10. `Top 10 products by item_revenue with a Gemini upsell strategy and their strategy text.`

### CTO / Data Quality

11. `How many customers in mart_executive_summary_enriched have ai_status not equal to success?`
12. `What is the most recent generated_at in customer_concierge?`
13. `How many products have upsell_status = success vs all other statuses?`
14. `Are there customer_ids in mart_executive_summary_enriched that do not appear in customer_concierge?`
15. `What is the distribution of generation_status values in customer_concierge?`

> **Tip**: Be specific with field names (say `revenue_last_month` not "revenue") and always specify the segment or time period. The more precise the question, the more accurate the result.

---

*Build guide updated 2026-04-03. AI pages and Conversational Bot section added.*
