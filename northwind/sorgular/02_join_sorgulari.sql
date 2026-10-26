/* =====================================================================
   02 - JOIN SORGULARI
   Konular: INNER JOIN, LEFT JOIN, çoklu JOIN, SELF JOIN, anti join
   Veritabanı: Northwind (SQL Server)
   ===================================================================== */
USE Northwind;
GO

-- 2.1 Ürünler, kategori ve tedarikçi adlarıyla birlikte
SELECT  p.ProductName,
        c.CategoryName,
        s.CompanyName AS Tedarikci,
        p.UnitPrice
FROM    Products   AS p
JOIN    Categories AS c ON c.CategoryID = p.CategoryID
JOIN    Suppliers  AS s ON s.SupplierID = p.SupplierID
ORDER BY c.CategoryName, p.ProductName;

-- 2.2 Siparişler: müşteri, çalışan ve kargo firmasıyla
SELECT  o.OrderID,
        o.OrderDate,
        cu.CompanyName                       AS Musteri,
        CONCAT(e.FirstName, ' ', e.LastName)     AS Calisan,
        sh.CompanyName                       AS KargoFirmasi
FROM    Orders    AS o
JOIN    Customers AS cu ON cu.CustomerID = o.CustomerID
JOIN    Employees AS e  ON e.EmployeeID  = o.EmployeeID
JOIN    Shippers  AS sh ON sh.ShipperID  = o.ShipVia
ORDER BY o.OrderDate;

-- 2.3 Hiç sipariş vermemiş müşteriler (LEFT JOIN ile anti join)
SELECT  cu.CustomerID,
        cu.CompanyName,
        cu.Country
FROM    Customers AS cu
LEFT JOIN Orders  AS o ON o.CustomerID = cu.CustomerID
WHERE   o.OrderID IS NULL;

-- 2.4 SELF JOIN: her çalışan ve bağlı olduğu yönetici
SELECT  CONCAT(e.FirstName, ' ', e.LastName)                     AS Calisan,
        e.Title                                               AS Unvan,
        CASE WHEN m.EmployeeID IS NULL THEN '(Yönetici yok)'
             ELSE CONCAT(m.FirstName, ' ', m.LastName) END   AS Yonetici
FROM    Employees AS e
LEFT JOIN Employees AS m ON m.EmployeeID = e.ReportsTo
ORDER BY Yonetici, Calisan;

-- 2.5 Sipariş satırı detayları ve satır tutarı
SELECT  o.OrderID,
        p.ProductName,
        od.UnitPrice,
        od.Quantity,
        od.Discount,
        CAST(od.UnitPrice * od.Quantity * (1 - od.Discount) AS DECIMAL(12, 2)) AS SatirTutari
FROM    Orders          AS o
JOIN    [Order Details] AS od ON od.OrderID  = o.OrderID
JOIN    Products        AS p  ON p.ProductID = od.ProductID
WHERE   o.OrderID = 10248;

-- 2.6 Çalışanların sorumlu olduğu bölgeler (çoka çok ilişki)
SELECT  CONCAT(e.FirstName, ' ', e.LastName) AS Calisan,
        r.RegionDescription            AS Bolge,
        t.TerritoryDescription         AS SorumluluBolgesi
FROM    Employees           AS e
JOIN    EmployeeTerritories AS et ON et.EmployeeID = e.EmployeeID
JOIN    Territories         AS t  ON t.TerritoryID = et.TerritoryID
JOIN    Region              AS r  ON r.RegionID    = t.RegionID
ORDER BY Calisan, Bolge;
