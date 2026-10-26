# SQL Server Çalışmaları

Microsoft SQL Server üzerinde veritabanı oluşturma ve örnek veritabanlarıyla çalışma pratikleri.

## İçerik

| Klasör | Dosya | Açıklama |
|---|---|---|
| `northwind/` | `northwind_kurulum.sql` | Klasik **Northwind** örnek veritabanını (müşteriler, siparişler, ürünler, çalışanlar, tedarikçiler) oluşturan ve verisini yükleyen betik |
| `okul_veritabani/` | `okuldb_olustur.sql` | `okuldb` veritabanını ve `Ogrenci` tablosunu (IDENTITY birincil anahtar, NOT NULL kısıtı) oluşturan betik |

## Nasıl çalıştırılır?

1. [SQL Server Express](https://www.microsoft.com/sql-server/sql-server-downloads) ve [SQL Server Management Studio (SSMS)](https://learn.microsoft.com/sql/ssms/download-sql-server-management-studio-ssms) kurun.
2. SSMS'te betiği açın ve **F5** ile çalıştırın.
3. Northwind betiği veritabanını kendisi oluşturur (`CREATE DATABASE Northwind`).

## Örnek sorgular (Northwind)

```sql
-- En çok satış yapılan 5 ürün
SELECT TOP 5 p.ProductName, SUM(od.Quantity) AS ToplamAdet
FROM [Order Details] od
JOIN Products p ON p.ProductID = od.ProductID
GROUP BY p.ProductName
ORDER BY ToplamAdet DESC;

-- Ülkelere göre sipariş sayısı
SELECT c.Country, COUNT(*) AS SiparisSayisi
FROM Orders o
JOIN Customers c ON c.CustomerID = o.CustomerID
GROUP BY c.Country
ORDER BY SiparisSayisi DESC;
```

## Kaynak

Northwind veritabanı betiği Microsoft'a aittir ve [microsoft/sql-server-samples](https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/northwind-pubs) deposunda MIT lisansıyla yayımlanmaktadır.
