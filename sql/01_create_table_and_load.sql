/* ============================================================
   STEP 1 — CREATE TABLE & LOAD DATA
   File: global_supply_chain_risk_2026 (3).csv
   Location: C:\Users\WambaJose\Downloads\
   ============================================================ */

USE SupplyChainRisk;
GO

IF OBJECT_ID('dbo.Shipments', 'U') IS NOT NULL DROP TABLE dbo.Shipments;
GO

CREATE TABLE dbo.Shipments (
    Shipment_ID                 VARCHAR(15)     NOT NULL PRIMARY KEY,
    Ship_Date                   DATE            NOT NULL,
    Origin_Port                 VARCHAR(50)     NOT NULL,
    Destination_Port            VARCHAR(50)     NOT NULL,
    Transport_Mode               VARCHAR(20)     NOT NULL,
    Product_Category             VARCHAR(30)     NOT NULL,
    Distance_km                  DECIMAL(10,2)   NOT NULL,
    Weight_MT                    DECIMAL(10,2)   NOT NULL,
    Fuel_Price_Index              DECIMAL(5,2)    NOT NULL,
    Geopolitical_Risk_Score      DECIMAL(5,2)    NOT NULL,
    Weather_Condition            VARCHAR(20)     NOT NULL,
    Carrier_Reliability_Score    DECIMAL(5,3)    NOT NULL,
    Lead_Time_Days               DECIMAL(6,2)    NOT NULL,
    Disruption_Occurred          BIT             NOT NULL
);
GO

-- IMPORTANT: double-check the exact filename in your Downloads folder.
-- Windows may have renamed it (e.g. "global_supply_chain_risk_2026 (3).csv")
-- if you downloaded it more than once. Adjust the filename below to match
-- exactly what File Explorer shows.
BULK INSERT dbo.Shipments
FROM 'C:\Users\WambaJose\Downloads\global_supply_chain_risk_2026 (3).csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);
GO

-- Verify: must return 5000
SELECT COUNT(*) AS TotalRows FROM dbo.Shipments;
GO

-- Peek at the data
SELECT TOP 10 * FROM dbo.Shipments;
GO

-- Data quality checks
SELECT
    SUM(CASE WHEN Distance_km <= 0 THEN 1 ELSE 0 END)                       AS Bad_Distance,
    SUM(CASE WHEN Weight_MT <= 0 THEN 1 ELSE 0 END)                         AS Bad_Weight,
    SUM(CASE WHEN Fuel_Price_Index <= 0 THEN 1 ELSE 0 END)                  AS Bad_Fuel,
    SUM(CASE WHEN Geopolitical_Risk_Score < 0 OR Geopolitical_Risk_Score > 10 THEN 1 ELSE 0 END) AS Bad_Risk,
    SUM(CASE WHEN Carrier_Reliability_Score < 0 OR Carrier_Reliability_Score > 1 THEN 1 ELSE 0 END) AS Bad_Reliability,
    SUM(CASE WHEN Lead_Time_Days <= 0 THEN 1 ELSE 0 END)                    AS Bad_LeadTime
FROM dbo.Shipments;

SELECT Shipment_ID, COUNT(*) AS c FROM dbo.Shipments GROUP BY Shipment_ID HAVING COUNT(*) > 1;

SELECT DISTINCT Transport_Mode FROM dbo.Shipments;
SELECT DISTINCT Product_Category FROM dbo.Shipments;
SELECT DISTINCT Weather_Condition FROM dbo.Shipments;
GO
