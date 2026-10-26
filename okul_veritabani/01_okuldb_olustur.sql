/* =====================================================================
   OKUL VERİTABANI - ŞEMA
   Konular: CREATE DATABASE, CREATE TABLE, PRIMARY KEY, IDENTITY,
            FOREIGN KEY, UNIQUE, CHECK, DEFAULT, NOT NULL
   Tablolar:
     Bolum     (1) ──< (N) Ogrenci
     Bolum     (1) ──< (N) Ogretmen
     Ogretmen  (1) ──< (N) Ders
     Ogrenci   (N) >──< (N) Ders   →  Kayit (not bilgisiyle)
   ===================================================================== */
USE master;
GO

IF DB_ID(N'OkulDB') IS NULL
    CREATE DATABASE OkulDB;
GO

USE OkulDB;
GO

-- Yeniden çalıştırılabilir olsun diye önce bağımlı tablolar silinir
DROP TABLE IF EXISTS dbo.Kayit;
DROP TABLE IF EXISTS dbo.Ders;
DROP TABLE IF EXISTS dbo.Ogretmen;
DROP TABLE IF EXISTS dbo.Ogrenci;
DROP TABLE IF EXISTS dbo.Bolum;
GO

CREATE TABLE dbo.Bolum (
    BolumId     INT IDENTITY(1, 1) PRIMARY KEY,
    BolumAdi    NVARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE dbo.Ogrenci (
    OgrenciId   INT IDENTITY(1, 1) PRIMARY KEY,
    OgrenciNo   CHAR(8)      NOT NULL UNIQUE,
    Ad          NVARCHAR(30) NOT NULL,
    Soyad       NVARCHAR(30) NOT NULL,
    Cinsiyet    CHAR(1)      NOT NULL CHECK (Cinsiyet IN ('K', 'E')),
    DogumTarihi DATE         NOT NULL,
    BolumId     INT          NOT NULL REFERENCES dbo.Bolum (BolumId),
    KayitYili   SMALLINT     NOT NULL CHECK (KayitYili BETWEEN 2000 AND 2100),
    Eposta      NVARCHAR(100)     NULL UNIQUE
);

CREATE TABLE dbo.Ogretmen (
    OgretmenId  INT IDENTITY(1, 1) PRIMARY KEY,
    Ad          NVARCHAR(30) NOT NULL,
    Soyad       NVARCHAR(30) NOT NULL,
    Unvan       NVARCHAR(30) NOT NULL DEFAULT N'Öğr. Gör.',
    BolumId     INT          NOT NULL REFERENCES dbo.Bolum (BolumId)
);

CREATE TABLE dbo.Ders (
    DersId      INT IDENTITY(1, 1) PRIMARY KEY,
    DersKodu    VARCHAR(10)  NOT NULL UNIQUE,
    DersAdi     NVARCHAR(80) NOT NULL,
    Kredi       TINYINT      NOT NULL CHECK (Kredi BETWEEN 1 AND 8),
    OgretmenId  INT          NOT NULL REFERENCES dbo.Ogretmen (OgretmenId)
);

CREATE TABLE dbo.Kayit (
    OgrenciId   INT          NOT NULL REFERENCES dbo.Ogrenci (OgrenciId),
    DersId      INT          NOT NULL REFERENCES dbo.Ders (DersId),
    Donem       CHAR(7)      NOT NULL,                    -- örnek: 2025-GZ, 2026-BH
    Vize        TINYINT          NULL CHECK (Vize  BETWEEN 0 AND 100),
    Final       TINYINT          NULL CHECK (Final BETWEEN 0 AND 100),
    CONSTRAINT PK_Kayit PRIMARY KEY (OgrenciId, DersId, Donem)
);
GO
