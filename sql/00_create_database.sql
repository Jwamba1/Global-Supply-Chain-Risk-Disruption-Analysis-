/* ============================================================
   STEP 0 — FRESH START
   Creates a brand-new, clean database (no spaces in the name,
   so you never need brackets around USE statements again).
   ============================================================ */

CREATE DATABASE SupplyChainRisk;
GO

USE SupplyChainRisk;
GO

SELECT DB_NAME() AS CurrentDatabase;   -- should print: SupplyChainRisk
GO
