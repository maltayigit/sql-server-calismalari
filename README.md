# SQL Server Çalışmaları

Microsoft SQL Server (T-SQL) ile hazırlanmış iki proje:

1. **Northwind satış analizi:** Temel sorgulardan RFM segmentasyonu ve ABC analizine kadar 7 bölümde 40'tan fazla sorgu.
2. **Okul veritabanı:** Sıfırdan tasarlanmış, kısıtları tanımlı ilişkisel bir şema, örnek veri ve raporlama sorguları.

## 1. Northwind Satış Analizi

Klasik Northwind veritabanı (91 müşteri, 77 ürün, 830 sipariş, 1996–1998) üzerinde, konuları adım adım ilerleyen sorgu setleri.

| Dosya | Konular |
|---|---|
| [`01_temel_sorgular.sql`](northwind/sorgular/01_temel_sorgular.sql) | SELECT, WHERE, ORDER BY, TOP, DISTINCT, LIKE, IN, BETWEEN, IS NULL, CASE |
| [`02_join_sorgulari.sql`](northwind/sorgular/02_join_sorgulari.sql) | INNER / LEFT JOIN, çoklu JOIN, SELF JOIN, anti join, çoka çok ilişki |
| [`03_gruplama_ve_toplama.sql`](northwind/sorgular/03_gruplama_ve_toplama.sql) | GROUP BY, HAVING, toplama fonksiyonları, ROLLUP |
| [`04_alt_sorgu_ve_cte.sql`](northwind/sorgular/04_alt_sorgu_ve_cte.sql) | Alt sorgular, EXISTS, ilişkili alt sorgu, CTE, özyinelemeli CTE (organizasyon şeması) |
| [`05_pencere_fonksiyonlari.sql`](northwind/sorgular/05_pencere_fonksiyonlari.sql) | ROW_NUMBER, RANK, DENSE_RANK, NTILE, LAG, kümülatif toplam, pay hesabı |
| [`06_is_analizi_vakalari.sql`](northwind/sorgular/06_is_analizi_vakalari.sql) | RFM segmentasyonu, ABC (Pareto) analizi, kargo performansı, kohort analizi, sepet analizi |
| [`07_view_procedure_function.sql`](northwind/sorgular/07_view_procedure_function.sql) | VIEW, parametreli stored procedure, skaler ve tablo döndüren fonksiyonlar |

### Öne çıkan bulgular

| Soru | Sonuç |
|---|---|
| Toplam net satış (1996–1998) | **1.265.793,04** |
| En çok ciro getiren kategori | Beverages: %21,2 pay (267.868,18) |
| En çok ciro getiren müşteri | QUICK-Stop (110.277,30) |
| En yüksek satışı yapan çalışan | Margaret Peacock: 156 sipariş, 232.890,85 |
| ABC analizi | Ürünlerin **35'i (%45)** cironun **%79'unu** oluşturuyor |
| Geciken sipariş oranı | %4,57 (809 sevkiyattan 37'si) |
| En hızlı kargo firması | Federal Shipping: ort. 7,5 gün, %3,6 gecikme |
| En sık birlikte alınan ürünler | Sir Rodney's Scones + Sirop d'érable (8 sipariş) |

> Net satış = `UnitPrice × Quantity × (1 − Discount)`

### Örnek: RFM segmentasyonu

```sql
WITH Ham AS (
    SELECT  o.CustomerID,
            DATEDIFF(DAY, MAX(o.OrderDate), (SELECT RefTarih FROM Referans)) AS Recency,
            COUNT(DISTINCT o.OrderID)                                        AS Frequency,
            SUM(od.UnitPrice * od.Quantity * (1 - od.Discount))              AS Monetary
    FROM    Orders o JOIN [Order Details] od ON od.OrderID = o.OrderID
    GROUP BY o.CustomerID
),
Puan AS (
    SELECT *, NTILE(4) OVER (ORDER BY Recency DESC) AS R,
              NTILE(4) OVER (ORDER BY Frequency)    AS F,
              NTILE(4) OVER (ORDER BY Monetary)     AS M
    FROM Ham
)
SELECT ..., CASE WHEN R >= 3 AND F >= 3 AND M >= 3 THEN 'Şampiyon' ... END AS Segment
```

Tam sorgu: [`06_is_analizi_vakalari.sql`](northwind/sorgular/06_is_analizi_vakalari.sql)

## 2. Okul Veritabanı

Bölüm, öğrenci, öğretmen, ders ve ders kayıtlarından oluşan normalize bir şema.

```
Bolum ──< Ogrenci >──< Kayit >──< Ders >── Ogretmen >── Bolum
```

| Dosya | İçerik |
|---|---|
| [`01_okuldb_olustur.sql`](okul_veritabani/01_okuldb_olustur.sql) | 5 tablo. PRIMARY KEY, IDENTITY, FOREIGN KEY, UNIQUE, CHECK, DEFAULT ve bileşik anahtar kullanır. Tekrar çalıştırılabilir. |
| [`02_ornek_veri.sql`](okul_veritabani/02_ornek_veri.sql) | 8 öğrenci, 4 öğretmen, 6 ders, 17 kayıt. Dersi tekrar alan ve finale girmeyen öğrenci gibi gerçekçi durumlar içerir. |
| [`03_sorgular.sql`](okul_veritabani/03_sorgular.sql) | Not ortalaması ve geçme durumu, ders başarı oranları, kredi ağırlıklı GNO sıralaması, tekrar alınan dersler, koşullu toplamayla pivot |

## Nasıl çalıştırılır?

1. [SQL Server Express](https://www.microsoft.com/sql-server/sql-server-downloads) ve [SSMS](https://learn.microsoft.com/sql/ssms/download-sql-server-management-studio-ssms) kurun.
2. **Northwind:** Önce `northwind/northwind_kurulum.sql`, ardından `northwind/sorgular/` altındaki dosyaları çalıştırın.
3. **Okul veritabanı:** `okul_veritabani/` altındaki dosyaları 01 → 02 → 03 sırasıyla çalıştırın.

`07_view_procedure_function.sql` dosyası `CREATE OR ALTER` kullanır, bu yüzden SQL Server 2016 SP1 veya daha yeni bir sürüm gerekir.

## Kaynak

Northwind kurulum betiği Microsoft'a aittir ve [microsoft/sql-server-samples](https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/northwind-pubs) deposunda MIT lisansıyla yayımlanmaktadır. Sorgular ve okul veritabanı bu depoya özgüdür.
