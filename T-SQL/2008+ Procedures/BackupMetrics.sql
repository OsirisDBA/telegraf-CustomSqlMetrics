/* Create influx schema */
IF NOT EXISTS ( SELECT schema_name
                FROM information_schema.schemata
                WHERE   schema_name = 'influx' 
              ) 
BEGIN
    EXEC sp_executesql N'CREATE SCHEMA influx'
END

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('influx.BackupMetrics'))
   exec('CREATE PROCEDURE influx.BackupMetrics AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE influx.BackupMetrics (
    @FromDateTime DATETIME = NULL
)
AS
BEGIN
    SELECT N'sqlserver_backup' 
         
         /* TAGS */
         + N',sql_instance=' + Replace( @@serverName, '\', ':' ) 
         + N',database=' + bup.database_name
         + N',backuptype=' + CASE bup.type
                               WHEN N'D' THEN N'FullDatabase'
                               WHEN N'I' THEN N'DiffDatabase'
                               WHEN N'L' THEN N'Log'
                               WHEN N'F' THEN N'Filegroup'
                               WHEN N'G' THEN N'DiffFilegroup'
                               WHEN N'P' THEN N'Partial'
                               WHEN N'Q' THEN N'DiffPartial'
                               ELSE bup.type
                             END 
         /* METRICS */
         + N' duration_sec=' + Cast(Cast(DateDiff( SECOND, bup.backup_start_date, bup.backup_finish_date ) AS INT) AS NVARCHAR(50))
         + N',size_bytes=' + Cast(backup_size AS NVARCHAR) + N' '
           
         /* UTC Time Epoch */
         + Cast(DateDiff( s, '1970-01-01 00:00:00', DateAdd( hh, DateDiff( hh, GetDate(), GetUtcDate()), bup.backup_start_date )) AS NVARCHAR) + N'000000000' AS lineprotocol
    FROM   msdb.dbo.backupset AS bup
    WHERE  bup.backup_finish_date > IsNull( @FromDateTime, DateAdd( DAY, -1, GetDate()))
END
GO


