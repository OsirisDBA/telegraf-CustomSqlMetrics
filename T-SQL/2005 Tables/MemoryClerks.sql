/* Create influx schema */
IF NOT EXISTS ( SELECT schema_name
                FROM information_schema.schemata
                WHERE   schema_name = 'influx' 
              ) 
BEGIN
    EXEC sp_executesql N'CREATE SCHEMA influx'
END

CREATE TABLE influx.MemoryClerks
(
    system_name sysname NOT NULL
  , name        sysname NOT NULL
  , CONSTRAINT PK_MemoryClerks
        PRIMARY KEY CLUSTERED ( system_name )
        WITH ( IGNORE_DUP_KEY = ON )
);
GO

INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_BROKERDSH','Service Broker Dialog Security Header Cache');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_BROKERKEK','Service Broker Key Exchange Key Cache');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_BROKERREADONLY','Service Broker (Read-Only)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_BROKERRSB','Service Broker Null Remote Service Binding Cache');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_BROKERTBLACS','Broker dormant rowsets');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_BROKERTO','Service Broker Transmission Object Cache');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_BROKERUSERCERTLOOKUP','Service Broker user certificates lookup result cache');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_CLRPROC','CLR Procedure Cache');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_CLRUDTINFO','CLR UDT Info');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_COLUMNSTOREOBJECTPOOL','Column Store Object Pool');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_CONVPRI','Conversation Priority Cache');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_EVENTS','Event Notification Cache');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_FULLTEXTSTOPLIST','Full Text Stoplist Cache');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_NOTIF','Notification Store');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_OBJCP','Object Plans');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_PHDR','Bound Trees');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_SEARCHPROPERTYLIST','Search Property List Cache');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_SEHOBTCOLUMNATTRIBUTE','SE Shared Column Metadata Cache');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_SQLCP','SQL Plans');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_STACKFRAMES','SOS_StackFramesStore');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_SYSTEMROWSET','System Rowset Store');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_TEMPTABLES','Temporary Tables & Table Variables');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_VIEWDEFINITIONS','View Definition Cache');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_XML_SELECTIVE_DG','XML DB Cache (Selective)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_XMLDBATTRIBUTE','XML DB Cache (Attribute)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_XMLDBELEMENT','XML DB Cache (Element)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_XMLDBTYPE','XML DB Cache (Type)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_XPROC','Extended Stored Procedures');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_FILETABLE','Memory Clerk (File Table)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_FSCHUNKER','Memory Clerk (FS Chunker)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_FULLTEXT','Full Text');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_FULLTEXT_SHMEM','Full-text IG');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_HADR','HADR');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_HOST','Host');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_LANGSVC','Language Service');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_LWC','Light Weight Cache');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_QSRANGEPREFETCH','QS Range Prefetch');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SERIALIZATION','Serialization');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SNI','SNI');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SOSMEMMANAGER','SOS Memory Manager');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SOSNODE','SOS Node');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SOSOS','SOS Memory Clerk');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLBUFFERPOOL','Buffer Pool');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLCLR','CLR');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLCLRASSEMBLY','CLR Assembly');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLCONNECTIONPOOL','Connection Pool');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLGENERAL','General');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLHTTP','HTTP');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLLOGPOOL','Log Pool');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLOPTIMIZER','SQL Optimizer');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLQERESERVATIONS','SQL Reservations');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLQUERYCOMPILE','SQL Query Compile');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLQUERYEXEC','SQL Query Exec');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLQUERYPLAN','SQL Query Plan');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLSERVICEBROKER','SQL Service Broker');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLSERVICEBROKERTRANSPORT','Unified Communication Stack');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLSOAP','SQL SOAP');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLSOAPSESSIONSTORE','SQL SOAP (Session Store)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLSTORENG','SQL Storage Engine');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLUTILITIES','SQL Utilities');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLXML','SQL XML');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_SQLXP','SQL XP');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_TRACE_EVTNOTIF','Trace Event Notification');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_XE','XE Engine');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_XE_BUFFER','XE Buffer');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_XTP','In-Memory OLTP');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('OBJECTSTORE_LBSS','Lbss Cache (Object Store)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('OBJECTSTORE_LOCK_MANAGER','Lock Manager (Object Store)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('OBJECTSTORE_SECAUDIT_EVENT_BUFFER','Audit Event Buffer (Object Store)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('OBJECTSTORE_SERVICE_BROKER','Service Broker (Object Store)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('OBJECTSTORE_SNI_PACKET','SNI Packet (Object Store)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('OBJECTSTORE_XACT_CACHE','Transactions Cache (Object Store)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('USERSTORE_DBMETADATA','DB Metadata (User Store)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('USERSTORE_OBJPERM','Object Permissions (User Store)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('USERSTORE_SCHEMAMGR','Schema Manager (User Store)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('USERSTORE_SXC','SXC (User Store)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('USERSTORE_TOKENPERM','Token Permissions (User Store)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('USERSTORE_QDSSTMT','QDS Statement Buffer (Pre-persist)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_QDSRUNTIMESTATS','QDS Runtime Stats (Pre-persist)');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('CACHESTORE_QDSCONTEXTSETTINGS','QDS Unique Context Settings');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_QUERYDISKSTORE','QDS General');
INSERT INTO influx.MemoryClerks( system_name, name ) VALUES ('MEMORYCLERK_QUERYDISKSTORE_HASHMAP','QDS Query/Plan Hash Table')
GO