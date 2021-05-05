USE [WideWorldImporters]
GO

-- A minimalistic window function
-- ROW_NUMBER() requires an ORDER BY clause
SELECT
    c.CustomerID,
    c.CustomerName,
    c.DeliveryCityID,
    ROW_NUMBER() OVER (ORDER BY CustomerName) AS rownum
FROM Sales.Customers c;

-- Add PARTITION BY to spice things up
SELECT
    c.CustomerID,
    c.CustomerName,
    c.PostalPostalCode,
    ROW_NUMBER() OVER (
        PARTITION BY c.PostalPostalCode 
        ORDER BY CustomerName) AS rownum
FROM Sales.Customers c;
GO
