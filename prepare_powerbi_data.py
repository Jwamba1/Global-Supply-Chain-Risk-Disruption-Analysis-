"""
Prepare the Power BI dataset for the Global Supply Chain Risk & Disruption Analysis.

Input : data/global_supply_chain_risk_2026.csv  (Kaggle, 5,000 shipments)
Output: data/supply_chain_powerbi.csv            (enriched fact table)
        data/feature_importance.csv              (Random Forest feature importance)
"""
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import StratifiedKFold, cross_val_predict
from sklearn.metrics import roc_auc_score

df = pd.read_csv("data/global_supply_chain_risk_2026.csv", parse_dates=["Date"])

# ---- Business columns -------------------------------------------------------
def minmax(s):
    return (s - s.min()) / (s.max() - s.min())

df["Route"] = df["Origin_Port"] + " to " + df["Destination_Port"]

# Composite Risk Exposure Score (0-100): 50% geopolitical, 30% fuel, 20% distance
df["Risk_Exposure_Score"] = (100 * (
    0.5 * minmax(df["Geopolitical_Risk_Score"])
    + 0.3 * minmax(df["Fuel_Price_Index"])
    + 0.2 * minmax(df["Distance_km"])
)).round(1)

df["Reliability_Band"] = pd.cut(
    df["Carrier_Reliability_Score"], [0, 0.65, 0.80, 1.01], right=False,
    labels=["Low (<0.65)", "Medium (0.65-0.80)", "High (0.80+)"])
df["Reliability_Band_Order"] = df["Reliability_Band"].cat.codes + 1

# ---- Predictive model (features known before departure) ---------------------
features = ["Transport_Mode", "Product_Category", "Origin_Port", "Destination_Port",
            "Weather_Condition", "Distance_km", "Weight_MT", "Fuel_Price_Index",
            "Geopolitical_Risk_Score", "Carrier_Reliability_Score"]
X = pd.get_dummies(df[features], dtype=int)
y = df["Disruption_Occurred"]

rf = RandomForestClassifier(n_estimators=300, min_samples_leaf=5, random_state=42, n_jobs=-1)
cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)

# Out-of-fold probabilities: every shipment is scored by a model that never saw it
proba = cross_val_predict(rf, X, y, cv=cv, method="predict_proba")[:, 1]
print(f"Random Forest ROC AUC (5-fold CV): {roc_auc_score(y, proba):.3f}")

df["Disruption_Probability"] = proba.round(3)
df["Predicted_Risk_Band"] = pd.cut(proba, [0, 0.4, 0.7, 1.0], include_lowest=True,
                                   labels=["Low", "Medium", "High"])
df["Predicted_Risk_Band_Order"] = df["Predicted_Risk_Band"].cat.codes + 1

df["Date"] = df["Date"].dt.strftime("%Y-%m-%d")
df.to_csv("data/supply_chain_powerbi.csv", index=False)

# ---- Feature importance, grouped back to original columns -------------------
rf.fit(X, y)
imp = pd.Series(rf.feature_importances_, index=X.columns)
grouped = {}
for col, val in imp.items():
    base = next(f for f in features if col == f or col.startswith(f + "_"))
    grouped[base.replace("_", " ")] = grouped.get(base.replace("_", " "), 0) + val
(pd.DataFrame(grouped.items(), columns=["Feature", "Importance"])
   .sort_values("Importance", ascending=False).round(4)
   .to_csv("data/feature_importance.csv", index=False))
print("Saved data/supply_chain_powerbi.csv and data/feature_importance.csv")
