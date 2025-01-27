## 1-DATA CLEANING

UPDATE `chinook_data.Customer`
SET Email='unknown@email.com'
WHERE Email IS NULL;

DELETE FROM `chinook_data.Invoice`
WHERE Total<0;

UPDATE `chinook_data.InvoiceLine`
SET Quantity= (
    SELECT CAST(AVG(Quantity) AS int64)
    FROM `chinook_data.InvoiceLine`
)
WHERE Quantity IS NULL;


#Deduplication

DELETE FROM `chinook_data.Track_cluster`
WHERE TrackId IN(
    SELECT TrackId
    FROM (
        SELECT TrackId,ROW_NUMBER() OVER(PARTITION BY Name,AlbumId,MediaTypeId ORDER BY TrackId) AS RowNumber
        FROM `chinook_data.Track_cluster`
    )
    WHERE RowNumber >1
);




## 2-DATA TRANSFORMATION

#Calculate the month-over-month growth rate of revenue.

WITH MountlyRevanue AS(
    SELECT
        EXTRACT(YEAR FROM i.InvoiceDate) AS Year,
        Extract(MONTH FROM i.InvoiceDate) AS Month,
        SUM(il.UnitPrice * il.Quantity) AS Revanue
    FROM `chinook_data.Invoice` i
    JOIN `chinook_data.InvoiceLine` il ON i.InvoiceId=il.InvoiceLineId
    GROUP BY Year, Month
)
SELECT 
    Year,
    Month,
    Revanue,
    LAG(Revanue) OVER (ORDER BY Year,Month) AS PreviousMonthRevanue,
    ROUND((Revanue - LAG(Revanue) OVER (ORDER BY Year,Month)) / LAG(Revanue) OVER (ORDER BY Year,Month)*100,2) AS GrowthRate
FROM MountlyRevanue LIMIT 15;

#Add Date Column

ALTER TABLE `chinook_data.Invoice`
ADD COLUMN InvoiceYearMonth DATE;

UPDATE `chinook_data.Invoice`
SET InvoiceYearMonth = DATE(InvoiceDate)
WHERE InvoiceYearMonth IS NULL;


#Partitioning/Clustering

CREATE TABLE `chinook_data.Invoice_partitioned`
PARTITION BY DATE(InvoiceDate ) AS
SELECT *,CAST(InvoiceDate AS DATE) AS InvoiceDATE_cast
FROM `chinook_data.Invoice`;


CREATE Table `chinook_data.Track_cluster`
CLUSTER BY Name AS 
SELECT * FROM `chinook_data.Track`;


# Customer Segmentation

WITH CustomerSegment AS(
    SELECT
        c.CustomerId,
        c.FirstName,
        c.LastName,
        SUM(i.Total) AS TotalSpent
    FROM `chinook_data.Customer` c
    JOIN `chinook_data.Invoice_partitioned` i ON c.CustomerId=i.CustomerId
    GROUP BY c.CustomerId,c.FirstName,c.LastName
    ORDER BY TotalSpent DESC
)
SELECT 
    *,
    CASE 
        WHEN CustomerSegment.TotalSpent <10 THEN 'Low_Spending'
        WHEN TotalSpent BETWEEN 10 AND 30 THEN 'Medium_Spending'
        ELSE 'High_Spending'
    END AS Segment
FROM CustomerSegment;



## 3-QUERY TASKS

#Calculate the total revenue generated by each customer, sorted by the highest revenue.
SELECT 
    c.CustomerId,
    CONCAT(c.FirstName,' ',c.LastName) AS CustomerName,
    SUM(il.Quantity * il.UnitPrice) AS Revanue
FROM `chinook_data.Invoice` i
JOIN `chinook_data.InvoiceLine` il ON i.InvoiceId=il.InvoiceId
JOIN `chinook_data.Customer` c ON c.CustomerId=i.CustomerId
GROUP BY c.CustomerId,c.FirstName,c.LastName
ORDER BY Revanue DESC;


#Find the top 5 tracks by total sales revenue, including their artist names.

SELECT
    ar.Name AS ArtistName, 
    tr.Name AS TrackName,
    SUM(il.Quantity * il.Quantity) AS Revanue
FROM `chinook_data.Artist` ar
JOIN `chinook_data.Album` al ON ar.ArtistId=al.ArtistId
JOIN `chinook_data.Track` tr ON al.AlbumId=tr.AlbumId
JOIN `chinook_data.InvoiceLine` il ON tr.TrackId=il.TrackId
GROUP BY ar.Name,tr.Name
ORDER BY Revanue DESC
LIMIT 5;



#Calculate the total revenue for each month and year, and identify the months with the highest revenue.

SELECT
    EXTRACT(YEAR FROM i.InvoiceDate) AS Year,
    EXTRACT(MONTH FROM i.InvoiceDate) AS Month,
    SUM(il.UnitPrice * il.Quantity) Revanue
FROM `chinook_data.Invoice` i
JOIN `chinook_data.InvoiceLine` il ON i.InvoiceId=il.InvoiceId
GROUP BY Year,Month
ORDER BY Revanue;



#Identify the most popular genres based on the total revenue generated.

SELECT
    gr.Name AS GenreName,
    SUM(il.UnitPrice * il.Quantity) AS Revanue
FROM `chinook_data.InvoiceLine` il
JOIN `chinook_data.Track` tr ON tr.TrackId=il.TrackId
JOIN `chinook_data.Genre` gr ON gr.GenreId=tr.GenreId
GROUP BY GenreName
ORDER BY Revanue DESC; 



#Identify the customers with the highest number of invoices and their total revenue.

SELECT
    c.CustomerId,
    CONCAT(c.FirstName, ' ',c.LastName) AS CustomerName,
    COUNT(il.InvoiceId) AS InvoiceNumber,
    SUM(il.Quantity * il.Quantity) AS Revanue
FROM `chinook_data.Customer` c
JOIN `chinook_data.Invoice` i ON c.CustomerId=i.CustomerId
JOIN `chinook_data.InvoiceLine` il ON i.InvoiceId=il.InvoiceLineId
GROUP BY c.CustomerId, CustomerName
ORDER BY InvoiceNumber DESC , Revanue DESC;




#Loyalty Wiew

CREATE VIEW `chinook_data.customer_loyalty` AS
SELECT
    c.CustomerId,
    CONCAT(c.FirstName,' ',c.LastName) AS CustomerName,
    COUNT(i.InvoiceId) AS TotalInvoices,
    SUM(il.UnitPrice * il.Quantity) AS TotalRevanue,
    i.Total,
    ROUND(SUM(il.UnitPrice * il.Quantity) / COUNT(i.InvoiceId),2) AS AvgRevanuePerInvoice
FROM `chinook_data.Customer` c
JOIN `chinook_data.Invoice_partitioned` i ON c.CustomerId=i.CustomerId
JOIN `chinook_data.InvoiceLine` il ON i.InvoiceId=il.InvoiceId
GROUP BY c.CustomerId,i.Total,CustomerName;

SELECT * FROM `chinook_data.customer_loyalty`;



#YoY Growth Analysis

WITH YearlyRevanue AS(
    SELECT
        EXTRACT(YEAR FROM i.InvoiceDate ) AS Year,
        i.Total AS TotalRevanue
    FROM `chinook_data.Invoice_partitioned` i
    JOIN `chinook_data.InvoiceLine` il ON i.InvoiceId=il.InvoiceId
    GROUP BY TotalRevanue, Year
)
SELECT
    Year,
    TotalRevanue,
    LAG(TotalRevanue) OVER(ORDER BY Year) AS PreviousYear,
    ROUND(((LAG(TotalRevanue) OVER(ORDER BY Year))-TotalRevanue) /  LAG(TotalRevanue) OVER(ORDER BY Year)*100,2) AS YoYGrowthRate
FROM YearlyRevanue;



#Identify the most popular genre for each country.


WITH MostGenre AS(
    SELECT
        c.CustomerId,
        c.Country AS Country,
        g.Name AS GenreName,
        COUNT(il.InvoiceLineId) AS Purchases
    FROM `chinook_data.Customer` c 
    JOIN `chinook_data.Invoice_partitioned` i ON c.CustomerId=i.CustomerId
    JOIN `chinook_data.InvoiceLine` il ON il.InvoiceId=i.InvoiceId
    JOIN `chinook_data.Track_cluster` t ON t.TrackId=il.TrackId
    JOIN `chinook_data.Genre` g ON g.GenreId=t.GenreId
    GROUP BY c.CustomerId,c.Country,g.Name
)
SELECT 
    Country,
    GenreName,
    Purchases
FROM (
    SELECT *,
    ROW_NUMBER() OVER(PARTITION BY Country ORDER BY Purchases) AS RANK
    FROM MostGenre
)
WHERE Rank=1










