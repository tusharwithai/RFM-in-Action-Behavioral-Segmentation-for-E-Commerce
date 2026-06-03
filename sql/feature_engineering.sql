-- ============================================================
-- Project : RFM in Action: Behavioral Segmentation for E-Commerce
-- Script  : Feature Engineering — Customer-Level RFM & Behavioral Metrics
-- ============================================================

-- create new table with Revenue feature
DROP TABLE IF EXISTS transactions_enriched;
SELECT 
	Invoice,
	StockCode,
	Description,
	Quantity,
	InvoiceDatetime AS InvoiceDate,
	Price,
	Customer_ID AS CustomerID,
	Country,
	Quantity * Price AS Revenue
INTO dbo.transactions_enriched
FROM dbo.transactions_clean;

-- determine reference dates for Recency calculations
SELECT
	MIN(InvoiceDate) AS min_date,
	MAX(InvoiceDate) AS max_date
FROM dbo.transactions_enriched;


-- create customer-level features table
DROP TABLE IF EXISTS customer_features; -- if needed to refresh table
-- set RecencyReference to day after max transaction date to avoid 0-day recency for last-day purchasers
DECLARE @RecencyReference DATE = '2011-12-10';
CREATE TABLE dbo.customer_features (
	CUSTOMERID INT,
	first_purchase_date DATETIME,
	last_purchase_date DATETIME,
	recency_days INT,
	frequency_orders INT,
	monetary_total DECIMAL(18, 2),
	aov DECIMAL(18, 2),
	active_lifespan_days INT,
	interpurchase_gap INT,
	avg_items_per_order DECIMAL(18, 2),
	avg_unit_price DECIMAL(18, 2)
);
INSERT INTO dbo.customer_features (
	CustomerID,
	first_purchase_date,
	last_purchase_date,
	recency_days,
	frequency_orders,
	monetary_total,
	aov,
	active_lifespan_days,
	interpurchase_gap,
	avg_items_per_order,
	avg_unit_price
)
SELECT
	CustomerID,
	-- lifecycle dates
	MIN(InvoiceDate) AS first_purchase_date,
	MAX(InvoiceDate) AS last_purchase_date,
	-- rfm metrics
	DATEDIFF(DAY, MAX(InvoiceDate), @RecencyReference) AS recency_days,
	COUNT(DISTINCT Invoice) AS frequency_orders,
	SUM(Revenue) AS monetary_total,
	SUM(Revenue) / NULLIF(COUNT(DISTINCT Invoice), 0) AS aov,
	-- lifecycle depth
	DATEDIFF(DAY, MIN(InvoiceDate), MAX(InvoiceDate)) AS active_lifespan_days,
	DATEDIFF(DAY, MIN(InvoiceDate), MAX(InvoiceDate)) / NULLIF(COUNT(DISTINCT Invoice), 0) AS interpurchase_gap,
	(SUM(Quantity) * 1.0) / NULLIF(COUNT(DISTINCT Invoice), 0) AS avg_items_per_order,
	-- avg price paid per unit
	SUM(Revenue) / NULLIF(SUM(Quantity), 0) AS avg_unit_price
FROM dbo.transactions_enriched
GROUP BY CustomerID;