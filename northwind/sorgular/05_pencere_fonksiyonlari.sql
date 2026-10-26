/* =====================================================================
   05 - PENCERE (WINDOW) FONKSİYONLARI
   Konular: ROW_NUMBER, RANK, DENSE_RANK, NTILE, SUM() OVER,
            LAG, kümülatif toplam, pay hesaplama
   Veritabanı: Northwind (SQL Server)
   ===================================================================== */
USE Northwind;
GO

-- 5.1 Her kategorideki en pahalı 3 ürün (ROW_NUMBER)
WITH Sirali AS (
    SELECT  c.CategoryName,
            p.ProductName,
            p.UnitPrice,
            ROW_NUMBER() OVER (PARTITION BY c.CategoryName ORDER BY p.UnitPrice DESC) AS Sira
    FROM    Products   AS p
    JOIN    Categories AS c ON c.CategoryID = p.CategoryID
)
SELECT  CategoryName,
        Sira,
        ProductName,
        UnitPrice
FROM    Sirali
WHERE   Sira <= 3
ORDER BY CategoryName, Sira;

-- 5.2 Ürünlerin satış sıralaması (RANK ve DENSE_RANK farkı)
WITH UrunSatis AS (
    SELECT  p.ProductName,
            SUM(od.Quantity) AS ToplamAdet
    FROM    [Order Details] AS od
    JOIN    Products        AS p ON p.ProductID = od.ProductID
    GROUP BY p.ProductName
)
SELECT  ProductName,
        ToplamAdet,
        RANK()       OVER (ORDER BY ToplamAdet DESC) AS Rank_,
        DENSE_RANK() OVER (ORDER BY ToplamAdet DESC) AS DenseRank_
FROM    UrunSatis
ORDER BY ToplamAdet DESC;

-- 5.3 Aylık satış ve yıl içi kümülatif toplam
WITH Aylik AS (
    SELECT  YEAR(o.OrderDate)  AS Yil,
            MONTH(o.OrderDate) AS Ay,
            SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS NetSatis
    FROM    Orders          AS o
    JOIN    [Order Details] AS od ON od.OrderID = o.OrderID
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
)
SELECT  Yil,
        Ay,
        CAST(NetSatis AS DECIMAL(12, 2)) AS NetSatis,
        CAST(SUM(NetSatis) OVER (PARTITION BY Yil ORDER BY Ay
                                 ROWS UNBOUNDED PRECEDING) AS DECIMAL(12, 2)) AS YilIciKumulatif
FROM    Aylik
ORDER BY Yil, Ay;

-- 5.4 Aydan aya değişim yüzdesi (LAG)
WITH Aylik AS (
    SELECT  DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1) AS AyBasi,
            SUM(od.UnitPrice * od.Quantity * (1 - od.Discount))    AS NetSatis
    FROM    Orders          AS o
    JOIN    [Order Details] AS od ON od.OrderID = o.OrderID
    GROUP BY DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1)
)
SELECT  AyBasi,
        CAST(NetSatis AS DECIMAL(12, 2))                          AS NetSatis,
        CAST(LAG(NetSatis) OVER (ORDER BY AyBasi) AS DECIMAL(12, 2)) AS OncekiAy,
        CAST(100.0 * (NetSatis - LAG(NetSatis) OVER (ORDER BY AyBasi))
             / LAG(NetSatis) OVER (ORDER BY AyBasi) AS DECIMAL(8, 2)) AS DegisimYuzde
FROM    Aylik
ORDER BY AyBasi;

-- 5.5 Her kategorinin toplam satıştaki payı
WITH KategoriSatis AS (
    SELECT  c.CategoryName,
            SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS NetSatis
    FROM    [Order Details] AS od
    JOIN    Products        AS p ON p.ProductID  = od.ProductID
    JOIN    Categories      AS c ON c.CategoryID = p.CategoryID
    GROUP BY c.CategoryName
)
SELECT  CategoryName,
        CAST(NetSatis AS DECIMAL(12, 2))                               AS NetSatis,
        CAST(100.0 * NetSatis / SUM(NetSatis) OVER () AS DECIMAL(5, 2)) AS PayYuzde
FROM    KategoriSatis
ORDER BY NetSatis DESC;

-- 5.6 Müşterileri satış tutarına göre 4 dilime ayırma (NTILE)
WITH MusteriSatis AS (
    SELECT  o.CustomerID,
            SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS NetSatis
    FROM    Orders          AS o
    JOIN    [Order Details] AS od ON od.OrderID = o.OrderID
    GROUP BY o.CustomerID
)
SELECT  cu.CompanyName,
        CAST(ms.NetSatis AS DECIMAL(12, 2))       AS NetSatis,
        NTILE(4) OVER (ORDER BY ms.NetSatis DESC) AS Ceyreklik
FROM    MusteriSatis AS ms
JOIN    Customers    AS cu ON cu.CustomerID = ms.CustomerID
ORDER BY ms.NetSatis DESC;
