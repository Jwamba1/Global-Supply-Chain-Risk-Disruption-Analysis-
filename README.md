# Global Supply Chain Risk & Disruption Analysis

An end-to-end data analytics project examining 5,000 international shipments (2024–2025) to identify what drives supply chain disruptions, and to predict which shipments are at risk before they happen.

Project Goal

Supply chains are exposed to geopolitical tension, weather events, fuel price swings, and unreliable carriers. This project answers three questions:

1. Where is risk concentrated? Which routes, transport modes, and product categories see the most disruptions?
2. How can we quantify exposure? A composite Risk Exposure Score combining geopolitical risk, fuel volatility, and shipping distance.
3. Can disruption be predicted? A machine learning model that flags high-risk shipments in advance, using only features known before departure.

Dataset

5,000 shipments, January 2024 to December 2025. 14 features: route (origin/destination port), transport mode, product category, distance, weight, fuel price index, geopolitical risk score, weather condition, carrier reliability score, lead time, and a binary disruption outcome. Overall disruption rate is 61.3%. No missing values, clean and ready for analysis.

Tools & Approach

| Stage | Tool | What it does |
|---|---|---|
| Data loading & cleaning | SQL Server | Table creation, bulk import, data quality checks |
| Exploratory analysis | SQL Server | Aggregations by mode, category, route, weather, and time |
| Risk scoring | SQL Server | Composite Risk Exposure Score (weighted 50% geopolitical risk, 30% fuel volatility, 20% distance) |
| Reporting layer | SQL Server Views | Analysis-ready views for BI tools |
| Deep-dive EDA & modeling | Python (Jupyter) | Pandas, seaborn/matplotlib visualizations, correlation analysis |
| Predictive modeling | Python (scikit-learn) | Logistic Regression and Random Forest classifiers predicting disruption, with ROC/AUC evaluation and feature importance |
| Dashboard | Power BI | Interactive dashboard for route risk, monthly trends, and a "shipments to watch" view based on predicted disruption probability |

Repository Structure

```
supply-chain-risk-analysis/
├── sql/
│ ├── 00_create_database.sql
│ ├── 01_create_table_and_load.sql
│ ├── 02_exploratory_analysis.sql
│ └── 03_risk_score_and_views.sql
├── notebook/
│ └── supply_chain_analysis.ipynb
├── powerbi/
│ └── (dashboard file, added after Power BI build)
└── README.md

```

Key Findings

Hurricane weather corresponds to a 100% disruption rate, the single strongest predictor in the dataset, dropping to 37% for clear weather. Air freight had the highest disruption rate among transport modes at 61.7%, though all modes clustered close together (61–62%). Rotterdam to Marseille was the riskiest single route, with a 75% disruption rate. Carrier reliability showed a modest but real effect: shipments with low-reliability carriers (below 0.65) had a 65.3% disruption rate versus 56.1% for high-reliability carriers. The Random Forest model achieved a ROC AUC of 0.816, meaningfully better than random guessing, with weather condition and carrier reliability as the top predictive features.

How to Reproduce

SQL Server: run the scripts in sql/ in numeric order (00 to 03) in SQL Server Management Studio. Update the file path in 01_create_table_and_load.sql to match your local CSV location.

Python: open notebook/supply_chain_analysis.ipynb in Jupyter, place the source CSV in the same folder, and run all cells.

Power BI: connect to the SupplyChainRisk database and import the views created in 03_risk_score_and_views.sql.

Dataset Source

Synthetic global supply chain risk dataset (2026), used for educational and portfolio purposes.

---
Part of my data analytics portfolio, built to demonstrate SQL, Python, and BI skills across a realistic end-to-end analytics workflow.
```





