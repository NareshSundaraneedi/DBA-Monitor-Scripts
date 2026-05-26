More details :  https://docs.oracle.com/cd/E63000_01/EMVWS/examples.htm#CIHCJJID

Addedline for tetsing 

--Find Availiable Target Types in OEM
select distinct target_type,type_display_name from mgmt_targets order by 1;

--Find all registered targets in OEM for a particular target type
select target_name,target_type,target_guid from mgmt_targets where target_type='Cluster Database';

--Find a particular target information registered in OEM
select * from mgmt_targets where target_name='EBSPRE';

--Find Importent Matrics related to a particular Target
select * from mgmt$metric_daily where target_name = 'EBSPRE' and trunc(rollup_timestamp) = trunc(sysdate)-1

--Find the daily growth of a database from OEM repository
select rollup_timestamp, average
from mgmt$metric_daily
where target_name = 'EBSPROD'
and column_label = 'Used Space(GB)'
order by rollup_timestamp;

--Find targets under blackout

SELECT target_name, target_type, start_time, end_time
FROM   mgmt$blackout_history
WHERE  sysdate BETWEEN start_time AND NVL(end_time,sysdate+1/60*60*24);

select distinct blackout_name "BLACKOUT_NAME",created_by "CREATED_BY",start_time "START_TIME",target_name "TARGET_NAME",
target_type "TARGET_TYPE",status "STATUS"
from SYSMAN.MGMT$BLACKOUT_HISTORY where STATUS in('Partial Blackout','Started');

-- view a list of future scheduled blackouts

SELECT blackout_name, reason, created_by, schedule_type, scheduled_time
FROM   mgmt$blackouts
WHERE  status = 'Scheduled';

--view the number of targets blacked out in the last 30 days
SELECT target_type, COUNT(*) cnt
FROM   mgmt$blackout_history
WHERE  start_time > SYSDATE-30
GROUP BY target_type

--Targets which are down/unreachable 
SELECT TARGET_NAME, TARGET_TYPE, AVAILABILITY_STATUS FROM
     MGMT$AVAILABILITY_CURRENT WHERE AVAILABILITY_STATUS_CODE
     IN ('0', '4');
     
---Staus code
select distinct AVAILABILITY_STATUS,AVAILABILITY_STATUS_CODE from MGMT$AVAILABILITY_CURRENT;     

--find all registered targets in OEM for a particular target type
select target_name,target_type,target_guid from mgmt_targets where target_type='rac_database'

---find database user accounts password is going to expire in next 15 days

select distinct Target_name "Target_Database",host_name,username,profile,expiry_date
from sysman.mgmt$db_users
where expiry_date is not null  and username not like '%SYS%'
and trunc(expiry_date-sysdate) between 0 and 15;

---find CPU Utilization of one host for last 24 hours

SELECT a.collection_time, a.value
FROM sysman.gc_metric_values a 
WHERE TRUNC(a.collection_time) between TRUNC(SYSDATE-1) AND TRUNC(SYSDATE)
AND a.entity_type = 'host'
AND metric_group_name = 'Load'
AND metric_column_name = 'cpuUtil'
AND a.entity_name like 'at1oexdbadm01%' order by a.collection_time;

--Find Memory Utilization of one host for last 24 hours

SELECT a.collection_time, a.value
FROM sysman.gc_metric_values a WHERE TRUNC(a.collection_time) between TRUNC(SYSDATE-1) AND TRUNC(SYSDATE)
AND a.entity_type = 'host'
AND metric_group_name = 'Load'
AND metric_column_name = 'memUsedPct'
AND a.entity_name like 'at1oexdbadm01%' order by a.collection_time;

--find Requests Per Minute for any java application

SELECT a.collection_time, a.value  
FROM sysman.gc_metric_values a WHERE  TRUNC(a.collection_time) between TRUNC(SYSDATE-1) AND TRUNC(SYSDATE)
AND a.entity_type = 'weblogic_j2eeserver'
AND metric_group_name = 'server_servlet_jsp'
AND metric_column_name = 'service.throughput'
AND a.entity_name like '%/TST_WEB_webdomain/testwebdomain/hcmapp1%' order by a.collection_time;

--find Archive log summary for all Oracle databases from oem
select distinct database_name "DATABASE_NAME",instance_name "INSTANCE_NAME",log_mode "LOG_MODE",host_name "HOST_NAME"
from mgmt$db_dbninstanceinfo order by LOG_MODE;

---List Machine_Names, CPU Count & Database Verion

SELECT mgmt$target.host_name,mgmt$target.target_name
 , mgmt$target_properties.property_name
 , mgmt$target_properties.property_value
 FROM mgmt$target
 , mgmt$target_properties
 WHERE ( mgmt$target.target_name = mgmt$target_properties.target_name )
 AND ( mgmt$target.target_type = mgmt$target_properties.target_type )
 AND ( mgmt$target_properties.property_name in ( 'CPUCount','DBVersion' ) )
 GROUP BY mgmt$target.host_name,mgmt$target.target_name
 , mgmt$target_properties.property_name
 , mgmt$target_properties.property_value
 order by mgmt$target.host_name;
 
 ---simple query to pull incidents for a particular set of targets
 SELECT 
  TO_CHAR(a.last_updated_date, 'YYYY-MM-DD') "Last Updated Date", 
  TO_CHAR(a.last_updated_date, 'HH24:MI:SS') "Last Updated Time",
  a.summary_msg                              "Message", 
  b.target_type                              "Target Type", 
  b.target_name                              "Target Name", 
  a.severity                                 "Severity", 
  a.resolution_state                         "Resolution State"
FROM   
  sysman.mgmt$incidents a,
  sysman.mgmt$target b
WHERE a.target_guid = b.target_guid
AND   a.last_updated_date >= SYSDATE - 30
AND   (b.target_name LIKE '%EBS%'
OR     b.target_name LIKE 'EBS%')
AND    a.severity != 'Clear'
AND    b.target_type IN (
  'host',
  'j2ee_application',
  'j2ee_application_cluster',
  'j2ee_application_domain',
  'oracle_apache',
  'oracle_coherence',
  'oracle_coherence_cache',
  'oracle_coherence_node',
  'oracle_home',
  'oracle_sdpmessagingdriver',
  'oracle_sdpmessagingdriver_email',
  'oracle_sdpmessagingdriver_smpp',
  'oracle_sdpmessagingdriver_xmpp',
  'oracle_sdpmessagingserver',
  'oracle_soa_composite',
  'oracle_soa_folder',
  'oracle_soainfra',
  'oracle_soainfra_cluster',
  'scheduler_service',
  'scheduler_service_group',
  'weblogic_cluster',
  'weblogic_domain',
  'weblogic_j2eeserver',
  'weblogic_nodemanager')
ORDER BY 1 DESC, 2 DESC


--CPU consumption for a host
select entity_name ,collection_time,min_value as min,avg_value as avg,max_value as max
from gc$metric_values_daily
where metric_group_name = 'Load'
and metric_column_name = 'cpuUtil'
and (entity_name like '%at1oexdbadm01%' )
order by 2,1 asc;

---Hourly
select entity_name,collection_time,min_value as min,avg_value as avg,max_value as max
from gc$metric_values_hourly
where metric_group_name = 'Load'
and metric_column_name = 'cpuUtil'
and (entity_name like 'exanproddb01.onerheem.com%' )
and collection_time < sysdate-1
order by 1,2

---Target database and versions

select db.TARGET_NAME DATABASE_NAME, db.target_type TARGET_TYPE, prop.PROPERTY_VALUE DATABASE_VERSION, os.TARGET_NAME SERVER, os.TYPE_QUALIFIER1 OS, os.TYPE_QUALIFIER2 OS_VERSION
from SYSMAN.MGMT$TARGET db, SYSMAN.MGMT$TARGET os, SYSMAN.MGMT$TARGET_PROPERTIES prop
where db.HOST_NAME = os.TARGET_NAME
and db.TARGET_GUID = prop.TARGET_GUID
and prop.PROPERTY_NAME='Version'
and (db.target_type='oracle_database' or db.target_type='rac_database' or db.target_type='oracle_pdb')
and os.target_type='host'
order by 1;

---get the availability history for 1 database for past 180 days
SELECT a.AVAILABILITY_STATUS,round(SUM(a.VALUE*24/100 ),2)as Hours FROM(
    (select 'Down' AVAILABILITY_STATUS, 0 VALUE, 2 ORDER_COL
        from dual
    union all
    select 'Up' AVAILABILITY_STATUS, 0 VALUE, 1 ORDER_COL
        from dual
    union all
    select 'System Error' AVAILABILITY_STATUS, 0 VALUE, 5 ORDER_COL
        from dual
    union all
    select 'Agent Down' AVAILABILITY_STATUS, 0 VALUE, 4 ORDER_COL
        from dual
    union all
    select 'Blackout' AVAILABILITY_STATUS, 0 VALUE, 3 ORDER_COL
        from dual
    union all
    select 'Status Pending' AVAILABILITY_STATUS, 0 VALUE, 6 ORDER_COL
        from dual )
    UNION ALL
    SELECT decode(LOWER(AVAILABILITY_STATUS),
                 'target down','Down',
                 'target up','Up',
                 'metric error','System Error',
                 'agent down','Agent Down',
                 'unreachable','Unreachable',
                 'blackout','Blackout',
                 'pending/unknown','Status Pending'
       )AVAILABILITY_STATUS,
    round(SUM( least(nvl(MGMT_VIEW_UTIL.ADJUST_TZ(end_timestamp,T.TIMEZONE_REGION,:T_ZONE),(MGMT_VIEW_UTIL.ADJUST_TZ(sysdate,sessiontimezone,:T_ZONE))),
    sysdate) - greatest(MGMT_VIEW_UTIL.ADJUST_TZ(start_timestamp,T.TIMEZONE_REGION,:T_ZONE),sysdate-180))*100,8 ) as VALUE, 
    decode(LOWER(AVAILABILITY_STATUS),
          'target down',2,
          'target up',1,
          'metric error',5,
          'agent down',4,
          'unreachable',7
          ,'blackout',3,
          'pending/unknown',6
       )ORDER_COL
    from mgmt$availability_history b, MGMT$TARGET T
    WHERE upper(b.target_name)=:DB_NAME
    and b.target_guid=T.TARGET_GUID
    and LOWER(AVAILABILITY_STATUS)!='unreachable'
    and MGMT_VIEW_UTIL.ADJUST_TZ(b.start_timestamp,T.timezone_region,:T_ZONE)<= sysdate
    and (MGMT_VIEW_UTIL.ADJUST_TZ(b.end_timestamp,T.timezone_region,:T_ZONE)>= sysdate-180 OR b.end_timestamp is NULL)
    group by LOWER(AVAILABILITY_STATUS),
     decode(LOWER(AVAILABILITY_STATUS),
            'target down',2,
            'target up',1,
            'metric error',5,
            'agent down',4,
            'unreachable',7,
            'blackout',3,
            'pending/unknown',6
         )
    ) a
    GROUP BY a.AVAILABILITY_STATUS,a.ORDER_COL ORDER BY a.ORDER_COL;

--Get value for TZONE from following query:
SELECT DISTINCT tzname || ' (' || tzabbrev || ')' as display_tz, tzname  as tzone, tzabbrev as tzabbr FROM v$timezone_names;


-------hosts hardware information

SELECT
  HOST,
  CPU_SOCKETS,
  CPU_CORES,
  HYPERTHREAD_ENABLED,
  VCORES,
  CPU_MODEL,
  RAM_GB,
  OPERATION_SYSTEM
FROM (
  SELECT
    table1.TARGET_GUID,
    LOWER(table1.TARGET_NAME) as HOST,
    CPU_SOCKETS,
    CPU_CORES,
    HYPERTHREAD_ENABLED,
    VCORES,
    OPERATION_SYSTEM,
    CPU_MODEL
  FROM (
    SELECT 
      TARGET_GUID,
      TARGET_NAME,
      MAX(INSTANCE_COUNT)*COUNT(*) as CPU_SOCKETS,
      MAX(INSTANCE_COUNT)*SUM(NUM_CORES) as CPU_CORES, 
      DECODE(SUM(IS_HYPERTHREAD_ENABLED),
          0,'NO',
          1,'YES', 
          'YES') --When several CPUs assigned with/without HT, could be higher
          as HYPERTHREAD_ENABLED,
      MAX(INSTANCE_COUNT)*SUM(SIBLINGS) as VCORES,
      DECODE(REGEXP_SUBSTR(LISTAGG(IMPL, ' & ') WITHIN GROUP (ORDER BY 1),'Xeon|Opteron|PA[0-9]+|Family [0-9]+ Model [0-9]+|Itanium'),'',LISTAGG(IMPL, ' & ') WITHIN GROUP (ORDER BY 1),REGEXP_SUBSTR(LISTAGG(IMPL, ' & ') WITHIN GROUP (ORDER BY 1),'Xeon|Opteron|PA[0-9]+|Family [0-9]+ Model [0-9]+|Itanium')) as CPU_MODEL
    FROM
      SYSMAN.MGMT$HW_CPU_DETAILS
    GROUP BY
      TARGET_GUID,
      TARGET_NAME
    ) table1
  LEFT JOIN (
    SELECT 
      table1.TARGET_GUID,    
      table2.PROPERTY_VALUE as OPERATION_SYSTEM
    FROM 
      SYSMAN.MGMT$TARGET table1,
      SYSMAN.MGMT$TARGET_PROPERTIES table2
    WHERE 
      table1.TARGET_TYPE(+)='host' AND 
      table2.TARGET_GUID(+)=table1.TARGET_GUID AND 
      table2.PROPERTY_NAME(+)='OS'    
    ) table2
  ON
    table2.TARGET_GUID=table1.TARGET_GUID
) table3
LEFT JOIN (
  SELECT 
    TARGET_GUID,
    ROUND(MEM/1024) as RAM_GB
  FROM
    SYSMAN.MGMT$OS_HW_SUMMARY
) table4
ON
  table3.TARGET_GUID=table4.TARGET_GUID
ORDER BY
  HOST ;


 SELECT
    rollup_timestamp,
    average   AS avg_cpu_pct,
    maximum   AS max_cpu_pct
FROM
    sysman.mgmt$metric_hourly
WHERE
    target_name  = 'at1oexdbadm01'   -- e.g. OBIPRODC1_host or node hostname
    AND target_type  = 'host'
    AND metric_name  = 'Load'
    AND metric_column = 'cpuUtilization'
    AND rollup_timestamp BETWEEN
            TO_TIMESTAMP('2025-05-02 07:00:00','YYYY-MM-DD HH24:MI:SS')
        AND TO_TIMESTAMP('2025-05-03 01:00:00','YYYY-MM-DD HH24:MI:SS')
ORDER BY 1; 