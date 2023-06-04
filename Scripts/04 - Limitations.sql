USE [WideWorldImporters]
GO

-- Windows and APPLY
-- Let's re-create #t1 and refill it.  Our goal is to delete duplicate rows.
DROP TABLE IF EXISTS #t1;

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

-- Remember that we used a common table expression to get rownum.
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

-- We then learn that the APPLY operator is awesome (and it is!) and want to do that here:
SELECT
	rn.*
FROM #t1 t1
	CROSS APPLY
	(
		SELECT
			t1.Id,
			t1.EventDate,
			t1.NumberOfAttendees,
			ROW_NUMBER() OVER (PARTITION BY t1.EventDate ORDER BY t1.Id) AS rownum
	) rn;

-- Why is this?  Because CROSS APPLY operates once per row in t1.
-- The window is therefore **that row** and not the entire table!
