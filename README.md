# 📦 OLIST Seller Promise Analytics
### End-to-End SQL Analytics Project | E-Commerce Delivery Intelligence

![SQL](https://img.shields.io/badge/SQL-PostgreSQL-blue?logo=postgresql)
![Python](https://img.shields.io/badge/Python-pandas%20%7C%20seaborn-green?logo=python)
[![Tableau](https://img.shields.io/badge/Tableau-Dashboard-orange?logo=tableau)](https://public.tableau.com/views/OLIST-Seller-Promise-Analytics/OLISTSellerPromiseAnalytics?:language=en-GB&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)
![Status](https://img.shields.io/badge/Status-Active-brightgreen)
![Blocks](https://img.shields.io/badge/Blocks-SP1--SP6-purple)

---

## 🧩 The Business Problem

E-commerce platforms live and die by one promise: **deliver on time, every time.**

When a seller lists a product online and commits to a delivery window, that promise becomes a contract with the customer. Breaking it — even once — erodes trust, tanks review scores, and increases churn. The challenge isn't just getting products from A to B. It's about building a system where:

- Sellers set **realistic delivery promises** they can consistently keep
- Incentive programs **reward genuine performance**, not gaming
- Platform economics remain **healthy** as order volumes scale
- Customer satisfaction is **predictable and improvable**

### 🌍 Who Faces This Problem?

This is not a hypothetical challenge. It is a live operational problem for some of the largest e-commerce and logistics platforms in the world:

| Company | Country | The Problem |
|---|---|---|
| **BOL.com** | Netherlands | Seller delivery promise accuracy across 50,000+ seller partners |
| **Bol.com PLF Team** | Netherlands | Product Lifecycle Fulfilment — managing seller delivery windows at scale |
| **Zalando** | Germany / Netherlands | Seller SLA compliance across fashion categories |
| **Coolblue** | Netherlands | Last-mile delivery promise for electronics |
| **Flipkart** | India | Seller partner on-time fulfilment across 1M+ sellers |
| **Meesho** | India | Tier-2 and Tier-3 city delivery promise accuracy |
| **Amazon India** | India | Fulfilment promise integrity for third-party marketplace sellers |
| **Nykaa** | India | Beauty and wellness seller delivery SLA management |

The common thread: **all these platforms need to answer the same questions** — Are our sellers delivering on time? Are our incentive programs working? Where is our revenue concentrated? Which sellers are gaming the system?

This project answers all of those questions — using real e-commerce data.

---

## 🗄️ Why OLIST?

To practice solving these real-world business problems, I needed a dataset that mirrors actual e-commerce operations — with sellers, orders, reviews, products, and payments all linked together.

**OLIST** is a Brazilian e-commerce marketplace that connects small businesses to major retail channels. Their public dataset on Kaggle is one of the richest open-source e-commerce datasets available, containing:

- **100,000+ real orders** from 2016 to 2018
- **Multiple linked tables** covering the full order lifecycle
- **Seller and customer geography** across Brazil
- **Review scores, payment data, and product categories**

It is the closest publicly available approximation to what platforms like BOL.com, Flipkart, and Zalando work with internally — making it the ideal sandbox for practicing delivery analytics, seller performance analysis, and e-commerce business intelligence.

---

## 📊 Dataset Structure

The OLIST dataset contains **9 tables** stored in the `kaggle` schema of a PostgreSQL database (`olist_db`):

| Table | Description | Key Columns |
|---|---|---|
| `olist_orders` | Master order table | `order_id`, `order_status`, `order_delivered_customer_date`, `order_estimated_delivery_date` |
| `olist_order_items` | Line items per order | `order_id`, `seller_id`, `product_id`, `price`, `freight_value` |
| `olist_order_reviews` | Customer review scores | `order_id`, `review_score`, `review_creation_date` |
| `olist_products` | Product catalogue | `product_id`, `product_category_name` |
| `olist_sellers` | Seller master data | `seller_id`, `seller_city`, `seller_state` |
| `olist_customers` | Customer master data | `customer_id`, `customer_city`, `customer_state` |
| `olist_geolocation` | Geographic coordinates | `geolocation_zip_code_prefix`, `geolocation_lat`, `geolocation_lng` |
| `olist_order_payments` | Payment transactions | `order_id`, `payment_type`, `payment_value` |
| `product_category_translation` | Category name mapping | `product_category_name`, `product_category_name_english` |

### 🧪 Synthetic Table — `olist_seller_promise`

To simulate a real platform incentive program, I created a **synthetic table** that does not exist in the original Kaggle dataset. This table models the kind of seller promise and incentive data that platforms like BOL.com's PLF team would maintain internally:

```sql
kaggle.olist_seller_promise (
    seller_id,                  -- links to olist_sellers
    promise_change_date,        -- date seller changed their delivery promise
    promise_days_before,        -- delivery days promised before change
    promise_days_after,         -- delivery days promised after change
    treatment_group,            -- 'control' or 'treated' for A/B test
    incentive_tier,             -- 'Gold', 'Silver', or 'Bronze'
    incentive_earned,           -- BOOLEAN: did seller earn the incentive?
    freight_subsidy_pct,        -- % freight subsidy received
    target_on_time_pct          -- platform target for on-time delivery
)
-- 3,095 rows — one per seller
```

This synthetic table is the backbone of the entire project, enabling analysis of incentive gaming, promise change impact, diff-in-diff A/B testing, and seller financial risk.

---

## 👤 Business Context — Lars Visser, PLF Product Manager

Throughout this project, all analysis is framed around a fictional but realistic stakeholder: **Lars Visser**, Product Manager for the PLF (Product Lifecycle Fulfilment) team.

Lars asks product-level questions and needs:
- Business impact framing — not just data readouts
- Root cause explanations behind the numbers
- Concrete recommendations with next steps
- Awareness of data limitations
- OKR-level thinking

Every block ends with a stakeholder message written to Lars, translating SQL findings into actionable product insights.

---

## 🗂️ Project Blocks

| Block | Focus Area | Key Question | Core Finding |
|---|---|---|---|
| **SP1** | Seller Delivery Baseline | Does incentive tier predict on-time delivery? | Tier structure does NOT differentiate delivery performance |
| **SP2** | Time-Based Revenue Analysis | What are the revenue trends and seasonality patterns? | Nov 2017 Black Friday cascade caused Feb-Mar 2018 platform-wide SLA collapse |
| **SP3** | Promise Change Impact | Does tightening delivery promises improve performance? | Aggressive tightening (4-5 days) consistently worsens on-time rate; DiD = -3.02pp |
| **SP4** | Gaming Detection | Are sellers earning incentives they don't deserve? | 0% on-time sellers receiving freight subsidies; incentive eligibility logic is broken |
| **SP5** | Customer Feedback & Returns | What drives customer review scores? | Early delivery scores 4.29 vs on-time 4.04 — customers reward beating expectations |
| **SP6** | Financial Analytics | Where is platform revenue concentrated and at risk? | Top 20% of sellers drive 82.29% of revenue; freight >90% of revenue for worst sellers |

---

## 📈 Project Status

| Component | Status | Details |
|---|---|---|
| **SQL Analysis** | ✅ Complete | 6 blocks · SP1 to SP6 · 18 queries across delivery, gaming, revenue and satisfaction analysis |
| **Tableau Dashboard** | ✅ Complete | 5 dashboard pages · Tableau Story published on Tableau Public |
| **Python Visualizations** | 🔄 In Progress | Data visualizations for all SP blocks using pandas · matplotlib · seaborn |

---

## 🛠️ SQL Concepts Applied

| Concept | Status | Block |
|---|---|---|
| Window functions — LAG, LEAD | ✅ Done | SP1 Q2, SP2 Q1 |
| PARTITION BY 2 columns | ✅ Done | SP1 Q2 |
| Fan-out fix — DISTINCT order_id, seller_id | ✅ Done | Throughout |
| NULLIF safe division | ✅ Done | Throughout |
| DATE_TRUNC for time grouping | ✅ Done | SP2 Q1-Q4 |
| MAX(date) not CURRENT_DATE for historical data | ✅ Done | SP2, SP3, SP5 |
| 7-day and 30-day rolling averages | ✅ Done | SP2 Q3 |
| Seasonality analysis | ✅ Done | SP2 Q4 |
| FILTER(WHERE) for conditional aggregation | ✅ Done | SP3 Q1-Q3 |
| Before/after period comparison | ✅ Done | SP3 Q1 |
| Diff-in-Diff A/B test simulation | ✅ Done | SP3 Q3 |
| Right-censoring identification | ✅ Done | SP2 Q3 |
| Gaming detection pattern | ✅ Done | SP4 Q1-Q3 |
| INTERVAL date arithmetic | ✅ Done | SP5 Q2 |
| Delivery outcome bucketing | ✅ Done | SP5 Q1 |
| LIKE for partial string matching | ✅ Done | SP5 Q3 |
| Freight efficiency classification | ✅ Done | SP1 Q3, SP6 Q1 |
| Pareto / cumulative revenue | ✅ Done | SP6 Q2 |
| SUM() OVER() for platform total | ✅ Done | SP6 Q2 |
| ROWS BETWEEN UNBOUNDED PRECEDING | ✅ Done | SP2 Q3, SP6 Q2 |

---

## 🔑 Key Findings

1. **Incentive tiers don't work** — Gold, Silver and Bronze sellers perform almost identically on delivery. The worst performers exist across all tiers. The tier structure needs a complete redesign tied to actual delivery outcomes.

2. **Promise tightening has a ceiling** — Diff-in-Diff analysis shows treated sellers underperformed control by 3.02pp after aggressive promise changes. Capping changes at 1-2 days per intervention is recommended before full rollout.

3. **Gaming is systematic** — Sellers with 0% on-time delivery rate are earning `incentive_earned = TRUE` and collecting freight subsidies. Some have zero delivered orders. The eligibility logic is broken at the source.

4. **Early delivery is the secret weapon** — Customers give 4.29 stars for early delivery vs 4.04 for on-time delivery. A buffer day strategy — setting conservative promises and arriving early — is the highest ROI satisfaction lever available.

5. **Revenue concentration is dangerous** — Top 20% of sellers drive 82.29% of platform revenue. Losing these sellers would collapse the platform. A structured key account retention program is urgent.

6. **Freight is destroying unit economics** — The worst sellers have freight costs exceeding 89% of revenue. Low average order value products (under $20) cannot support the fixed cost of fulfilment. A minimum order value threshold for new seller onboarding is recommended.

---

## ⚙️ Tools & Stack

| Tool | Purpose |
|---|---|
| **PostgreSQL** | Primary database — all SQL analysis |
| **DataGrip** | SQL IDE — query development and execution |
| **Python** (pandas, seaborn, matplotlib) | Data visualisation |
| **Tableau Public** | Interactive dashboard |
| **GitHub** | Version control and portfolio publishing |

---

## 📊 Interactive Dashboard

[![Tableau](https://img.shields.io/badge/View%20Dashboard-Tableau%20Public-orange?logo=tableau)](https://public.tableau.com/views/OLIST-Seller-Promise-Analytics/OLISTSellerPromiseAnalytics?:language=en-GB&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

5 dashboard pages covering Platform Health, Promise Change Impact, Gaming Audit, Revenue Risk and Customer Satisfaction — built as a Tableau Story.

---

## 👤 Author

**Sahil Changotra**
Data Analyst | The Hague, Netherlands
Specialising in e-commerce, logistics, and marketing analytics

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?logo=linkedin)](https://linkedin.com/in/sahilchangotra)
[![GitHub](https://img.shields.io/badge/GitHub-Portfolio-black?logo=github)](https://github.com/sahilmchangotra)

---

*This project is part of an ongoing SQL practice series using public datasets to simulate real-world business analytics problems.*