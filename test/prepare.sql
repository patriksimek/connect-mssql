exec('create table [dbo].[sessions] (
	sid varchar (255) not null primary key,
	session varchar (max) not null,
	expires datetime not null
)')