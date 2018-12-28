/* Create influx schema */
IF NOT EXISTS ( SELECT schema_name
                FROM information_schema.schemata
                WHERE   schema_name = 'influx' 
              ) 
BEGIN
    EXEC sp_executesql N'CREATE SCHEMA influx'
END

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('influx.DatabaseIO'))
   exec('CREATE PROCEDURE influx.DatabaseIO AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE influx.DatabaseIO
AS
BEGIN
	SET NOCOUNT ON;

    SELECT N'sqlserver_database_io' 

	     /* TAGS */
	     + N',sql_instance=' + Replace( @@serverName, '\', ':' ) 
		 + N',database_name=' + Replace( Db_Name( vfs.database_id ), ' ', '\ ' ) 
		 + N',logical_filename=' + Replace( b.name, ' ', '\ ' )
         + N',physical_filename=' + Replace( b.physical_name, ' ', '\ ' ) 
         + N',file_type=' + CASE WHEN vfs.file_id = 2 THEN 'LOG' ELSE 'DATA' END 
		 
		 /* METRICS */
		 + N' read_latency_ms=' + Cast(vfs.io_stall_read_ms AS NVARCHAR) + N'i' 
		 + N',reads=' + Cast(vfs.num_of_reads AS NVARCHAR) + N'i' 
		 + N',read_bytes=' + Cast(vfs.num_of_bytes_read AS NVARCHAR) + N'i' 
		 + N',write_latency_ms=' + Cast(vfs.io_stall_write_ms AS NVARCHAR) + N'i' 
		 + N',writes=' + Cast(vfs.num_of_writes AS NVARCHAR) + N'i' 
		 + N',write_bytes=' + Cast(vfs.num_of_bytes_written AS NVARCHAR) + N'i'  
		 
		 /* UTC Time Epoch */
         + N' ' + Cast(DateDiff( s, '1970-01-01 00:00:00', GetUtcDate()) AS NVARCHAR(MAX)) + N'000000000' AS lineprotocol
    FROM           sys.dm_io_virtual_file_stats( NULL, NULL ) AS vfs
        INNER JOIN sys.database_files                         b ON b.file_id = vfs.file_id;

END;