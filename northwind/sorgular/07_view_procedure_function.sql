/* =====================================================================
   07 - VIEW, STORED PROCEDURE VE FONKSİYON
   Konular: CREATE OR ALTER VIEW, parametreli stored procedure,
            skaler fonksiyon, tablo döndüren fonksiyon
   Gereksinim: SQL Server 2016 SP1 ve üzeri (CREATE OR ALTER)
   Veritabanı: Northwind (SQL Server)
   ===================================================================== */
USE Northwind;
GO

-- 7.1 VIEW: sipariş satırlarını raporlamaya hazır hale getirir
CREATE OR ALTER VIEW dbo.vw_SatisDetay
AS
SELECT  o.OrderID,
        o.OrderDate,
        YEAR(o.OrderDate)                               AS Yil,
        MONTH(o.OrderDate)                              AS Ay,
        cu.CustomerID,
        cu.CompanyName                                  AS Musteri,
        cu.Country                                      AS Ulke,
        CONCAT(e.FirstName, ' ', e.LastName)                AS Calisan,
        c.CategoryName                                  AS Kategori,
        p.ProductName                                   AS Urun,
        od.Quantity                                     AS Adet,
        od.UnitPrice                                    AS BirimFiyat,
        od.Discount                                     AS Indirim,
        od.UnitPrice * od.Quantity * (1 - od.Discount)  AS NetSatis
FROM    Orders          AS o
JOIN    [Order Details] AS od ON od.OrderID   = o.OrderID
JOIN    Customers       AS cu ON cu.CustomerID = o.CustomerID
JOIN    Employees       AS e  ON e.EmployeeID  = o.EmployeeID
JOIN    Products        AS p  ON p.ProductID   = od.ProductID
JOIN    Categories      AS c  ON c.CategoryID  = p.CategoryID;
GO

-- View kullanımı
SELECT  Ulke,
        CAST(SUM(NetSatis) AS DECIMAL(12, 2)) AS NetSatis
FROM    dbo.vw_SatisDetay
GROUP BY Ulke
ORDER BY NetSatis DESC;
GO

-- 7.2 STORED PROCEDURE: tarih aralığı ve (isteğe bağlı) ülkeye göre en çok satan ürünler
CREATE OR ALTER PROCEDURE dbo.sp_EnCokSatanUrunler
    @BaslangicTarihi DATE,
    @BitisTarihi     DATE,
    @Ulke            NVARCHAR(15) = NULL,   -- NULL ise tüm ülkeler
    @Adet            INT          = 10
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Adet)
            Urun,
            Kategori,
            SUM(Adet)                             AS ToplamAdet,
            CAST(SUM(NetSatis) AS DECIMAL(12, 2)) AS NetSatis
    FROM    dbo.vw_SatisDetay
    WHERE   OrderDate >= @BaslangicTarihi
      AND   OrderDate <  DATEADD(DAY, 1, @BitisTarihi)
      AND   (@Ulke IS NULL OR Ulke = @Ulke)
    GROUP BY Urun, Kategori
    ORDER BY NetSatis DESC;
END;
GO

-- Procedure kullanımı
EXEC dbo.sp_EnCokSatanUrunler @BaslangicTarihi = '1997-01-01', @BitisTarihi = '1997-12-31';
EXEC dbo.sp_EnCokSatanUrunler @BaslangicTarihi = '1997-01-01', @BitisTarihi = '1997-12-31',
                              @Ulke = 'Germany', @Adet = 5;
GO

-- 7.3 SKALER FONKSİYON: bir siparişin net tutarı
CREATE OR ALTER FUNCTION dbo.fn_SiparisTutari (@OrderID INT)
RETURNS DECIMAL(12, 2)
AS
BEGIN
    DECLARE @Tutar DECIMAL(12, 2);

    SET @Tutar = (
        SELECT  SUM(UnitPrice * Quantity * (1 - Discount))
        FROM    [Order Details]
        WHERE   OrderID = @OrderID
    );

    RETURN ISNULL(@Tutar, 0);
END;
GO

-- Fonksiyon kullanımı
SELECT TOP 10
        OrderID,
        OrderDate,
        dbo.fn_SiparisTutari(OrderID) AS SiparisTutari
FROM    Orders
ORDER BY SiparisTutari DESC;
GO

-- 7.4 TABLO DÖNDÜREN FONKSİYON: bir müşterinin sipariş geçmişi
CREATE OR ALTER FUNCTION dbo.fn_MusteriSiparisleri (@CustomerID NCHAR(5))
RETURNS TABLE
AS
RETURN
(
    SELECT  o.OrderID,
            o.OrderDate,
            o.ShippedDate,
            COUNT(od.ProductID)                                                         AS KalemSayisi,
            CAST(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS DECIMAL(12, 2)) AS NetTutar
    FROM    Orders          AS o
    JOIN    [Order Details] AS od ON od.OrderID = o.OrderID
    WHERE   o.CustomerID = @CustomerID
    GROUP BY o.OrderID, o.OrderDate, o.ShippedDate
);
GO

-- Fonksiyon kullanımı
SELECT  *
FROM    dbo.fn_MusteriSiparisleri('ALFKI')
ORDER BY OrderDate;
GO
