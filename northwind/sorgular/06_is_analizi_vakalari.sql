/* =====================================================================
   06 - İŞ ANALİZİ VAKALARI
   Gerçek iş sorularına SQL ile cevap:
     6.1 RFM müşteri segmentasyonu
     6.2 ABC (Pareto) ürün analizi
     6.3 Kargo firması performansı
     6.4 Müşteri elde tutma: ilk sipariş yılına göre kohort
     6.5 Birlikte satın alınan ürün çiftleri (sepet analizi)
   Veritabanı: Northwind (SQL Server)
   ===================================================================== */
USE Northwind;
GO

/* ---------------------------------------------------------------------
   6.1 RFM SEGMENTASYONU
   R (Recency)   : son siparişten bu yana geçen gün (az = iyi)
   F (Frequency) : sipariş sayısı
   M (Monetary)  : toplam net harcama
   Her boyut 1-4 arası puanlanır (4 = en iyi).
   Referans tarih: veri setindeki son siparişten bir gün sonrası.
   --------------------------------------------------------------------- */
WITH Referans AS (
    SELECT DATEADD(DAY, 1, MAX(OrderDate)) AS RefTarih FROM Orders
),
Ham AS (
    SELECT  o.CustomerID,
            DATEDIFF(DAY, MAX(o.OrderDate), (SELECT RefTarih FROM Referans)) AS Recency,
            COUNT(DISTINCT o.OrderID)                                        AS Frequency,
            SUM(od.UnitPrice * od.Quantity * (1 - od.Discount))              AS Monetary
    FROM    Orders          AS o
    JOIN    [Order Details] AS od ON od.OrderID = o.OrderID
    GROUP BY o.CustomerID
),
Puan AS (
    SELECT  *,
            NTILE(4) OVER (ORDER BY Recency DESC) AS R,
            NTILE(4) OVER (ORDER BY Frequency)    AS F,
            NTILE(4) OVER (ORDER BY Monetary)     AS M
    FROM    Ham
)
SELECT  cu.CompanyName,
        p.Recency,
        p.Frequency,
        CAST(p.Monetary AS DECIMAL(12, 2)) AS Monetary,
        p.R, p.F, p.M,
        CASE
            WHEN p.R >= 3 AND p.F >= 3 AND p.M >= 3 THEN 'Şampiyon'
            WHEN p.R >= 3 AND p.F >= 2              THEN 'Sadık'
            WHEN p.R <= 2 AND p.F >= 3              THEN 'Kaybedilme Riski'
            WHEN p.R = 1                            THEN 'Uykuda'
            ELSE 'Gelişmekte'
        END AS Segment
FROM    Puan      AS p
JOIN    Customers AS cu ON cu.CustomerID = p.CustomerID
ORDER BY p.Monetary DESC;

/* ---------------------------------------------------------------------
   6.2 ABC (PARETO) ANALİZİ
   A: cironun ilk %80'ini oluşturan ürünler
   B: sonraki %15
   C: kalan %5
   --------------------------------------------------------------------- */
WITH UrunSatis AS (
    SELECT  p.ProductName,
            SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS NetSatis
    FROM    [Order Details] AS od
    JOIN    Products        AS p ON p.ProductID = od.ProductID
    GROUP BY p.ProductName
),
Kumulatif AS (
    SELECT  ProductName,
            NetSatis,
            SUM(NetSatis) OVER (ORDER BY NetSatis DESC ROWS UNBOUNDED PRECEDING)
              / SUM(NetSatis) OVER () AS KumulatifPay
    FROM    UrunSatis
)
SELECT  ProductName,
        CAST(NetSatis AS DECIMAL(12, 2))             AS NetSatis,
        CAST(100 * KumulatifPay AS DECIMAL(5, 2))    AS KumulatifPayYuzde,
        CASE
            WHEN KumulatifPay <= 0.80 THEN 'A'
            WHEN KumulatifPay <= 0.95 THEN 'B'
            ELSE 'C'
        END AS AbcSinifi
FROM    Kumulatif
ORDER BY NetSatis DESC;

-- 6.2b ABC sınıflarının özeti
WITH UrunSatis AS (
    SELECT  od.ProductID,
            SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS NetSatis
    FROM    [Order Details] AS od
    GROUP BY od.ProductID
),
Siniflar AS (
    SELECT  ProductID,
            NetSatis,
            CASE
                WHEN SUM(NetSatis) OVER (ORDER BY NetSatis DESC ROWS UNBOUNDED PRECEDING)
                     / SUM(NetSatis) OVER () <= 0.80 THEN 'A'
                WHEN SUM(NetSatis) OVER (ORDER BY NetSatis DESC ROWS UNBOUNDED PRECEDING)
                     / SUM(NetSatis) OVER () <= 0.95 THEN 'B'
                ELSE 'C'
            END AS AbcSinifi
    FROM    UrunSatis
)
SELECT  AbcSinifi,
        COUNT(*)                                                      AS UrunSayisi,
        CAST(100.0 * SUM(NetSatis) / (SELECT SUM(NetSatis) FROM Siniflar) AS DECIMAL(5, 2)) AS CiroPayiYuzde
FROM    Siniflar
GROUP BY AbcSinifi
ORDER BY AbcSinifi;

/* ---------------------------------------------------------------------
   6.3 KARGO FİRMASI PERFORMANSI
   Ortalama teslim süresi, gecikme oranı ve ortalama kargo ücreti
   --------------------------------------------------------------------- */
SELECT  sh.CompanyName                                                   AS KargoFirmasi,
        COUNT(*)                                                         AS SiparisSayisi,
        CAST(AVG(1.0 * DATEDIFF(DAY, o.OrderDate, o.ShippedDate)) AS DECIMAL(5, 2)) AS OrtTeslimGunu,
        SUM(CASE WHEN o.ShippedDate > o.RequiredDate THEN 1 ELSE 0 END)  AS GecikenSiparis,
        CAST(100.0 * SUM(CASE WHEN o.ShippedDate > o.RequiredDate THEN 1 ELSE 0 END)
             / COUNT(*) AS DECIMAL(5, 2))                                AS GecikmeOraniYuzde,
        CAST(AVG(o.Freight) AS DECIMAL(10, 2))                           AS OrtKargoUcreti
FROM    Orders   AS o
JOIN    Shippers AS sh ON sh.ShipperID = o.ShipVia
WHERE   o.ShippedDate IS NOT NULL
GROUP BY sh.CompanyName
ORDER BY GecikmeOraniYuzde;

/* ---------------------------------------------------------------------
   6.4 KOHORT ANALİZİ
   Müşterileri ilk sipariş yılına göre gruplar; sonraki yıllarda
   kaçının tekrar sipariş verdiğini gösterir.
   --------------------------------------------------------------------- */
WITH IlkSiparis AS (
    SELECT  CustomerID,
            YEAR(MIN(OrderDate)) AS KohortYili
    FROM    Orders
    GROUP BY CustomerID
),
Aktivite AS (
    SELECT DISTINCT
            o.CustomerID,
            YEAR(o.OrderDate) AS SiparisYili
    FROM    Orders AS o
)
SELECT  i.KohortYili,
        COUNT(DISTINCT i.CustomerID)                                          AS YeniMusteri,
        COUNT(DISTINCT CASE WHEN a.SiparisYili = 1997 THEN a.CustomerID END)  AS Aktif1997,
        COUNT(DISTINCT CASE WHEN a.SiparisYili = 1998 THEN a.CustomerID END)  AS Aktif1998
FROM    IlkSiparis AS i
JOIN    Aktivite   AS a ON a.CustomerID = i.CustomerID
GROUP BY i.KohortYili
ORDER BY i.KohortYili;

/* ---------------------------------------------------------------------
   6.5 SEPET ANALİZİ
   Aynı siparişte en sık birlikte alınan ürün çiftleri
   --------------------------------------------------------------------- */
SELECT TOP 10
        p1.ProductName AS Urun1,
        p2.ProductName AS Urun2,
        COUNT(*)       AS BirlikteSiparisSayisi
FROM    [Order Details] AS a
JOIN    [Order Details] AS b  ON b.OrderID   = a.OrderID
                             AND b.ProductID > a.ProductID
JOIN    Products        AS p1 ON p1.ProductID = a.ProductID
JOIN    Products        AS p2 ON p2.ProductID = b.ProductID
GROUP BY p1.ProductName, p2.ProductName
ORDER BY BirlikteSiparisSayisi DESC, Urun1, Urun2;
