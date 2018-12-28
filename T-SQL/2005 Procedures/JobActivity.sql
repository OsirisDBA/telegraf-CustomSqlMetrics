/* Create influx schema */
IF NOT EXISTS ( SELECT schema_name
                FROM information_schema.schemata
                WHERE   schema_name = 'influx' 
              ) 
BEGIN
    EXEC sp_executesql N'CREATE SCHEMA influx'
END

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('influx.JobActivity'))
   exec('CREATE PROCEDURE influx.JobActivity AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE [influx].[JobActivity](
	@FromDateTime DATETIME = NULL
)
AS 
BEGIN
	SELECT N'sqlserver_jobstatus'
	
	     /* TAGS */
		 + N',sql_instance=' + Replace( @@serverName, '\', ':' )
		 + N',job_name=' +  Replace( T2.name, N' ' , N'\ ' )       
		 + N',status=' + Replace( CASE T1.run_status 
							WHEN 0 THEN 'Failed'
							WHEN 1 THEN 'Succeeded'
							WHEN 2 THEN 'Retry'
							WHEN 3 THEN 'Canceled'
							WHEN 4 THEN 'In Progress'
		                 END, ' ' ,'\ ')

         /* METRICS */
		 + N' run_duration=' + Cast( T1.run_duration AS NVARCHAR(12) ) + N'i'
		 + N',status_code=' + Cast( T1.run_status AS NVARCHAR(1) ) + N'i'

		 /* UTC Time Epoch */
		 + N' ' + Cast(DateDiff( Second
						  , '1970-01-01 00:00:00'
						  , DateAdd( hh, DateDiff( hh, GetDate(), GetUtcDate()), msdb.dbo.agent_datetime( run_date, run_time ) )
						) AS NVARCHAR(30)) + N'000000000' AS lineprotocol
             

	FROM           msdb.dbo.sysjobhistory T1
		INNER JOIN msdb.dbo.sysjobs       T2 ON T1.job_id = T2.job_id
	WHERE          T1.step_id = 0
	  AND          run_date   >= Convert( CHAR(8), IsNull( @FromDateTime,  DateAdd( DAY, -1, GetDate()) ), 112 )
END
GO

