USE [WideWorldImporters]
GO

-------------------------
-- Aggregate functions --
-------------------------
SELECT
    i.CustomerID,
    SUM(il.LineProfit) AS TotalProfit
FROM Sales.InvoiceLines il
    INNER JOIN Sales.Invoices i
        ON il.InvoiceID = i.InvoiceID
GROUP BY
    i.CustomerID;

-- Turn it into a window function with an OVER() clause
-- An empty OVER clause sums across the entire table.
-- Note that we don't need a GROUP BY anymore!
SELECT
    i.InvoiceID,
    i.CustomerID,
    i.InvoiceDate,
    SUM(il.LineProfit) OVER () AS TotalProfit
FROM Sales.InvoiceLines il
    INNER JOIN Sales.Invoices i
        ON il.InvoiceID = i.InvoiceID;

-- Add a PARTITION BY to sum by customer
SELECT
    i.InvoiceID,
    i.CustomerID,
    i.InvoiceDate,
    SUM(il.LineProfit) OVER (PARTITION BY i.CustomerID) AS TotalProfit
FROM Sales.InvoiceLines il
    INNER JOIN Sales.Invoices i
        ON il.InvoiceID = i.InvoiceID;

-- Add an ORDER BY to create a running total
SELECT
    i.InvoiceID,
    i.CustomerID,
    i.InvoiceDate,
    il.InvoiceLineID,
    il.LineProfit,
    SUM(il.LineProfit) OVER (
        PARTITION BY i.CustomerID
        ORDER BY i.InvoiceDate) AS RunningTotalProfit
FROM Sales.InvoiceLines il
    INNER JOIN Sales.Invoices i
        ON il.InvoiceID = i.InvoiceID
ORDER BY
    i.CustomerID,
    i.InvoiceDate;

-- This is equivalent to a RANGE query from the beginning of time to the current row:
SELECT
    i.InvoiceID,
    i.CustomerID,
    i.InvoiceDate,
    il.InvoiceLineID,
    il.LineProfit,
    SUM(il.LineProfit) OVER (
        PARTITION BY i.CustomerID
        ORDER BY i.InvoiceDate
        RANGE BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW) AS RunningTotalProfit
FROM Sales.InvoiceLines il
    INNER JOIN Sales.Invoices i
        ON il.InvoiceID = i.InvoiceID
ORDER BY
    i.CustomerID,
    i.InvoiceDate;

-- If we want to avoid that:
SELECT
    i.InvoiceID,
    i.CustomerID,
    i.InvoiceDate,
    il.InvoiceLineID,
    il.LineProfit,
    SUM(il.LineProfit) OVER (
        PARTITION BY i.CustomerID
        ORDER BY i.InvoiceDate
        ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW) AS RunningTotalProfit
FROM Sales.InvoiceLines il
    INNER JOIN Sales.Invoices i
        ON il.InvoiceID = i.InvoiceID
ORDER BY
    i.CustomerID,
    i.InvoiceDate;

-- A variety of aggregate functions:
SELECT
    i.InvoiceID,
    i.CustomerID,
    i.InvoiceDate,
    il.InvoiceLineID,
    il.LineProfit,
    SUM(il.LineProfit) OVER (
        PARTITION BY i.CustomerID
        ORDER BY i.InvoiceDate
        ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW) AS RunningTotalProfit,
    SUM(il.LineProfit) OVER () AS TotalProfit,
    MIN(il.Lineprofit) OVER(
        PARTITION BY i.CustomerID
        ORDER BY i.InvoiceDate
        ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
    ) AS MinLineProfit,
    MAX(il.Lineprofit) OVER(
        PARTITION BY i.CustomerID
        ORDER BY i.InvoiceDate
        ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
    ) AS MaxLineProfit,
    AVG(il.Lineprofit) OVER(
        PARTITION BY i.CustomerID
        ORDER BY i.InvoiceDate
        ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
    ) AS AvgLineProfit,
    STDEV(il.Lineprofit) OVER(
        PARTITION BY i.CustomerID
        ORDER BY i.InvoiceDate
        ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
    ) AS StdevLineProfit,
    COUNT(il.Lineprofit) OVER(
        PARTITION BY i.CustomerID
        ORDER BY i.InvoiceDate
        ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
    ) AS CountLineProfit
FROM Sales.InvoiceLines il
    INNER JOIN Sales.Invoices i
        ON il.InvoiceID = i.InvoiceID
ORDER BY
    i.CustomerID,
    i.InvoiceDate;

-----------------------
-- Ranking functions --
-----------------------

-- "Normal" Ranking functions
SELECT TOP(250)
    il.InvoiceLineID,
    il.InvoiceID,
    i.CustomerID,
    ROW_NUMBER() OVER (ORDER BY il.InvoiceID) AS rownum,
    DENSE_RANK() OVER (ORDER BY il.InvoiceID) AS dr,
    RANK() OVER (ORDER BY il.InvoiceID) AS rk
FROM Sales.InvoiceLines il
    INNER JOIN Sales.Invoices i
        ON il.InvoiceID = i.InvoiceID
ORDER BY
    il.InvoiceLineID,
	rownum;

-- Ntile
WITH records AS
(
    SELECT TOP(250)
        il.InvoiceLineID,
        il.InvoiceID,
        i.CustomerID,
        il.LineProfit
    FROM Sales.InvoiceLines il
        INNER JOIN Sales.Invoices i
            ON il.InvoiceID = i.InvoiceID
    ORDER BY il.InvoiceLineID
)
SELECT
    il.InvoiceLineID,
    il.InvoiceID,
    il.CustomerID,
    il.LineProfit,
    NTILE(3) OVER (ORDER BY il.LineProfit) AS nt3,
    NTILE(5) OVER (ORDER BY il.LineProfit) AS nt5,
    NTILE(10) OVER (ORDER BY il.LineProfit) AS nt10,
    NTILE(20) OVER (ORDER BY il.LineProfit) AS nt20,
    NTILE(100) OVER (ORDER BY il.LineProfit) AS nt100
FROM records il
ORDER BY
    il.LineProfit;

----------------------
-- Offset functions --
----------------------

-- Note that all offset functions REQUIRE an ORDER BY clause!

-- LAG() and LEAD()
WITH records AS
(
    SELECT
        i.InvoiceDate,
        SUM(il.LineProfit) AS DailyProfit
    FROM Sales.InvoiceLines il
        INNER JOIN Sales.Invoices i
            ON il.InvoiceID = i.InvoiceID
    GROUP BY
        i.InvoiceDate
)
SELECT
    r.InvoiceDate,
    r.DailyProfit,
    LAG(r.DailyProfit) OVER (ORDER BY r.InvoiceDate) AS LagDefaultProfit,
    LAG(r.DailyProfit, 1) OVER (ORDER BY r.InvoiceDate) AS PriorDayProfit,
    LAG(r.DailyProfit, 2) OVER (ORDER BY r.InvoiceDate) AS PriorDay2Profit,
    LAG(r.DailyProfit, 7) OVER (ORDER BY r.InvoiceDate) AS PriorDay7Profit,
    LAG(r.DailyProfit, 14) OVER (ORDER BY r.InvoiceDate) AS PriorDay14Profit,
    LEAD(r.DailyProfit) OVER (ORDER BY r.InvoiceDate) AS LeadDefaultProfit,
    LEAD(r.DailyProfit, 1) OVER (ORDER BY r.InvoiceDate) AS NextDayProfit,
    LEAD(r.DailyProfit, 2) OVER (ORDER BY r.InvoiceDate) AS NextDay2Profit,
    LEAD(r.DailyProfit, 7) OVER (ORDER BY r.InvoiceDate) AS NextDay7Profit,
    LEAD(r.DailyProfit, 14) OVER (ORDER BY r.InvoiceDate) AS NextDay14Profit
FROM records r
ORDER BY
    r.InvoiceDate;

-- FIRST_VALUE() and LAST_VALUE()
WITH records AS
(
    SELECT
        i.InvoiceDate,
        SUM(il.LineProfit) AS DailyProfit
    FROM Sales.InvoiceLines il
        INNER JOIN Sales.Invoices i
            ON il.InvoiceID = i.InvoiceID
    GROUP BY
        i.InvoiceDate
)
SELECT
    r.InvoiceDate,
    r.DailyProfit,
    FIRST_VALUE(r.DailyProfit) OVER (ORDER BY r.InvoiceDate) AS DefaultFirstValue,
    LAST_VALUE(r.DailyProfit) OVER (ORDER BY r.InvoiceDate) AS DefaultLastValue
FROM records r
ORDER BY
    r.InvoiceDate;

-- Note that LAST_VALUE() "weirdness" and remember the default window!
WITH records AS
(
    SELECT
        i.InvoiceDate,
        SUM(il.LineProfit) AS DailyProfit
    FROM Sales.InvoiceLines il
        INNER JOIN Sales.Invoices i
            ON il.InvoiceID = i.InvoiceID
    GROUP BY
        i.InvoiceDate
)
SELECT
    r.InvoiceDate,
    r.DailyProfit,
    FIRST_VALUE(r.DailyProfit) OVER (ORDER BY r.InvoiceDate) AS DefaultFirstValue,
    LAST_VALUE(r.DailyProfit) OVER (
        ORDER BY r.InvoiceDate
        RANGE BETWEEN UNBOUNDED PRECEDING
            AND UNBOUNDED FOLLOWING) AS RealLastValue
FROM records r
ORDER BY
    r.InvoiceDate;

-- FIRST_VALUE() and LAST_VALUE() over partitions
WITH records AS
(
    SELECT
        i.InvoiceDate,
        i.CustomerID,
        SUM(il.LineProfit) AS DailyProfit
    FROM Sales.InvoiceLines il
        INNER JOIN Sales.Invoices i
            ON il.InvoiceID = i.InvoiceID
    GROUP BY
        i.InvoiceDate,
        i.CustomerID
)
SELECT
    r.InvoiceDate,
    r.CustomerID,
    r.DailyProfit,
    FIRST_VALUE(r.DailyProfit) OVER (
        PARTITION BY r.CustomerID
        ORDER BY r.InvoiceDate) AS DefaultFirstValue,
    LAST_VALUE(r.DailyProfit) OVER (
        PARTITION BY r.CustomerID
        ORDER BY r.InvoiceDate
        RANGE BETWEEN UNBOUNDED PRECEDING
            AND UNBOUNDED FOLLOWING) AS RealLastValue
FROM records r
ORDER BY
    r.CustomerID;

-- Ordering also works the other direction!
WITH records AS
(
    SELECT
        i.InvoiceDate,
        i.CustomerID,
        SUM(il.LineProfit) AS DailyProfit
    FROM Sales.InvoiceLines il
        INNER JOIN Sales.Invoices i
            ON il.InvoiceID = i.InvoiceID
    GROUP BY
        i.InvoiceDate,
        i.CustomerID
)
SELECT
    r.InvoiceDate,
    r.CustomerID,
    r.DailyProfit,
    FIRST_VALUE(r.DailyProfit) OVER (
        PARTITION BY r.CustomerID
        ORDER BY r.InvoiceDate) AS DefaultFirstValue,
    LAST_VALUE(r.DailyProfit) OVER (
        PARTITION BY r.CustomerID
        ORDER BY r.InvoiceDate
        RANGE BETWEEN UNBOUNDED PRECEDING
            AND UNBOUNDED FOLLOWING) AS RealLastValue,
    FIRST_VALUE(r.DailyProfit) OVER (
        PARTITION BY r.CustomerID
        ORDER BY r.InvoiceDate DESC) AS DescFirstValue,
    LAST_VALUE(r.DailyProfit) OVER (
        PARTITION BY r.CustomerID
        ORDER BY r.InvoiceDate DESC
        RANGE BETWEEN UNBOUNDED PRECEDING
            AND UNBOUNDED FOLLOWING) AS DescLastValue
FROM records r
ORDER BY
    r.CustomerID;

---------------------------
-- Statistical functions --
---------------------------

-- PERCENT_RANK(), easy mode
WITH records AS
(
    SELECT
        i.InvoiceDate,
        i.CustomerID,
        SUM(il.LineProfit) AS DailyProfit
    FROM Sales.InvoiceLines il
        INNER JOIN Sales.Invoices i
            ON il.InvoiceID = i.InvoiceID
    GROUP BY
        i.InvoiceDate,
        i.CustomerID
)
SELECT
    r.InvoiceDate,
    r.CustomerID,
    r.DailyProfit,
    PERCENT_RANK() OVER(ORDER BY r.DailyProfit) AS PercentRank
FROM records r
ORDER BY
	PercentRank DESC;

-- PERCENT_RANK() by customer
WITH records AS
(
    SELECT
        i.InvoiceDate,
        i.CustomerID,
        SUM(il.LineProfit) AS DailyProfit
    FROM Sales.InvoiceLines il
        INNER JOIN Sales.Invoices i
            ON il.InvoiceID = i.InvoiceID
    GROUP BY
        i.InvoiceDate,
        i.CustomerID
)
SELECT
    r.InvoiceDate,
    r.CustomerID,
    r.DailyProfit,
    PERCENT_RANK() OVER(
        PARTITION BY r.CustomerID
        ORDER BY r.DailyProfit) AS PercentRank
FROM records r
ORDER BY
    r.CustomerID,
    PercentRank;

-- Rank and distribution
WITH records AS
(
    SELECT
        i.InvoiceDate,
        i.CustomerID,
        SUM(il.LineProfit) AS DailyProfit
    FROM Sales.InvoiceLines il
        INNER JOIN Sales.Invoices i
            ON il.InvoiceID = i.InvoiceID
    GROUP BY
        i.InvoiceDate,
        i.CustomerID
)
SELECT
    r.InvoiceDate,
    r.CustomerID,
    r.DailyProfit,
    PERCENT_RANK() OVER(
        PARTITION BY r.CustomerID
        ORDER BY r.DailyProfit) AS PercentRank,
    CUME_DIST() OVER(
        PARTITION BY r.CustomerID
        ORDER BY r.DailyProfit) AS CumeDist
FROM records r
ORDER BY
    r.CustomerID,
    PercentRank;

-- Percentiles
WITH records AS
(
    SELECT
        i.InvoiceDate,
        i.CustomerID,
        SUM(il.LineProfit) AS DailyProfit
    FROM Sales.InvoiceLines il
        INNER JOIN Sales.Invoices i
            ON il.InvoiceID = i.InvoiceID
    GROUP BY
        i.InvoiceDate,
        i.CustomerID
)
SELECT
    r.CustomerID,
    r.InvoiceDate,
    r.DailyProfit,
    PERCENTILE_CONT(0.0) WITHIN GROUP (ORDER BY r.DailyProfit) OVER (PARTITION BY r.CustomerID) AS Min,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY r.DailyProfit) OVER (PARTITION BY r.CustomerID) AS Q1,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY r.DailyProfit) OVER (PARTITION BY r.CustomerID) AS Median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY r.DailyProfit) OVER (PARTITION BY r.CustomerID) AS Q3,
    PERCENTILE_CONT(1.0) WITHIN GROUP (ORDER BY r.DailyProfit) OVER (PARTITION BY r.CustomerID) AS Max
FROM records r
ORDER BY
    r.CustomerID DESC,
    r.InvoiceDate;

-- A variety of percentiles
WITH records AS
(
    SELECT
        i.InvoiceDate,
        i.CustomerID,
        SUM(il.LineProfit) AS DailyProfit
    FROM Sales.InvoiceLines il
        INNER JOIN Sales.Invoices i
            ON il.InvoiceID = i.InvoiceID
    GROUP BY
        i.InvoiceDate,
        i.CustomerID
)
SELECT
    r.CustomerID,
    r.InvoiceDate,
    r.DailyProfit,
    PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY r.DailyProfit) OVER (PARTITION BY r.CustomerID) AS MedianDisc,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY r.DailyProfit) OVER (PARTITION BY r.CustomerID) AS Median
FROM records r
ORDER BY
    r.CustomerID DESC,
    r.InvoiceDate;

---------------------------
-- Ordered set functions --
---------------------------

-- STRING_AGG() is the only ordered set function in SQL Server 2019.
SELECT
    SalesTerritory,
    StateProvinceCode
FROM Application.StateProvinces s;

SELECT
    SalesTerritory,
    STRING_AGG(StateProvinceCode, ',')  AS StatesList
FROM Application.StateProvinces s
GROUP BY
    SalesTerritory;

-- Sorting by state name
SELECT
    SalesTerritory,
    STRING_AGG(StateProvinceCode, ',')
        WITHIN GROUP(ORDER BY StateProvinceCode)  AS StatesList
FROM Application.StateProvinces s
GROUP BY
    SalesTerritory;
