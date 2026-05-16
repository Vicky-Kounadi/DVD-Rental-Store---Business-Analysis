# DVD-Rental-Store---Business-Analysis

## Executive Summary

The DVD rental business shows stable demand and balanced operations, but deeper analysis reveals hidden inefficiencies affecting profitability and inventory management.

The primary issue identified is systematic late returns, particularly among high-value customers who generate significant revenue while also contributing heavily to operational dysfunction.

Additionally, although demand is evenly distributed across films, profitability varies significantly by category, creating opportunities for pricing and inventory optimization.

#Key Recommendations
- Introduce segmented late return policies (strict for low-value customers, flexible for high-value customers) 
- Optimize pricing and inventory based on category-level profitability (not just demand) 
- Maintain balanced staffing and store operations, as performance is already high and efficient 
- Use seasonal demand patterns to better plan inventory and marketing strategies 

---

## Business Problem

The goal of this analysis was to understand:

- What drives revenue and customer engagement
- Where operational inefficiencies exist
- How profitability can be improved without harming customer retention

### Key Questions

- Which films and categories drive demand VS profit?
- Who are the most valuable customers- and how reliable are they?
- Are late returns impacting revenue and inventory availability?
- When does demand peak across time?
- How efficient are staff and store operations?

---

## Methodology

The analysis was performed using SQL on the Sakila database:

- Data extraction and transformation using `JOIN` across relational tables 
- Aggregations using `COUNT`, `SUM`, and `GROUP BY`
- Customer segmentation using `CASE` logic and CTEs
- Time-based analysis using date functions
- Revenue analysis across customers, categories, staff, and stores 
- Late return handling using expected VS actual return dates

---

## Skills

- SQL: CTEs, JOINs, aggregations, CASE logic  
- Business analysis: segmentation, KPI evaluation, profitability analysis  
- Data modeling: combining multiple business dimensions  
- Decision-making: translating insights into actionable strategies  

---

# Key Insights & Decisions

## 1. Film & Category Performance

- Demand is evenly distributed—no single film dominates  
- Categories like Sports and Sci-Fi drive volume, while Comedy and New releases drive higher revenue per rental  

### Decision:
- Manage inventory at category level, not film level  
- Balance:
  - High-demand categories → retention  
  - High-margin categories → profitability  

---

## 2. Customer Behaviour & Risk

- High-value customers generate the most revenue but also show high lateness rates (~50%+)  
- Late returns are systemic, not isolated to a few customers  

### Decision:
- Avoid strict penalties for top customers (losing retention risk)  
- Apply tiered policies:
  - High-value → reminders / incentives  
  - Low-value → stricter enforcement  

---

## 3. Late Returns Impact

- Customers frequently exceed rental duration  
- Late fees generate revenue, but also:
  - Reduce inventory availability  
  - Limit potential future rentals  

### Decision:
- Reassess rental duration policy  
- Test whether slightly longer rental windows reduce problem  
- Adjust late fees to act as a discouraging factor, not just revenue source  

---

## 4. Rental Trends (Time Analysis)

- Demand peaks in mid-year (summer months)  
- Activity is consistent across the week, with a slight mid-week peak  

### Decision:
- Plan inventory and marketing around seasonal peaks  
- Avoid over-investing in weekend-only strategies  
- Maintain stable staffing levels throughout the week  

---

## 5. Revenue Optimization (Categories)

- Some categories generate high volume but low revenue per rental  
- Others generate higher value per transaction despite lower demand  

### Decision:
- Increase focus on high-margin profit (e.g. Comedy, New releases)  
- Re-evaluate pricing or bundle-strategy for low-value categories  

---

## 6. Operations (Staff & Stores)

- Staff performance is highly consistent, with minor efficiency differences  
- Store performance is almost perfectly balanced (~50/50 revenue split)  

### Decision:
- No structural operational changes needed  
- Use current setup as a benchmark for scalability  

---

## Next Steps

- Implement segmented late return policy and measure retention impact  
- Test pricing strategies by category (A/B testing)  
- Track KPIs such as:
  - Late return rate  
  - Revenue per rental  
  - Customer tier movement  
- Build Power BI dashboard for ongoing KPI monitoring and operational decision support.
