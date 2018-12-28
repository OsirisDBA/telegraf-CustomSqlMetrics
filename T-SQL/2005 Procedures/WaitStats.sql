/* Create influx schema */
IF NOT EXISTS ( SELECT schema_name
                FROM information_schema.schemata
                WHERE   schema_name = 'influx' 
              ) 
BEGIN
    EXEC sp_executesql N'CREATE SCHEMA influx'
END

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('influx.WaitStats'))
   exec('CREATE PROCEDURE influx.WaitStats AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE influx.WaitStats
AS
BEGIN
    SET NOCOUNT ON;


    SELECT N'sqlserver_waitstats' 

	     /* TAGS */
		 + N',sql_instance=' + LTrim( RTrim( Replace( @@serverName, N'\', N':' )))
         + N',wait_type=' + LTrim( RTrim( Replace( ws.wait_type, N' ', N'\ ' ))) 
		 + N',wait_category=' + LTrim( RTrim( IsNull( Replace( wc.wait_category, N' ', N'\ ' ), N'OTHER' ))) 

		 /* METRICS */
		 + N' wait_time_ms=' + LTrim( RTrim( Cast(Cast(wait_time_ms AS BIGINT) AS NVARCHAR(15)))) + 'i' 
		 + N',resource_wait_ms=' + LTrim( RTrim( Cast(( wait_time_ms - signal_wait_time_ms ) AS NVARCHAR(15)))) + 'i'
         + N',signal_wait_time_ms=' + LTrim( RTrim( Cast(signal_wait_time_ms AS NVARCHAR(15)))) + 'i'
         + N',max_wait_time_ms=' + LTrim( RTrim( Cast(max_wait_time_ms AS NVARCHAR(15)))) + 'i'
         + N',waiting_tasks_count=' + LTrim( RTrim( Cast(waiting_tasks_count AS NVARCHAR(15)))) + 'i' 
		 
		 /* UTC Time Epoch */
		 + N' ' + Cast(DateDiff( s, '1970-01-01 00:00:00', GetUtcDate()) AS NVARCHAR(MAX)) + N'000000000' AS lineprotocol

    FROM                sys.dm_os_wait_stats   AS ws WITH ( NOLOCK )
        LEFT OUTER JOIN influx.WaitCategories AS wc ON ws.wait_type = wc.wait_type
    WHERE               ws.wait_type NOT IN ( N'BROKER_EVENTHANDLER'
                                            , N'BROKER_RECEIVE_WAITFOR'
                                            , N'BROKER_TASK_STOP'
                                            , N'BROKER_TO_FLUSH'
                                            , N'BROKER_TRANSMITTER'
                                            , N'CHECKPOINT_QUEUE'
                                            , N'CHKPT'
                                            , N'CLR_AUTO_EVENT'
                                            , N'CLR_MANUAL_EVENT'
                                            , N'CLR_SEMAPHORE'
                                            , N'DBMIRROR_DBM_EVENT'
                                            , N'DBMIRROR_EVENTS_QUEUE'
                                            , N'DBMIRROR_WORKER_QUEUE'
                                            , N'DBMIRRORING_CMD'
                                            , N'DIRTY_PAGE_POLL'
                                            , N'DISPATCHER_QUEUE_SEMAPHORE'
                                            , N'EXECSYNC'
                                            , N'FSAGENT'
                                            , N'FT_IFTS_SCHEDULER_IDLE_WAIT'
                                            , N'FT_IFTSHC_MUTEX'
                                            , N'HADR_CLUSAPI_CALL'
                                            , N'HADR_FILESTREAM_IOMGR_IOCOMPLETION'
                                            , N'HADR_LOGCAPTURE_WAIT'
                                            , N'HADR_NOTIFICATION_DEQUEUE'
                                            , N'HADR_TIMER_TASK'
                                            , N'HADR_WORK_QUEUE'
                                            , N'KSOURCE_WAKEUP'
                                            , N'LAZYWRITER_SLEEP'
                                            , N'LOGMGR_QUEUE'
                                            , N'MEMORY_ALLOCATION_EXT'
                                            , N'ONDEMAND_TASK_QUEUE'
                                            , N'PARALLEL_REDO_WORKER_WAIT_WORK'
                                            , N'PREEMPTIVE_HADR_LEASE_MECHANISM'
                                            , N'PREEMPTIVE_SP_SERVER_DIAGNOSTICS'
                                            , N'PREEMPTIVE_OS_LIBRARYOPS'
                                            , N'PREEMPTIVE_OS_COMOPS'
                                            , N'PREEMPTIVE_OS_CRYPTOPS'
                                            , N'PREEMPTIVE_OS_PIPEOPS'
                                            , 'PREEMPTIVE_OS_GENERICOPS'
                                            , N'PREEMPTIVE_OS_VERIFYTRUST'
                                            , N'PREEMPTIVE_OS_DEVICEOPS'
                                            , N'PREEMPTIVE_XE_CALLBACKEXECUTE'
                                            , N'PREEMPTIVE_XE_DISPATCHER'
                                            , N'PREEMPTIVE_XE_GETTARGETSTATE'
                                            , N'PREEMPTIVE_XE_SESSIONCOMMIT'
                                            , N'PREEMPTIVE_XE_TARGETINIT'
                                            , N'PREEMPTIVE_XE_TARGETFINALIZE'
                                            , N'PWAIT_ALL_COMPONENTS_INITIALIZED'
                                            , N'PWAIT_DIRECTLOGCONSUMER_GETNEXT'
                                            , N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP'
                                            , N'QDS_ASYNC_QUEUE'
                                            , N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP'
                                            , N'REQUEST_FOR_DEADLOCK_SEARCH'
                                            , N'RESOURCE_QUEUE'
                                            , N'SERVER_IDLE_CHECK'
                                            , N'SLEEP_BPOOL_FLUSH'
                                            , N'SLEEP_DBSTARTUP'
                                            , N'SLEEP_DCOMSTARTUP'
                                            , N'SLEEP_MASTERDBREADY'
                                            , N'SLEEP_MASTERMDREADY'
                                            , N'SLEEP_MASTERUPGRADED'
                                            , N'SLEEP_MSDBSTARTUP'
                                            , N'SLEEP_SYSTEMTASK'
                                            , N'SLEEP_TASK'
                                            , N'SLEEP_TEMPDBSTARTUP'
                                            , N'SNI_HTTP_ACCEPT'
                                            , N'SP_SERVER_DIAGNOSTICS_SLEEP'
                                            , N'SQLTRACE_BUFFER_FLUSH'
                                            , N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP'
                                            , N'SQLTRACE_WAIT_ENTRIES'
                                            , N'WAIT_FOR_RESULTS'
                                            , N'WAITFOR'
                                            , N'WAITFOR_TASKSHUTDOWN'
                                            , N'WAIT_XTP_HOST_WAIT'
                                            , N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG'
                                            , N'WAIT_XTP_CKPT_CLOSE'
                                            , N'XE_BUFFERMGR_ALLPROCESSED_EVENT'
                                            , N'XE_DISPATCHER_JOIN'
                                            , N'XE_DISPATCHER_WAIT'
                                            , N'XE_LIVE_TARGET_TVF'
                                            , N'XE_TIMER_EVENT'
                                            , N'SOS_WORK_DISPATCHER'
                                            , 'RESERVED_MEMORY_ALLOCATION_EXT'
    )
      AND               waiting_tasks_count > 0
      AND               wait_time_ms        > 100
    OPTION ( RECOMPILE );

END;
GO