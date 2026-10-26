/* =====================================================================
   01 - TEMEL SORGULAR
   Konular: SELECT, WHERE, ORDER BY, TOP, DISTINCT, LIKE, IN, BETWEEN,
            IS NULL, hesaplanmış sütunlar, CASE
   Veritabanı: Northwind (SQL Server)
   ===================================================================== */
USE Northwind;
GO

-- 1.1 Stokta 10 adetten az kalan ve satışı sürdürülen ürünler
SELECT  ProductID,
        ProductName,
        UnitsInStock,
        ReorderLevel
FROM    Products
WHERE   UnitsInStock < 10
  AND   Discontinued = 0
ORDER BY UnitsInStock;

-- 1.2 En pahalı 5 ürün
SELECT TOP 5
        ProductName,
        UnitPrice
FROM    Products
ORDER BY UnitPrice DESC;

-- 1.3 Müşterilerin bulunduğu ülkeler (tekrarsız)
SELECT DISTINCT Country
FROM    Customers
ORDER BY Country;

-- 1.4 Adı "Ch" ile başlayan ürünler
SELECT  ProductName,
        QuantityPerUnit
FROM    Products
WHERE   ProductName LIKE 'Ch%';

-- 1.5 Almanya, Fransa veya İspanya'daki müşteriler
SELECT  CompanyName,
        City,
        Country
FROM    Customers
WHERE   Country IN ('Germany', 'France', 'Spain')
ORDER BY Country, City;

-- 1.6 1997 yılının ilk çeyreğinde verilen siparişler
SELECT  OrderID,
        CustomerID,
        OrderDate
FROM    Orders
WHERE   OrderDate BETWEEN '1997-01-01' AND '1997-03-31'
ORDER BY OrderDate;

-- 1.7 Henüz kargoya verilmemiş siparişler
SELECT  OrderID,
        CustomerID,
        OrderDate,
        RequiredDate
FROM    Orders
WHERE   ShippedDate IS NULL
ORDER BY RequiredDate;

-- 1.8 Hesaplanmış sütun: stok değeri
SELECT  ProductName,
        UnitPrice,
        UnitsInStock,
        UnitPrice * UnitsInStock AS StokDegeri
FROM    Products
WHERE   UnitsInStock > 0
ORDER BY StokDegeri DESC;

-- 1.9 CASE ile fiyat segmenti
SELECT  ProductName,
        UnitPrice,
        CASE
            WHEN UnitPrice < 20 THEN 'Ekonomik'
            WHEN UnitPrice < 50 THEN 'Orta'
            ELSE 'Premium'
        END AS FiyatSegmenti
FROM    Products
ORDER BY UnitPrice;
