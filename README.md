# Global Supply Chain Risk & Disruption Analysis

I analysed 5,000 international shipments from 2024 and 2025 to work out what actually causes supply chain disruptions, and whether you can spot a risky shipment before it leaves port.

The short answer: yes, and weather is most of the story.

I built this in four stages. The raw CSV goes into SQL Server for cleaning and aggregation, a Jupyter notebook handles the deeper analysis and the models, and Power BI turns the results into a dashboard someone in operations could actually use.

---

## The Dashboard

![Executive Overview](images/01_executive_overview.png)

![Route Risk](images/02_route_risk.png)

[Open the .pbix file](powerbi/supply_chain_risk_dashboard.pbix) · 📄 [PDF version](powerbi/supply_chain_risk_dashboard.pdf) · 📘 [How the dashboard was built](powerbi/README.md)

---

## What I set out to answer

Supply chains get hit by geopolitical tension, storms, fuel price swings, and carriers that don't deliver. I wanted to know three things:

1. **Where does the risk actually sit?** Is it certain routes, certain transport modes, certain products?
2. **Can I put a number on it?** I built a Risk Exposure Score that combines geopolitical risk, fuel volatility, and distance into one figure per shipment.
3. **Can it be predicted?** Not explained after the fact, but predicted using only what you know at booking time.

---

## The data

5,000 shipments between January 2024 and December 2025, covering 8 ports, 64 routes, 4 transport modes, and 5 product categories. Each row has the route, distance, weight, fuel price index, geopolitical risk score, weather condition, carrier reliability score, lead time, and whether the shipment was disrupted.

The overall disruption rate is 61.3%, which is high, but that's the baseline every finding below is measured against. No missing values.

**Source:** [Global Supply Chain Risk & Logistics 2024–2026](https://www.kaggle.com/datasets/nudratabbas/global-supply-chain-risk-and-logistics-2024-2026) on Kaggle. It's synthetic data, so the patterns are realistic but made up. The method is what matters here, not the numbers as a description of real trade.

---

## How it fits together

```
   CSV              SQL Server            Jupyter / Python          Power BI
   ───              ──────────            ────────────────          ────────
 5,000 rows  ──►  load · clean  ──►  EDA · correlation ·  ──►  2-page dashboard
 14 columns       aggregate           Logistic Regression
                  risk score          Random Forest
                  views
```

| Stage | Tool | What happens |
|---|---|---|
| Load and clean | SQL Server | Create the database and table, bulk import the CSV, run data quality checks |
| Explore | SQL Server | Aggregate by mode, category, route, weather, and month |
| Score | SQL Server | Build the Risk Exposure Score: 50% geopolitical risk, 30% fuel volatility, 20% distance |
| Serve | SQL Server views | Analysis-ready views for the BI layer |
| Analyse | Python (Jupyter) | pandas, seaborn and matplotlib, correlation analysis |
| Model | Python (scikit-learn) | Logistic Regression and Random Forest, ROC/AUC, feature importance |
| Visualise | Power BI | Route heatmap, monthly trend, and a watchlist of shipments the model flags |

I used SQL for the aggregation because that's what it's good at, Python for the modelling, and Power BI for delivery. Each tool does the part it's best suited to.

---

## What I found

### Weather dominates everything else

| Weather | Disruption rate |
|---|---|
| Hurricane | 100.0% |
| Storm | 79.5% |
| Fog | 48.1% |
| Rain | 42.0% |
| Clear | 37.0% |

Every single hurricane shipment in the dataset was disrupted. Not most of them, all of them. Storms aren't far behind at 79.5%. Compare that to 37% in clear weather and you can see why weather accounts for 43% of the model's predictive power on its own.

### Transport mode makes almost no difference

Air 61.7%, Rail 61.2%, Road 61.0%, Sea 61.0%. That's a spread of 0.7 percentage points across all four modes.

This one surprised me. If you were planning to switch freight from sea to air to improve reliability, the data says don't bother. Pick your mode on cost and speed, and spend the attention elsewhere.

### The risk is in the lanes, not the ports

Look at any single port and the rates cluster tightly between 59.8% and 63.3%. Nothing stands out. But look at specific origin-destination pairs and the range opens right up: from 48.3% on Los Angeles to Dubai, to 75.0% on Rotterdam to Marseille.

So "which port is risky" is the wrong question. "Which lane is risky" is the right one.

### Carrier reliability is worth paying for

Carriers scoring below 0.65 disrupt 65.3% of their shipments. Carriers above 0.80 disrupt 56.8%. It's an 8.5-point gap, which is smaller than the weather effect but it's consistent, and unlike the weather it's something you can actually choose.

### The Risk Exposure Score works

Splitting shipments into quartiles by score, the disruption rate climbs steadily: 49.2%, then 57.5%, then 65.5%, then 73.0%. A score that didn't work would show a flat line, so this is a reasonable check that the weighting is doing something real.

### Disruption is predictable before departure

The Random Forest hit a ROC AUC of 0.816, and 0.82 when I ran it again under 5-fold cross-validation. Logistic Regression landed in the same range, which told me the signal was genuine and not just something tree models happen to pick up.

More usefully than the AUC: of the 1,741 shipments the model flags as high risk (about a third of total volume), 92.9% really were disrupted. That's a list an operations team could act on.

**What the model leans on:** weather 43.3%, geopolitical risk 15.1%, carrier reliability 7.4%, weight 6.9%, fuel index 6.8%, distance 6.7%. Everything else is below 4%.

---

## What I'd recommend

| | Recommendation | Why |
|---|---|---|
| 1 | Build weather-triggered contingency routing. When a hurricane or storm forecast hits a lane, hold the shipment, reroute it, or at minimum warn the customer early. | Hurricane 100% and storm 79.5%, against a 37% clear-weather baseline |
| 2 | Stop trying to fix reliability by switching transport mode. Choose on cost and speed instead. | 0.7-point spread across all four modes |
| 3 | Monitor the ten riskiest lanes rather than the busiest ports. Start with Rotterdam to Marseille (75.0%), Los Angeles to Singapore (72.1%), and Hamburg to Rotterdam (70.8%). | Lanes vary by 27 points, ports by 3.5 |
| 4 | Set a carrier reliability floor of 0.80 for high-value freight. | 56.8% versus 65.3% disruption |
| 5 | Score every shipment at booking and escalate the high-risk band. Buffer stock, an expedited backup, or a heads-up to the customer. | A third of volume, disrupted 93% of the time |

---

## The dashboard

**Page 1, Executive Overview.** Five KPIs across the top (volume, disruption rate, average risk score, average lead time, and how many shipments the model flags), then the monthly trend, disruption by weather, and disruption by transport mode.

**Page 2, Route Risk.** An origin-by-destination heatmap shaded green through to red, the ten worst lanes, and a scorecard ranking all 64 lanes.

It's built on a star schema with a proper date table and 11 DAX measures. Colour means something throughout: red is high risk, green is low, and nothing is coloured just to look nice. Every visual cross-filters the page, so clicking "Hurricane" reshapes all the KPIs at once. More detail in [`powerbi/README.md`](powerbi/README.md).

---

## What's in this repo

```
supply-chain-risk-analysis/
├── data/
│   ├── global_supply_chain_risk_2026.csv   raw extract
│   ├── supply_chain_powerbi.csv            enriched table with scores and predictions
│   └── feature_importance.csv
├── sql/
│   ├── 00_create_database.sql
│   ├── 01_create_table_and_load.sql
│   ├── 02_exploratory_analysis.sql
│   └── 03_risk_score_and_views.sql
├── notebook/
│   ├── supply_chain_analysis.ipynb         EDA and modelling
│   └── prepare_powerbi_data.py             builds the Power BI dataset
├── powerbi/
│   ├── supply_chain_risk_dashboard.pbix
│   ├── supply_chain_risk_dashboard.pdf
│   ├── powerbi_measures.dax                all 11 measures
│   ├── supply_chain_theme.json
│   └── README.md                           how the dashboard was built
├── images/
├── requirements.txt
└── README.md
```

---

## Running it yourself

```bash
git clone https://github.com/Jwamba1/supply-chain-risk-analysis.git
cd supply-chain-risk-analysis
pip install -r requirements.txt
```

**SQL Server.** Run the scripts in `sql/` in order, 00 through 03, in SQL Server Management Studio. You'll need to change the file path in `01_create_table_and_load.sql` to wherever your CSV lives.

**Python.** Open `notebook/supply_chain_analysis.ipynb`, put the CSV in the same folder, and run all cells. Or just run `python notebook/prepare_powerbi_data.py` if you only want the enriched dataset for Power BI.

**Power BI.** Open the `.pbix` and refresh, repointing the source to your local `data/` folder. You can also connect it to the `SupplyChainRisk` database and use the views from script 03.

---

## A few notes on method

**I scored shipments with a model that hadn't seen them.** The predicted probabilities come from `cross_val_predict` with 5 stratified folds. If I'd scored the training data directly, the numbers would have looked much better and meant much less.

**I left lead time out of the features.** It's an outcome of a disruption, not something you know when you book. Including it would have inflated the model and taught it nothing useful.

**I fitted two models, not one.** Logistic Regression alongside the Random Forest, as a sanity check. Similar performance from two different approaches suggests the signal is in the data rather than in the algorithm.

**I normalised before weighting.** Each component of the Risk Exposure Score is min-max scaled to 0–1 first, otherwise distance in kilometres would swamp a geopolitical score that runs 0 to 10.

**I didn't report accuracy.** With a 61.3% base rate, a model that predicted "disrupted" every time would score 61.3% accuracy and be useless. ROC AUC and the precision of the high-risk band are the honest measures here.

---

## Skills this project covers

SQL Server (T-SQL, aggregation, views) · Python (pandas, scikit-learn, seaborn, matplotlib) · Machine learning (Logistic Regression, Random Forest, cross-validation, ROC/AUC, feature importance) · Power BI (data modelling, DAX, conditional formatting, dashboard design) · Git and GitHub

Part of my data analytics portfolio, built to show SQL, Python, and BI skills across a realistic end-to-end workflow.

---

**Wamba Jose** — Data Analyst working in risk, fraud, and supply chain analytics.
[LinkedIn](https://www.linkedin.com/in/your-profile) · [GitHub](https://github.com/Jwamba1)
