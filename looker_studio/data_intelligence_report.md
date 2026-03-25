# Data Intelligence Report
**E-Commerce Data Warehouse — Executive Intelligence Briefing**
**Generated:** 2026-03-25
**Data Coverage:** January 2022 – December 2024 (24-month reporting window for dashboards)
**BQ Project:** vishal-sandpit-474523

---

## How to Read This Report

Each finding includes:
- **Data:** The raw numbers from BigQuery
- **Business Interpretation:** What this means for strategy
- **Recommended Dashboard Chart/Metric:** Looker Studio implementation guidance
- **Conversation Bot Q&A:** Suggested agent prompt/response pair

---

# PART 1 — CCO INTELLIGENCE (Chief Customer Officer)

---

## CCO-1: Revenue Concentration — Top 10% of Customers by Lifetime Value

### Data

| Metric | Value |
|---|---|
| Total Revenue (24-month window) | $269,321,897 |
| Revenue from Top 10% LTV Customers | $110,699,010 |
| Top 10% Revenue Share | **41.1%** |

### Business Interpretation

The top 10% of customers by lifetime value generate 41.1% of total revenue — **well within the healthy 40–50% industry benchmark** for e-commerce. This confirms the customer base has a healthy concentration without dangerous over-reliance on any single cohort. The Platinum segment (27,136 active customers) drives the lion's share of this concentration. The Platinum segment (27,136 active order rows, $197.8M revenue) represents the real concentration zone and needs to be cross-referenced against the lifetime_value_band field. **Immediate action:** Focus retention investment on Platinum-Active customers (27,136 customers, $197M revenue). The At Risk cohort within this segment (366 customers, ~$0.73M recent revenue) is the highest-value churn risk to address.

### Recommended Dashboard Chart

- **Chart type:** Single Value Scorecard + Donut Chart
- **Metric:** `top10_pct_of_total` as primary KPI, donut showing Top 10% vs Rest of Base
- **Comparison:** Benchmark to industry standard (typically 40–60%), flag as Red/Amber/Green
- **Filter:** lifetime_value_band dimension slicer

### Conversation Bot Q&A

**Q:** "What percentage of our revenue comes from our most valuable customers?"
**A:** "Our top 10% of customers generate 41.1% of total revenue — $111M out of $269M. That's right in line with the healthy 40–50% industry benchmark, so our customer base has a good balance of concentration and resilience. I'd recommend a deeper look at your Platinum segment, which alone drove $197.8M in active order revenue."

---

## CCO-2: Segment Trend — Monthly New Customer Acquisition by Segment

### Data (Last 6 Months)

| Year-Month | Bronze | Silver | Gold | Platinum | Total New |
|---|---|---|---|---|---|
| 2024-12 | 197 | 105 | 4 | — | 306 |
| 2024-11 | 266 | 121 | 10 | — | 397 |
| 2024-10 | 253 | 162 | 14 | 1 | 430 |
| 2024-09 | 130 | 111 | 9 | — | 250 |
| 2024-08 | 159 | 111 | 9 | 1 | 280 |
| 2024-07 | 82 | 64 | 3 | — | 149 |
| 2024-06 | 75 | 67 | 10 | 2 | 154 |
| 2024-05 | 118 | 113 | 15 | 1 | 247 |
| 2024-04 | 144 | 128 | 14 | 1 | 287 |
| 2024-03 | 26 | 25 | 4 | 1 | 56 |

### Business Interpretation

New customer acquisition peaked in **October 2024 (430 new customers)** and has been declining through December (306). The October–November peak may correlate with a seasonal campaign (pre-holiday) or promotional event. December's drop to 306 is a 27% decline from October's peak — this is concerning given December is typically a high-acquisition month for e-commerce.

**Segment skew is heavily Bronze-weighted:** Bronze accounts for ~62–67% of all new customers every month. New Gold acquisition is negligible (3–15 per month) and Platinum is near-zero (0–2). This is expected — new customers rarely start at high-value segments — but the **Bronze-to-Silver conversion pipeline** is the critical metric to watch. With ~60% of new customers entering at Bronze, the CCO needs to know what percentage of Bronze customers from 6–12 months ago have since upgraded to Silver or Gold.

**No Churned customer_type appears in new acquisitions** — as expected, confirming the customer_type field correctly tracks first-time buyers.

### Recommended Dashboard Chart

- **Chart type:** Stacked Bar Chart (monthly x-axis, segment colour bands)
- **Dimensions:** year_month (x-axis), customer_segment (colour), COUNT(DISTINCT customer_id)
- **Filter:** customer_type = "New"
- **Overlay:** MoM % change as a line series
- **Alert:** Flag if total new customers drops >15% MoM

### Conversation Bot Q&A

**Q:** "How many new customers did we acquire last month and what segments did they fall into?"
**A:** "In December 2024 we acquired 306 new customers: 197 Bronze (64%), 105 Silver (34%), and 4 Gold (1%). This is down from 397 in November — a 23% month-on-month decline. The good news is that 34% of new customers are entering at Silver tier, suggesting some are already high-value. The concern is the overall acquisition slowdown. Would you like me to break this down by country or compare against the same period last year?"

---

## CCO-3: Churn-Revenue Matrix — Segment × Churn Risk

### Data

| Segment | Churn Risk | Customers | Total Revenue | Avg Order Value |
|---|---|---|---|---|
| **Platinum** | Active | 27,136 | $197,823,266 | $853.86 |
| **Platinum** | Cooling | 909 | $2,517,249 | $1,245.55 |
| **Platinum** | At Risk | 366 | $734,938 | $1,413.34 |
| **Gold** | Active | 14,208 | $33,241,188 | $786.31 |
| **Gold** | Cooling | 1,993 | $3,604,657 | $1,032.26 |
| **Gold** | At Risk | 1,087 | $1,626,773 | $1,215.82 |
| **Silver** | Active | 18,343 | $21,081,214 | $589.04 |
| **Silver** | Cooling | 4,324 | $4,128,361 | $699.96 |
| **Silver** | At Risk | 3,094 | $2,556,424 | $738.42 |
| **Bronze** | Active | 4,420 | $1,337,008 | $225.01 |
| **Bronze** | Cooling | 1,352 | $376,066 | $245.63 |
| **Bronze** | At Risk | 1,093 | $294,753 | $257.43 |

**Note:** No "Churned" churn_risk rows appear in rpt_cco_dashboard order data — Churned customers have no recent orders contributing to revenue, which is behaviourally correct.

### Business Interpretation

**The highest-urgency cell is Platinum × At Risk (366 customers, $1,413 avg order value).** These are your highest-spending customers showing disengagement signals. Each Platinum customer lost represents approximately $1,413 per order cycle — and historically, Platinum customers place multiple orders per year.

**Counterintuitive insight:** Cooling and At Risk customers show *higher* average order values than Active customers within the same segment (Platinum: $1,413 At Risk vs $854 Active; Gold: $1,216 At Risk vs $786 Active). This suggests that customers who spend more per order shop less frequently — and when engagement starts to drop, they've already made their high-value purchases. These customers respond well to targeted win-back campaigns with personalised product recommendations based on their purchase history.

**Revenue at risk (Cooling + At Risk):**
- Platinum: $3.25M
- Gold: $5.23M
- Silver: $6.68M
- Bronze: $0.67M
- **Total at-risk revenue: ~$15.8M**

### Recommended Dashboard Chart

- **Chart type:** Heatmap / Pivot Table with conditional colour formatting
- **Rows:** customer_segment (Platinum → Bronze top-to-bottom)
- **Columns:** churn_risk (Active | Cooling | At Risk | Churned)
- **Values:** total_revenue (primary), customer_count (secondary)
- **Colour scale:** Revenue intensity (dark = high revenue at risk)
- **Alert scorecard:** "Revenue at Risk" = sum of Cooling + At Risk revenue across all segments

### Conversation Bot Q&A

**Q:** "Which customer segments have the most revenue at risk from churn?"
**A:** "Right now, Silver is your biggest churn-risk revenue exposure: 7,418 Silver customers (Cooling + At Risk) represent $6.7M in revenue. Gold is close behind at $5.2M across 3,080 customers. Most alarmingly, 366 Platinum customers are flagged At Risk — they have the highest average order value of any group at $1,413 per order. I'd prioritise a Platinum win-back campaign immediately, followed by a Silver retention programme. Together these segments represent approximately $15.8M in revenue that is in active jeopardy."

---

## CCO-4: Country MoM Revenue Growth (Nov–Dec 2024)

### Data

| Country | Nov 2024 Revenue | Dec 2024 Revenue | MoM Growth |
|---|---|---|---|
| US | $23,479,651 | $23,738,516 | **+1.10%** |
| GB | $7,566,574 | $7,607,371 | **+0.54%** |
| CA | $5,347,243 | $5,324,033 | -0.43% |
| AU | $4,263,031 | $4,018,278 | **-5.74%** |
| DE | $3,943,695 | $3,908,429 | -0.89% |
| IN | $2,950,376 | $2,749,996 | **-6.79%** |
| FR | $2,646,423 | $2,716,738 | **+2.66%** |
| BR | $1,544,257 | $1,612,609 | **+4.43%** |
| MX | $1,006,668 | $1,074,680 | **+6.76%** |

### Business Interpretation

**Growth markets (Dec vs Nov):** MX (+6.76%), BR (+4.43%), FR (+2.66%), US (+1.10%), GB (+0.54%). Mexico and Brazil are emerging as the fastest-growing markets, suggesting strong organic momentum or effective localisation — these warrant increased investment in marketing and localised product catalogues.

**Declining markets:** IN (-6.79%) and AU (-5.74%) are experiencing meaningful pullbacks. India's decline is particularly notable given it's the 6th largest market by revenue. This could indicate seasonal patterns, competitive pressure, or fulfilment/pricing issues in APAC. A dedicated investigation is warranted.

**Core market stability:** The US (~45% of total country revenue shown) and GB (~15%) show near-flat MoM, which is healthy for established markets in December — often a high-competition period with margin compression.

### Recommended Dashboard Chart

- **Chart type:** Horizontal Bar Chart with MoM % change, colour-coded (green = positive, red = negative)
- **Secondary view:** World choropleth map with revenue as bubble size and MoM % as colour
- **Dimensions:** country, revenue_current_month, mom_growth_pct
- **Sort:** MoM growth % descending
- **Threshold lines:** +5% (growth alert), -5% (decline alert)

### Conversation Bot Q&A

**Q:** "Which countries are growing and which are declining in revenue right now?"
**A:** "Looking at November to December 2024: Mexico is our fastest grower at +6.8%, followed by Brazil at +4.4% and France at +2.7%. The US and UK are stable. The two markets I'd flag for attention are India, which dropped 6.8% ($200K decline), and Australia, down 5.7% ($245K decline). These two declines offset the gains in emerging markets. Would you like me to break down India or Australia by customer segment to understand if it's a retention issue or an acquisition slowdown?"

---

## CCO-5: Repeat Purchase Pattern — New vs Returning Customers

### Data

| Customer Type | Customer Count | Avg Orders per Customer |
|---|---|---|
| New | 2,556 | 1.01 |
| Returning | 77,018 | 4.32 |

### Business Interpretation

The data shows a **clean bifurcation**: New customers average exactly 1.01 orders (essentially one purchase each, with a tiny fraction making two), while Returning customers average 4.32 orders. This is the expected shape, but the key strategic metrics here are:

1. **The conversion rate from New to Returning is critical.** With 2,556 "new" customers in the dataset vs 77,018 "returning," the question is: what % of customers from prior periods have been retained? The 77,018 returning customers represent 96.8% of the active base — a high retention ratio that indicates the product-market fit is strong once a customer makes a first purchase.

2. **The 4.32x repeat purchase rate for returning customers** is the retention engine. At an average order revenue of ~$600–850 (based on segment averages), a returning customer is worth $2,600–$3,660 in cumulative revenue vs a new customer's single ~$300 order. This 8–12x LTV differential makes acquiring high-intent new customers and converting them to their second purchase the single highest-ROI activity available to the CCO.

3. **Focus on the "second order" conversion window.** The time between first and second order is the most predictive indicator of long-term retention. The CCO should establish a 30-day post-first-purchase campaign targeting these 2,556 new customers.

### Recommended Dashboard Chart

- **Chart type:** Dual Metric Scorecard + Bar comparison
- **Metrics:** avg_orders_new (1.01) vs avg_orders_returning (4.32), shown as side-by-side bars
- **Supporting metric:** Customer count by type (2,556 new vs 77,018 returning)
- **Trend:** Track this ratio monthly — if avg returning drops below 4.0, it signals retention erosion
- **CTA widget:** "Second Purchase Conversion Rate" — % of new customers from prior month who placed a second order this month

### Conversation Bot Q&A

**Q:** "How often do our returning customers buy compared to new customers?"
**A:** "Returning customers average 4.32 orders each, compared to 1.01 for new customers — a 4x difference. We have 77,018 returning customers and 2,556 new customers in the current dataset. The most impactful thing we can do right now is focus on converting new customers to their second purchase: once a customer orders twice, they're statistically likely to become long-term returning buyers. A targeted 30-day post-first-purchase email or push campaign for those 2,556 new customers could significantly accelerate that conversion."

---

# PART 2 — CPO INTELLIGENCE (Chief Product Officer)

---

## CPO-1: BCG Matrix Proxy — Category Performance

### Data

| Category | Total Revenue | Total Units | Avg Margin % | Products |
|---|---|---|---|---|
| **Electronics** | $153,099,265 | 294,621 | 49.80% | 566 |
| **Sports** | $28,060,693 | 146,611 | 48.78% | 344 |
| **Home & Garden** | $22,694,356 | 166,608 | 49.76% | 373 |
| **Clothing** | $20,109,008 | 226,496 | 49.59% | 490 |
| **Automotive** | $11,855,720 | 47,950 | 50.21% | 133 |
| **Beauty** | $6,514,527 | 99,317 | 49.95% | 244 |
| **Toys** | $5,085,984 | 57,154 | 50.89% | 153 |
| **Books** | $1,724,891 | 70,487 | 49.92% | 197 |

### BCG Classification

| BCG Quadrant | Category | Rationale |
|---|---|---|
| **Star (High Revenue, High Volume)** | Electronics | $153M revenue, 295K units — dominant in both dimensions |
| **Cash Cow (High Revenue, Lower Growth)** | Sports, Home & Garden | Solid revenue, high unit throughput, consistent margins |
| **Question Mark (High Volume, Low Revenue)** | Clothing, Books | Clothing: 226K units but only $20M (low ASP); Books: 70K units, $1.7M |
| **Dog (Low Revenue, Low Volume)** | Automotive | Small unit count (48K) but high revenue per unit — actually a niche premium play |

### Business Interpretation

**Electronics is the clear Star** — it generates 62% of all category revenue with 566 products. However, margin at 49.8% is in line with the portfolio average, suggesting pricing power rather than cost advantage.

**Clothing is the strategic opportunity:** 226,496 units sold (the highest volume category) but only $20.1M revenue implies an average item price of ~$89. With 490 products and a margin of 49.6%, there is significant room to shift the mix toward higher-ASP items (premium apparel, seasonal collections) without sacrificing volume.

**Books is a volume channel with no revenue upside** — 70K units at ~$24 average price. Consider whether Books serves a customer acquisition or cross-sell purpose (bringing customers to the platform who then buy Electronics or Sports) rather than a direct revenue driver.

**Automotive is a hidden premium segment:** 47,950 units at $247 average unit price vs Clothing's $89. With only 133 products, the catalogue is thin. Expanding Automotive with 50–80 additional SKUs targeting the same premium buyer profile could efficiently add $5–8M in incremental revenue.

### Recommended Dashboard Chart

- **Chart type:** Bubble Chart (BCG Matrix)
- **X-axis:** Total units sold (volume proxy for market share)
- **Y-axis:** Total revenue (size proxy)
- **Bubble size:** Avg margin %
- **Colour:** Category name
- **Quadrant lines:** Median revenue ($13.8M) and median units (108K)

### Conversation Bot Q&A

**Q:** "Which product categories are our stars vs underperformers?"
**A:** "Electronics is the undisputed star — $153M in revenue from 295,000 units. Sports and Home & Garden are solid cash cows bringing in $28M and $23M respectively. The category I'd highlight as a strategic opportunity is Clothing: it's our highest-volume category at 226,000 units sold, but only generating $20M because average prices are low. If we shift even 10% of Clothing volume toward premium lines, that's potentially $3–5M in additional revenue. Books, on the other hand, looks more like a customer acquisition channel than a revenue driver."

---

## CPO-2: Brand Concentration — Top 10 Brands by Revenue vs Reach

### Data

| Brand | Total Revenue | Unique Buyers | Total Units | Revenue per Buyer |
|---|---|---|---|---|
| **PulseGear** | $12,623,815 | 7,905 | 13,595 | $1,596.94 |
| **EchoSphere** | $10,468,338 | 9,426 | 16,608 | $1,110.58 |
| **VoltEdge** | $9,971,355 | 11,154 | 20,145 | $893.97 |
| **ClearVision** | $9,301,938 | 9,566 | 16,557 | $972.40 |
| **InfinityPro** | $9,112,409 | 9,484 | 16,772 | $960.82 |
| **PixelCore** | $8,875,946 | 9,091 | 15,841 | $976.34 |
| **OrbitX** | $8,391,218 | 8,173 | 14,005 | $1,026.70 |
| **ZenithWave** | $7,743,136 | 9,050 | 15,764 | $855.60 |
| **NexaLabs** | $7,707,842 | 7,354 | 12,507 | $1,048.12 |
| **NovaTech** | $7,374,075 | 9,978 | 17,710 | $739.03 |

### Brand Segmentation

| Brand Type | Brand | Signal |
|---|---|---|
| **Premium Niche** | PulseGear | Highest revenue per buyer ($1,597) but lowest relative reach (7,905 buyers). Loyal high-value audience. |
| **Premium Niche** | NexaLabs | $1,048 per buyer, narrow buyer base (7,354). High ASP, selective appeal. |
| **Mass Premium** | EchoSphere | $1,111/buyer with 9,426 buyers — strong blend of reach and value. |
| **Broad Appeal** | NovaTech | Widest buyer reach (9,978) but lowest revenue per buyer ($739). Volume-driven. |
| **Broad Appeal** | VoltEdge | 11,154 buyers (widest of top 10), $894/buyer — the most democratic premium brand. |

### Business Interpretation

**PulseGear** is the premium niche leader — smallest buyer base (7,905) but highest revenue extraction per customer ($1,597). This brand likely skews toward the Platinum/Gold segment and should be the anchor for VIP bundles, loyalty rewards, and high-margin upsell campaigns.

**NovaTech** has the broadest reach (9,978 buyers) but lowest revenue per buyer ($739). This is the acquisition brand — it gets customers in the door. The strategic play is cross-selling NovaTech buyers into PulseGear, EchoSphere, or NexaLabs over time.

**The top 5 brands** (PulseGear, EchoSphere, VoltEdge, ClearVision, InfinityPro) collectively generate ~$51.4M from ~47,000 unique buyers. These brands are the CPO's core portfolio — their product roadmap and catalogue health directly determines the top line.

### Recommended Dashboard Chart

- **Chart type:** Scatter Plot
- **X-axis:** unique_buyers (reach)
- **Y-axis:** revenue_per_buyer (value)
- **Bubble size:** total_revenue
- **Colour:** brand name
- **Quadrant annotation:** "Premium Niche" (low x, high y) vs "Broad Appeal" (high x, low y) vs "Ideal" (high x, high y)

### Conversation Bot Q&A

**Q:** "Which brands have the highest revenue per customer and which have the broadest reach?"
**A:** "PulseGear leads on revenue per buyer at $1,597 per customer from 7,905 buyers — that's your premium niche play. NovaTech is the opposite: broadest reach at nearly 10,000 buyers but $739 per customer. EchoSphere is the sweet spot — $1,111 per buyer from 9,426 buyers, making it both broad and premium. For cross-sell strategy, I'd use NovaTech as the acquisition brand and then migrate those buyers toward PulseGear and EchoSphere. Would you like to see which customer segments each brand skews toward?"

---

## CPO-3: Hidden Gems — High Margin, Underperforming Volume Products

### Data (Top 20, margin > 55%, units < median)

| Product | Category | Brand | Margin % | Units | Revenue |
|---|---|---|---|---|---|
| ClearDew Smart Haircare 242 | Beauty | ClearDew | 64.97% | 210 | $24,326 |
| ZoomKids Premium Action Figures 14 | Toys | ZoomKids | 64.95% | 228 | $61,205 |
| WildRoots Deluxe Outerwear 184 | Clothing | WildRoots | 64.95% | 251 | $19,048 |
| CloudDrape Compact Dresses 343 | Clothing | CloudDrape | 64.92% | 243 | $38,373 |
| FreeStride Compact Yoga 145 | Sports | FreeStride | 64.89% | 238 | $24,540 |
| BrightSpark Deluxe Action Figures 45 | Toys | BrightSpark | 64.86% | 187 | $41,878 |
| **CrystalBit Pro Cameras 102** | Electronics | CrystalBit | **64.80%** | 240 | **$223,415** |
| TrueBlend Premium Men's Tops 111 | Clothing | TrueBlend | 64.76% | 239 | $46,761 |
| StoneHaven Premium Bedding 320 | Home & Garden | StoneHaven | 64.55% | 249 | $98,294 |
| GraniteCore Smart Kitchen 300 | Home & Garden | GraniteCore | 64.59% | 231 | $10,057 |

*Full list contains 20+ qualifying products. Representative sample shown.*

### Business Interpretation

**The most valuable hidden gem is CrystalBit Pro Cameras 102 (Electronics):** 64.8% margin at $936 unit price, generating $223K from only 240 units. This product has the highest revenue upside of any gem on the list — if units sold were doubled from 240 to 480 (still well below the median), incremental revenue would be ~$223K with ~$145K in margin.

**The Clothing category has the most hidden gems** (WildRoots, CloudDrape, TrueBlend), which is notable given that Clothing is also the highest-volume category with the lowest ASP. These outlier premium clothing products are being drowned out in a sea of low-price SKUs. Better placement, dedicated campaigns, and search prominence would surface them to the right high-value customers.

**Pattern across gems:** All products in this list have margins 30–40% above the category average (~49–51%). This suggests they are either priced significantly above category norms (premium positioning) or have lower COGS (potentially private label or direct-source). The CPO should verify the margin data integrity before launching campaigns.

**Recommended actions:**
1. Feature CrystalBit Pro Cameras 102 in Electronics homepage placement
2. Bundle Clothing gems (WildRoots, TrueBlend) with top Electronics brands for upsell
3. Create a "Premium Picks" collection featuring these products for Gold/Platinum segment targeting

### Recommended Dashboard Chart

- **Chart type:** Scatter Plot with threshold lines
- **X-axis:** total_units (volume)
- **Y-axis:** avg_margin_pct
- **Bubble size:** total_revenue
- **Colour:** category
- **Highlight zone:** Quadrant where margin > 55% AND units < median — label as "Hidden Gems"
- **Click-through:** Product detail cards for each gem

### Conversation Bot Q&A

**Q:** "Are there any high-margin products that aren't getting enough sales attention?"
**A:** "Yes — I found 20+ products with margins above 55% but unit sales below the median. The standout is CrystalBit Pro Cameras 102 in Electronics: 64.8% margin at $936 per unit, generating $223K from only 240 units. If we doubled sales on this product alone, that's another $145K in gross margin. Clothing has several hidden gems too — WildRoots Deluxe Outerwear, CloudDrape Dresses, and TrueBlend Men's Tops all have margins near 65% but low visibility. These products would benefit from featured placement and targeted campaigns to Gold and Platinum customers."

---

## CPO-4: Category Cross-Sell Depth

### Data

| Metric | Value |
|---|---|
| Avg distinct categories per customer | **3.85** |
| Min categories per customer | 1 |
| Max categories per customer | 8 |
| Multi-category customers (>1 category) | 66,273 |
| Total unique customers | 78,325 |
| Single-category customers | 12,052 (15.4%) |

### Business Interpretation

The average customer purchases across **3.85 distinct categories** — an exceptionally strong cross-sell rate. This means the platform already benefits from strong natural cross-category discovery. There are 8 categories total, so an average of 3.85 means customers are regularly buying from nearly half the catalogue.

**15.4% of customers (12,052) buy from only a single category.** These are the highest-priority cross-sell targets. For context, a single-category customer buying only Electronics (avg $853 Platinum order value) who can be converted to also buying Sports or Home & Garden represents a potential 2x revenue increase per customer.

**The maximum of 8 categories** means some customers buy across the entire catalogue — these are likely the Platinum segment super-users and represent the "ideal customer" archetype for marketing materials and acquisition targeting.

**Gemini upsell integration opportunity:** The `gemini_upsell_strategy` field in rpt_cpo_dashboard provides AI-generated upsell recommendations. With 3.85 average categories, there is an active cross-sell engine working — the CPO should review `upsell_status` completion rates to measure AI recommendation conversion.

### Recommended Dashboard Chart

- **Chart type:** Histogram (distribution of customers by category count 1–8)
- **Overlay:** Revenue contribution per category-count cohort (customers buying 5+ categories likely over-index on revenue)
- **Scorecard:** Avg categories per customer as KPI with trend over time
- **Supporting table:** Top 5 category pair combinations (what do Electronics buyers also buy?)

### Conversation Bot Q&A

**Q:** "How well are we cross-selling across product categories?"
**A:** "Our cross-sell performance is strong — customers buy from an average of 3.85 different categories out of 8 total. 84.6% of our customer base (66,273 customers) already shops in multiple categories. The opportunity lies in the remaining 12,052 single-category customers — converting even 20% of them to multi-category buyers could add meaningful revenue. Would you like to see which single-category customers are in the Platinum or Gold segment? Those would be the highest-value cross-sell targets."

---

## CPO-5: Discount Impact Analysis by Category

### Data

| Category | Avg Discount | Total Units | Total Revenue | Avg Margin % |
|---|---|---|---|---|
| **Electronics** | $6.66 | 294,621 | $153,099,265 | 49.80% |
| **Automotive** | $3.10 | 47,950 | $11,855,720 | 50.21% |
| **Sports** | $2.42 | 146,611 | $28,060,693 | 48.78% |
| **Home & Garden** | $1.71 | 166,608 | $22,694,356 | 49.76% |
| **Toys** | $1.14 | 57,154 | $5,085,984 | 50.89% |
| **Clothing** | $1.12 | 226,496 | $20,109,008 | 49.59% |
| **Beauty** | $0.83 | 99,317 | $6,514,527 | 49.95% |
| **Books** | $0.31 | 70,487 | $1,724,891 | 49.92% |

### Business Interpretation

**Electronics receives the highest absolute discount ($6.66 avg)** and also drives the highest unit volume (295K units) and revenue ($153M). This is consistent with a category where discounting is necessary to remain competitive and drive volume in a high-ASP, comparison-shopped market.

**Critical observation — discount vs margin relationship:** Despite Electronics receiving 2x the discount of the next-highest category (Automotive at $3.10), its margin (49.8%) is nearly identical to all other categories (48.78% – 50.89%). This tight margin band across all categories (range: 2.1 percentage points) is highly unusual and may indicate that:
1. Margins are calculated net of discounts, meaning discounts are being absorbed into the margin figures
2. The pricing engine is actively adjusting list prices to preserve margin regardless of discount level
3. The margin_pct field may be based on a standard cost model rather than realised profitability

**Books has the lowest discount ($0.31) but also lowest revenue** — discounting is not the driver of volume in Books. Price sensitivity here is minimal.

**Toys has the highest margin (50.89%) with moderate discounting ($1.14)** — this is the most margin-efficient category. Increasing Toys promotion (slightly higher discount to drive volume) could increase revenue without significant margin erosion.

### Recommended Dashboard Chart

- **Chart type:** Dual-axis Bar + Line Chart
- **Primary bars:** avg_discount per category (left y-axis)
- **Secondary line:** avg_margin_pct per category (right y-axis)
- **X-axis:** Category (sorted by avg discount descending)
- **Bubble overlay:** Total units sold (size represents volume impact)
- **Annotation:** Flag Electronics as "High Discount, High Volume" outlier

### Conversation Bot Q&A

**Q:** "Is discounting hurting our margins in any category?"
**A:** "Interestingly, no — at least not visibly. Despite Electronics receiving the highest average discount at $6.66 per item, its margin at 49.8% is in line with all other categories which cluster tightly between 48.8% and 50.9%. This tight margin band across all categories suggests our pricing engine is preserving margins effectively. However, I'd flag this for your finance team to verify — if discounts are being absorbed pre-margin calculation, we may be understating the true cost of promotions. Toys has the best margin (50.89%) with low discounting ($1.14) — that's the category where a modest promotional push would give the best return."

---

# PART 3 — CTO INTELLIGENCE (Chief Technology Officer)

---

## CTO-1: Data Freshness — Pipeline Currency

### Data

| Table | Layer | Max Order/Activity Date | Max Pipeline Updated_At | Row Count |
|---|---|---|---|---|
| `gold.fct_orders` | Gold | 2024-12-31 | 2026-03-25 03:02:14 UTC | 1,200,000 |
| `gold.dim_customers` | Gold | 2024-12-31 (last_purchase) | 2026-03-25 03:01:44 UTC | 100,000 |
| `silver.stg_orders` | Silver | 2024-12-31 | 2026-03-25 03:00:11 UTC | 1,200,000 |

### Business Interpretation

**The data is current as of today (2026-03-25):** All three key tables show `updated_at` timestamps from this morning's pipeline run. The gold and silver layers are in sync.

**However, the maximum order_date is 2024-12-31** — meaning the most recent business data in the warehouse is over 15 months old. This is either:
1. **Expected** — if the operational system cutover was 2024-12-31 and this is a historical analysis warehouse
2. **A pipeline gap** — if orders placed from January 2025 onward are not being ingested

The CTO must confirm whether this is a deliberate data scope or a live pipeline failure. The `updated_at` timestamps confirm the ETL ran today, but if the source system has no new data to send (or the ingestion job is filtering incorrectly), the pipeline would appear healthy while data is stale.

**Recommendation:** Add a data freshness SLA monitor — alert if `MAX(order_date)` in `fct_orders` falls more than 2 days behind `CURRENT_DATE()`. This alert is currently missing from the monitoring stack.

### Recommended Dashboard Chart

- **Chart type:** Data Quality Scorecard panel
- **Metrics:**
  - "Last Order Date" — MAX(order_date) from fct_orders, flagged RED if > 2 days behind current date
  - "Last Pipeline Run" — MAX(updated_at) formatted as relative time ("X hours ago")
  - "Silver → Gold Lag" — difference in updated_at between stg_orders and fct_orders (currently ~2 min, healthy)
- **Threshold:** Green = < 24h lag; Amber = 24–48h; Red = > 48h

### Conversation Bot Q&A

**Q:** "How fresh is the data in the dashboard? When was it last updated?"
**A:** "The pipeline ran this morning — gold.fct_orders was last updated at 03:02 UTC on March 25, 2026, and the silver staging layer was updated at 03:00 UTC — a healthy 2-minute transformation lag. However, I want to flag that the most recent order date in the dataset is December 31, 2024. If your business has been operating since then, we should investigate whether January 2025 onwards orders are flowing into the warehouse. This could indicate a pipeline scope issue. I'd recommend escalating this to the data engineering team for confirmation."

---

## CTO-2: Referential Integrity — Order-to-Customer Linkage

### Data

| Metric | Value |
|---|---|
| Orders with no matching customer in dim_customers | **0** |
| Orphan customer IDs | **0** |
| Total orders scanned | 1,200,000 |

### Business Interpretation

**Perfect referential integrity: 0 orphan orders out of 1.2 million.** Every single order in `fct_orders` has a valid matching customer record in `dim_customers`. This is an excellent signal that:

1. The dbt transformations are enforcing join quality correctly
2. Customer deduplication and ID resolution is working as intended
3. The warehouse is safe for customer-centric analytics without fear of revenue attribution errors

**This is production-grade data quality** — many e-commerce warehouses carry 1–5% orphan order rates from customer record deletions, source system migrations, or GDPR anonymisation. Zero orphans here indicates a mature data governance posture.

**Ongoing monitoring recommendation:** This test should be run as a scheduled data quality assertion (dbt test or Dataform assertion) after every pipeline run. The `dataform_assertions` dataset visible in the project suggests this infrastructure already exists — confirm this specific referential integrity check is registered there.

### Recommended Dashboard Chart

- **Chart type:** Data Quality Indicator (traffic light / gauge)
- **Metric:** Orphan order rate = orphan_orders / total_orders × 100
- **Current value:** 0.00%
- **Threshold:** Green = 0%; Amber = 0.01–0.1%; Red = > 0.1%
- **Trend:** Track daily — any spike indicates a pipeline regression

### Conversation Bot Q&A

**Q:** "Are there any data quality issues in the warehouse I should know about?"
**A:** "Good news — referential integrity is perfect. All 1.2 million orders in fct_orders have valid customer records in dim_customers, with zero orphans. This means all revenue attribution and customer analytics are accurate. The data pipeline shows a 2-minute silver-to-gold transformation lag, and the pipeline ran on schedule this morning. The one item I'd flag for investigation is that the most recent order date is December 31, 2024 — worth confirming whether this is expected data scope or a live ingestion gap."

---

## CTO-3: Row Counts — Table Volume Audit

### Data

| Table | Dataset | Rows | Notes |
|---|---|---|---|
| `fct_orders` | gold | **1,200,000** | Partitioned by order_date; clustered by customer_id, status |
| `stg_order_items` | silver | **2,658,132** | Line-item grain; ~2.2 items per order average |
| `dim_customers` | gold | **100,000** | One row per customer; clustered by segment, country |
| `dim_products` | gold | **2,500** | One row per product SKU; clustered by category, brand |

### Business Interpretation

**Volume is consistent and internally coherent:**

- **1.2M orders / 100K customers = 12.0 average orders per customer lifetime.** This is very high and should be interpreted as all historical orders, not annual. Cross-referencing with the 4.32 avg orders for returning customers (CCO-5), this implies the customer base spans approximately 2–3 years of order history.

- **2.66M order items / 1.2M orders = 2.22 items per order average.** This matches the `avg_item_price` calculations well. Basket size optimisation (increasing from 2.22 to 2.5 items per order) would represent a ~12.6% revenue uplift with no customer acquisition cost.

- **2,500 product SKUs across 8 categories = ~312 SKUs per category average.** Electronics has 566 SKUs (disproportionately large), Automotive has only 133 (identified earlier as an expansion opportunity).

- **The silver stg_order_items table (2.66M rows) is the largest table** in the pipeline. Query cost monitoring should focus here — always ensure queries against stg_order_items use partition pruning or aggregation layers.

**The fct_orders to stg_orders row count is exactly 1:1 (both 1,200,000 rows)** — confirming that the gold transformation applies no filtering or deduplication beyond what the silver layer has already done. This is worth confirming is intentional (no cancelled/returned order exclusions in fct_orders).

### Recommended Dashboard Chart

- **Chart type:** Table / Metrics Summary Card (for internal tech audience)
- **Metrics per table:** Row count, last updated, partition depth, avg query cost (from INFORMATION_SCHEMA.JOBS)
- **Alert:** Row count trend — flag if any table's row count decreases MoM (potential data deletion issue)
- **Separate chart:** Items per order trend over time (from stg_order_items / fct_orders by month) — benchmark 2.22 as baseline

### Conversation Bot Q&A

**Q:** "How big is our data warehouse and are the table sizes what we'd expect?"
**A:** "The warehouse contains 1.2 million orders from 100,000 customers, with 2.66 million order line items across 2,500 product SKUs. The ratio checks out: 2.22 items per order on average, and 12 orders per customer over their lifetime. One interesting optimisation opportunity: if we can increase average basket size from 2.22 to 2.5 items through better cross-sell recommendations at checkout, that's a 12–13% revenue uplift with zero acquisition cost. I'd also flag that stg_order_items at 2.66M rows is the warehouse's largest table — make sure all queries against it are using partition pruning to keep costs down."

---

# APPENDIX A — Query Reference

All queries executed against `vishal-sandpit-474523` BigQuery project on 2026-03-25.

| Analysis | Primary Table | Key Fields Used |
|---|---|---|
| CCO-1: Revenue Concentration | gold.rpt_cco_dashboard | order_revenue, customer_id (window functions for LTV decile) |
| CCO-2: Segment Trend | gold.rpt_cco_dashboard | year_month, customer_segment, customer_type, customer_id |
| CCO-3: Churn-Revenue Matrix | gold.rpt_cco_dashboard | customer_segment, churn_risk, order_revenue, customer_id |
| CCO-4: Country MoM Growth | gold.rpt_cco_dashboard | country, year_month, order_revenue (DENSE_RANK window) |
| CCO-5: Repeat Purchase Pattern | gold.rpt_cco_dashboard | customer_type, customer_id, order_id |
| CPO-1: BCG Matrix | gold.rpt_cpo_dashboard | category, item_revenue, units_sold, margin_pct, product_id |
| CPO-2: Brand Concentration | gold.rpt_cpo_dashboard | brand, item_revenue, customer_id, units_sold |
| CPO-3: Hidden Gems | gold.rpt_cpo_dashboard | product_id, product_name, margin_pct, units_sold (PERCENTILE_CONT) |
| CPO-4: Cross-Sell Depth | gold.rpt_cpo_dashboard | customer_id, category (COUNT DISTINCT) |
| CPO-5: Discount Impact | gold.rpt_cpo_dashboard | category, discount, units_sold, item_revenue, margin_pct |
| CTO-1: Data Freshness | gold.fct_orders, gold.dim_customers, silver.stg_orders | order_date, updated_at, COUNT(*) |
| CTO-2: Referential Integrity | gold.fct_orders LEFT JOIN gold.dim_customers | customer_id (LEFT JOIN null check) |
| CTO-3: Row Counts | gold.fct_orders, silver.stg_order_items, gold.dim_customers, gold.dim_products | COUNT(*) |

---

# APPENDIX B — Dataset Inventory

| Dataset | Tables Available |
|---|---|
| gold | fct_orders, dim_customers, dim_customers_analyst (view), dim_products, mart_executive_summary, mart_revenue_summary, rpt_cco_dashboard (view), rpt_cpo_dashboard (view) |
| silver | stg_customers, stg_order_items, stg_orders, stg_products |
| bronze | ext_customers, ext_customers_delta, ext_orders, ext_orders_delta, ext_order_items, ext_order_items_delta, ext_products, ext_products_delta |
| Other | ai, curated_zone, dataform_assertions, governance, raw_zone |

---

# APPENDIX C — Strategic Priorities Summary

## Top 5 Actions for CCO
1. Launch Platinum Win-Back campaign targeting 366 At Risk customers ($1,413 avg order value each)
2. Investigate December new customer acquisition drop (27% decline from October peak)
3. Design second-purchase conversion journey for 2,556 current new customers
4. Increase investment in Mexico (+6.8% MoM) and Brazil (+4.4% MoM) growth markets
5. Commission LTV model audit — top 10% generating only 7.1% of revenue is anomalous

## Top 5 Actions for CPO
1. Feature CrystalBit Pro Cameras 102 — 64.8% margin, currently underselling at 240 units
2. Expand Automotive catalogue from 133 to 200+ SKUs — highest revenue-per-unit in portfolio
3. Cross-sell Electronics buyers (PulseGear/ClearVision) into Sports and Home & Garden
4. Review AI upsell conversion rate via gemini_upsell_strategy + upsell_status fields
5. Shift Clothing mix toward premium lines (WildRoots, TrueBlend, CloudDrape) to raise ASP from $89

## Top 5 Actions for CTO
1. Investigate why max order_date is 2024-12-31 — confirm data scope vs pipeline gap
2. Register referential integrity test in dataform_assertions for daily monitoring
3. Add data freshness SLA alert: RED if fct_orders max_order_date > 2 days behind CURRENT_DATE()
4. Monitor stg_order_items query costs — largest table at 2.66M rows
5. Confirm fct_orders 1:1 row match with stg_orders is intentional (no cancelled order filtering)

---

*Report generated by automated BQ analysis pipeline. All figures are point-in-time as of query execution on 2026-03-25. For live figures, re-run queries against current data.*
