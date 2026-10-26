/* =====================================================================
   OKUL VERİTABANI - SORGULAR
   Ders notu = Vize %40 + Final %60
   Geçme koşulu: ortalama >= 60 ve final >= 50
   ===================================================================== */
USE OkulDB;
GO

-- 1. Öğrenci listesi, bölüm adıyla birlikte
SELECT  o.OgrenciNo,
        CONCAT(o.Ad, ' ', o.Soyad) AS AdSoyad,
        b.BolumAdi,
        o.KayitYili
FROM    dbo.Ogrenci AS o
JOIN    dbo.Bolum   AS b ON b.BolumId = o.BolumId
ORDER BY b.BolumAdi, o.Soyad;

-- 2. Her kaydın ortalaması ve geçme durumu
SELECT  CONCAT(o.Ad, ' ', o.Soyad)                          AS Ogrenci,
        d.DersKodu,
        k.Donem,
        k.Vize,
        k.Final,
        CAST(k.Vize * 0.4 + k.Final * 0.6 AS DECIMAL(5, 2))  AS Ortalama,
        CASE
            WHEN k.Final IS NULL                                    THEN N'Finale girmedi'
            WHEN k.Vize * 0.4 + k.Final * 0.6 >= 60 AND k.Final >= 50 THEN N'Geçti'
            ELSE N'Kaldı'
        END                                                  AS Durum
FROM    dbo.Kayit   AS k
JOIN    dbo.Ogrenci AS o ON o.OgrenciId = k.OgrenciId
JOIN    dbo.Ders    AS d ON d.DersId    = k.DersId
ORDER BY Ogrenci, k.Donem;

-- 3. Ders bazında öğrenci sayısı, not ortalaması ve başarı oranı
SELECT  d.DersKodu,
        d.DersAdi,
        COUNT(*)                                                         AS KayitSayisi,
        CAST(AVG(k.Vize * 0.4 + k.Final * 0.6) AS DECIMAL(5, 2))         AS NotOrtalamasi,
        CAST(100.0 * SUM(CASE WHEN k.Vize * 0.4 + k.Final * 0.6 >= 60 AND k.Final >= 50
                              THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5, 2)) AS BasariOraniYuzde
FROM    dbo.Kayit AS k
JOIN    dbo.Ders  AS d ON d.DersId = k.DersId
GROUP BY d.DersKodu, d.DersAdi
ORDER BY BasariOraniYuzde DESC;

-- 4. Öğretmenlerin verdiği dersler ve toplam kredi
SELECT  CONCAT(t.Unvan, ' ', t.Ad, ' ', t.Soyad) AS Ogretmen,
        COUNT(d.DersId)                          AS DersSayisi,
        SUM(d.Kredi)                             AS ToplamKredi
FROM    dbo.Ogretmen AS t
LEFT JOIN dbo.Ders   AS d ON d.OgretmenId = t.OgretmenId
GROUP BY t.Unvan, t.Ad, t.Soyad
ORDER BY ToplamKredi DESC;

-- 5. Kredi ağırlıklı genel not ortalaması (GNO) ve sıralama
--    Tekrar alınan derslerde yalnızca en son dönem dikkate alınır.
WITH SonKayit AS (
    SELECT  k.*,
            ROW_NUMBER() OVER (PARTITION BY k.OgrenciId, k.DersId ORDER BY k.Donem DESC) AS rn
    FROM    dbo.Kayit AS k
    WHERE   k.Final IS NOT NULL
)
SELECT  CONCAT(o.Ad, ' ', o.Soyad)                                                    AS Ogrenci,
        b.BolumAdi,
        SUM(d.Kredi)                                                                  AS ToplamKredi,
        CAST(SUM((s.Vize * 0.4 + s.Final * 0.6) * d.Kredi) / SUM(d.Kredi) AS DECIMAL(5, 2)) AS GNO,
        RANK() OVER (ORDER BY SUM((s.Vize * 0.4 + s.Final * 0.6) * d.Kredi) / SUM(d.Kredi) DESC) AS Sira
FROM    SonKayit    AS s
JOIN    dbo.Ogrenci AS o ON o.OgrenciId = s.OgrenciId
JOIN    dbo.Bolum   AS b ON b.BolumId   = o.BolumId
JOIN    dbo.Ders    AS d ON d.DersId    = s.DersId
WHERE   s.rn = 1
GROUP BY o.Ad, o.Soyad, b.BolumAdi
ORDER BY Sira;

-- 6. Bir dersi tekrar almış öğrenciler
SELECT  CONCAT(o.Ad, ' ', o.Soyad) AS Ogrenci,
        d.DersKodu,
        COUNT(*)                   AS AlinmaSayisi
FROM    dbo.Kayit   AS k
JOIN    dbo.Ogrenci AS o ON o.OgrenciId = k.OgrenciId
JOIN    dbo.Ders    AS d ON d.DersId    = k.DersId
GROUP BY o.Ad, o.Soyad, d.DersKodu
HAVING  COUNT(*) > 1;

-- 7. Henüz hiç öğrencinin kaydolmadığı dersler (NOT EXISTS)
SELECT  d.DersKodu,
        d.DersAdi
FROM    dbo.Ders AS d
WHERE   NOT EXISTS (SELECT 1 FROM dbo.Kayit AS k WHERE k.DersId = d.DersId);

-- 8. E-posta adresi eksik öğrenciler
SELECT  OgrenciNo,
        CONCAT(Ad, ' ', Soyad) AS AdSoyad
FROM    dbo.Ogrenci
WHERE   Eposta IS NULL;

-- 9. Bölümlerin cinsiyet dağılımı (koşullu toplama ile pivot)
SELECT  b.BolumAdi,
        SUM(CASE WHEN o.Cinsiyet = 'K' THEN 1 ELSE 0 END) AS Kadin,
        SUM(CASE WHEN o.Cinsiyet = 'E' THEN 1 ELSE 0 END) AS Erkek,
        COUNT(*)                                          AS Toplam
FROM    dbo.Bolum   AS b
JOIN    dbo.Ogrenci AS o ON o.BolumId = b.BolumId
GROUP BY b.BolumAdi
ORDER BY Toplam DESC;
