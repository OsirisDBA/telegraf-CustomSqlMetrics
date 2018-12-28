/* Create influx schema */
IF NOT EXISTS ( SELECT schema_name
                FROM information_schema.schemata
                WHERE   schema_name = 'influx' 
              ) 
BEGIN
    EXEC sp_executesql N'CREATE SCHEMA influx'
END

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('influx.MemoryClerks'))
   exec('CREATE PROCEDURE influx.MemoryClerks AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE influx.MemoryClerks
AS
BEGIN
    SELECT N'sqlserver_memory_clerks' 
	     
		 /* TAGS */
	     + N',sql_instance=' + Replace( @@serverName, '\', ':' ) 
		 + N',clerk_type=' + Replace( IsNull( clerk_names.name, mc.type ), ' ', '\ ' ) 

		 /* METRICS */
		 + N' size_kb=' + Cast(Sum( mc.single_pages_kb + mc.multi_pages_kb ) AS NVARCHAR) + 'i'

         /* UTC Time Epoch */
		 + N' ' + Cast(DateDiff( s, '1970-01-01 00:00:00', GetUtcDate()) AS NVARCHAR(MAX)) + N'000000000' AS lineprotocol

    FROM          sys.dm_os_memory_clerks AS mc WITH ( NOLOCK )
        LEFT JOIN influx.MemoryClerks    AS clerk_names ON mc.type = clerk_names.system_name
    GROUP BY IsNull( clerk_names.name, mc.type )
    HAVING   Sum( mc.single_pages_kb + mc.multi_pages_kb ) >= 1024
    OPTION ( RECOMPILE );
END;
GO