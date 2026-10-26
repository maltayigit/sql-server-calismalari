use master 
go
create database okuldb
go 
use okuldb
go 
create table Ogrenci(
ıd int primary Key identity(1,1),
Name varchar(30) not null,
Surname varchar(30)

)