/* =====================================================================
   03 - GRUPLAMA VE TOPLAMA
   Konular: GROUP BY, HAVING, COUNT, SUM, AVG, MIN, MAX, ROLLUP
   Net satış = UnitPrice * Quantity * (1 - Discount)
   Veritabanı: Northwind (SQL Server)
   ===================================================================== */
USE Northwind;
GO

-- 3.1 Kategori bazında ürün sayısı ve ortalama fiyat
SELECT  c.CategoryName,
        COUNT(*)                                 AS UrunSayisi,
        CAST(AVG(p.UnitPrice) AS DECIMAL(10, 2)) AS OrtalamaFiyat,
        MIN(p.UnitPrice)                         AS EnDusukFiyat,
        MAX(p.UnitPrice)                         AS EnYuksekFiyat
FROM    Products   AS p
JOIN    Categories AS c ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryName
ORDER BY UrunSayisi DESC;

-- 3.2 Kategori bazında net satış
SELECT  c.CategoryName,
        CAST(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS DECIMAL(12, 2)) AS NetSatis
FROM    [Order Details] AS od
JOIN    Products        AS p ON p.ProductID  = od.ProductID
JOIN    Categories      AS c ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryName
ORDER BY NetSatis DESC;

-- 3.3 Yıllara göre sipariş sayısı ve net satış
SELECT  YEAR(o.OrderDate)                                                        AS Yil,
        COUNT(DISTINCT o.OrderID)                                                AS SiparisSayisi,
        CAST(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS DECIMAL(12, 2)) AS NetSatis
FROM    Orders          AS o
JOIN    [Order Details] AS od ON od.OrderID = o.OrderID
GROUP BY YEAR(o.OrderDate)
ORDER BY Yil;

-- 3.4 10'dan fazla sipariş veren müşteriler (HAVING)
SELECT  cu.CompanyName,
        cu.Country,
        COUNT(o.OrderID) AS SiparisSayisi
FROM    Customers AS cu
JOIN    Orders    AS o ON o.CustomerID = cu.CustomerID
GROUP BY cu.CompanyName, cu.Country
HAVING  COUNT(o.OrderID) > 10
ORDER BY SiparisSayisi DESC;

-- 3.5 Çalışan performansı: sipariş sayısı, ciro ve ortalama sipariş tutarı
SELECT  CONCAT(e.FirstName, ' ', e.LastName)                                            AS Calisan,
        COUNT(DISTINCT o.OrderID)                                                   AS SiparisSayisi,
        CAST(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS DECIMAL(12, 2)) AS NetSatis,
        CAST(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount))
             / COUNT(DISTINCT o.OrderID) AS DECIMAL(12, 2))                         AS OrtSiparisTutari
FROM    Employees       AS e
JOIN    Orders          AS o  ON o.EmployeeID = e.EmployeeID
JOIN    [Order Details] AS od ON od.OrderID   = o.OrderID
GROUP BY e.FirstName, e.LastName
ORDER BY NetSatis DESC;

-- 3.6 Ülke bazında ortalama kargo ücreti (en az 20 sipariş olan ülkeler)
SELECT  ShipCountry,
        COUNT(*)                               AS SiparisSayisi,
        CAST(AVG(Freight) AS DECIMAL(10, 2))   AS OrtKargoUcreti
FROM    Orders
GROUP BY ShipCountry
HAVING  COUNT(*) >= 20
ORDER BY OrtKargoUcreti DESC;

-- 3.7 ROLLUP: yıl ve kategori bazında satış + ara toplamlar + genel toplam
SELECT  YEAR(o.OrderDate)                                                        AS Yil,
        c.CategoryName,
        CAST(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS DECIMAL(12, 2)) AS NetSatis
FROM    Orders          AS o
JOIN    [Order Details] AS od ON od.OrderID   = o.OrderID
JOIN    Products        AS p  ON p.ProductID  = od.ProductID
JOIN    Categories      AS c  ON c.CategoryID = p.CategoryID
GROUP BY ROLLUP (YEAR(o.OrderDate), c.CategoryName)
ORDER BY Yil, c.CategoryName;
