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

ALTER PROCEDURE [influx].[TableStats]
AS
BEGIN

    DECLARE @cmd NVARCHAR(2000);

    -----------------------------------------------
    -- Sys.Tables
    -----------------------------------------------
	DECLARE @sysTables TABLE
	(
		database_name sysname NULL
	  , table_schema  sysname NULL DEFAULT 'dbo'
	  , object_id     INT     NULL
	  , name          sysname NULL
	);

    SET @cmd = N'USE [?];SELECT DB_NAME(), Object_Schema_Name( object_id ) , object_id, name FROM sys.tables;';

    INSERT INTO @sysTables ( database_name, table_schema, object_id, name ) EXEC sys.sp_MSforeachdb @command1 = @cmd;

    -----------------------------------------------
    -- Sys.Indexes
    -----------------------------------------------
	DECLARE @sysIndexes TABLE
	(
		database_name        sysname      NULL
	  , index_schema         sysname      NULL
	  , object_id            INT          NULL
	  , name                 sysname      NULL
	  , type_desc            NVARCHAR(60) NULL
	  , is_unique            BIT          NULL
	  , type                 TINYINT      NULL
	  , ignore_dup_key       BIT          NULL
	  , is_primary_key       BIT          NULL
	  , is_unique_constraint BIT          NULL
	  , fill_factor          TINYINT      NULL
	  , is_padded            BIT          NULL
	  , is_disabled          BIT          NULL
	  , is_hypothetical      BIT          NULL
	  , allow_row_locks      BIT          NULL
	  , allow_page_locks     BIT          NULL
	  , has_filter           BIT          NULL
	  , data_space_id        INT          NULL
	  , index_id             INT          NULL
	);

    SET @cmd = N'USE [?];
	SELECT DB_NAME()
	     , Object_Schema_Name( object_id ) 
	     , object_id           
	     , name                
	     , type_desc           
	     , is_unique           
	     , type                
	     , ignore_dup_key      
	     , is_primary_key      
	     , is_unique_constraint
	     , fill_factor         
	     , is_padded           
	     , is_disabled         
	     , is_hypothetical     
	     , allow_row_locks     
	     , allow_page_locks    
	     , has_filter    
		 , data_space_id      
		 , index_id
	 FROM sys.Indexes;';

    INSERT INTO @sysIndexes EXEC sys.sp_MSforeachdb @command1 = @cmd;

    -----------------------------------------------
    -- Sys.Partitions
    -----------------------------------------------
	DECLARE @sysPartitions TABLE
	(
		database_name         sysname      NULL
	  , object_id             INT          NULL
	  , data_compression_desc NVARCHAR(60) NULL
	  , rows                  BIGINT       NULL
	  , partition_number      INT          NULL
	  , data_compression      TINYINT      NULL
	  , index_id              INT          NULL
	);

    SET @cmd = N'USE [?];
		SELECT DB_NAME()
		     , object_id            
		     , data_compression_desc
		     , rows                 
		     , partition_number     
		     , data_compression     
		     , index_id             
		FROM sys.Partitions;';

    INSERT INTO @sysPartitions EXEC sys.sp_MSforeachdb @command1 = @cmd;

    -----------------------------------------------
    -- Sys.Partition_Schemes
    -----------------------------------------------
	DECLARE @sysPartitionSchemes TABLE ( database_name sysname NULL, data_space_id INT NULL );

	SET @cmd = N'USE [?];SELECT DB_NAME(), data_space_id FROM sys.Partition_Schemes;';

	INSERT INTO @sysPartitionSchemes EXEC sys.sp_MSforeachdb @command1 = @cmd;

    -----------------------------------------------
    -- Sys.destination_data_spaces
    -----------------------------------------------
	DECLARE @sysDestinationDataSpaces TABLE
	(
		database_name       sysname NULL
	  , partition_scheme_id INT     NULL
	  , data_space_id       INT     NULL
	  , destination_id      INT     NULL
	);

	SET @cmd = N'USE [?];SELECT DB_NAME(), partition_scheme_id, data_space_id, destination_id  FROM sys.destination_data_spaces;';

	INSERT INTO @sysDestinationDataSpaces
	EXEC sys.sp_MSforeachdb @command1 = @cmd;

    -----------------------------------------------
    -- Sys.Filegroups
    -----------------------------------------------
	DECLARE @sysFilegroups TABLE
	(
		database_name sysname NULL
	  , name          sysname NULL
	  , data_space_id INT     NULL
	);

	SET @cmd = N'USE [?];SELECT DB_NAME(), name, data_space_id  FROM sys.Filegroups;';

	INSERT INTO @sysFilegroups EXEC sys.sp_MSforeachdb @command1 = @cmd;

    -----------------------------------------------
    -- Sys.dm_db_partition_stats
    -----------------------------------------------
	DECLARE @sysDmDbPartitionStats TABLE
	(
		database_name        sysname      NULL
	  , in_row_data_page_count bigint NULL
	  , in_row_used_page_count bigint NULL
	  , in_row_reserved_page_count bigint NULL
	  , lob_used_page_count bigint NULL
	  , lob_reserved_page_count bigint NULL
	  , row_overflow_used_page_count bigint NULL
	  , row_overflow_reserved_page_count bigint NULL
	  , used_page_count bigint NULL
	  , reserved_page_count bigint NULL
	  , object_id  int NULL
	  , index_id   int NULL
	);

	SET @cmd = N'USE [?];
				 SELECT DB_NAME()
					  , in_row_data_page_count          
					  , in_row_used_page_count          
					  , in_row_reserved_page_count      
					  , lob_used_page_count             
					  , lob_reserved_page_count         
					  , row_overflow_used_page_count    
					  , row_overflow_reserved_page_count
					  , used_page_count                 
					  , reserved_page_count             
					  , object_id                       
					  , index_id                        
				 FROM sys.dm_db_partition_stats;';

	INSERT INTO @sysDmDbPartitionStats EXEC sys.sp_MSforeachdb @command1 = @cmd;

	-- remove tempdb
	DELETE FROM @sysTables WHERE database_name = 'tempdb';

	SELECT N'sqlserver_table_stats'

		 /* TAGS */
		 + N',sql_instance=' + Replace( @@serverName, '\', ':' )
		 + N',database_name='+ Replace( t.database_name, ' ', '\ ' )
		 + N',table_schema=' + Replace(t.table_schema, ' ', '\ ')
		 + N',table_name='   + Replace(t.name, ' ', '\ ')
		 + N',index_schema=' + Replace(i.index_schema, ' ', '\ ')
		 + CASE WHEN i.name IS NOT NULL THEN N',index_name='   + Replace(i.name, ' ', '\ ') ELSE N'' END
		 + N',index_type_desc='   + Replace(i.type_desc COLLATE DATABASE_DEFAULT, ' ', '\ ')
		 + N',filegroup_name=' + Replace(fg.name, ' ', '\ ')
		 + N',compression_type=' + Replace(p.data_compression_desc, ' ', '\ ')

		 /* METRICS */
		 + N' index_id='            + Cast( i.index_id AS NVARCHAR(3) )
		 + N',rows='                + CAST(p.ROWS AS NVARCHAR(25))
		 + N',in_row_data_size_kb=' + CAST( Sum( s.in_row_data_page_count ) OVER ( PARTITION BY i.object_id, i.index_id ) * 8 AS NVARCHAR(25))
		 + N',in_row_used_size_kb=' + CAST( Sum( s.in_row_used_page_count ) OVER ( PARTITION BY i.object_id, i.index_id ) * 8           AS 			  NVARCHAR(25))
		 + N',in_row_reserved_size_kb=' + CAST( Sum( s.in_row_reserved_page_count ) OVER ( PARTITION BY i.object_id, i.index_id ) * 8       AS 		  NVARCHAR(25))
		 + N',lob_used_size_kb=' + CAST( Sum( s.lob_used_page_count ) OVER ( PARTITION BY i.object_id, i.index_id ) * 8              AS 				  NVARCHAR(25))
		 + N',lob_reserved_size_kb=' + CAST( Sum( s.lob_reserved_page_count ) OVER ( PARTITION BY i.object_id, i.index_id ) * 8          AS 			  NVARCHAR(25))
		 + N',row_overflow_used_size_kb=' + CAST( Sum( s.row_overflow_used_page_count ) OVER ( PARTITION BY i.object_id, i.index_id ) * 8     AS 	  NVARCHAR(25))
		 + N',row_overflow_reserved_size_kb=' + CAST( Sum( s.row_overflow_reserved_page_count ) OVER ( PARTITION BY i.object_id, i.index_id ) * 8 AS   NVARCHAR(25))
		 + N',used_size_kb=' + CAST( Sum( s.used_page_count ) OVER ( PARTITION BY i.object_id, i.index_id ) * 8                  AS 					  NVARCHAR(25))
		 + N',reserved_size_kb=' + CAST( Sum( s.reserved_page_count ) OVER ( PARTITION BY i.object_id, i.index_id ) * 8              AS NVARCHAR(25))
		 + N',is_unique=' + CAST( i.is_unique			  AS NVARCHAR(25))
		 + N',index_type=' + CAST( i.type					  AS NVARCHAR(25))
		 + N',ignore_dup_key=' + CAST( i.ignore_dup_key		  AS NVARCHAR(25))
		 + N',is_primary_key=' + CAST( i.is_primary_key		  AS NVARCHAR(25))
		 + N',is_unique_constraint=' + CAST( i.is_unique_constraint	  AS NVARCHAR(25))
		 + N',fill_factor=' + CAST( i.fill_factor			  AS NVARCHAR(25))
		 + N',is_padded=' + CAST( i.is_padded			  AS NVARCHAR(25))
		 + N',is_disabled=' + CAST( i.is_disabled			  AS NVARCHAR(25))
		 + N',is_hypothetical=' + CAST( i.is_hypothetical		  AS NVARCHAR(25))
		 + N',allow_row_locks=' + CAST( i.allow_row_locks		  AS NVARCHAR(25))
		 + N',allow_page_locks=' + CAST( i.allow_page_locks		  AS NVARCHAR(25))
		 + N',partition_number=' + CAST( p.partition_number		  AS NVARCHAR(25))
	     + N',data_compression=' + CAST( p.data_compression AS NVARCHAR(25))
	     + N',has_filter=' + CAST( i.has_filter  AS NVARCHAR(25))
		 
		 /* UTC Time Epoch */
		 + N' ' + Cast(DateDiff( s, '1970-01-01 00:00:00', GetUtcDate()) AS NVARCHAR(MAX)) + N'000000000' AS lineprotocol

	FROM           @sysTables                  t
		INNER JOIN @sysIndexes                 i ON t.object_id                                     = i.object_id AND i.database_name = t.database_name
		INNER JOIN @sysPartitions              p ON i.object_id                                     = p.object_id AND p.database_name = i.database_name
												AND i.index_id                                      = p.index_id
		LEFT JOIN  @sysPartitionSchemes       ps ON i.data_space_id                                = ps.data_space_id
		LEFT JOIN  @sysDestinationDataSpaces dds ON ps.data_space_id                              = dds.partition_scheme_id AND dds.database_name = ps.database_name
												  AND p.partition_number                            = dds.destination_id
		INNER JOIN @sysFilegroups              fg ON Coalesce( dds.data_space_id, i.data_space_id ) = fg.data_space_id AND (fg.database_name = i.database_name OR fg.database_name = dds.database_name)
		INNER JOIN @sysDmDbPartitionStats   AS s ON s.object_id                                  = i.object_id AND s.database_name = i.database_name
												   AND s.index_id                                   = i.index_id

END;
GO

