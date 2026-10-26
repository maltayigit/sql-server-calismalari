/* =====================================================================
   04 - ALT SORGULAR VE CTE
   Konular: skaler alt sorgu, IN / EXISTS, ilişkili alt sorgu,
            CTE (WITH), özyinelemeli (recursive) CTE
   Veritabanı: Northwind (SQL Server)
   ===================================================================== */
USE Northwind;
GO

-- 4.1 Ortalama fiyatın üzerindeki ürünler (skaler alt sorgu)
SELECT  ProductName,
        UnitPrice
FROM    Products
WHERE   UnitPrice > (SELECT AVG(UnitPrice) FROM Products)
ORDER BY UnitPrice DESC;

-- 4.2 "Beverages" kategorisinden ürün almış müşteriler (EXISTS)
SELECT  cu.CompanyName,
        cu.Country
FROM    Customers AS cu
WHERE   EXISTS (
            SELECT 1
            FROM   Orders          AS o
            JOIN   [Order Details] AS od ON od.OrderID   = o.OrderID
            JOIN   Products        AS p  ON p.ProductID  = od.ProductID
            JOIN   Categories      AS c  ON c.CategoryID = p.CategoryID
            WHERE  o.CustomerID   = cu.CustomerID
              AND  c.CategoryName = 'Beverages'
        )
ORDER BY cu.CompanyName;

-- 4.3 Kendi kategorisinin ortalama fiyatından pahalı ürünler (ilişkili alt sorgu)
SELECT  p.ProductName,
        p.CategoryID,
        p.UnitPrice
FROM    Products AS p
WHERE   p.UnitPrice > (
            SELECT AVG(p2.UnitPrice)
            FROM   Products AS p2
            WHERE  p2.CategoryID = p.CategoryID
        )
ORDER BY p.CategoryID, p.UnitPrice DESC;

-- 4.4 1998 yılında hiç satılmamış ürünler (NOT IN)
SELECT  ProductID,
        ProductName,
        Discontinued
FROM    Products
WHERE   ProductID NOT IN (
            SELECT DISTINCT od.ProductID
            FROM   [Order Details] AS od
            JOIN   Orders          AS o ON o.OrderID = od.OrderID
            WHERE  YEAR(o.OrderDate) = 1998
        )
ORDER BY ProductName;

-- 4.5 CTE: müşteri bazında toplam satış, sonra ortalamanın üzerindekiler
WITH MusteriSatis AS (
    SELECT  o.CustomerID,
            SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS NetSatis
    FROM    Orders          AS o
    JOIN    [Order Details] AS od ON od.OrderID = o.OrderID
    GROUP BY o.CustomerID
)
SELECT  cu.CompanyName,
        CAST(ms.NetSatis AS DECIMAL(12, 2)) AS NetSatis
FROM    MusteriSatis AS ms
JOIN    Customers    AS cu ON cu.CustomerID = ms.CustomerID
WHERE   ms.NetSatis > (SELECT AVG(NetSatis) FROM MusteriSatis)
ORDER BY ms.NetSatis DESC;

-- 4.6 Birden çok CTE: siparişlerin teslim süresi ve geç kalan siparişler
WITH Teslimat AS (
    SELECT  OrderID,
            CustomerID,
            OrderDate,
            RequiredDate,
            ShippedDate,
            DATEDIFF(DAY, OrderDate, ShippedDate) AS TeslimGunu
    FROM    Orders
    WHERE   ShippedDate IS NOT NULL
),
Gecikenler AS (
    SELECT  *
    FROM    Teslimat
    WHERE   ShippedDate > RequiredDate
)
SELECT  COUNT(*)                                     AS GecikenSiparis,
        (SELECT COUNT(*) FROM Teslimat)              AS KargolananSiparis,
        CAST(100.0 * COUNT(*) / (SELECT COUNT(*) FROM Teslimat) AS DECIMAL(5, 2)) AS GecikmeOraniYuzde
FROM    Gecikenler;

-- 4.7 Özyinelemeli CTE: şirket organizasyon şeması (yönetici hiyerarşisi)
WITH OrgSema AS (
    -- Başlangıç: kimseye bağlı olmayan üst yönetici
    SELECT  EmployeeID,
            CAST(CONCAT(FirstName, ' ', LastName) AS NVARCHAR(200)) AS Hiyerarsi,
            0                                                 AS Seviye
    FROM    Employees
    WHERE   ReportsTo IS NULL

    UNION ALL

    -- Tekrar: bir üst seviyeye bağlı çalışanlar
    SELECT  e.EmployeeID,
            CAST(CONCAT(o.Hiyerarsi, ' > ', e.FirstName, ' ', e.LastName) AS NVARCHAR(200)),
            o.Seviye + 1
    FROM    Employees AS e
    JOIN    OrgSema   AS o ON e.ReportsTo = o.EmployeeID
)
SELECT  Seviye,
        Hiyerarsi
FROM    OrgSema
ORDER BY Hiyerarsi;
