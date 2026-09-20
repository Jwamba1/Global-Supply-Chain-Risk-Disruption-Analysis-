# Power BI Build Guide — Global Supply Chain Risk Dashboard

Everything below matches `data/supply_chain_powerbi.csv` exactly (5,000 rows, 21 columns).
Estimated time: 3–4 hours. Save often with **Ctrl + S**.

---

## Part 1 — Load the data (15 min)

1. Open Power BI Desktop → **Blank report** → **File → Save as** → `supply_chain_risk_dashboard.pbix`.
2. **Home → Get data → Text/CSV** → pick `supply_chain_powerbi.csv` → click **Transform Data**.
3. In Power Query, check the preview. If the File Origin looks wrong (odd symbols), go back and set **File Origin = 65001: Unicode (UTF-8)**.
4. On the left, right-click the query → **Rename** → `Shipments`.
5. Set column types (click the icon left of each column name):

| Column | Type |
|---|---|
| Shipment_ID, Origin_Port, Destination_Port, Transport_Mode, Product_Category, Weather_Condition, Route, Reliability_Band, Predicted_Risk_Band | Text |
| Date | Date |
| Distance_km, Weight_MT, Fuel_Price_Index, Geopolitical_Risk_Score, Carrier_Reliability_Score, Lead_Time_Days, Risk_Exposure_Score, Disruption_Probability | Decimal Number |
| Disruption_Occurred, Reliability_Band_Order, Predicted_Risk_Band_Order | Whole Number |

   If a "Changed Type" step says "Using Locale" or shows errors, delete that step and set the types again.
6. **Home → New Source → Text/CSV** → `feature_importance.csv` → rename it `Feature Importance` (Feature = Text, Importance = Decimal).
7. **Close & Apply**.

**Check:** Table view → Shipments → the bottom bar shows **5,000 rows**.

---

## Part 2 — Model (20 min)

1. **Date table:** Modeling → **New table** → paste the `Date` formula from `powerbi_measures.dax` → Enter.
2. Select the Date table → **Table tools → Mark as date table** → column `Date` → OK.
3. Select `Date[Month]` → **Column tools → Sort by column → MonthNum**.
4. **Model view** → drag `Date[Date]` onto `Shipments[Date]` → confirm **One to many (1:\*)**, single direction → OK.
5. **Sort the band columns** so they don't appear alphabetically:
   - `Shipments[Reliability_Band]` → Sort by column → `Reliability_Band_Order`
   - `Shipments[Predicted_Risk_Band]` → Sort by column → `Predicted_Risk_Band_Order`
6. **Hide helper columns** (right-click → Hide in report view): `Reliability_Band_Order`, `Predicted_Risk_Band_Order`, and `Shipments[Date]` (you'll use `Date[Date]` instead).
7. **Measures table:** Home → **Enter data** → name `_Measures` → Load.
8. Select `_Measures` → **Modeling → New measure** → paste each measure from `powerbi_measures.dax`, one at a time. Apply the format noted under each one (Measure tools → % button / decimal places).
9. Delete `_Measures[Column1]` once measures exist.

**Check:** drop `Disruption Rate` into a card → it shows **61.3%**. Delete the test card.

---

## Part 3 — Theme & layout (10 min)

1. **View → Themes → Browse for themes** → `supply_chain_theme.json`.
2. **View → Page view → Fit to page.** Canvas stays 16:9 (1280 × 720).
3. Layout for every page:
   - **Header band** (top 60 px): Insert → Shapes → Rectangle, fill `#1F3A5F`, no border. Add a white text box on top with the page title.
   - **Slicer row** on the right of the header.
   - Leave ~10 px gaps between visuals; use **Format → Align** and **Distribute** to tidy.
4. Once Page 1's header is done, right-click the page tab → **Duplicate page** to reuse it for Pages 2–4.

---

## Part 4 — Page 1: Executive Overview

Rename the page tab `Executive Overview`. Header text: **Global Supply Chain Risk — Executive Overview**

**KPI cards (row under header)** — use the *Card* visual, one measure each:

| Card | Measure | Expected value |
|---|---|---|
| Shipments | Total Shipments | 5,000 |
| Disruption Rate | Disruption Rate | 61.3% |
| Avg Risk Exposure | Avg Risk Exposure Score | 50.4 |
| Avg Lead Time | Avg Lead Time (Days) | 19.4 days |
| Predicted High Risk | High Risk Shipments | 1,741 |

For each card: Format → Callout value (size 26) → turn **Category label** on.

**Visuals:**

1. **Line chart** — X-axis `Date[YearMonth]`, Y-axis `Disruption Rate`.
   Title: *Disruption rate stayed high across 2024–2025 (62.0% → 60.6%)*
   Format → Y-axis → Minimum `0.4` so the trend is readable.
2. **Clustered bar chart** — Y-axis `Weather_Condition`, X-axis `Disruption Rate`. Sort by Disruption Rate descending, data labels on.
   Title: *Hurricanes disrupt 100% of shipments; storms 80%*
   Optional: Format → Bars → Colors → **fx** → Rules: value ≥ 0.7 → red `#C8102E`, else navy.
3. **Clustered column chart** — X-axis `Transport_Mode`, Y-axis `Disruption Rate`, data labels on.
   Title: *Transport mode barely matters (61.0%–61.7%)*
4. **Slicers** (Dropdown style): `Date[Year]`, `Transport_Mode`, `Product_Category`.

**Test:** pick 2024 in the Year slicer — every visual should change.

---

## Part 5 — Page 2: Route Risk

Duplicate the page → rename `Route Risk`. Delete the Page 1 visuals except header and slicers.

1. **Matrix** — Rows `Origin_Port`, Columns `Destination_Port`, Values `Disruption Rate`.
   Format → Cell elements → **Background color → fx** → Gradient: lowest = green `#2E8B57`, center = amber `#F2A541`, highest = red `#C8102E`.
   Title: *Route heatmap: disruption rate by origin and destination*
2. **Clustered bar chart** — Y-axis `Route`, X-axis `Disruption Rate`.
   Filters pane → `Route` → Filter type **Top N** → Top **10** → By value: `Disruption Rate` → Apply. Sort descending, labels on.
   Title: *Rotterdam to Marseille is the riskiest route (75%)*
3. **Table** — `Route`, `Total Shipments`, `Disruption Rate`, `Disruption Rate vs Average`, `Avg Risk Exposure Score`.
   Format → Cell elements → `Disruption Rate vs Average` → **Font color** rules: > 0 red, < 0 green.
   Title: *Route scorecard vs 61.3% average*
4. **Scatter chart** — Values `Route`, X-axis `Avg Geopolitical Risk`, Y-axis `Disruption Rate`, Size `Total Shipments`.
   Title: *Higher geopolitical risk, higher disruption*

---

## Part 6 — Page 3: Risk Drivers

Duplicate → rename `Risk Drivers`.

1. **Clustered bar chart** — Y-axis `Feature Importance[Feature]`, X-axis `Importance`. Sort descending.
   Title: *Weather drives 43% of the model's predictive power*
2. **Clustered column chart** — X-axis `Reliability_Band`, Y-axis `Disruption Rate`, labels on.
   Title: *Reliable carriers cut disruption from 65% to 57%*
3. **Clustered column chart** — X-axis `Product_Category`, Y-axis `Disruption Rate`, sorted descending.
   Title: *Textiles are the most exposed category (64.9%)*
4. **Line chart (risk score)** — first create a grouping: right-click `Risk_Exposure_Score` in the Data pane → **New group** → Group type **Bin**, Bin size **20** → OK. Then X-axis `Risk_Exposure_Score (bins)`, Y-axis `Disruption Rate`.
   Title: *Disruption rises steadily with the Risk Exposure Score*
5. **Text box** (model summary):
   > **Random Forest model** · ROC AUC **0.82** (5-fold cross-validation)
   > Features known before departure only · Shipments flagged High were disrupted **92.9%** of the time

---

## Part 7 — Page 4: Shipments to Watch

Duplicate → rename `Shipments to Watch`.

1. **KPI cards:** `High Risk Shipments` (1,741), `High Risk Share` (34.8%), `Model Hit Rate (High Band)` (92.9%), `Avg Predicted Probability`.
2. **Donut chart** — Legend `Predicted_Risk_Band`, Values `Total Shipments`.
   Format → Slices → Low green, Medium amber, High red.
   Title: *1 in 3 shipments is predicted high risk*
3. **Table** — `Shipment_ID`, `Date[Date]`, `Route`, `Transport_Mode`, `Weather_Condition`, `Carrier_Reliability_Score`, `Disruption_Probability`.
   - Click the `Disruption_Probability` header to sort descending.
   - Format → Cell elements → `Disruption_Probability` → **Data bars** on (red).
   - Filters pane → **Filters on this visual** → `Predicted_Risk_Band` → tick **High**.
   Title: *Watchlist: highest predicted disruption probability*
4. **Slicers:** `Origin_Port`, `Transport_Mode`, `Weather_Condition`.

---

## Part 8 — Navigation & polish (20 min)

1. On Page 1: **Insert → Buttons → Navigator → Page navigator**. Place it under the header, then copy-paste it onto every page.
2. **Sync slicers:** View → **Sync slicers** → select the Year slicer → tick all pages → repeat for Transport Mode.
3. **Tooltips:** on the weather and route charts, drag `Total Shipments` and `Avg Risk Exposure Score` into **Tooltips**.
4. Turn off gridlines on every chart (Format → X/Y axis → Gridlines off).
5. Check every title reads as a finding, not a label.
6. Use **Ctrl + click** on the page tabs in order to confirm navigation works.

---

## Part 9 — Export & publish to GitHub

1. For each page: **Win + Shift + S** → snip the canvas → save as
   `images/01_executive_overview.png`, `02_route_risk.png`, `03_risk_drivers.png`, `04_shipments_to_watch.png`.
2. **File → Export → Export to PDF** → `powerbi/supply_chain_risk_dashboard.pdf`.
3. Put the `.pbix` in `powerbi/`.
4. Final repo structure:

```
Global-Supply-Chain-Risk-Disruption-Analysis/
├── data/
│   ├── global_supply_chain_risk_2026.csv
│   ├── supply_chain_powerbi.csv
│   └── feature_importance.csv
├── sql/  (existing scripts)
├── notebook/
│   ├── supply_chain_analysis.ipynb
│   └── prepare_powerbi_data.py
├── powerbi/
│   ├── supply_chain_risk_dashboard.pbix
│   ├── supply_chain_risk_dashboard.pdf
│   ├── powerbi_measures.dax
│   └── supply_chain_theme.json
├── images/  (4 screenshots)
├── requirements.txt
└── README.md
```

5. Upload on GitHub: **Add file → Upload files** → drag folders in → commit message `Add Power BI dashboard`.
   Files over 25 MB must be pushed with Git from the command line.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Card shows 3,063 instead of 61.3% | You used the column, not the measure. Use `_Measures` items. |
| Months out of order | `Date[Month]` → Sort by column → MonthNum |
| Bands in wrong order (High, Low, Medium) | Part 2, step 5 |
| Slicer doesn't filter a chart | Check the Date relationship in Model view; use `Date[...]` fields, not `Shipments[Date]` |
| Measure error "column cannot be found" | Table must be named exactly `Shipments` |
| Decimals show as whole numbers or text | Redo types in Power Query (Part 1, step 5) |
