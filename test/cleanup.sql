if exists (select * from sys.tables where name = 'sessions')
	exec('drop table [dbo].[sessions]')