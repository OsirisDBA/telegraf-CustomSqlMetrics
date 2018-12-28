/* Create influx schema */
IF NOT EXISTS ( SELECT schema_name
                FROM information_schema.schemata
                WHERE   schema_name = 'influx' 
              ) 
BEGIN
    EXEC sp_executesql N'CREATE SCHEMA influx'
END

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('influx.DatabaseProperties'))
   exec('CREATE PROCEDURE influx.DatabaseProperties AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE influx.DatabaseProperties
AS
BEGIN
	SET NOCOUNT ON;

    WITH DatabaseSize AS (
        SELECT d.[database_id]
		     , mf.type
			 , Sum(mf.Size) * 8 AS SizeKB
        FROM sys.databases d
          JOIN sys.master_files mf ON mf.database_id = d.database_id
        WHERE d.source_database_id IS NULL
        GROUP BY d.database_id, mf.type
    )

    SELECT N'sqlserver_database_properties' 
    
           /* TAGS */
         + N',sql_instance=' + Replace( @@serverName, '\', ':' )
         + N',database_name=' + Replace(d.name, ' ', '\ ' )  
         + N',owner_login=' + IsNull(sp.name,'Unknown') 
         + N',compatibility_level=' + Cast(d.compatibility_level AS NVARCHAR)
         	 
           /* METRICS */
         + N' database_id=' +  Cast(d.database_id AS NVARCHAR(3)) + N'i'
         + N',state=' + Cast( d.state AS NVARCHAR(1) ) + N'i'
         + N',recovery_model=' + Cast( d.recovery_model AS NVARCHAR(1) ) + N'i'
         + N',page_verify_option=' + Cast( d.page_verify_option AS NVARCHAR(1) ) + N'i'
         + N',is_trustworthy_on=' + Cast( d.is_trustworthy_on AS NVARCHAR(1) ) + N'i'
         + N',is_broker_enabled=' + CAST( d.is_broker_enabled AS NVARCHAR(1) ) + N'i'
         + N',log_reuse_wait=' + CAST( d.log_reuse_wait AS NVARCHAR(1) ) + N'i'
         + N',user_access=' + CAST( d.user_access AS NVARCHAR(1) ) + N'i'
         + N',data_size_kb=' + CAST( dz.SizeKB AS NVARCHAR ) + N'i'
         + N',log_size_kb=' + CAST( lz.SizeKB AS NVARCHAR ) + N'i'
         
           /* UTC Time Epoch */
         + N' ' + Cast(DateDiff( s, '1970-01-01 00:00:00', GetUtcDate()) AS NVARCHAR(MAX)) + N'000000000' AS lineprotocol
    
    FROM sys.databases d
    LEFT JOIN sys.server_principals sp ON sp.sid = d.owner_sid
    LEFT JOIN DatabaseSize dz ON dz.database_id = d.database_id AND dz.Type = 0
    LEFT JOIN DatabaseSize lz ON lz.database_id = d.database_id AND lz.Type = 1
    WHERE d.source_database_id IS NULL;
END
GO


