DROP TABLE IF EXISTS `chinook_data.Report`;
CREATE TABLE `chinook_data.Report`
PARTITION BY DATE(InvoiceDate)
CLUSTER BY CustomerId AS 
WITH BaseData AS(
  SELECT
    c.CustomerId,
    c.Country,
    c.FirstName,
    c.LastName,
    i.InvoiceDate,
    i.InvoiceId,
    i.Total AS TotalSale,
    il.InvoiceLineId,
    il.Quantity,
    il.UnitPrice,
    t.TrackId,
    t.Name AS TrackName,
    t.AlbumId,
    g.Name AS GenreName
  FROM `chinook_data.Customer` c
  INNER JOIN `chinook_data.Invoice` i ON c.CustomerId=i.CustomerId
  INNER JOIN `chinook_data.InvoiceLine` il ON i.InvoiceId=il.InvoiceId
  INNER JOIN `chinook_data.Track` t ON il.TrackId=t.TrackId
  INNER JOIN `chinook_data.Genre` g ON g.GenreId=t.GenreId
),
Deduplicated As(
  SELECT
    *,ROW_NUMBER() OVER(PARTITION BY InvoiceLineId ORDER BY InvoiceDate) AS RowNum
  FROM BaseData
),
CleanData AS(
  SELECT*
  FROM Deduplicated
  WHERE RowNum=1
),
NewFeatures AS(
  SELECT
    *,
    DATE(InvoiceDate) AS InvoiceDateOnly,
    FORMAT_TIMESTAMP('%Y-%m', InvoiceDate) AS InvoiceMonth,
    SUM(Quantity * UnitPrice) OVER(PARTITION BY CustomerId) AS TotalCustomerSale,
    SUM(TotalSale) OVER(PARTITION BY CustomerId) / NULLIF( COUNT(DISTINCT InvoiceId) OVER(PARTITION BY CustomerId),0) AS AvgPurchase,
    
    CASE 
      WHEN DATE_DIFF(CURRENT_DATE(), MAX(DATE(InvoiceDate)) OVER(PARTITION BY CustomerId), MONTH) > 6
      THEN 1
      ELSE 0
    END AS ChurnFlag,

    CASE
      WHEN SUM(Quantity * UnitPrice) OVER(PARTITION BY CustomerId) <40 THEN 'Low_Spending'
      WHEN SUM(Quantity * UnitPrice) OVER(PARTITION BY CustomerId) BETWEEN 40 AND 45 THEN 'Medium_Spending'
      ELSE 'High_Spending'
    END AS CustomerSegment,


  FROM CleanData
)
SELECT
  CustomerId,
  Country,
  FirstName,
  LastName,
  InvoiceDate,
  InvoiceId,
  TotalSale,
  InvoiceLineId,
  Quantity,
  UnitPrice,
  TrackId,
  TrackName,
  AlbumId,
  GenreName,
  InvoiceDateOnly,
  InvoiceMonth,
  TotalCustomerSale,
  AvgPurchase,
  ChurnFlag,
  CustomerSegment
FROM NewFeatures;






  





