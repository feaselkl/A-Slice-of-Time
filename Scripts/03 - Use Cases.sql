USE [WideWorldImporters]
GO

-- Delete "duplicate" rows
CREATE TABLE #t1
(
    Id INT IDENTITY(1,1) NOT NULL,
    EventDate DATE NOT NULL,
    NumberOfAttendees INT NOT NULL
);

-- Our first round of insertions
INSERT INTO #t1(EventDate, NumberOfAttendees) VALUES
('2021-04-01', 150),
('2021-04-08', 165),
('2021-04-15', 144),
('2021-04-22', 170),
('2021-04-29', 168),
('2021-05-06', 164),
('2021-05-13', 152),
('2021-05-20', 158),
('2021-05-27', 168),
('2021-06-03', 170),
('2021-06-10', 161),
('2021-06-17', 155);


-- Due to a bug in our system, we accidentally added some rows again.
INSERT INTO #t1(EventDate, NumberOfAttendees) VALUES
('2021-04-01', 150),
('2021-04-01', 150),
('2021-04-01', 150),
('2021-04-01', 150),
('2021-04-08', 165),
('2021-04-08', 165),
('2021-04-29', 168);

-- Look at the mess we've made.
SELECT * FROM #t1;

-- Figure out which are "duplicates" and keep the one with the lowest ID
WITH records AS
(
    SELECT
        t1.Id,
        t1.EventDate,
        t1.NumberOfAttendees,
        ROW_NUMBER() OVER (PARTITION BY t1.EventDate ORDER BY t1.Id) AS rownum
    FROM #t1 t1
)
SELECT *
FROM records
ORDER BY
    EventDate,
    Id;

-- Now delete them.
WITH records AS
(
    SELECT
        t1.Id,
        t1.EventDate,
        t1.NumberOfAttendees,
        ROW_NUMBER() OVER (PARTITION BY t1.EventDate ORDER BY t1.Id) AS rownum
    FROM #t1 t1
)
DELETE FROM records
WHERE
    rownum > 1;

-- Looking good!
SELECT * FROM #t1;

-- Calculate running total
SELECT
    t1.Id,
    t1.EventDate,
    t1.NumberOfAttendees,
    SUM(t1.NumberOfAttendees) OVER (
        ORDER BY t1.EventDate
        RANGE BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
    ) AS RunningTotal
FROM #t1 t1;

-- Calculate moving average
-- Suppose we want a 3-week moving average
SELECT
    t1.Id,
    t1.EventDate,
    t1.NumberOfAttendees,
    AVG(t1.NumberOfAttendees) OVER (
        ORDER BY t1.EventDate
        ROWS BETWEEN 2 PRECEDING
            AND CURRENT ROW
    ) AS MovingAverage3
FROM #t1 t1;

-- Calculate percent of total
SELECT
    t1.Id,
    t1.EventDate,
    t1.NumberOfAttendees,
    SUM(t1.NumberOfAttendees) OVER (
        ORDER BY t1.EventDate
        RANGE BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
    ) AS RunningTotal,
    SUM(t1.NumberOfAttendees) OVER () AS GrandTotal,
    1.0 * t1.NumberOfAttendees / SUM(t1.NumberOfAttendees) OVER () AS PercentOfTotal,
    1.0 * SUM(t1.NumberOfAttendees) OVER (
        ORDER BY t1.EventDate
        RANGE BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
    ) / SUM(t1.NumberOfAttendees) OVER () AS CumulativePercent
FROM #t1 t1;

-- Get the latest N values
-- Review the set of customers
SELECT
    c.CustomerID,
    c.CustomerName
FROM Sales.Customers c
WHERE
    CustomerName NOT LIKE N'% Toys%';

-- Find the latest 5 orders for each customer
WITH customers AS
(
    SELECT
        c.CustomerID,
        c.CustomerName
    FROM Sales.Customers c
    WHERE
        CustomerName NOT LIKE N'% Toys%'
),
invoices AS
(
    SELECT
        i.CustomerID,
        i.InvoiceID,
        i.InvoiceDate,
        i.TotalChillerItems,
        i.TotalDryItems,
        ROW_NUMBER() OVER (PARTITION BY i.CustomerID ORDER BY i.InvoiceDate DESC) AS rownum
    FROM Sales.InvoicesSmall i
        INNER JOIN customers c
            ON i.CustomerID = c.CustomerID
)
SELECT *
FROM customers c
    LEFT OUTER JOIN invoices i
        ON c.CustomerID = i.CustomerID
        AND rownum <= 5;

-- Find the distinct number of customers who have ordered something over time
WITH records AS
(
	SELECT
		OrderDate,
		CASE
			WHEN ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate) = 1 THEN CustomerID
		END AS DistinctCustomerID
	FROM Sales.Orders o
)
SELECT DISTINCT
	OrderDate,
	COUNT(DistinctCustomerID) OVER (ORDER BY OrderDate) AS NumCustomers
FROM records r
ORDER BY
	OrderDate;

-- Turn start date and end date into an event system
-- Our goal:  for each customer, what is the largest number of orders en route at any point in time?
-- Use Order Date as the start point and Expected Delivery Date as the end point.
SELECT TOP(10) *
FROM Sales.Orders o;

WITH StartStopPoints AS
(
	SELECT
		o.CustomerID,
		o.OrderDate AS TimeUTC,
		1 AS IsStartingPoint,
		ROW_NUMBER() OVER (PARTITION BY o.CustomerID ORDER BY o.OrderDate) AS StartOrdinal
	FROM Sales.Orders o

	UNION ALL

	SELECT
		o.CustomerID,
		o.ExpectedDeliveryDate AS TimeUTC,
		0 AS IsStartingPoint,
		NULL AS StartOrdinal
	FROM Sales.Orders o
),
StartStopOrder AS
(
	SELECT
		s.CustomerID,
		s.TimeUTC,
		s.IsStartingPoint,
		s.StartOrdinal,
		ROW_NUMBER() OVER (PARTITION BY s.CustomerID ORDER BY s.TimeUTC, s.IsStartingPoint) AS StartOrEndOrdinal
	FROM StartStopPoints s
)
SELECT
	s.CustomerID,
	MAX(2 * s.StartOrdinal - s.StartOrEndOrdinal) AS MaxConcurrentOrders
FROM StartStopOrder s
WHERE
	s.IsStartingPoint = 1
GROUP BY
	s.CustomerID
ORDER BY
	MaxConcurrentOrders DESC,
	CustomerID ASC;
