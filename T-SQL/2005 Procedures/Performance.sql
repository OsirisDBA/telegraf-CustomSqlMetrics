/* Create influx schema */
IF NOT EXISTS ( SELECT schema_name
                FROM information_schema.schemata
                WHERE   schema_name = 'influx' 
              ) 
BEGIN
    EXEC sp_executesql N'CREATE SCHEMA influx'
END

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('influx.Performance'))
   exec('CREATE PROCEDURE influx.Performance AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE influx.Performance
AS
BEGIN
    DECLARE @PCounters TABLE
    (
        object_name   NVARCHAR(128)
      , counter_name  NVARCHAR(128)
      , instance_name NVARCHAR(128)
      , cntr_value    BIGINT
      , cntr_type     INT
      ,
      PRIMARY KEY ( object_name, counter_name, instance_name )
    );
    INSERT INTO @PCounters
    SELECT DISTINCT
           RTrim( spi.object_name )       AS object_name
         , RTrim( spi.counter_name )      AS counter_name
         , RTrim( spi.instance_name )     AS instance_name
         , Cast(spi.cntr_value AS BIGINT) AS cntr_value
         , spi.cntr_type
    FROM   sys.dm_os_performance_counters AS spi
    WHERE  ( counter_name IN ( 'SQL Compilations/sec'
                             , 'SQL Re-Compilations/sec'
                             , 'User Connections'
                             , 'Batch Requests/sec'
                             , 'Logouts/sec'
                             , 'Logins/sec'
                             , 'Processes blocked'
                             , 'Latch Waits/sec'
                             , 'Full Scans/sec'
                             , 'Index Searches/sec'
                             , 'Page Splits/sec'
                             , 'Page Lookups/sec'
                             , 'Page Reads/sec'
                             , 'Page Writes/sec'
                             , 'Readahead Pages/sec'
                             , 'Lazy Writes/sec'
                             , 'Checkpoint Pages/sec'
                             , 'Page life expectancy'
                             , 'Log File(s) Size (KB)'
                             , 'Log File(s) Used Size (KB)'
                             , 'Data File(s) Size (KB)'
                             , 'Transactions/sec'
                             , 'Write Transactions/sec'
                             , 'Active Temp Tables'
                             , 'Temp Tables Creation Rate'
                             , 'Temp Tables For Destruction'
                             , 'Free Space in tempdb (KB)'
                             , 'Version Store Size (KB)'
                             , 'Memory Grants Pending'
                             , 'Memory Grants Outstanding'
                             , 'Free list stalls/sec'
                             , 'Buffer cache hit ratio'
                             , 'Buffer cache hit ratio base'
                             , 'Backup/Restore Throughput/sec'
                             , 'Total Server Memory (KB)'
                             , 'Target Server Memory (KB)'
                             , 'Log Flushes/sec'
                             , 'Log Flush Wait Time'
                             , 'Memory broker clerk size'
                             , 'Log Bytes Flushed/sec'
                             , 'Bytes Sent to Replica/sec'
                             , 'Log Send Queue'
                             , 'Bytes Sent to Transport/sec'
                             , 'Sends to Replica/sec'
                             , 'Bytes Sent to Transport/sec'
                             , 'Sends to Transport/sec'
                             , 'Bytes Received from Replica/sec'
                             , 'Receives from Replica/sec'
                             , 'Flow Control Time (ms/sec)'
                             , 'Flow Control/sec'
                             , 'Resent Messages/sec'
                             , 'Redone Bytes/sec'
                             , 'XTP Memory Used (KB)'
                             , 'Transaction Delay'
                             , 'Log Bytes Received/sec'
                             , 'Log Apply Pending Queue'
                             , 'Redone Bytes/sec'
                             , 'Recovery Queue'
                             , 'Log Apply Ready Queue'
                             , 'CPU usage %'
                             , 'CPU usage % base'
                             , 'Queued requests'
                             , 'Requests completed/sec'
                             , 'Blocked tasks'
                             , 'Active memory grant amount (KB)'
                             , 'Disk Read Bytes/sec'
                             , 'Disk Read IO Throttled/sec'
                             , 'Disk Read IO/sec'
                             , 'Disk Write Bytes/sec'
                             , 'Disk Write IO Throttled/sec'
                             , 'Disk Write IO/sec'
                             , 'Used memory (KB)'
                             , 'Forwarded Records/sec'
                             , 'Background Writer pages/sec'
                             , 'Percent Log Used'
    )
    )
       OR  ( object_name LIKE '%User Settable%' OR object_name LIKE '%SQL Errors%' )
       OR  (
             instance_name IN ( '_Total' )
         AND counter_name IN ( 'Lock Timeouts/sec', 'Number of Deadlocks/sec', 'Lock Waits/sec', 'Latch Waits/sec' )
       );


    SELECT N'sqlserver_performance' 

	     /* TAGS */
	     + N',sql_instance=' + Replace( @@serverName, '\', ':' ) 
		 + N',object=' + Replace( pc.object_name, ' ', '\ ' ) 
		 + N',counter=' + Replace( pc.counter_name, ' ', '\ ' )
                        + CASE
                              WHEN pc.instance_name = '_Total' THEN
                                  N',instance=Total'
                              WHEN pc.instance_name IS NOT NULL
                               AND Len( LTrim( RTrim( pc.instance_name ))) > 0 THEN
                                  N',instance=' + Replace( pc.instance_name, ' ', '\ ' )
                              ELSE
                                  N''
                          END 
		
		 /* METRICS */				  
         + N' value=' + Cast( Cast( CASE 
		                              WHEN pc.cntr_type = 537003264 AND pc1.cntr_value > 0 
									    THEN ( pc.cntr_value * 1.0 ) / ( pc1.cntr_value * 1.0 ) * 100
                                      ELSE pc.cntr_value
                                    END AS DECIMAL) AS NVARCHAR(100)) 
									
		 /* UTC Time Epoch */
		 + ' ' + Cast(DateDiff( s, '1970-01-01 00:00:00', GetUtcDate()) AS NVARCHAR(MAX)) + N'000000000' AS lineprotocol
    FROM                @PCounters AS pc
        LEFT OUTER JOIN @PCounters AS pc1 ON (
                                               pc.counter_name  = Replace( pc1.counter_name, ' base', '' )
                                            OR pc.counter_name = Replace( pc1.counter_name, ' base', ' (ms)' )
                                          )
                                         AND pc.object_name    = pc1.object_name
                                         AND pc.instance_name  = pc1.instance_name
                                         AND pc1.counter_name LIKE '%base'
    WHERE               pc.counter_name NOT LIKE '% base'
    OPTION ( RECOMPILE );

END;
GO