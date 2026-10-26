/* =====================================================================
   OKUL VERİTABANI - ÖRNEK VERİ
   Tüm kişi adları kurgusaldır.
   ===================================================================== */
USE OkulDB;
GO

INSERT INTO dbo.Bolum (BolumAdi) VALUES
    (N'Bilgisayar Mühendisliği'),
    (N'İşletme'),
    (N'Endüstri Mühendisliği');

INSERT INTO dbo.Ogretmen (Ad, Soyad, Unvan, BolumId) VALUES
    (N'Ayşe',   N'Yılmaz', N'Prof. Dr.',     1),
    (N'Mehmet', N'Kaya',   N'Doç. Dr.',      1),
    (N'Zeynep', N'Demir',  N'Dr. Öğr. Üyesi', 2),
    (N'Ali',    N'Şahin',  N'Öğr. Gör.',     3);

INSERT INTO dbo.Ders (DersKodu, DersAdi, Kredi, OgretmenId) VALUES
    ('BIL101', N'Programlamaya Giriş',  4, 1),
    ('BIL204', N'Veritabanı Sistemleri', 4, 2),
    ('ISL110', N'İşletme Yönetimi',      3, 3),
    ('END220', N'Yöneylem Araştırması',  4, 4),
    ('IST201', N'İstatistik',            3, 4),
    ('BIL310', N'Veri Madenciliği',      3, 2);   -- yeni açılan ders, henüz kaydı yok

INSERT INTO dbo.Ogrenci (OgrenciNo, Ad, Soyad, Cinsiyet, DogumTarihi, BolumId, KayitYili, Eposta) VALUES
    ('24010001', N'Elif',   N'Arslan',  'K', '2005-03-14', 1, 2024, N'elif.arslan@ornek.edu.tr'),
    ('24010002', N'Burak',  N'Öztürk',  'E', '2004-11-02', 1, 2024, N'burak.ozturk@ornek.edu.tr'),
    ('24010003', N'Selin',  N'Koç',     'K', '2005-07-21', 1, 2024, N'selin.koc@ornek.edu.tr'),
    ('24020001', N'Emre',   N'Aydın',   'E', '2004-05-30', 2, 2024, N'emre.aydin@ornek.edu.tr'),
    ('24020002', N'Deniz',  N'Çelik',   'K', '2005-01-09', 2, 2024, NULL),
    ('25030001', N'Can',    N'Yıldız',  'E', '2006-09-17', 3, 2025, N'can.yildiz@ornek.edu.tr'),
    ('25030002', N'İrem',   N'Polat',   'K', '2006-02-25', 3, 2025, N'irem.polat@ornek.edu.tr'),
    ('25010004', N'Kerem',  N'Erdem',   'E', '2006-12-03', 1, 2025, N'kerem.erdem@ornek.edu.tr');

INSERT INTO dbo.Kayit (OgrenciId, DersId, Donem, Vize, Final) VALUES
    (1, 1, '2024-GZ', 85, 92),
    (1, 2, '2025-GZ', 78, 88),
    (1, 5, '2025-BH', 90, 95),
    (2, 1, '2024-GZ', 45, 38),
    (2, 1, '2025-GZ', 60, 72),   -- dersi tekrar alıp geçmiş
    (2, 2, '2025-GZ', 55, 61),
    (3, 1, '2024-GZ', 70, 74),
    (3, 2, '2025-GZ', 92, 97),
    (4, 3, '2024-GZ', 68, 75),
    (4, 5, '2025-BH', 40, 52),
    (5, 3, '2024-GZ', 88, 81),
    (5, 5, '2025-BH', 73, NULL), -- finale girmedi
    (6, 4, '2025-GZ', 64, 70),
    (6, 5, '2025-GZ', 35, 42),
    (7, 4, '2025-GZ', 81, 90),
    (7, 5, '2025-GZ', 77, 83),
    (8, 1, '2025-GZ', 58, 66);
GO
