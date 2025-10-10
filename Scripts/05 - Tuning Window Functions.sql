USE [WideWorldImporters]
GO
-- Run in SSMS to get actual timings.

-- Ensure that compatibility mode is 2019!
SELECT compatibility_level FROM sys.databases WHERE name = 'WideWorldImporters';
ALTER DATABASE WideWorldImporters SET COMPATIBILITY_LEVEL = 160;

-- Remove an index if it already exists.
IF EXISTS
(
	SELECT 1
	FROM sys.indexes i
	WHERE
		i.name = N'IX_Sales_Invoices_WindowFunction'
)
BEGIN
	DROP INDEX [IX_Sales_Invoices_WindowFunction] ON Sales.Invoices;
END
GO

-- Indexing helps!
WITH records AS
(
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY i.CustomerID
            ORDER BY i.OrderID) AS rownum
    FROM Sales.Invoices i
)
SELECT *
FROM records r
WHERE
    r.rownum = 0;
GO

IF NOT EXISTS
(
	SELECT 1
	FROM sys.indexes i
	WHERE
		i.name = N'IX_Sales_Invoices_WindowFunction'
)
BEGIN
	CREATE INDEX [IX_Sales_Invoices_WindowFunction] ON Sales.Invoices
	(
		CustomerID,
		OrderID
	);
END
GO

WITH records AS
(
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY i.CustomerID
            ORDER BY i.OrderID) AS rownum
    FROM Sales.Invoices i
)
SELECT *
FROM records r
WHERE
    r.rownum = 0;
GO

-- Order matters!
WITH records AS
(
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY i.CustomerID
            ORDER BY i.OrderID DESC) AS rownum
    FROM Sales.Invoices i
)
SELECT *
FROM records r
WHERE
    r.rownum = 0;
GO

-- What about additional filters?
SELECT
    COUNT(*) AS NumberOfInvoices,
	SUM(CASE WHEN i.TotalChillerItems >= 3 THEN 1 ELSE 0 END) AS EnoughChillerItems
FROM Sales.Invoices i;

WITH records AS
(
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY i.CustomerID
            ORDER BY i.OrderID) AS rownum
    FROM Sales.Invoices i
	WHERE
		i.TotalChillerItems >= 3
)
SELECT *
FROM records r
WHERE
    r.rownum = 0;
GO

-- This index doesn't work at all--SQL Server ignores it altogether.
CREATE INDEX [IX_Sales_Invoices_WindowFunction] ON Sales.Invoices
(
	TotalChillerItems,
	CustomerID,
	OrderID
) WITH (DROP_EXISTING = ON);

-- Now we have an index worth using.
WITH records AS
(
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY i.CustomerID
            ORDER BY i.OrderID) AS rownum
    FROM Sales.Invoices i
	WHERE
		i.TotalChillerItems >= 3
)
SELECT *
FROM records r
WHERE
    r.rownum = 0;
GO

-- Get rid of the index.
IF EXISTS
(
	SELECT 1
	FROM sys.indexes i
	WHERE
		i.name = N'IX_Sales_Invoices_WindowFunction'
)
BEGIN
	DROP INDEX [IX_Sales_Invoices_WindowFunction] ON Sales.Invoices;
END
GO

-- Batch mode can make a huge difference for large datasets.
SELECT COUNT(*) FROM Warehouse.ColdRoomTemperatures_Archive;
GO

WITH records AS
(
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY c.ColdRoomSensorNumber
            ORDER BY c.ColdRoomTemperatureID) AS rownum
    FROM Warehouse.ColdRoomTemperatures_Archive c
)
SELECT *
FROM records r
WHERE
    r.rownum = 0
OPTION(USE HINT ('QUERY_OPTIMIZER_COMPATIBILITY_LEVEL_140'));
GO

WITH records AS
(
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY c.ColdRoomSensorNumber
            ORDER BY c.ColdRoomTemperatureID) AS rownum
    FROM Warehouse.ColdRoomTemperatures_Archive c
)
SELECT *
FROM records r
WHERE
    r.rownum = 0;
GO


-- Batch mode redux, plus RANGE versus ROWS
-- NOTE: This is a pretty bad query!
WITH records AS
(
	-- Recall: default frame uses RANGE
    SELECT
        SUM(c.Temperature) OVER (
            PARTITION BY c.ColdRoomSensorNumber
            ORDER BY c.ColdRoomTemperatureID) AS sumtemp
    FROM Warehouse.ColdRoomTemperatures_Archive c
)
SELECT *
FROM records r
WHERE
    r.sumtemp = 0
OPTION(USE HINT ('QUERY_OPTIMIZER_COMPATIBILITY_LEVEL_140'));
GO

WITH records AS
(
    SELECT
        SUM(c.Temperature) OVER (
            PARTITION BY c.ColdRoomSensorNumber
            ORDER BY c.ColdRoomTemperatureID
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS sumtemp
    FROM Warehouse.ColdRoomTemperatures_Archive c
)
SELECT *
FROM records r
WHERE
    r.sumtemp = 0
OPTION(USE HINT ('QUERY_OPTIMIZER_COMPATIBILITY_LEVEL_140'));
GO

WITH records AS
(
    SELECT
        SUM(c.Temperature) OVER (
            PARTITION BY c.ColdRoomSensorNumber
            ORDER BY c.ColdRoomTemperatureID) AS sumtemp
    FROM Warehouse.ColdRoomTemperatures_Archive c
)
SELECT *
FROM records r
WHERE
    r.sumtemp = 0;
GO

WITH records AS
(
    SELECT
        SUM(c.Temperature) OVER (
            PARTITION BY c.ColdRoomSensorNumber
            ORDER BY c.ColdRoomTemperatureID
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS sumtemp
    FROM Warehouse.ColdRoomTemperatures_Archive c
)
SELECT *
FROM records r
WHERE
    r.sumtemp = 0;
GO

-- Limit the number of unique windows!
SELECT
	il.InvoiceLineID,
	il.InvoiceID,
	ROW_NUMBER() OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS rownum1,
	ROW_NUMBER() OVER (PARTITION BY il.StockItemID ORDER BY il.InvoiceLineID) AS rownum2,
	ROW_NUMBER() OVER (PARTITION BY il.PackageTypeID ORDER BY il.InvoiceLineID) AS rownum3,
	ROW_NUMBER() OVER (PARTITION BY il.TaxAmount ORDER BY il.InvoiceLineID) AS rownum4,
	ROW_NUMBER() OVER (PARTITION BY il.LineProfit ORDER BY il.InvoiceLineID) AS rownum5
FROM Sales.InvoiceLines il;

-- Order matters!
WITH records AS
(
	SELECT
		il.InvoiceLineID,
		il.InvoiceID,
		ROW_NUMBER() OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS rownum1,
		ROW_NUMBER() OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID DESC) AS rownum2
	FROM Sales.InvoiceLines il
)
SELECT *
FROM records
WHERE
	rownum1 = 0;

-- If you have one window, life is good!
WITH records AS
(
	SELECT
		il.InvoiceLineID,
		il.InvoiceID,
		ROW_NUMBER() OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS rownum,
		RANK() OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS rk,
		DENSE_RANK() OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS dr
	FROM Sales.InvoiceLines il
)
SELECT *
FROM records
WHERE
	rownum = 0;

-- But watch out:  aggregate functions do behave differently.
WITH records AS
(
	SELECT
		il.InvoiceLineID,
		il.InvoiceID,
		ROW_NUMBER() OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS rownum,
		RANK() OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS rk,
		DENSE_RANK() OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS dr,
		SUM(il.Quantity) OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS s,
		MIN(il.Quantity) OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS mn,
		MAX(il.Quantity) OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS mx,
		COUNT(il.LineProfit) OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS c
	FROM Sales.InvoiceLines il
)
SELECT *
FROM records
WHERE
	rownum = 0;

-- Let's try removing the non-aggregate functions
WITH records AS
(
	SELECT
		il.InvoiceLineID,
		il.InvoiceID,
		SUM(il.Quantity) OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS s,
		MIN(il.Quantity) OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS mn,
		MAX(il.Quantity) OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS mx,
		COUNT(il.LineProfit) OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS c
	FROM Sales.InvoiceLines il
)
SELECT *
FROM records
WHERE
	s < 0;

-- Let's make everything aggregate by quantity.
WITH records AS
(
	SELECT
		il.InvoiceLineID,
		il.InvoiceID,
		SUM(il.Quantity) OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS s,
		MIN(il.Quantity) OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS mn,
		MAX(il.Quantity) OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS mx,
		COUNT(il.Quantity) OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS c
	FROM Sales.InvoiceLines il
)
SELECT *
FROM records
WHERE
	s < 0;

-- Aggregate columns don't change the performance profile like changing the window does.
WITH records AS
(
	SELECT
		il.InvoiceLineID,
		il.InvoiceID,
		SUM(il.Quantity) OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS s,
		MIN(il.UnitPrice) OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS mn,
		MAX(il.TaxRate) OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS mx,
		COUNT(il.Quantity) OVER (PARTITION BY il.InvoiceID ORDER BY il.InvoiceLineID) AS c
	FROM Sales.InvoiceLines il
)
SELECT *
FROM records
WHERE
	s < 0;
