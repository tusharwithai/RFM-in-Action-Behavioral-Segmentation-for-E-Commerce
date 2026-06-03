-- ============================================================
-- Project : RFM in Action: Behavioral Segmentation for E-Commerce
-- Script  : Cohort Construction & Retention Rate Analysis
-- ============================================================

-- create cohort_activity table
DROP TABLE IF EXISTS cohort_activity;
CREATE TABLE dbo.cohort_activity (
	cohort_month_start DATE,
	activity_month_start DATE,
	months_since_cohort INT,
	customers_active INT,
	cohort_size INT,
	retention_rate DECIMAL(18, 2)
);
-- cohorts: assign each user to a cohort (first purchase)
WITH cohorts AS (
	SELECT 
		CustomerID,
		DATEFROMPARTS(
			YEAR(MIN(InvoiceDate)),
			MONTH(MIN(InvoiceDate)),
			1
		) AS cohort_month_start
	FROM dbo.transactions_enriched
	GROUP BY CustomerID
),
cohort_sizes AS (
	SELECT
		cohort_month_start,
		COUNT(DISTINCT CustomerID) AS cohort_size
	FROM cohorts
	GROUP BY cohort_month_start
),
-- activity: create monthly activity records at customer-month grain
activity AS (
	SELECT 
		CustomerID,
		DATEFROMPARTS(
			YEAR(InvoiceDate),
			MONTH(InvoiceDate),
			1
		) AS activity_month_start
	FROM dbo.transactions_enriched
	GROUP BY CustomerID, YEAR(InvoiceDate), MONTH(InvoiceDate)
)
INSERT INTO dbo.cohort_activity (
	cohort_month_start,
	activity_month_start,
	months_since_cohort,
	customers_active,
	cohort_size,
	retention_rate
)
SELECT
	c.cohort_month_start,
	a.activity_month_start,
	DATEDIFF(MONTH, c.cohort_month_start, a.activity_month_start) AS months_since_cohort,
	COUNT(DISTINCT a.CustomerID) AS customers_active,
	s.cohort_size,
	((COUNT(DISTINCT a.CustomerID) * 1.0) / NULLIF(s.cohort_size, 0)) * 100 AS retention_rate
FROM cohorts c
JOIN activity a
	ON c.CustomerID = a.CustomerID
JOIN cohort_sizes s
	ON c.cohort_month_start = s.cohort_month_start
WHERE a.activity_month_start >= c.cohort_month_start
GROUP BY c.cohort_month_start, a.activity_month_start, s.cohort_size;


-- create cohort_activity_by_segment table
WITH cohorts AS (
	SELECT 
		CustomerID,
		DATEFROMPARTS(
			YEAR(MIN(InvoiceDate)),
			MONTH(MIN(InvoiceDate)),
			1
		) AS cohort_month_start
	FROM dbo.transactions_enriched
	GROUP BY CustomerID
),
activity AS (
	SELECT 
		CustomerID,
		DATEFROMPARTS(
			YEAR(InvoiceDate),
			MONTH(InvoiceDate),
			1
		) AS activity_month_start
	FROM dbo.transactions_enriched
	GROUP BY CustomerID, YEAR(InvoiceDate), MONTH(InvoiceDate)
),
monthly_cust_activity  AS (
	SELECT 
		c.CustomerID,
		c.cohort_month_start,
		a.activity_month_start,
		DATEDIFF(MONTH, c.cohort_month_start, a.activity_month_start) AS months_since_cohort
	FROM cohorts c
	JOIN activity a
	ON c.CustomerID = a.CustomerID
),
cust_activity AS (
	SELECT
		rfm.CUSTOMERID,
		mca.cohort_month_start,
		mca.activity_month_start,
		mca.months_since_cohort,
		rfm.segment
	FROM dbo.rfm rfm
	JOIN monthly_cust_activity mca
		ON rfm.CUSTOMERID = mca.CustomerID
),
active_customers AS (
	SELECT
		segment,
		cohort_month_start,
		months_since_cohort,
		COUNT(DISTINCT CUSTOMERID) AS customers_active
	FROM cust_activity
	GROUP BY segment, cohort_month_start, months_since_cohort
),
cohort_sizes AS (
	SELECT
		segment,
		cohort_month_start,
		COUNT(DISTINCT CUSTOMERID) AS cohort_size
	FROM cust_activity
	WHERE months_since_cohort = 0
	GROUP BY segment, cohort_month_start
)
SELECT 
	a.segment,
	a.cohort_month_start,
	DATEADD(MONTH, a.months_since_cohort, a.cohort_month_start) AS activity_month_start,
	a.months_since_cohort,
	a.customers_active,
	s.cohort_size,
	CAST(1.0 * a.customers_active / NULLIF(s.cohort_size, 0) AS DECIMAL(18, 4)) AS retention_rate
INTO dbo.cohort_activity_by_segment
FROM active_customers a
JOIN cohort_sizes s
	ON s.segment = a.segment
	AND s.cohort_month_start = a.cohort_month_start;