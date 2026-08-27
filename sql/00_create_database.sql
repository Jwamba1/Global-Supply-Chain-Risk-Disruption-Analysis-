/* ============================================================
   STEP 0 — FRESH START
   Creates a brand-new, clean database (no spaces in the name,
   so you never need brackets around USE statements again).
   ============================================================ */

-- If you want to wipe the old attempt entirely, uncomment this:
-- DROP DATABASE IF EXISTS [Supply CHain];

CREATE DATABASE SupplyChainRisk;
GO

USE SupplyChainRisk;
GO

SELECT DB_NAME() AS CurrentDatabase;   -- should print: SupplyChainRisk
GO
