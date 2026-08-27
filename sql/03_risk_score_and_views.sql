/* ============================================================
   STEP 3 — RISK EXPOSURE SCORE + REPORTING VIEWS
   ============================================================ */

USE SupplyChainRisk;

-- 3.1 I am gonna build a scored table with a composite Risk Exposure Score (0-10)
--     50% Geopolitical_Risk_Score (already 0-10)
--     30% normalized Fuel_Price_Index
--     20% normalized Distance_km
IF OBJECT_ID('dbo.Shipments_Scored', 'U') IS NOT NULL DROP TABLE dbo.Shipments_Scored;

;WITH Bounds AS (
    SELECT
        MIN(Fuel_Price_Index) AS Fuel_Min, MAX(Fuel_Price_Index) AS Fuel_Max,
        MIN(Distance_km)      AS Dist_Min, MAX(Distance_km)      AS Dist_Max
    FROM dbo.Shipments
)
SELECT
    s.*,
    ROUND(
        0.5 * s.Geopolitical_Risk_Score
      + 0.3 * ((s.Fuel_Price_Index - b.Fuel_Min) / (b.Fuel_Max - b.Fuel_Min) * 10)
      + 0.2 * ((s.Distance_km - b.Dist_Min) / (b.Dist_Max - b.Dist_Min) * 10)
    , 2) AS Risk_Exposure_Score
INTO dbo.Shipments_Scored
FROM dbo.Shipments s
CROSS JOIN Bounds b;

ALTER TABLE dbo.Shipments_Scored ADD Risk_Tier VARCHAR(10);

UPDATE dbo.Shipments_Scored
SET Risk_Tier = CASE
    WHEN Risk_Exposure_Score >= 7 THEN 'High'
    WHEN Risk_Exposure_Score >= 4 THEN 'Medium'
    ELSE 'Low'
END;

-- Verify
SELECT COUNT(*) AS TotalRows FROM dbo.Shipments_Scored;   -- expect 5000

SELECT Risk_Tier, COUNT(*) AS Shipments,
       ROUND(AVG(Risk_Exposure_Score),2) AS Avg_Score,
       ROUND(AVG(CAST(Disruption_Occurred AS FLOAT))*100,1) AS Disruption_Rate_Pct
FROM dbo.Shipments_Scored
GROUP BY Risk_Tier
ORDER BY Avg_Score DESC;


/* ============================================================
   3.2 REPORTING VIEWS — what Power BI will connect to
   ============================================================ */

CREATE OR ALTER VIEW dbo.vw_Shipments_Master AS
SELECT
    Shipment_ID, Ship_Date,
    YEAR(Ship_Date)  AS Ship_Year,
    MONTH(Ship_Date) AS Ship_Month,
    DATENAME(MONTH, Ship_Date) AS Ship_Month_Name,
    Origin_Port, Destination_Port,
    CONCAT(Origin_Port, ' -> ', Destination_Port) AS Route,
    Transport_Mode, Product_Category, Weather_Condition,
    Distance_km, Weight_MT, Fuel_Price_Index,
    Geopolitical_Risk_Score, Carrier_Reliability_Score, Lead_Time_Days,
    Disruption_Occurred, Risk_Exposure_Score, Risk_Tier
FROM dbo.Shipments_Scored;

CREATE OR ALTER VIEW dbo.vw_Route_Summary AS
SELECT
    Origin_Port, Destination_Port,
    CONCAT(Origin_Port, ' -> ', Destination_Port) AS Route,
    COUNT(*)                                        AS Shipment_Count,
    ROUND(AVG(Risk_Exposure_Score),2)               AS Avg_Risk_Exposure,
    ROUND(AVG(CAST(Disruption_Occurred AS FLOAT))*100,1) AS Disruption_Rate_Pct,
    ROUND(AVG(Fuel_Price_Index),2)                  AS Avg_Fuel_Index,
    ROUND(AVG(Distance_km),0)                       AS Avg_Distance_km,
    ROUND(AVG(Lead_Time_Days),1)                    AS Avg_Lead_Time
FROM dbo.Shipments_Scored
GROUP BY Origin_Port, Destination_Port;

CREATE OR ALTER VIEW dbo.vw_Monthly_Trend AS
SELECT
    YEAR(Ship_Date)  AS Ship_Year,
    MONTH(Ship_Date) AS Ship_Month,
    FORMAT(Ship_Date,'yyyy-MM') AS Year_Month,
    COUNT(*)                                         AS Shipment_Count,
    ROUND(AVG(Risk_Exposure_Score),2)                AS Avg_Risk_Exposure,
    ROUND(AVG(CAST(Disruption_Occurred AS FLOAT))*100,1) AS Disruption_Rate_Pct,
    ROUND(AVG(Fuel_Price_Index),2)                   AS Avg_Fuel_Index
FROM dbo.Shipments_Scored
GROUP BY YEAR(Ship_Date), MONTH(Ship_Date), FORMAT(Ship_Date,'yyyy-MM');

CREATE OR ALTER VIEW dbo.vw_Category_Summary AS
SELECT
    Product_Category,
    COUNT(*)                                         AS Shipment_Count,
    ROUND(AVG(Risk_Exposure_Score),2)                AS Avg_Risk_Exposure,
    ROUND(AVG(CAST(Disruption_Occurred AS FLOAT))*100,1) AS Disruption_Rate_Pct,
    ROUND(SUM(Weight_MT),0)                          AS Total_Weight_MT
FROM dbo.Shipments_Scored
GROUP BY Product_Category;

-- Verify all views
SELECT TOP 5 * FROM dbo.vw_Shipments_Master;
SELECT * FROM dbo.vw_Route_Summary ORDER BY Disruption_Rate_Pct DESC;
SELECT * FROM dbo.vw_Monthly_Trend ORDER BY Ship_Year, Ship_Month;
SELECT * FROM dbo.vw_Category_Summary ORDER BY Disruption_Rate_Pct DESC;
