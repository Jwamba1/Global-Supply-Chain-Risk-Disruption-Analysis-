/* ============================================================
   STEP 2 — EXPLORATORY ANALYSIS
   ============================================================ */

USE SupplyChainRisk;
GO

-- 2.1 Overall snapshot
SELECT
    COUNT(*)                                          AS Total_Shipments,
    MIN(Ship_Date)                                    AS First_Date,
    MAX(Ship_Date)                                     AS Last_Date,
    ROUND(AVG(Geopolitical_Risk_Score),2)             AS Avg_Geo_Risk,
    ROUND(AVG(Fuel_Price_Index),2)                    AS Avg_Fuel_Index,
    ROUND(AVG(Carrier_Reliability_Score),3)           AS Avg_Reliability,
    ROUND(AVG(Lead_Time_Days),1)                      AS Avg_Lead_Time,
    ROUND(AVG(CAST(Disruption_Occurred AS FLOAT))*100,1) AS Disruption_Rate_Pct
FROM dbo.Shipments;

-- 2.2 Disruption rate by Transport Mode
SELECT
    Transport_Mode,
    COUNT(*)                                          AS Shipments,
    SUM(CAST(Disruption_Occurred AS INT))              AS Disruptions,
    ROUND(AVG(CAST(Disruption_Occurred AS FLOAT))*100,1) AS Disruption_Rate_Pct,
    ROUND(AVG(Geopolitical_Risk_Score),2)              AS Avg_Geo_Risk,
    ROUND(AVG(Carrier_Reliability_Score),3)            AS Avg_Reliability
FROM dbo.Shipments
GROUP BY Transport_Mode
ORDER BY Disruption_Rate_Pct DESC;

-- 2.3 Disruption rate by Weather Condition
SELECT
    Weather_Condition,
    COUNT(*)                                          AS Shipments,
    ROUND(AVG(CAST(Disruption_Occurred AS FLOAT))*100,1) AS Disruption_Rate_Pct,
    ROUND(AVG(Lead_Time_Days),1)                       AS Avg_Lead_Time
FROM dbo.Shipments
GROUP BY Weather_Condition
ORDER BY Disruption_Rate_Pct DESC;

-- 2.4 Disruption rate by Product Category
SELECT
    Product_Category,
    COUNT(*)                                          AS Shipments,
    ROUND(AVG(CAST(Disruption_Occurred AS FLOAT))*100,1) AS Disruption_Rate_Pct,
    ROUND(SUM(Weight_MT),0)                            AS Total_Weight_MT
FROM dbo.Shipments
GROUP BY Product_Category
ORDER BY Disruption_Rate_Pct DESC;

-- 2.5 Highest-risk trade routes
SELECT TOP 15
    Origin_Port, Destination_Port,
    COUNT(*)                                          AS Shipments,
    ROUND(AVG(CAST(Disruption_Occurred AS FLOAT))*100,1) AS Disruption_Rate_Pct,
    ROUND(AVG(Geopolitical_Risk_Score),2)              AS Avg_Geo_Risk,
    ROUND(AVG(Lead_Time_Days),1)                       AS Avg_Lead_Time
FROM dbo.Shipments
GROUP BY Origin_Port, Destination_Port
ORDER BY Disruption_Rate_Pct DESC;

-- 2.6 Monthly trend: disruption rate & fuel price
SELECT
    FORMAT(Ship_Date, 'yyyy-MM')                       AS Year_Month,
    COUNT(*)                                           AS Shipments,
    ROUND(AVG(CAST(Disruption_Occurred AS FLOAT))*100,1) AS Disruption_Rate_Pct,
    ROUND(AVG(Fuel_Price_Index),2)                     AS Avg_Fuel_Index,
    ROUND(AVG(Geopolitical_Risk_Score),2)              AS Avg_Geo_Risk
FROM dbo.Shipments
GROUP BY FORMAT(Ship_Date, 'yyyy-MM')
ORDER BY Year_Month;

-- 2.7 Does carrier reliability actually predict fewer disruptions?
SELECT
    CASE
        WHEN Carrier_Reliability_Score >= 0.85 THEN 'High (>=0.85)'
        WHEN Carrier_Reliability_Score >= 0.65 THEN 'Medium (0.65-0.85)'
        ELSE 'Low (<0.65)'
    END AS Reliability_Bucket,
    COUNT(*)                                           AS Shipments,
    ROUND(AVG(CAST(Disruption_Occurred AS FLOAT))*100,1) AS Disruption_Rate_Pct
FROM dbo.Shipments
GROUP BY CASE
        WHEN Carrier_Reliability_Score >= 0.85 THEN 'High (>=0.85)'
        WHEN Carrier_Reliability_Score >= 0.65 THEN 'Medium (0.65-0.85)'
        ELSE 'Low (<0.65)'
    END
ORDER BY Disruption_Rate_Pct DESC;

-- 2.8 Lead time comparison: disrupted vs non-disrupted shipments
SELECT
    Disruption_Occurred,
    COUNT(*)                       AS Shipments,
    ROUND(AVG(Lead_Time_Days),1)   AS Avg_Lead_Time,
    ROUND(AVG(Distance_km),0)      AS Avg_Distance_km
FROM dbo.Shipments
GROUP BY Disruption_Occurred;
GO
