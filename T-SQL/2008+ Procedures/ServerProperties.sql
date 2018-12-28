/* Create influx schema */
IF NOT EXISTS ( SELECT schema_name
                FROM information_schema.schemata
                WHERE   schema_name = 'influx' 
              ) 
BEGIN
    EXEC sp_executesql N'CREATE SCHEMA influx'
END

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('influx.ServerProperties'))
   exec('CREATE PROCEDURE influx.ServerProperties AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE [influx].[ServerProperties]
AS
BEGIN
    DECLARE @sys_info TABLE
	(
		cpu_count            INT
	  , server_memory        BIGINT
	  , sku                  NVARCHAR(64)
	  , engine_edition       SMALLINT
	  , hardware_type        VARCHAR(16)
	  , total_storage_mb     BIGINT
	  , available_storage_mb BIGINT
	  , uptime               INT
	);
	IF Object_Id( 'master.sys.dm_os_sys_info' ) IS NOT NULL
	BEGIN
		IF ServerProperty( 'EngineEdition' ) = 8 -- Managed Instance
			INSERT INTO @sys_info (
				cpu_count
			  , server_memory
			  , sku
			  , engine_edition
			  , hardware_type
			  , total_storage_mb
			  , available_storage_mb
			  , uptime
			)
			SELECT   TOP ( 1 )
					 virtual_core_count                                           AS cpu_count
				   , ( SELECT process_memory_limit_mb FROM sys.dm_os_job_object ) AS server_memory
				   , sku
				   , Cast(ServerProperty( 'EngineEdition' ) AS SMALLINT)          AS engine_edition
				   , hardware_generation                                          AS hardware_type
				   , reserved_storage_mb                                          AS total_storage_mb
				   , ( reserved_storage_mb - storage_space_used_mb )              AS available_storage_mb
				   , (
						 SELECT DateDiff( MINUTE, sqlserver_start_time, GetDate())
						 FROM   sys.dm_os_sys_info
					 )                                                            AS uptime
			FROM     sys.server_resource_stats
			ORDER BY start_time DESC;
		ELSE
		BEGIN
			DECLARE @total_disk_size_mb BIGINT
				  , @available_space_mb BIGINT;
			SELECT @total_disk_size_mb = Sum( total_disk_size_mb )
				 , @available_space_mb = Sum( free_disk_space_mb )
			FROM   (
				SELECT          DISTINCT
								logical_volume_name               AS LogicalName
							  , total_bytes / ( 1024 * 1024 )     AS total_disk_size_mb
							  , available_bytes / ( 1024 * 1024 ) AS free_disk_space_mb
				FROM            sys.master_files AS f
					CROSS APPLY sys.dm_os_volume_stats( f.database_id, f.file_id )
			) AS osVolumes;
			INSERT INTO @sys_info (
				cpu_count
			  , server_memory
			  , sku
			  , engine_edition
			  , hardware_type
			  , total_storage_mb
			  , available_storage_mb
			  , uptime
			)
			SELECT cpu_count
				 , ( SELECT total_physical_memory_kb FROM sys.dm_os_sys_memory ) AS server_memory
				 , Cast(ServerProperty( 'Edition' ) AS NVARCHAR(64))             AS sku
				 , Cast(ServerProperty( 'EngineEdition' ) AS SMALLINT)           AS engine_edition
				 , CASE virtual_machine_type_desc
					   WHEN 'NONE' THEN
						   'PHYSICAL Machine'
					   ELSE
						   virtual_machine_type_desc
				   END                                                           AS hardware_type
				 , @total_disk_size_mb
				 , @available_space_mb
				 , DateDiff( MINUTE, sqlserver_start_time, GetDate())
			FROM   sys.dm_os_sys_info;
		END;
	END;

	DECLARE @Env SYSNAME;
	SELECT @Env = Cast( value AS NVARCHAR(128))  FROM sys.extended_properties WHERE class = 0 AND name = 'Environment'
	
	DECLARE @Series SYSNAME;
	SELECT @Series = Cast( value AS NVARCHAR(128))  FROM sys.extended_properties WHERE class = 0 AND name = 'Series'
	
	DECLARE @Description NVARCHAR(MAX);
	SELECT @Description = Cast( value AS NVARCHAR(MAX))  FROM sys.extended_properties WHERE class = 0 AND name = 'Description'
	
	SELECT N'sqlserver_server_properties' 
	     
		 /* TAGS */
		 + N',sql_instance=' + Replace( @@serverName, '\', ':' ) 
		 + N',sku=' + Replace( s.sku, ' ', '\ ' ) 
		 + N',hardware_type=' + Replace( s.hardware_type, ' ', '\ ' ) 
		 + N',sql_version=' + Replace( Cast( ServerProperty('ProductVersion') AS NVARCHAR(16)), ' ', '\ ' ) 
		 + N',service_name=' + Replace( @@serviceName, ' ', '\ ' ) 
		 + CASE WHEN @Env IS NOT NULL THEN N',environment=' + @Env ELSE N'' END
		 + CASE WHEN @Series IS NOT NULL THEN N',series=' + @Series ELSE N'' END
		 
		 /* METRICS */
		 + N' cpu_count=' + Cast(s.cpu_count AS NVARCHAR) + 'i' 
		 + N',engine_edition=' + Cast(s.engine_edition AS NVARCHAR) + 'i' 
		 + N',uptime=' + Cast(s.uptime AS NVARCHAR) + 'i' 
		 + N',db_online=' + Cast(db_online AS NVARCHAR) + 'i' 
		 + N',db_restoring=' + Cast(db_restoring AS NVARCHAR) + 'i'
         + N',db_recovering=' + Cast(db_recovering AS NVARCHAR) + 'i' 
		 + N',db_recoveryPending=' + Cast(db_recoveryPending AS NVARCHAR) + 'i' 
		 + N',db_suspect=' + Cast(db_suspect AS NVARCHAR) + 'i'
         + N',db_offline=' + Cast(db_offline AS NVARCHAR) + 'i' 
		 + N',description="' + Replace( Coalesce( @Description, 'No Description Available' ), '"', '\"' ) + N'"'
		 
		 /* UTC Time Epoch */
		 + N' ' + Cast(DateDiff( s, '1970-01-01 00:00:00', GetUtcDate()) AS NVARCHAR(MAX)) + N'000000000' AS lineprotocol
    FROM            (
        SELECT Sum( CASE WHEN state = 0 THEN 1 ELSE 0 END )               AS db_online
             , Sum( CASE WHEN state = 1 THEN 1 ELSE 0 END )               AS db_restoring
             , Sum( CASE WHEN state = 2 THEN 1 ELSE 0 END )               AS db_recovering
             , Sum( CASE WHEN state = 3 THEN 1 ELSE 0 END )               AS db_recoveryPending
             , Sum( CASE WHEN state = 4 THEN 1 ELSE 0 END )               AS db_suspect
             , Sum( CASE WHEN state = 6 OR state = 10 THEN 1 ELSE 0 END ) AS db_offline
        FROM   sys.databases
    )                                                                                AS dbs
        CROSS APPLY ( SELECT cpu_count, sku, engine_edition, uptime, hardware_type FROM @sys_info ) AS s
    OPTION ( RECOMPILE );
END;
GO

