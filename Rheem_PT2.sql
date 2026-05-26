GV$SESSION and GV$SQL

----------	Oracle Catalog: Dynamic Toolbox - Diagnostic Tools, Scripts, and Analyzers for All Product and Services (Doc ID 52.2)

SELECT s.inst_id,s.sid,s.serial#, s.username,s.program,s.module,
s.action,s.logon_time,q.sql_id,q.sql_text
FROM gv$session s
JOIN gv$sql q ON s.sql_id = q.sql_id AND s.inst_id = q.inst_id
where 
s.username='DEMANTRA'
--and STATUS='ACTIVE';
;


Queries from Memory in last n minutes:
-------------------------------------------------

SELECT sql_text
FROM v$sql
WHERE last_active_time > SYSDATE - INTERVAL '5' MINUTE; -- Adjust the time window as needed


SELECT sql_text
FROM v$sqlarea
WHERE last_active_time > SYSDATE - INTERVAL '5' MINUTE; -- Adjust the time window as needed



===============================
DBA_HIST_ACTIVE_SESS_HISTORY

select h.sample_time,h.instance_number,h.session_id,h.session_serial#,h.machine,h.program,h.module ,
        h.top_level_sql_id,h.sql_id,h.sql_exec_id,h.SQL_OPNAME,h.SQL_PLAN_HASH_VALUE,h.SQL_PLAN_LINE_ID,h.SQL_PLAN_OPERATION,h.SQL_PLAN_OPTIONS,
           h.SQL_EXEC_START,h.PLSQL_OBJECT_ID,H.PLSQL_ENTRY_OBJECT_ID,H.PLSQL_ENTRY_SUBPROGRAM_ID,H.PLSQL_SUBPROGRAM_ID,
           h.seq#,h.event,h.session_state,h.wait_class,h.time_waited,h.WAIT_TIME,h.p1text,h.p1,h.p2text,h.p2, h.p3text,h.p3,
           h.session_state,h.current_obj#,h.current_file#,h.current_block#,
           h.REMOTE_INSTANCE#,
           h.xid,
           h.blocking_session_status,
           h.blocking_session,
           h.blocking_session_serial#,
           h.BLOCKING_INST_ID,
           h.pga_allocated/1024/1024/1024,
           h.temp_space_allocated,
           h.tm_Delta_time , h.PX_FLAGS
from 
DBA_HIST_ACTIVE_SESS_HISTORY h
where 
sql_id='18kcp83jg9buf' 
and SQL_EXEC_START>SYSDATE-1 
-- sample_time BETWEEN TO_DATE ('202311211330', 'yyyymmddhh24mi') 
                --AND  TO_DATE ('202311211500','yyyymmddhh24mi')
order by SAMPLE_TIME desc;


include text of SQL
------------------------------------

SELECT 
    h.sample_time,
    h.instance_number,
    h.session_id,
    h.session_serial#,
    h.machine,
    h.program,
    h.module,
    h.top_level_sql_id,
    h.sql_id,
    h.sql_exec_id,
    h.SQL_OPNAME,
    h.SQL_PLAN_HASH_VALUE,
    h.SQL_PLAN_LINE_ID,
    h.SQL_PLAN_OPERATION,
    h.SQL_PLAN_OPTIONS,
    h.SQL_EXEC_START,
    h.PLSQL_OBJECT_ID,
    h.PLSQL_ENTRY_OBJECT_ID,
    h.PLSQL_ENTRY_SUBPROGRAM_ID,
    h.PLSQL_SUBPROGRAM_ID,
    h.seq#,
    h.event,
    h.session_state,
    h.wait_class,
    h.time_waited,
    h.WAIT_TIME,
    h.p1text,
    h.p1,
    h.p2text,
    h.p2,
    h.p3text,
    h.p3,
    h.session_state,
    h.current_obj#,
    h.current_file#,
    h.current_block#,
    h.REMOTE_INSTANCE#,
    h.xid,
    h.blocking_session_status,
    h.blocking_session,
    h.blocking_session_serial#,
    h.BLOCKING_INST_ID,
    h.pga_allocated / 1024 / 1024 / 1024 AS pga_allocated_gb,
    h.temp_space_allocated,
    h.tm_Delta_time,
    h.PX_FLAGS,
    s.sql_text
FROM 
    DBA_HIST_ACTIVE_SESS_HISTORY h
LEFT JOIN 
    DBA_HIST_SQLTEXT s ON h.sql_id = s.sql_id
WHERE 
    h.sample_time BETWEEN TO_DATE('202405080600', 'yyyymmddhh24mi') 
                      AND TO_DATE('202405081000', 'yyyymmddhh24mi')
    AND h.module LIKE 'ODI%'
ORDER BY 
    h.sample_time;


=========================================================
DBA_HIST_SNAPSHOT AND DBA_HIST_ACTIVE_SESS_HISTORY

  SELECT  /*+LEADING(x h) USE_NL(h)*/
        h.sample_time,h.instance_number,h.session_id,h.session_serial#,du.username,h.machine,h.program,h.module ,
        h.top_level_sql_id,h.sql_id,h.sql_exec_id,h.SQL_OPNAME,h.SQL_PLAN_HASH_VALUE,h.SQL_PLAN_LINE_ID,h.SQL_PLAN_OPERATION,h.SQL_PLAN_OPTIONS,
           h.SQL_EXEC_START,h.PLSQL_OBJECT_ID,H.PLSQL_ENTRY_OBJECT_ID,H.PLSQL_ENTRY_SUBPROGRAM_ID,H.PLSQL_SUBPROGRAM_ID,
           h.seq#,h.event,h.session_state,h.wait_class,h.time_waited,h.WAIT_TIME,h.p1text,h.p1,h.p2text,h.p2, h.p3text,h.p3,
           h.session_state,h.current_obj#,do.object_name,do.subobject_name,h.current_file#,h.current_block#,
           h.REMOTE_INSTANCE#,
           h.xid,
           h.blocking_session_status,
           h.blocking_session,
           h.blocking_session_serial#,
           h.BLOCKING_INST_ID,
           h.pga_allocated/1024/1024/1024,
           h.temp_space_allocated,
           h.tm_Delta_time , h.PX_FLAGS
          FROM   dba_hist_snapshot x,
           dba_hist_active_sess_history h,
           dba_objects do,
           dba_users du
   WHERE
     --x.end_interval_time >= TO_DATE ('202311131300', 'yyyymmddhh24mi')
     --      AND x.begin_interval_time <= TO_DATE ('202311130700', 'yyyymmddhh24mi')
        h.sample_time BETWEEN TO_DATE ('202311211330', 'yyyymmddhh24mi') 
                            AND  TO_DATE ('202311211500','yyyymmddhh24mi')
           AND h.snap_id = x.snap_id
           AND h.dbid = x.dbid
           AND h.instance_number = x.instance_number
           and h.instance_number = 1
           AND h.current_obj# = do.object_id(+)
           AND h.user_id = du.user_id(+)
           --AND h.sql_id = 'a0u5jqwc5zm1c' 
ORDER BY   sample_time DESC

===================================================

DBA_HIST_SQLSTAT   DBA_HIST_SNAPSHOT  DBA_HIST_SQLTEXT 
	 
SELECT instance_number,module , SQL_EXECUTIONS,PLAN_HASH_VALUE,IOPS, IOPS/SQL_EXECUTIONS IOPS_Per_Exec,
round (ELAPSED_TIME/SQL_EXECUTIONS/1000/1000,2) Elapsed_Per_Exec_seconds ,
round(CPUTIME/SQL_EXECUTIONS/1000/1000,2) CPU_Per_Exec_seconds,CPUTIME/1000/1000 CPUTIME_IN_SEC,
round (100*(1-(totbytestransfer_gb/totphysialread_gb)),2)  offload_efficiency,sql_id , 
schema_name ,ROWS_PROCESSED,totphysialread_gb,totbytestransfer_gb ,Totofflelgbytes_gb,TotoffloadRet_gb,totphysialwrite_gb,SQLTEXT
FROM 
( 
       select  a.instance_number,module ,PLAN_HASH_VALUE,PARSING_SCHEMA_NAME SCHEMA_NAME  , a.sql_id ,TO_CHAR(DBMS_LOB.SUBSTR(c.sql_text, 200)) SQLTEXT ,
       sum(executions_delta) SQL_EXECUTIONS , sum(rows_processed_delta) ROWS_PROCESSED , 
       sum(disk_reads_delta) IOPS , sum( a.cpu_time_delta) CPUTIME , sum(a.ELAPSED_TIME_DELTA) ELAPSED_TIME ,
       sum(buffer_gets_delta) MEMORY_BUFFERS ,
       sum(IO_OFFLOAD_RETURN_BYTES_DELTA)/1024/1024/1024 TotoffloadRet_gb ,
       sum(PHYSICAL_READ_BYTES_DELTA)/1024/1024/1024 totphysialread_gb,
       sum(PHYSICAL_WRITE_BYTES_DELTA)/1024/1024/1024 totphysialwrite_gb,
       sum(IO_INTERCONNECT_BYTES_DELTA)/1024/1024/1024 totbytestransfer_gb , 
       sum(IO_OFFLOAD_ELIG_BYTES_DELTA)/1024/1024/1024 Totofflelgbytes_gb
       from  DBA_HIST_SQLSTAT a , dba_hist_snapshot b , dba_hist_sqltext c 
       where a.dbid                     = c.dbid
       and c.sql_id                     = a.sql_id 
       and a.snap_id                    = b.snap_id 
       and a.instance_number            = b.instance_number 
       and a.dbid                       = b.dbid 
       and a.dbid in ( select dbid from v$database)
       --and begin_interval_time between TO_DATE ('202405270800', 'yyyymmddhh24mi') AND TO_DATE ('202406050800', 'yyyymmddhh24mi')
       --to_Date ('02/12/2020 11        : 00: 00','MM/DD/YYYY HH24: MI: SS' ) 
       --and     to_Date ('02/18/2020 11: 00: 00','MM/DD/YYYY HH24: MI: SS' )
       and a.sql_id                  = 'b5p3saq9c0t22'
       and parsing_schema_name not in ('SYS','SYSTEM','DBSNMP','APEX_PUBLIC_USER')
       and executions_delta > 0 and PHYSICAL_READ_BYTES_DELTA > 0 
       --and a.instance_number            = 2
       group by   a.instance_number,module ,PARSING_SCHEMA_NAME, a.sql_id , PLAN_HASH_VALUE,TO_CHAR(DBMS_LOB.SUBSTR(c.sql_text, 200)) 
       order by  
       --sum( a.cpu_time_delta) 
       sum(disk_reads_delta)
       desc ) 
WHERE ROWNUM < 300 
order by CPUTIME_IN_SEC desc;


----- Session executions in particular time

WITH SQL_STATS AS (
    SELECT
        a.instance_number,
        module,
        PLAN_HASH_VALUE,
        PARSING_SCHEMA_NAME AS SCHEMA_NAME,
        TRIM(TO_CHAR(b.begin_interval_time, 'DAY')) AS DAY,
        a.sql_id,
        TO_CHAR(DBMS_LOB.SUBSTR(c.sql_text, 200)) AS SQLTEXT,
        SUM(executions_delta) AS SQL_EXECUTIONS,
        SUM(rows_processed_delta) AS ROWS_PROCESSED,
        SUM(disk_reads_delta) AS IOPS,
        SUM(a.cpu_time_delta) AS CPUTIME,
        SUM(a.ELAPSED_TIME_DELTA) AS ELAPSED_TIME,
        SUM(buffer_gets_delta) AS MEMORY_BUFFERS,
        SUM(IO_OFFLOAD_RETURN_BYTES_DELTA) / 1024 / 1024 / 1024 AS TotoffloadRet_gb,
        SUM(PHYSICAL_READ_BYTES_DELTA) / 1024 / 1024 / 1024 AS totphysialread_gb,
        SUM(PHYSICAL_WRITE_BYTES_DELTA) / 1024 / 1024 / 1024 AS totphysialwrite_gb,
        SUM(IO_INTERCONNECT_BYTES_DELTA) / 1024 / 1024 / 1024 AS totbytestransfer_gb,
        SUM(IO_OFFLOAD_ELIG_BYTES_DELTA) / 1024 / 1024 / 1024 AS Totofflelgbytes_gb
    FROM
        DBA_HIST_SQLSTAT a
    JOIN dba_hist_snapshot b ON a.snap_id = b.snap_id
    JOIN dba_hist_sqltext c ON c.sql_id = a.sql_id AND a.dbid = c.dbid
    WHERE
        a.dbid IN (SELECT dbid FROM v$database)
        AND TRIM(TO_CHAR(b.begin_interval_time, 'DAY')) IN ('SATURDAY', 'SUNDAY')
        AND TO_CHAR(b.begin_interval_time, 'HH24:MI:SS') BETWEEN '04:00:00' AND '09:00:00'
        AND TO_CHAR(b.begin_interval_time, 'YYYY-MM-DD') BETWEEN '2024-09-30' AND '2024-10-08'
        AND parsing_schema_name NOT IN ('SYS', 'SYSTEM', 'DBSNMP', 'APEX_PUBLIC_USER')
        AND executions_delta > 0
        AND PHYSICAL_READ_BYTES_DELTA > 0
    GROUP BY
        a.instance_number, module, PARSING_SCHEMA_NAME, a.sql_id, PLAN_HASH_VALUE,
        TRIM(TO_CHAR(b.begin_interval_time, 'DAY')),  -- Add DAY here
        TO_CHAR(DBMS_LOB.SUBSTR(c.sql_text, 200))  -- Ensure SQLTEXT is also included
    ORDER BY
        SUM(disk_reads_delta) DESC
)
SELECT
    instance_number,
    module,
    SQL_EXECUTIONS,
    PLAN_HASH_VALUE,
    IOPS,
    IOPS / SQL_EXECUTIONS AS IOPS_Per_Exec,
    DAY,
    ROUND(ELAPSED_TIME / SQL_EXECUTIONS / 1000 / 1000, 2) AS Elapsed_Per_Exec_seconds,
    ROUND(CPUTIME / SQL_EXECUTIONS / 1000 / 1000, 2) AS CPU_Per_Exec_seconds,
    CPUTIME / 1000 / 1000 AS CPUTIME_IN_SEC,
    ROUND(100 * (1 - (totbytestransfer_gb / totphysialread_gb)), 2) AS offload_efficiency,
    sql_id,
    SCHEMA_NAME,
    ROWS_PROCESSED,
    totphysialread_gb,
    totbytestransfer_gb,
    Totofflelgbytes_gb,
    TotoffloadRet_gb,
    totphysialwrite_gb,
    SQLTEXT
FROM
    SQL_STATS
WHERE
    ROWNUM < 300
ORDER BY
    CPUTIME_IN_SEC DESC;


=============================================================

Current 

-- This will show historical information for the query


SELECT  inst_id, sql_id,plan_hash_value,DELTA_EXECUTION_COUNT,
        (CASE WHEN DELTA_EXECUTION_COUNT != 0 OR DELTA_ELAPSED_TIME != 0 
             THEN ((DELTA_ELAPSED_TIME/1000000)/DELTA_EXECUTION_COUNT) ELSE 0 END ) AS "sec_per_exec" ,
        --(DELTA_ELAPSED_TIME/1000000)/DELTA_EXECUTION_COUNT AS "sec_per_exec" ,
        DELTA_ELAPSED_TIME,
        (CASE WHEN DELTA_EXECUTION_COUNT != 0 OR DELTA_CPU_TIME != 0 
            THEN ((DELTA_CPU_TIME/1000000)/DELTA_EXECUTION_COUNT) ELSE 0 END ) AS "cpu_per_exec" ,
        --(DELTA_CPU_TIME/1000000)/DELTA_EXECUTION_COUNT "cpu_per_exec",
        DELTA_CPU_TIME,
        DELTA_DIRECT_WRITES,DELTA_DISK_READS,DELTA_PHYSICAL_READ_BYTES,
        DELTA_ROWS_PROCESSED,DELTA_SORTS,DELTA_USER_IO_WAIT_TIME,
        --elapsed_time/1000000 "total_elapsed_sec",
        sql_text
FROM GV$SQLSTATS_PLAN_HASH 
WHERE 1=1 
AND sql_id in ('b5p3saq9c0t22') 
--and DELTA_EXECUTION_COUNT>0
;  


SELECT  inst_id,sql_id, MODULE, plan_hash_value,sql_profile,round(elapsed_time/1000000) ELAPSED,round(CPU_TIME/1000000) CPU_TIME,EXECUTIONS, 
        round((elapsed_time/1000000)/executions) "sec_per_exec", round((CPU_TIME/1000000)/executions) "cpu_per_exec",
        (rows_processed/executions) "rows_processed_delta" , rows_processed,
        BUFFER_GETS,DISK_READS,FIRST_LOAD_TIME,LAST_ACTIVE_TIME,LAST_LOAD_TIME,USER_IO_WAIT_TIME,
        sql_text
FROM GV$SQLAREA
WHERE 1=1 
AND executions <> 0
;

---- Another including DBA_HIST_ACTIVE_SESS_HISTORY to get action and session start time
select stat.sql_id,h.action,h.sample_time,
    TO_CHAR (h.SQL_EXEC_START, 'mm-dd-yy hh24:mi:ss') "SQL_EXEC_START",
	plan_hash_value
             PHV,
         sql_profile,
    RPAD (stat.parsing_schema_name, 10)
             "schema",
         ((elapsed_time_total / 1000000) / NULLIF(stat.executions_total, 0)) "Sec per exec",
         elapsed_time_total / 1000000 / 60
             "Min",
         ROUND (stat.elapsed_time_total / 1000000 / 60 / 60, 1)
             "Hrs",
         elapsed_time_delta,     
         txt.sql_text 			 
    FROM dba_hist_sqlstat stat, dba_hist_sqltext txt, dba_hist_snapshot ss, DBA_HIST_ACTIVE_SESS_HISTORY h
   WHERE     stat.sql_id = txt.sql_id
         AND stat.dbid = txt.dbid
         AND ss.dbid = stat.dbid
         AND ss.instance_number = stat.instance_number
         AND stat.snap_id = ss.snap_id
         AND parsing_schema_name NOT LIKE 'sys%'
         --AND stat.executions_delta > 0
         --  AND ss.begin_interval_time >= sysdate-100
         --AND stat.elapsed_time_total / 1000000 > 1 --and sql_text like '%TAB_NAME%'
         and UPPER(txt.sql_text) LIKE UPPER('create%index%')
         and stat.sql_id=h.sql_id
         --and h.Action like '%6474271969%'
         --and sql_text like '%index%OBI_DW.W_AP_XACT_F%'
         --and to_char(ss.end_interval_time,'dd-mm-yy')='18-06-17'
         --AND stat.sql_id = '8xzdzuhq0fd7j'
--and plan_hash_value in (1461727023,879721768)
ORDER BY h.SQL_EXEC_START DESC;

--- Anothe one to get details of Index creation OBIEE large_pool_size

SELECT a.SAMPLE_TIME,a.session_id,a.session_serial#,a.machine,a.program,a.module,
       a.SQL_OPNAME,
       a.SQL_EXEC_START,
       a.SQL_EXEC_START + (a.SQL_EXEC_ID/1000000/24/60/60) AS SQL_EXEC_END,
       (a.SQL_EXEC_START + (a.SQL_EXEC_ID/1000000/24/60/60)) - a.SQL_EXEC_START AS DURATION_SECONDS,
       a.program,
       a.client_id,
       b.SQL_TEXT
FROM DBA_HIST_ACTIVE_SESS_HISTORY a
JOIN dba_hist_sqltext b ON a.SQL_ID = b.SQL_ID
WHERE UPPER(b.sql_text) LIKE UPPER('%create%index%')
--and a.Action like '%6474271969%'
ORDER BY a.SQL_EXEC_START DESC;


-- If there is more than one plan and you want to flush the share pool to get rid of the bad plan, get the following info


 SELECT INST_ID, SQL_ID, ADDRESS, HASH_VALUE, PLAN_HASH_VALUE,SQL_PROFILE, SQL_PLAN_BASELINE FROM GV$SQLAREA WHERE SQL_ID='8xzdzuhq0fd7j';
 
 -- Use this to flush the shared pool on the correct node
 --                             address          hash_value
 
 EXEC DBMS_SHARED_POOL.PURGE ('0000000176E57028,1674277719','C');


 select inst_id,SQL_ID, SQL_PROFILE,PLAN_HASH_VALUE from GV$SQL where SQL_ID='b5p3saq9c0t22';

select inst_id,address, hash_value, executions, SQL_PROFILE,PLAN_HASH_VALUE,loads, version_count, invalidations, parse_calls from gv$sqlarea where sql_id = 'b5p3saq9c0t22';

select SQL_FULLTEXT,SQL_ID,LAST_ACTIVE_TIME,PLAN_HASH_VALUE,EXECUTIONS,CPU_TIME,ELAPSED_TIME from gV$SQLSTATS_PLAN_HASH where SQL_ID='b5p3saq9c0t22';
 

---------------SQL History

SELECT --stat.*,
        ss.instance_number,
         stat.sql_id,
         plan_hash_value
             PHV,
         sql_profile,
         RPAD (stat.parsing_schema_name, 10)  "schema",
         ((elapsed_time_total / 1000000) / stat.executions_total)   "Sec per exec",
         ((elapsed_time_total / 1000000) / 60/ stat.executions_total) AS "Min",
         ((elapsed_time_total / 1000000) / 60 / 60 / stat.executions_total) AS "Hrs",
         elapsed_time_delta
             EL_T_DELT,
         disk_reads_delta
             DISK_R_DELT,
         stat.executions_delta
             EXEC_DELT,
         stat.executions_total
             EXEC_TOT,
         cpu_time_total / 1000000,
         cpu_time_delta / 1000000,
         (cpu_time_delta / 1000000) / stat.executions_delta
             "cpu per exec",
         rows_processed_total
             rows_total,
         rows_processed_delta
             rows_delta,
         ((cpu_time_total / 1000000) / stat.executions_total)
             "cpu per exec",
         TO_CHAR (ss.BEGIN_INTERVAL_TIME, 'mm-dd-yy hh24:mi:ss')
             "BeginTime",
         TO_CHAR (ss.end_interval_time, 'mm-dd-yy hh24:mi:ss')
             "EndTime",
         RPAD (txt.sql_text, 40)
             text,
         ss.snap_id
    FROM dba_hist_sqlstat stat, dba_hist_sqltext txt, dba_hist_snapshot ss
   WHERE     stat.sql_id = txt.sql_id
         AND stat.dbid = txt.dbid
         AND ss.dbid = stat.dbid
         AND ss.instance_number = stat.instance_number
         AND stat.snap_id = ss.snap_id
         AND parsing_schema_name NOT LIKE 'sys%'
         AND stat.executions_delta > 0
         --  AND ss.begin_interval_time >= sysdate-100
         AND stat.elapsed_time_total / 1000000 > 1 --and sql_text like '%TAB_NAME%'
         --and sql_text like '%CREATE MATERIALIZED VIEW BIEO_RHM_ACD_WKLY_OPS_RPT%'
         --and to_char(ss.end_interval_time,'dd-mm-yy')='18-06-17'
         AND stat.sql_id = '85wnyj5xypcuu'
--and plan_hash_value in (1461727023,879721768)
ORDER BY ss.BEGIN_INTERVAL_TIME DESC;

--- modifed to search with sql_text

select stat.sql_id,
	plan_hash_value
             PHV,
         sql_profile,
    RPAD (stat.parsing_schema_name, 10)
             "schema",
         ((elapsed_time_total / 1000000) / NULLIF(stat.executions_total, 0)) "Sec per exec",
         elapsed_time_total / 1000000 / 60
             "Min",
         ROUND (stat.elapsed_time_total / 1000000 / 60 / 60, 1)
             "Hrs",
         elapsed_time_delta,     
    TO_CHAR (ss.BEGIN_INTERVAL_TIME, 'mm-dd-yy hh24:mi:ss')
             "BeginTime",
         TO_CHAR (ss.end_interval_time, 'mm-dd-yy hh24:mi:ss')
             "EndTime",
       txt.sql_text 			 
    FROM dba_hist_sqlstat stat, dba_hist_sqltext txt, dba_hist_snapshot ss
   WHERE     stat.sql_id = txt.sql_id
         AND stat.dbid = txt.dbid
         AND ss.dbid = stat.dbid
         AND ss.instance_number = stat.instance_number
         AND stat.snap_id = ss.snap_id
         AND parsing_schema_name NOT LIKE 'sys%'
         --AND stat.executions_delta > 0
         --  AND ss.begin_interval_time >= sysdate-100
         --AND stat.elapsed_time_total / 1000000 > 1 --and sql_text like '%TAB_NAME%'
         and UPPER(txt.sql_text) LIKE UPPER('create%index%OBI_DW.W_AP_XACT_F%')
         --and sql_text like '%index%OBI_DW.W_AP_XACT_F%'
         --and to_char(ss.end_interval_time,'dd-mm-yy')='18-06-17'
         --AND stat.sql_id = '8xzdzuhq0fd7j'
--and plan_hash_value in (1461727023,879721768)
ORDER BY ss.BEGIN_INTERVAL_TIME DESC;

-----SQL Profile:

Cursor:
-------
select module,parsing_schema_name,inst_id,sql_id,plan_hash_value,sql_profile,child_number,sql_fulltext,
to_char(last_active_time,'DD/MM/YY HH24:MI:SS' ),sql_plan_baseline,executions,
elapsed_time/executions/1000/1000,rows_processed from gv$sql
where sql_id in ('2dh286fuxpgq0');

select distinct
p.name sql_profile_name,
s.sql_id
from
dba_sql_profiles p,
DBA_HIST_SQLSTAT s
where
p.name=s.sql_profile and s.sql_id='323hjjc0x1049';       



Parallel Execution:
-----------------------
select sql_id,
       sample_time,
       sql_opname,
       trunc(px_flags/2097152) dop,
       program
from DBA_HIST_ACTIVE_SESS_HISTORY
where sql_id = 'c90mm8k91wjuy';

select sql_id,
       sample_time,
       sql_opname,
       trunc(px_flags/2097152) dop,
       program from GV$ACTIVE_SESSION_HISTORY where sql_id = '1fjfungkpakq8'

 Executions form Cursor:
 --------------------------
select INST_ID ,SQL_ID,to_char(LAST_ACTIVE_TIME,'DD-MON_YYYY hh24:mi:ss')LAST_ACTIVE_TIME, LAST_LOAD_TIME,
EXECUTIONS ,ELAPSED_TIME/EXECUTIONS/1000/1000 elapsedtime_per_exec_sec,
CPU_TIME/EXECUTIONS/1000,SQL_PROFILE,SQL_PATCH,
SQL_PLAN_BASELINE,PLAN_HASH_VALUE,SQL_FULLTEXT ,BUFFER_GETS/EXECUTIONS,ROWS_PROCESSED/EXECUTIONS,
DISK_READS/EXECUTIONS ,USER_IO_WAIT_TIME/EXECUTIONS/1000,SORTS,PROGRAM_ID ,PROGRAM_LINE#, 
ELAPSED_TIME,END_OF_FETCH_COUNT ,USERS_EXECUTING ,LOADS ,
CLUSTER_WAIT_TIME,ROWS_PROCESSED,OPTIMIZER_COST ,CHILD_NUMBER ,MODULE    ,ACTION    ,LAST_LOAD_TIME    ,
IS_BIND_SENSITIVE ,IS_BIND_AWARE ,IS_SHAREABLE,    
LAST_ACTIVE_TIME,IO_CELL_OFFLOAD_ELIGIBLE_BYTES,IO_INTERCONNECT_BYTES,    
PHYSICAL_READ_REQUESTS,PHYSICAL_READ_BYTES,PHYSICAL_WRITE_REQUESTS,PHYSICAL_WRITE_BYTES,OPTIMIZED_PHY_READ_REQUESTS     from gV$sql where 
sql_id ='2dh286fuxpgq0'  
--program_id=604550
--module='e:AR:cp:ar/ARBFB_GEN'
--module like 'e:AR:cp:bks_ar%'
and executions > 0
--order by LAST_ACTIVE_TIME desc
--order by elapsedtime_per_exec_ms desc 
order by 3 desc;



AWR:
---------------

SELECT 
    SN.INSTANCE_NUMBER,
    S.SNAP_ID,
    S.SQL_ID,
    TO_CHAR(SN.BEGIN_INTERVAL_TIME,'DD-MON-YYYY HH24:MI') BEGIN_TIME,
    TO_CHAR(SN.END_INTERVAL_TIME,'DD-MON-YYYY HH24:MI') END_TIME,
    S.EXECUTIONS_DELTA,
    S.ELAPSED_TIME_DELTA/1000000 ELAPSED_SEC,
    S.CPU_TIME_DELTA/1000000 CPU_SEC,
    S.PLAN_HASH_VALUE,
    S.PARSING_SCHEMA_NAME,
    S.MODULE,
    S.ACTION,
    S.BUFFER_GETS_DELTA,
    S.DISK_READS_DELTA
FROM DBA_HIST_SQLSTAT S
JOIN DBA_HIST_SNAPSHOT SN
  ON S.SNAP_ID = SN.SNAP_ID
 AND S.DBID = SN.DBID
 AND S.INSTANCE_NUMBER = SN.INSTANCE_NUMBER
WHERE S.SQL_ID = '3hgvh4ch4nxkw'
ORDER BY S.SNAP_ID DESC;


AWR:
---------------
select PARSING_SCHEMA_NAME, dhss.sql_id, dhss.sql_profile, dhss.module,dhss.action,dhss.executions_delta, dhss.executions_total, dhss.ELAPSED_TIME_TOTAL/1000/1000, 
dhss.CPU_TIME_TOTAL, sn.begin_interval_time, sn.end_interval_time, sq.sql_text 
from dba_hist_sqlstat dhss, dba_hist_snapshot sn, dba_hist_sqltext sq 
where dhss.snap_id = sn.snap_id 
and sq.sql_id = dhss.sql_id 
and trunc(sn.begin_interval_time) = trunc(sysdate-30) 
and sq.sql_id ='2dh286fuxpgq0'
--and sq.sql_id ='59rbbmb9t6wyy'
--and PARSING_SCHEMA_NAME not in ('SYS','SYSTEM'

 ---- History of tunning advisor

 select dbms_sqltune.report_auto_tuning_task(
  (select min(execution_name) from dba_advisor_findings
    where task_name like 'SYS_AUTO_SQL%'),
  (select max(execution_name) from dba_advisor_findings
    where task_name like 'SYS_AUTO_SQL%')
) from dual;


Bind values:
------------------------------------------

--From Cursor :

SELECT NAME,POSITION,DATATYPE_STRING,VALUE_STRING FROM gv$sql_bind_capture WHERE sql_id='dsyq9252qn13a';


--from history:
-----
with mysnap as (
select max(SNAP_ID) SNAP_ID from dba_hist_sqlbind where sql_id ='b5p3saq9c0t22')
select distinct
b.SNAP_ID, b.sql_id, b.NAME, b.position,b.DATATYPE, b.VALUE_STRING 
from 
mysnap, dba_hist_sqlbind b
where b.SNAP_ID=mysnap.SNAP_ID and b.sql_id ='b5p3saq9c0t22'
order by b.position;


CPU Utilization:
================================
WITH
dhsp AS (
          SELECT snap_id
               , dbid
               , instance_number
               , begin_interval_time
               , end_interval_time
          FROM dba_hist_snapshot
        ),
dhstm AS (
           SELECT snap_id
                , dbid
                , instance_number
                , stat_name
                , value
           FROM dba_hist_sys_time_model
           WHERE stat_name = 'DB time'
         ),
dhos AS (
          SELECT snap_id
               , dbid
               , instance_number
               , stat_name
               , value
          FROM dba_hist_osstat
          WHERE stat_name = 'NUM_CPUS'
        ),
all_awr_dbtime_and_cpus AS (
                             SELECT dhsp.instance_number
                                  , LAG(dhsp.snap_id, 1, 0) OVER (PARTITION BY dhsp.dbid, dhsp.instance_number ORDER BY dhsp.snap_id) first_snap_id
                                  , dhsp.snap_id second_snap_id
                                  , CAST(dhsp.begin_interval_time AS DATE) begin_time
                                  , CAST(dhsp.end_interval_time AS DATE) end_time
                                  , ROUND((dhstm.value - LAG(dhstm.value, 1, 0) OVER (PARTITION BY dhstm.dbid, dhstm.instance_number ORDER BY dhstm.snap_id))/1e6/6e1, 2) dbtime_mins
                                  , (CAST(dhsp.end_interval_time AS DATE) - CAST(begin_interval_time AS DATE))*24*6e1 elapsed_mins
                                  , dhos.value num_cpus
                             FROM dhsp
                                , dhstm
                                , dhos
                             WHERE dhsp.snap_id = dhstm.snap_id
                             AND   dhsp.instance_number = dhstm.instance_number
                             AND   dhsp.dbid = dhstm.dbid
                             AND   dhstm.snap_id = dhos.snap_id
                             AND   dhstm.instance_number = dhos.instance_number
                             AND   dhstm.dbid = dhos.dbid
                             ORDER BY dhsp.instance_number
                                    , first_snap_id
                           )
SELECT instance_number
     , first_snap_id
     , second_snap_id
     , begin_time
     , end_time
     , ROUND(dbtime_mins/(elapsed_mins*num_cpus)*100, 2) || '%' awr_cpu_load
FROM all_awr_dbtime_and_cpus
WHERE first_snap_id <> 0
--AND begin_time>sysdate -7
AND begin_time between to_date ('202312040000','yyyymmddhh24mi') and to_date ('202312090000','yyyymmddhh24mi')
order by 2 asc;

Another query for CPU:
----------------------------
select INSTANCE_NUMBER,to_char(BEGIN_TIME,'MM-DD-YYYY') WaitDay,
max(decode(to_char(END_TIME,'HH24'),'00',AVERAGE,0)) "00",
max(decode(to_char(END_TIME,'HH24'),'01',AVERAGE,0)) "01",
max(decode(to_char(END_TIME,'HH24'),'02',AVERAGE,0)) "02",
max(decode(to_char(END_TIME,'HH24'),'03',AVERAGE,0)) "03",
max(decode(to_char(END_TIME,'HH24'),'04',AVERAGE,0)) "04",
max(decode(to_char(END_TIME,'HH24'),'05',AVERAGE,0)) "05",
max(decode(to_char(END_TIME,'HH24'),'06',AVERAGE,0)) "06",
max(decode(to_char(END_TIME,'HH24'),'07',AVERAGE,0)) "07",
max(decode(to_char(END_TIME,'HH24'),'08',AVERAGE,0)) "08",
max(decode(to_char(END_TIME,'HH24'),'09',AVERAGE,0)) "09",
max(decode(to_char(END_TIME,'HH24'),'10',AVERAGE,0)) "10",
max(decode(to_char(END_TIME,'HH24'),'11',AVERAGE,0)) "11",
max(decode(to_char(END_TIME,'HH24'),'12',AVERAGE,0)) "12",
max(decode(to_char(END_TIME,'HH24'),'13',AVERAGE,0)) "13",
max(decode(to_char(END_TIME,'HH24'),'14',AVERAGE,0)) "14",
max(decode(to_char(END_TIME,'HH24'),'15',AVERAGE,0)) "15",
max(decode(to_char(END_TIME,'HH24'),'16',AVERAGE,0)) "16",
max(decode(to_char(END_TIME,'HH24'),'17',AVERAGE,0)) "17",
max(decode(to_char(END_TIME,'HH24'),'18',AVERAGE,0)) "18",
max(decode(to_char(END_TIME,'HH24'),'19',AVERAGE,0)) "19",
max(decode(to_char(END_TIME,'HH24'),'20',AVERAGE,0)) "20",
max(decode(to_char(END_TIME,'HH24'),'21',AVERAGE,0)) "21",
max(decode(to_char(END_TIME,'HH24'),'22',AVERAGE,0)) "22",
max(decode(to_char(END_TIME,'HH24'),'23',AVERAGE,0)) "23"
from DBA_HIST_SYSMETRIC_SUMMARY
where METRIC_NAME like 'Host CPU Utilization%' --and INSTANCE_NUMBER = &inst_num
group by INSTANCE_NUMBER,to_char(BEGIN_TIME,'MM-DD-YYYY') order by 2 asc;


-------------############Worst and Best PLAN_HASH_VALUE for SQL
 WITH snaps
     AS (SELECT /*+  materialize */
               dbid, SNAP_ID
           FROM dba_hist_snapshot s
          WHERE (begin_interval_time BETWEEN sysdate-&1 AND sysdate))
select * from (
SELECT t.*, row_number () over (order by impact_secs desc ) seq#
FROM (
  SELECT DISTINCT  sql_id
                  , execs executions
                  , FIRST_VALUE (plan_hash_value) OVER (PARTITION BY sql_id ORDER BY pln_avg DESC) worst_plan
                  , ROUND (MAX (pln_avg) OVER (PARTITION BY sql_id), 2) worst_plan_et_secs
                  , FIRST_VALUE (plan_hash_value) OVER (PARTITION BY sql_id ORDER BY pln_avg ASC) best_plan
                  , ROUND (MIN (pln_avg) OVER (PARTITION BY sql_id), 2) best_plan_et_secs
                  , ROUND ( (MAX (pln_avg) OVER (PARTITION BY sql_id) - MIN (pln_avg) OVER (PARTITION BY sql_id)) * execs) impact_secs
                  , ROUND (MAX (pln_avg) OVER (PARTITION BY sql_id) / MIN (pln_avg) OVER (PARTITION BY sql_id), 2) times_faster
    FROM (SELECT PARSING_SCHEMA_NAME
                 , sql_id
                 , plan_hash_value
                 , AVG (elapsed_time_delta / 1000000 / executions_delta) OVER (PARTITION BY sql_id, plan_hash_value) pln_avg
                 , SUM (executions_delta) OVER (PARTITION BY sql_id) execs
            FROM DBA_HIST_SQLSTAT h
           WHERE  sql_id='2dh286fuxpgq0'  and  (dbid, SNAP_ID) IN (SELECT dbid, SNAP_ID FROM snaps) 
                 AND NVL (h.executions_delta, 0) > 0)
) t
)
where seq# < 11
ORDER BY seq#
/

-- Below script will provide the dependent queries getting triggered from a procedure. 

SELECT s.sql_id, s.sql_text
FROM gv$sqlarea s JOIN dba_objects o ON s.program_id = o.object_id
and o.object_name = '&procedure_name';


SELECT sql_id, sql_text, executions, elapsed_time, cpu_time
FROM dba_hist_sqlstat s
JOIN dba_hist_sqltext t ON s.sql_id = t.sql_id
JOIN dba_objects o ON t.object_name = o.object_name
WHERE o.object_type = 'PROCEDURE'
  AND o.object_name = '&procedure_name'
ORDER BY elapsed_time DESC;

--- to know procedure/package with SQL_ID

Select s.inst_id,s.sql_id,s.sql_text,s.EXECUTIONS,s.FIRST_LOAD_TIME,s.PLAN_HASH_VALUE,
s.LAST_ACTIVE_TIME,s.LAST_LOAD_TIME,S.Module,s.PLSQL_EXEC_TIME,s.SQL_PROFILE,o.object_name
FROM gv$sqlarea s JOIN dba_objects o ON s.program_id = o.object_id
--and sql_id='0bujgc94rg3fj'
and o.object_name = 'WF_EVENT';

SELECT s.sql_id, s.sql_text,o.object_name
FROM gv$sqlarea s JOIN dba_objects o ON s.program_id = o.object_id
and sql_id='4x0supytwybg3'
--and o.object_name = 'XXRHM_ACD_CTO_ITEM_ATTR_PKG';



-------Query to find no.of DML's on table

SELECT TABLE_OWNER,TABLE_NAME,INSERTS,UPDATES,DELETES,TIMESTAMP AS LAST_CHANGE
FROM  DBA_TAB_MODIFICATIONS
WHERE --TO_CHAR(TIMESTAMP,'DD.MM.YYYY') = TO_CHAR(sysdate,'DD.MM.YYYY') 
--and table_owner='SCHEMA_NAME'
table_name in ('MTL_SYSTEM_ITEMS_B','PO_LINE_LOCATIONS_ALL','PO_HEADERS_ALL','PER_ALL_PEOPLE_F','FND_LOOKUP_VALUES') order by 2;

-----------Index details:

SELECT idx.table_name, idx.index_name, SUM(bytes)/1024/1024 MB
  FROM dba_segments seg,
       dba_indexes idx
  WHERE 
     idx.table_name in ('MTL_SYSTEM_ITEMS_B','PO_LINE_LOCATIONS_ALL','PO_HEADERS_ALL','PER_ALL_PEOPLE_F','FND_LOOKUP_VALUES')
    AND idx.owner       = seg.owner
    AND idx.index_name  = seg.segment_name
  GROUP BY idx.index_name, idx.table_name order by idx.table_name; 

----include creation data with dba_objects:

    SELECT idx.table_name,
       idx.index_name,
       obj.created,
       SUM(seg.bytes)/1024/1024 AS MB
FROM dba_segments seg
JOIN dba_indexes idx ON idx.owner = seg.owner AND idx.index_name = seg.segment_name
JOIN dba_objects obj ON idx.owner = obj.owner AND idx.index_name = obj.object_name
WHERE idx.table_name IN ('W_SALES_ORDER_LINE_F')
AND obj.object_type = 'INDEX'
GROUP BY idx.index_name, idx.table_name, obj.created
ORDER BY idx.table_name;

  ---include columns


 ----1st one is working one

 SELECT 
    idx.index_name,
    idx.table_owner,
    LISTAGG(DISTINCT idx.table_name, ', ') WITHIN GROUP (ORDER BY idx.table_name) AS table_names,
    LISTAGG(col.column_name, ', ') WITHIN GROUP (ORDER BY col.column_position) AS column_names,
    ROUND((SUM(seg.bytes) / 1024 / 1024 /1024 )/ COUNT(DISTINCT col.column_name), 2) AS gb_size,
    obj.created AS index_created_date
FROM 
    dba_segments seg
JOIN 
    dba_indexes idx ON idx.owner = seg.owner AND idx.index_name = seg.segment_name
JOIN 
    all_ind_columns col ON idx.index_name = col.index_name AND idx.table_name = col.table_name
JOIN 
    dba_objects obj ON idx.owner = obj.owner AND idx.index_name = obj.object_name AND obj.object_type = 'INDEX'
WHERE 
    idx.table_name LIKE '%W_GL_LINKAGE_INFO%'
GROUP BY 
    idx.index_name, idx.table_owner, obj.created
ORDER BY 
    idx.index_name;

---Including table, index Sizes

WITH table_sizes AS (
    SELECT 
        owner, 
        segment_name AS table_name, 
        SUM(bytes) AS table_bytes
    FROM 
        dba_segments
    WHERE 
        segment_type = 'TABLE'
    GROUP BY 
        owner, segment_name
), index_sizes AS (
    SELECT 
        owner, 
        segment_name AS index_name, 
        SUM(bytes) AS index_bytes
    FROM 
        dba_segments
    WHERE 
        segment_type = 'INDEX'
    GROUP BY 
        owner, segment_name
)
SELECT 
    idx.table_name,
    idx.index_name,
    idx.table_owner,    
    LISTAGG(col.column_name, ', ') WITHIN GROUP (ORDER BY col.column_position) AS column_names,
    ROUND(table_sizes.table_bytes / 1024 / 1024 / 1024, 2) AS table_size_gb,
    ROUND(index_sizes.index_bytes / 1024 / 1024 / 1024, 2) AS index_size_gb,
    obj.created AS index_created_date
FROM 
    dba_indexes idx
JOIN 
    all_ind_columns col ON idx.index_name = col.index_name AND idx.table_name = col.table_name
JOIN 
    dba_objects obj ON idx.owner = obj.owner AND idx.index_name = obj.object_name AND obj.object_type = 'INDEX'
LEFT JOIN 
    table_sizes ON idx.table_owner = table_sizes.owner AND idx.table_name = table_sizes.table_name
LEFT JOIN 
    index_sizes ON idx.owner = index_sizes.owner AND idx.index_name = index_sizes.index_name
WHERE 
    idx.table_name in ('ORDER_RELEASE_T','ORDER_RELEASE_STATUS_T')
    --and idx.index_name in ('OR_ORDER_RELEASE_XID','IX_ORS_STSVGID')
GROUP BY 
    idx.index_name, idx.table_owner, idx.table_name, obj.created, table_sizes.table_bytes, index_sizes.index_bytes
ORDER BY 
    idx.index_name;


 ----List out where index size is greater than table_size;   


 WITH table_sizes AS (
    SELECT 
        owner, 
        segment_name AS table_name, 
        SUM(bytes) AS table_bytes
    FROM 
        dba_segments
    WHERE 
        segment_type = 'TABLE'
    GROUP BY 
        owner, segment_name
), index_sizes AS (
    SELECT 
        owner, 
        segment_name AS index_name, 
        SUM(bytes) AS index_bytes
    FROM 
        dba_segments
    WHERE 
        segment_type = 'INDEX'
    GROUP BY 
        owner, segment_name
)
SELECT 
    idx.index_name,
    idx.table_owner,
    idx.table_name,
    LISTAGG(col.column_name, ', ') WITHIN GROUP (ORDER BY col.column_position) AS column_names,
    ROUND(table_sizes.table_bytes / 1024 / 1024 / 1024, 2) AS table_size_gb,
    ROUND(index_sizes.index_bytes / 1024 / 1024 / 1024, 2) AS index_size_gb,
    obj.created AS index_created_date
FROM 
    dba_indexes idx
JOIN 
    all_ind_columns col ON idx.index_name = col.index_name AND idx.table_name = col.table_name
JOIN 
    dba_objects obj ON idx.owner = obj.owner AND idx.index_name = obj.object_name AND obj.object_type = 'INDEX'
LEFT JOIN 
    table_sizes ON idx.table_owner = table_sizes.owner AND idx.table_name = table_sizes.table_name
LEFT JOIN 
    index_sizes ON idx.owner = index_sizes.owner AND idx.index_name = index_sizes.index_name
WHERE 
    idx.table_name LIKE 'ORDER_RELEASE_STATUS_T%'
GROUP BY 
    idx.index_name, idx.table_owner, idx.table_name, obj.created, table_sizes.table_bytes, index_sizes.index_bytes
HAVING 
    SUM(index_sizes.index_bytes) > SUM(table_sizes.table_bytes)
ORDER BY 
    idx.index_name;



SELECT
    idx.index_name,
    idx.table_owner,
    LISTAGG(DISTINCT idx.table_name, ', ') WITHIN GROUP (ORDER BY idx.table_name) AS table_names,
    LISTAGG(col.column_name, ', ') WITHIN GROUP (ORDER BY col.column_position) AS column_names,
    ROUND(SUM(seg.bytes) / 1024 / 1024, 2) AS mb_size
FROM
    dba_segments seg
JOIN
    dba_indexes idx ON idx.owner = seg.owner AND idx.index_name = seg.segment_name
JOIN
    all_ind_columns col ON idx.index_name = col.index_name AND idx.table_name = col.table_name
WHERE
    idx.table_name IN ('MTL_SYSTEM_ITEMS_B', 'PO_LINE_LOCATIONS_ALL', 'PO_HEADERS_ALL', 'PER_ALL_PEOPLE_F', 'FND_LOOKUP_VALUES')
GROUP BY
    idx.index_name, idx.table_owner
ORDER BY
    idx.index_name;



By default index monitoring is enabled starting from 12CR2:
----------------------------------------------------------

SELECT
    OBJECT_NAME,
    OBJECT_TYPE,
    TABLESPACE_NAME,
    SUM(CASE WHEN STATISTIC_NAME = 'logical reads' THEN VALUE ELSE 0 END) AS logical_reads,
    SUM(CASE WHEN STATISTIC_NAME = 'physical reads' THEN VALUE ELSE 0 END) AS physical_reads,
    SUM(CASE WHEN STATISTIC_NAME = 'db block changes' THEN VALUE ELSE 0 END) AS block_changes
FROM
    V$SEGMENT_STATISTICS
WHERE
    OBJECT_TYPE = 'INDEX'
    and object_name in ('OR_ORDER_RELEASE_XID','IX_ORS_STSVGID')
GROUP BY
    OBJECT_NAME, OBJECT_TYPE, TABLESPACE_NAME
ORDER BY
    logical_reads DESC;

 select object_id from dba_objects where object_name='OR_ORDER_RELEASE_XID'

 select * from dba_index_usage where name in ('OR_ORDER_RELEASE_XID','IX_ORS_STSVGID');


 ---history:

  

SELECT
    sn.INSTANCE_NUMBER,
    obj.OBJECT_NAME,
    obj.OBJECT_TYPE,
    obj.TABLESPACE_NAME,
    sn.BEGIN_INTERVAL_TIME,
    sn.END_INTERVAL_TIME,
    SUM(ss.PHYSICAL_READS_TOTAL) AS physical_reads,
    SUM(ss.PHYSICAL_READS_DELTA) AS Physical_Reads_Delta,
    --ss.PHYSICAL_READS_DELTA as PRD,
    SUM(ss.PHYSICAL_WRITES_TOTAL) AS physical_writes,    
    SUM(ss.LOGICAL_READS_TOTAL) AS logical_reads,
    SUM(ss.POPULATE_CUS_TOTAL) AS executions -- or another metric if 'executions' is not applicable
FROM
    DBA_HIST_SEG_STAT ss
JOIN
    DBA_HIST_SEG_STAT_OBJ obj ON ss.OBJ# = obj.OBJ#
JOIN
    DBA_HIST_SNAPSHOT sn ON ss.SNAP_ID = sn.SNAP_ID
WHERE
    obj.OBJECT_TYPE = 'INDEX'
    AND obj.object_name in ('OR_ORDER_RELEASE_XID','IX_ORS_STSVGID')
    --AND sn.BEGIN_INTERVAL_TIME >= SYSDATE-1
    AND sn.BEGIN_INTERVAL_TIME BETWEEN TO_DATE('2024-07-30 00:00:00', 'YYYY-MM-DD HH24:MI:SS') AND TO_DATE('2024-07-31 00:00:00', 'YYYY-MM-DD HH24:MI:SS')
GROUP BY
    obj.OBJECT_NAME, obj.OBJECT_TYPE, obj.TABLESPACE_NAME, sn.BEGIN_INTERVAL_TIME, sn.END_INTERVAL_TIME, ss.PHYSICAL_READS_DELTA,sn.INSTANCE_NUMBER
ORDER BY
    sn.BEGIN_INTERVAL_TIME DESC, obj.OBJECT_NAME;



select * from dba_hist_seg_stat;


Index monitoring:

--Enable Index monitoring:

ALTER INDEX index_name MONITORING USAGE;

--To check if an index is being used

SELECT * FROM V$OBJECT_USAGE WHERE OBJECT_NAME = 'index_name';

--Disable Index monitoring:

ALTER INDEX index_name NOMONITORING USAGE;

-- To see all indexes currently being monitored:

select * from dba_object_usage;
    
SELECT 
    INDEX_NAME,
    TABLE_NAME,
    MONITORING,
    USED,
    START_MONITORING,
    END_MONITORING
FROM 
    V$OBJECT_USAGE
WHERE 
    MONITORING = 'YES';


----------Memory Parameters checking:


set pages 10000 lines 200
col name for a40
col value for a40
select NAME,VALUE,ISSYS_MODIFIABLE  , ISSES_MODIFIABLE from v$parameter where NAME in ('sga_max_size','sga_min_size','sga_target','db_cache_size','shared_pool_size','large_pool_size','java_pool_size','streams_pool_size','data_transfer_cache_size','pga_aggregate_target','db_16k_cache_size');

select component, current_size/1024/1024 "CURRENT_SIZE",
	min_size/1024/1024 "MIN_SIZE",
	user_specified_size/1024/1024 "USER_SPECIFIED_SIZE"
from v$sga_dynamic_components;

-------SQL OFFLOAD Efficiency
select sql_id,
round(io_cell_offload_eligible_bytes/(1024*1024*1024),2) cell_offload_eligible_GB,
round(io_cell_uncompressed_bytes/(1024*1024*1024),2) io_uncompressed_GB,
round(io_interconnect_bytes/(1024*1024*1924),2) io_interconnect_GB,
round((physical_read_bytes + physical_write_bytes)/(1024*1024*1024),2) io_disk_GB,
round(io_cell_offload_returned_bytes/(1024*1024*1024),2) cell_return_bytes_GB,
round(100*((IO_CELL_OFFLOAD_ELIGIBLE_BYTES-IO_INTERCONNECT_BYTES)/IO_CELL_OFFLOAD_ELIGIBLE_BYTES),2) "IO_Saved_%"
from v$sql
where sql_id = '85wnyj5xypcuu' and io_cell_offload_eligible_bytes > 0
--and sql_text not like '%io_cell_offload_eligible_bytes%';


Advanced compression:
=========================================
SELECT owner,table_name, compression, compress_for
FROM all_tables
WHERE compression = 'ENABLED';

Re-org tables required list:
==================================
SELECT table_name, 
       num_rows,
       blocks,
       empty_blocks,
       chain_cnt,
       avg_space,
       avg_row_len
FROM all_tables
WHERE chain_cnt > 0 OR empty_blocks > 0
ORDER BY table_name;

------To locate highly fragmented tables

SELECT 
    table_name,
    tablespace_name,
    ROUND(((blocks * 8) / 1024 / 1024), 2) AS "size (gb)", 
    ROUND(((num_rows * avg_row_len / 1024) / 1024 / 1024), 2) AS "actual_data (gb)",
    round((((blocks*8)) - ((num_rows*avg_row_len/1024)))/1024/1024,2) "wasted_space (gb)",
    -- ROUND(((((blocks * 8) - (num_rows * avg_row_len / 1024)) / (blocks * 8)) * 100 - 10), 2) AS "reclaimable space %",
    ROUND((ROUND(((blocks * 16 / 1024) - (num_rows * avg_row_len / 1024 / 1024)), 2) / ROUND(((blocks * 16 / 1024)), 2)) * 100, 2) AS "reclaimable space",
    partitioned
FROM 
    dba_tables
WHERE 
    ROUND((blocks * 8), 2) > ROUND((num_rows * avg_row_len / 1024), 2)
    AND table_name IN ('XXRHMEDI_INBOUND_STG', 'XXRHMEDI_INBOUND_ERRORS_TAB')
ORDER BY  5 DESC;


select owner,table_name,blocks,num_rows,avg_row_len,round(((blocks*8/1024/1024)),2) "TOTAL_SIZE( GB)", round((num_rows*avg_row_len
 /1024/1024/1024),2) "ACTUAL_SIZE(GB)", round(((blocks*8/1024/1024)-(num_rows*avg_row_len/1024/1024/1024)),2)  "FRAGMENTED_SPACE(GB)" from
 dba_tables where owner='XXRHM' and table_name='XXRHMEDI_INBOUND_STG' and round(((blocks*8/1024)-(num_rows*avg_row_len/1024/1024)),2) > 1 order by 8 desc;


select OWNER,INDEX_NAME,TABLE_OWNER,TABLE_NAME,TABLESPACE_NAME,STATUS from dba_indexes where table_name in ('XXRHMEDI_INBOUND_STG','XXRHMEDI_INBOUND_ERRORS_TAB');

-----------------
SELECT *
FROM (
    SELECT
        table_name,
        ROUND(((blocks * 8) / 1024 / 1024), 2) AS "size (GB)",
        ROUND(((num_rows * avg_row_len / 1024) / 1024 / 1024), 2) AS "actual_data (GB)",
        ROUND((((blocks * 8)) - ((num_rows * avg_row_len / 1024))) / 1024 / 1024, 2) AS "wasted_space (GB)",
        ROUND(((((blocks * 8) - (num_rows * avg_row_len / 1024)) / (blocks * 8)) * 100), 2) AS "reclaimable_space %",
        partitioned
    FROM
    FROM
        dba_tables
    WHERE
        ROUND((blocks * 8), 2) > ROUND((num_rows * avg_row_len / 1024), 2)
    ORDER BY
        4 DESC
)
WHERE ROWNUM <= 30;


-----Notes:

Demantra Table Reorganization, Fragmentation, Null Columns, Primary Key, Editioning, Cluster Factor, PCT Fee, Freelist, Initrans, Automatic Segment Management (ASM), Blocksize…. (Doc ID 1990353.1)
SEGMENT SHRINK and Details. (Doc ID 242090.1)
How to Deallocate Unused Space from a Table, Index or Cluster. (Doc ID 115586.1)
How to Determine Real Space used by a Table (Below the High Water Mark) (Doc ID 77635.1)
Reclaiming Unused Space in an E-Business Suite Instance Tablespace (Doc ID 303709.1)
How to Re-Organize a Table Online (Doc ID 177407.1)
Reorg Failiure : Demantra Reorg Failing On SALES_DATA (Doc ID 2209718.1)
Script to Report Tablespace Free and Fragmentation (Doc ID 1019709.6)


-----Index required rebuild

select a.*, round(index_leaf_estimate_if_rebuilt/current_leaf_blocks*100) percent, case when index_leaf_estimate_if_rebuilt/current_leaf_blocks < 0.5 then 'candidate for rebuild' end status
from
(
select table_name, index_name, current_leaf_blocks, round (100 / 90 * (ind_num_rows * (rowid_length + uniq_ind + 4) + sum((avg_col_len) * (tab_num_rows) ) ) / (8192 - 192) ) as index_leaf_estimate_if_rebuilt
from (
select tab.table_name, tab.num_rows tab_num_rows , decode(tab.partitioned,'YES',10,6) rowid_length , ind.index_name, ind.index_type, ind.num_rows ind_num_rows, ind.leaf_blocks as current_leaf_blocks,
decode(uniqueness,'UNIQUE',0,1) uniq_ind,ic.column_name as ind_column_name, tc.column_name , tc.avg_col_len
from dba_tables tab
join dba_indexes ind on ind.owner=tab.owner and ind.table_name=tab.table_name
join dba_ind_columns ic on ic.table_owner=tab.owner and ic.table_name=tab.table_name and ic.index_owner=tab.owner and ic.index_name=ind.index_name
join dba_tab_columns tc on tc.owner=tab.owner and tc.table_name=tab.table_name and tc.column_name=ic.column_name
where tab.owner='&OWNER' and ind.leaf_blocks is not null and ind.leaf_blocks > 1000
) group by table_name, index_name, current_leaf_blocks, ind_num_rows, uniq_ind, rowid_length
) a where index_leaf_estimate_if_rebuilt/current_leaf_blocks < 0.5
order by index_leaf_estimate_if_rebuilt/current_leaf_blocks;



select owner,table_name,round((blocks*8),2)||' kb' "TABLE SIZE",round((num_rows*avg_row_len/1024),2)||' kb' "ACTUAL DATA" from dba_tables where table_name='&Table_name';


------Tablespace 



SQL> SELECT SUM(bytes/1024) "KB Free" FROM dba_free_space WHERE tablespace_name = 'SOAQA_SOAINFRA';

   KB Free
----------
  16400000

--------------------Tablespace Utilization

select  
               a.tablespace_name as tablespace_name,
               'SQLDEV:GAUGE:0:100:0:0:'||(100 - round((nvl(b.bytes_free, 0) / a.bytes_alloc) * 100)) percent_used,
               (100 - round((nvl(b.bytes_free, 0) / a.bytes_alloc) * 100, 2)) pct_used,
               round(a.bytes_alloc / 1024 / 1024,2) allocated,
               round((a.bytes_alloc - nvl(b.bytes_free, 0)) / 1024 / 1024,2) used,
               round(nvl(b.bytes_free, 0) / 1024 / 1024,2) free,
               a.datafiles
        from  ( select  f.tablespace_name,
                       sum(f.bytes) bytes_alloc,
                       sum(decode(f.autoextensible, 'YES',f.maxbytes,'NO', f.bytes)) maxbytes,
                       count(1) datafiles
                from dba_data_files f
                group by tablespace_name) a,
              ( select  f.tablespace_name,
                       sum(f.bytes)  bytes_free
                from dba_free_space f
                group by tablespace_name) b
        where a.tablespace_name = b.tablespace_name (+)
        union all
        select
            t.tablespace_name,
            t.percent_used,
            t.pct_used,
            t.allocated,
            t.used,
            t.free,
            f.datafiles
        from
            (    
                select 
                       h.tablespace_name as tablespace_name,
                       'SQLDEV:GAUGE:0:100:0:0:'||(100 - round((sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) / sum(h.bytes_used + h.bytes_free)) * 100)) percent_used,
                       (100 - round((sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) / sum(h.bytes_used + h.bytes_free)) * 100,2)) pct_used,
                       round(sum(h.bytes_free + h.bytes_used) / 1048576,2) allocated,
                       round(sum(nvl(p.bytes_used, 0))/ 1048576,2) used,
                       round(sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) / 1048576,2) free
                from   sys.gv_$TEMP_SPACE_HEADER h, 
                       sys.gv_$Temp_extent_pool p, 
                       dba_temp_files f
                where  p.file_id(+) = h.file_id
                and    p.tablespace_name(+) = h.tablespace_name
                and    f.file_id = h.file_id
                and    f.tablespace_name = h.tablespace_name
                group by h.tablespace_name
            ) t,
            (
                select tablespace_name, count(1) datafiles from dba_temp_files group by tablespace_name
            ) f
        where t.tablespace_name = f.tablespace_name    
        ORDER BY 3 desc;


Temp tablespace Size:
======================

SELECT a.tablespace_name,ROUND((c.total_blocks*b.block_size)/1024/1024/1024,2)
"Total Size [GB]",ROUND((a.used_blocks*b.block_size)/1024/1024/1024,2) "Used_size[GB]",
ROUND(((c.total_blocks-a.used_blocks)*b.block_size)/1024/1024/1024,2) "Free_size[GB]",
ROUND((a.max_blocks*b.block_size)/1024/1024/1024,2) "Max_Size_Ever_Used[GB]", 
ROUND((a.max_used_blocks*b.block_size)/1024/1024/1024,2) "MaxSize_ever_Used_by_Sorts[GB]" ,
ROUND((a.used_blocks/c.total_blocks)*100,2) "Used Percentage"
FROM V$sort_segment a,dba_tablespaces b,(SELECT tablespace_name,SUM(blocks)
total_blocks FROM dba_temp_files GROUP by tablespace_name) c
WHERE a.tablespace_name=b.tablespace_name AND a.tablespace_name=c.tablespace_name;




Freespace of a tablespace
~~~~~~~~~~~~~~~~~~~~~~~~~

select a.tbl "Name",a.tsz "Total Size",b.fsz "Free Space",
round((1-(b.fsz/a.tsz))*100) "Pct Used",round((b.fsz/a.tsz)*100) "Pct Free" from 
       (select tablespace_name tbl,sum(bytes)/1024/1024/1024 TSZ from dba_data_files
       where tablespace_name like '&a' group by tablespace_name ) a,
       (select tablespace_name tblsp,sum(bytes)/1024/1024/1024 FSZ from dba_free_space
       where tablespace_name like '&a' group by tablespace_name) b
Where a.tbl=b.tblsp;

SOAQA_SOAINFRA

Name                           Total Size Free Space   Pct Used   Pct Free
------------------------------ ---------- ---------- ---------- ----------
SOAQA_SOAINFRA                      32730  16015.625         51         49



col "Table name" for a20
select TABLESPACE_NAME "Table name",
round((TABLESPACE_SIZE*8192)/1024/1024/1024) "Total size(GB)",
round((USED_SPACE*8192)/1024/1024/1024) "Used space(GB)",
round(USED_PERCENT) "Pctused",round(100-USED_PERCENT) "Pct free" 
from dba_tablespace_usage_metrics where tablespace_name='&n';


Uage PCT:
===============
SELECT d.tablespace_name,
round(((a.bytes - NVL(f.bytes,0))*100/a.maxbytes),2) used_pct
FROM   sys.dba_tablespaces d,
(select tablespace_name, sum(bytes) bytes, sum(greatest(maxbytes,bytes)) maxbytes
from sys.dba_data_files group by tablespace_name) a,
(select tablespace_name, sum(bytes) bytes
from sys.dba_free_space group by tablespace_name) f
WHERE d.tablespace_name = a.tablespace_name(+)
AND d.tablespace_name = f.tablespace_name(+)
AND NOT (d.extent_management = 'LOCAL' AND d.contents = 'TEMPORARY')
and d.tablespace_name='&n';


SELECT d.tablespace_name,
round(((a.bytes - NVL(f.bytes,0))*100/a.maxbytes),2) used_pct
FROM   sys.dba_tablespaces d,
(select tablespace_name, sum(bytes) bytes, sum(greatest(maxbytes,bytes)) maxbytes
from sys.dba_data_files group by tablespace_name) a,
(select tablespace_name, sum(bytes) bytes
from sys.dba_free_space group by tablespace_name) f
WHERE d.tablespace_name = a.tablespace_name(+)
AND d.tablespace_name = f.tablespace_name(+)
AND NOT (d.extent_management = 'LOCAL' AND d.contents = 'TEMPORARY')
and d.tablespace_name='&n';

Free space of datafiles
~~~~~~~~~~~~~~~~~~~~~~~

col tablespace_name for a18
col file_name for 100
select tablespace_name,file_name,bytes/1024/1024/1024,AUTOEXTENSIBLE,MAXBYTES/1024/1024/1024 from dba_data_files
where tablespace_name like '&a' order by file_name ;



TABLESPACE_NAME    FILE_NAME                                     BYTES/1024/1024
------------------ --------------------------------------------- ---------------
SOAQA_SOAINFRA     +ERPAFMQ1_DATA/erpafmq1/datafile/soaqa_soainf           12250
                   ra.274.795488905

SOAQA_SOAINFRA     +ERPAFMQ1_DATA/erpafmq1/datafile/soaqa_soainf           10240
                   ra.295.815546793

SOAQA_SOAINFRA     +ERPAFMQ1_DATA/erpafmq1/datafile/soaqa_soainf           10240
                   ra.296.815546837

==============================

Tablespace usage:

===========================================================================================================================
Column definitions

TABLESPACE_NAME: This is the Tablespace Name.

AUTO_EXT: If the datafiles are ‘Auto Extendable’ or not.

Please Note: This is using a max function, so if all are ‘NO’, then the ‘NO’ is true for all datafiles, however if one is ‘YES’, then the ‘YES’ is possible for one through to all of the datafiles.

MAX_TS_SIZE: This is the maximum Tablespace Size if all the datafile reach their max size.

MAX_TS_PCT_USED: This is the percent of MAX_TS_SIZE reached and is the most important value in the query, as this reflects the true usage before DBA intervention is required.

CURR_TS_SIZE: This is the current size of the Tablespace.

USED_TS_SIZE: This is how much of the CURR_TS_SIZE is used.

TS_PCT_USED: This is the percent of CURR_TS_SIZE which if ‘Auto Extendable’ is on, is a little meaningless.  Use MAX_TS_PCT_USED for actual usage.

FREE_TS_SIZE: This is how much is free in CURR_TS_SIZE.

TS_PCT_FREE: This is how much is free in CURR_TS_SIZE as a percent.

==============================================================================================================================



set pages 999
set lines 400
SELECT df.tablespace_name tablespace_name,
 max(df.autoextensible) auto_ext,
 round(df.maxbytes / (1024 * 1024 * 1024), 2) max_ts_size,
 round((df.bytes - sum(fs.bytes)) / (df.maxbytes) * 100, 2) max_ts_pct_used,
 round(df.bytes / (1024 * 1024 * 1024), 2) curr_ts_size,
 round((df.bytes - sum(fs.bytes)) / (1024 * 1024 * 1024), 2) used_ts_size,
 round((df.bytes-sum(fs.bytes)) * 100 / df.bytes, 2) ts_pct_used,
 round(sum(fs.bytes) / (1024 * 1024 * 1024), 2) free_ts_size,
 nvl(round(sum(fs.bytes) * 100 / df.bytes), 2) ts_pct_free
FROM dba_free_space fs,
 (select tablespace_name,
 sum(bytes) bytes,
 sum(decode(maxbytes, 0, bytes, maxbytes)) maxbytes,
 max(autoextensible) autoextensible
 from dba_data_files
 group by tablespace_name) df
WHERE fs.tablespace_name (+) = df.tablespace_name 
GROUP BY df.tablespace_name, df.bytes, df.maxbytes
UNION ALL
SELECT df.tablespace_name tablespace_name,
 max(df.autoextensible) auto_ext,
 round(df.maxbytes / (1024 * 1024 * 1024), 2) max_ts_size,
 round((df.bytes - sum(fs.bytes)) / (df.maxbytes) * 100, 2) max_ts_pct_used,
 round(df.bytes / (1024 * 1024 * 1024), 2) curr_ts_size,
 round((df.bytes - sum(fs.bytes)) / (1024 * 1024 * 1024), 2) used_ts_size,
 round((df.bytes-sum(fs.bytes)) * 100 / df.bytes, 2) ts_pct_used,
 round(sum(fs.bytes) / (1024 * 1024 * 1024), 2) free_ts_size,
 nvl(round(sum(fs.bytes) * 100 / df.bytes), 2) ts_pct_free
FROM (select tablespace_name, bytes_used bytes
 from V$temp_space_header
 group by tablespace_name, bytes_free, bytes_used) fs,
 (select tablespace_name,
 sum(bytes) bytes,
 sum(decode(maxbytes, 0, bytes, maxbytes)) maxbytes,
 max(autoextensible) autoextensible
 from dba_temp_files
 group by tablespace_name) df
WHERE fs.tablespace_name (+) = df.tablespace_name 
GROUP BY df.tablespace_name, df.bytes, df.maxbytes
ORDER BY 5 DESC;

-----Best Query for tablespace utilization 
SELECT 
    t.name AS tablespace_name,
    COUNT(df.file_id) AS datafile_count,
    ROUND(SUM(df.bytes)/1024/1024/1024, 2) AS total_size_gb,
    ROUND(SUM(df.bytes - NVL(fs.free_bytes, 0))/1024/1024/1024, 2) AS used_size_gb,
    ROUND(SUM(NVL(fs.free_bytes, 0))/1024/1024/1024, 2) AS free_size_gb,
    ROUND((SUM(df.bytes - NVL(fs.free_bytes, 0)) / SUM(df.bytes)) * 100, 2) AS used_pct,
    ROUND((SUM(NVL(fs.free_bytes, 0)) / SUM(df.bytes)) * 100, 2) AS free_pct,
    dt.encrypted AS is_encrypted,
    et.ENCRYPTIONALG,
    et.STATUS
FROM 
    dba_tablespaces dt
JOIN 
    dba_data_files df ON dt.tablespace_name = df.tablespace_name
LEFT JOIN 
    (SELECT tablespace_name, file_id, SUM(bytes) AS free_bytes 
     FROM dba_free_space 
     GROUP BY tablespace_name, file_id) fs 
     ON df.file_id = fs.file_id AND df.tablespace_name = fs.tablespace_name
LEFT JOIN 
    v$tablespace t ON dt.tablespace_name = t.name
LEFT JOIN 
    v$encrypted_tablespaces et ON t.ts# = et.ts#
GROUP BY 
    t.name, dt.encrypted, et.ENCRYPTIONALG, et.STATUS
ORDER BY 
    total_size_gb DESC;

------CPU Usage by Session

set lines 1000
col OSPID for a06
col SID for 99999
col SERIAL# for 999999
col SQL_ID for a14
col USERNAME for a15
col PROGRAM for a20
col MODULE for a18
col OSUSER for a10
col MACHINE for a25
select * from (
select ss.inst_id,p.spid "ospid",
(se.SID),ss.serial#,ss.SQL_ID,ss.username,ss.program,ss.module,ss.osuser,ss.MACHINE,ss.status,
se.VALUE/100 cpu_usage_seconds
from
gv$session ss,
gv$sesstat se,
gv$statname sn,
gv$process p
where
se.STATISTIC# = sn.STATISTIC#
and
NAME like '%CPU used by this session%'
and
se.SID = ss.SID
and ss.username !='SYS' and
ss.status='ACTIVE'
and ss.username is not null
and ss.paddr=p.addr and value > 0
order by se.VALUE desc)
where rownum <16;


select rownum as rank, a.*
from (
SELECT v.inst_id,v.sid, program, sess.USERNAME,sess.sql_id,sess.module,sess.action,sess.osuser,sess.machine,v.value / (100 * 60) CPUMins
FROM gv$statname s , gv$sesstat v, gv$session sess
WHERE s.name = 'CPU used by this session'
and sess.sid = v.sid
and v.statistic#=s.statistic#
and v.value>0
ORDER BY v.value DESC) a
where rownum < 11;


---- ASH Report

SELECT   h.sample_time,h.inst_id,h.session_id,h.session_serial#,du.username,h.machine,h.program,h.module,h.CLIENT_ID,h.action,
           h.top_level_sql_id,h.sql_id,h.sql_exec_id,h.SQL_OPNAME,h.SQL_PLAN_HASH_VALUE,h.SQL_PLAN_LINE_ID,h.SQL_PLAN_OPERATION,h.SQL_PLAN_OPTIONS,
           h.SQL_EXEC_START,h.PLSQL_OBJECT_ID,PLSQL_ENTRY_OBJECT_ID,
           h.seq#,h.event,h.session_state,h.wait_class,h.time_waited,h.WAIT_TIME,h.p1text,h.p1,h.p2text,h.p2, h.p3text,h.p3,
           ss.name,h.current_obj#,do.object_name,do.subobject_name,h.current_file#,h.current_block#,
           h.REMOTE_INSTANCE#,
           h.xid,
           h.blocking_session_status,
           h.blocking_session,
           h.blocking_session_serial#,
           h.BLOCKING_INST_ID,
           h.pga_allocated,
           h.temp_space_allocated,
           h.tm_Delta_time ,DELTA_READ_IO_REQUESTS,  DELTA_WRITE_IO_REQUESTS  ,  DELTA_READ_IO_BYTES/1024/1024  ,
        DELTA_WRITE_IO_BYTES/1024/1024 ,  DELTA_INTERCONNECT_IO_BYTES
FROM   gv$active_session_history h,
           gv$services ss,
           dba_objects do,
           dba_users du
   WHERE   h.sample_time BETWEEN TO_DATE ('06/12/2024 09:30:00',
                                          'MM/DD/YYYY HH24:MI:SS')
                             AND  TO_DATE ('06/12/2024 10:15:00',
                                           'MM/DD/YYYY HH24:MI:SS')
           AND h.service_hash = ss.name_hash
           AND h.current_obj# = do.object_id(+)
           AND h.user_id = du.user_id(+)
           AND h.inst_id = ss.inst_id
        --  AND h.session_id = 1869
           --2074
         -- AND h.inst_id = 1
         --- and h.session_state <>'ON CPU'
--and h.top_level_sql_id in ('0bujgc94rg3fj','5h2dawbza3baz','d2annnz4tkqrp','48p74hks21g58','f5rar341ntbnq')
--and h.top_level_sql_id = '8a7krab9dxrzc'
--and module like '%e:AR:cp:bks_ar/BKS_AR_BKSARODS_PRINT_FILE%' 
--and sql_id =  'b5p3saq9c0t22'
--and h.CLIENT_ID = 'TRICIA.MERRICK'
--AND ACTION = 'ONT/RHM_OM_ORDENTRUSH_WHD'
order by h.sample_time desc;


ASH from Ddba_hist_active_sess_history:


SELECT 
    h.sample_time,
    h.instance_number AS inst_id,  
    h.session_id,
    h.session_serial#,
    du.username,
    h.machine,
    h.program,
    h.module,
    h.client_id,
    h.action,
    h.top_level_sql_id,
    h.sql_id,
    h.sql_exec_id,
    h.sql_opname,
    h.sql_plan_hash_value,
    h.sql_plan_line_id,
    h.sql_plan_operation,
    h.sql_plan_options,
    h.sql_exec_start,
    h.plsql_object_id,
    h.plsql_entry_object_id,
    h.seq#,
    h.event,
    h.session_state,
    h.wait_class,
    h.time_waited,
    h.wait_time,
    h.p1text,
    h.p1,
    h.p2text,
    h.p2,
    h.p3text,
    h.p3,
    ss.name,  -- Correct column name from dba_services
    h.current_obj#,
    do.object_name,
    do.subobject_name,
    h.current_file#,
    h.current_block#,
    h.remote_instance#,
    h.xid,
    h.blocking_session_status,
    h.blocking_session,
    h.blocking_session_serial#,
    h.blocking_inst_id,
    h.pga_allocated,
    h.temp_space_allocated,
    h.tm_delta_time,
    h.delta_read_io_requests,
    h.delta_write_io_requests,
    h.delta_read_io_bytes / 1024 / 1024 AS delta_read_io_mb,
    h.delta_write_io_bytes / 1024 / 1024 AS delta_write_io_mb,
    h.delta_interconnect_io_bytes
FROM 
    dba_hist_active_sess_history h
LEFT JOIN 
    dba_services ss ON h.service_hash = ss.name_hash  -- Using name_hash for join condition
LEFT JOIN 
    dba_objects do ON h.current_obj# = do.object_id
LEFT JOIN 
    dba_users du ON h.user_id = du.user_id
WHERE 
    h.sample_time BETWEEN TO_DATE('06/12/2024 09:30:00', 'MM/DD/YYYY HH24:MI:SS') AND TO_DATE('06/12/2024 10:15:00', 'MM/DD/YYYY HH24:MI:SS')
    AND h.sql_id = 'b5p3saq9c0t22'
ORDER BY 
    h.sample_time DESC;

 session per service_name:
------------------------------------------------------------------------------------------------
 SELECT service_name, COUNT(*) AS session_count
FROM gv$session
GROUP BY service_name
ORDER BY session_count DESC;

SELECT inst_id, sid, serial#, username, osuser, machine,CLIENT_IDENTIFIER,CLIENT_INFO 
       program, module, status, prev_exec_start, logon_time
FROM gv$session
WHERE service_name = 'EBSPROD_MAIN'
ORDER BY inst_id, sid;   


SELECT service_name,
       COUNT(*)                                                    AS total,
       SUM(CASE WHEN status     = 'ACTIVE'   THEN 1 ELSE 0 END)  AS active,
       SUM(CASE WHEN status     = 'INACTIVE' THEN 1 ELSE 0 END)  AS inactive,
       SUM(CASE WHEN wait_class != 'Idle'    THEN 1 ELSE 0 END)  AS waiting,
       SUM(CASE WHEN blocking_session IS NOT NULL THEN 1 ELSE 0 END) AS blocked,
       ROUND(AVG(last_call_et) / 60, 2)                          AS avg_idle_mins
FROM gv$session
where SERVICE_NAME not like '%BACKGROUND%'
--WHERE type = 'USER'
GROUP BY service_name
ORDER BY total DESC;

DB Size:
--------------------------------
 SELECT 'Database size before drop ' AS DBSIZE FROM DUAL;
break on report
compute sum of "size GB" on report
select 'Data files size         ', sum(bytes/1024/1024/1024) "size GB" from V$datafile
union
select 'Temp files size         ', sum(bytes/1024/1024/1024) "size GB" from V$tempfile
union
select 'Log files size          ', sum(bytes/1024/1024/1024) "size GB" from V$log;



Including all PDBs: (Run from CDB)

SET LINES 200
SET PAGES 200

COLUMN pdb_name FORMAT A30
COLUMN total_size_gb FORMAT 999,999,999.99

BREAK ON REPORT
COMPUTE SUM OF total_size_gb ON REPORT
SELECT pdb_name,
       ROUND(SUM(size_gb), 2) AS total_size_gb
FROM
(
    -- Datafiles
    SELECT c.name AS pdb_name,
           SUM(df.bytes)/1024/1024/1024 AS size_gb
    FROM   v$datafile df
    JOIN   v$containers c
           ON df.con_id = c.con_id
    GROUP BY c.name
    UNION ALL
    -- Tempfiles
    SELECT c.name AS pdb_name,
           SUM(tf.bytes)/1024/1024/1024 AS size_gb
    FROM   v$tempfile tf
    JOIN   v$containers c
           ON tf.con_id = c.con_id
    GROUP BY c.name
    UNION ALL
    -- Redo logs
    SELECT c.name AS pdb_name,
           SUM(l.bytes)/1024/1024/1024 AS size_gb
    FROM   v$log l
    CROSS JOIN v$containers c
    WHERE  c.con_id = 1
    GROUP BY c.name
)
GROUP BY pdb_name
ORDER BY total_size_gb DESC;

---- Total , FREE and USED

col "Database Size" format a20
col "Free space" format a20
col "Used space" format a20
select round(sum(used.bytes) / 1024 / 1024 / 1024 ) || ' GB' "Database Size"
, round(sum(used.bytes) / 1024 / 1024 / 1024 ) -
round(free.p / 1024 / 1024 / 1024) || ' GB' "Used space"
, round(free.p / 1024 / 1024 / 1024) || ' GB' "Free space"
from (select bytes
from v$datafile
union all
select bytes
from v$tempfile
union all
select bytes
from v$log) used
, (select sum(bytes) as p
from dba_free_space) free
group by free.p
/

----

break on report 
compute sum of "size GB" on report 
select 'Data files size  	', sum(bytes/1024/1024/1024) "size GB" from V$datafile
union 
select 'Temp files size  	', sum(bytes/1024/1024/1024) "size GB" from V$tempfile
union
select 'Log files size  	', sum(bytes/1024/1024/1024) "size GB" from V$log;

=======DB Free SPACE

SELECT TABLESPACE_NAME,SUM(BYTES/1024/1024/1024)GB FROM DBA_FREE_SPACE GROUP BY TABLESPACE_NAME ORDER BY 2 DESC;
   
 -----ASM Size


SET LINESIZE  145
SET PAGESIZE  9999
SET VERIFY    off
COLUMN group_name             FORMAT a20           HEAD 'Disk Group|Name'
COLUMN sector_size            FORMAT 99,999        HEAD 'Sector|Size'
COLUMN block_size             FORMAT 99,999        HEAD 'Block|Size'
COLUMN allocation_unit_size   FORMAT 999,999,999   HEAD 'Allocation|Unit Size'
COLUMN state                  FORMAT a11           HEAD 'State'
COLUMN type                   FORMAT a6            HEAD 'Type'
COLUMN total_mb               FORMAT 999,999,999   HEAD 'Total Size (GB)'
COLUMN used_mb                FORMAT 999,999,999   HEAD 'Used Size (GB)'
COLUMN pct_used               FORMAT 999.99        HEAD 'Pct. Used'

break on report on disk_group_name skip 1
compute sum label "Grand Total: " of total_mb used_mb on report

SELECT
    name                                     group_name
  , sector_size                              sector_size
  --, block_size                               block_size
  --, allocation_unit_size                     allocation_unit_size
  , state                                    state
  , type                                     type
  , round(total_mb/1024/3)                                 TOTAL_STORAGE_GB
  , (round(total_mb/1024/3) - round(USABLE_FILE_MB/1024))  TOTAL_USED_GB
  , round(USABLE_FILE_MB/1024) TOTAL_FREE_GB
  , ROUND((1- (round(USABLE_FILE_MB/1024) / round(total_mb/1024/3)))*100, 2)  pct_used
FROM
    v$asm_diskgroup
ORDER BY
    name
/


---in TB'S

SET LINESIZE  145
SET PAGESIZE  9999
SET VERIFY    off
COLUMN group_name             FORMAT a20           HEAD 'Disk Group|Name'
COLUMN sector_size            FORMAT 99,999        HEAD 'Sector|Size'
COLUMN block_size             FORMAT 99,999        HEAD 'Block|Size'
COLUMN allocation_unit_size   FORMAT 999,999,999   HEAD 'Allocation|Unit Size'
COLUMN state                  FORMAT a11           HEAD 'State'
COLUMN type                   FORMAT a6            HEAD 'Type'
COLUMN total_mb               FORMAT 999,999,999   HEAD 'Total Size (GB)'
COLUMN used_mb                FORMAT 999,999,999   HEAD 'Used Size (GB)'
COLUMN pct_used               FORMAT 999.99        HEAD 'Pct. Used'

break on report on disk_group_name skip 1
compute sum label "Grand Total: " of total_mb used_mb on report

SELECT
    name                                     group_name
  , sector_size                              sector_size
  --, block_size                               block_size
  --, allocation_unit_size                     allocation_unit_size
  , state                                    state
  , type                                     type
  , round(total_mb/1024/1024/3)                                 TOTAL_STORAGE_TB
  , (round(total_mb/1024/1024/3) - round(USABLE_FILE_MB/1024/1024))  TOTAL_USED_TB
  , round(USABLE_FILE_MB/1024/1024) TOTAL_FREE_TB
  , ROUND((1- (round(USABLE_FILE_MB/1024/1024) / round(total_mb/1024/1024/3)))*100, 2)  pct_used
FROM
    v$asm_diskgroup
ORDER BY
    name
/



DB Status:
-----------------

SELECT "Current Status", "Up Since", "Instance Name", "Database Version", "Database Status", "Shutdown Pending", "Active State", "Blocked", "Parallel", "Archiver", "Logins" FROM(
SELECT 
                    STATUS as "Current Status",
                    TO_CHAR(STARTUP_TIME, 'MON DD, YYYY HH12:MI:SS PM') as "Up Since",
                    INSTANCE_NAME as "Instance Name",
                    VERSION as "Database Version",
                    DATABASE_STATUS as "Database Status",
                    SHUTDOWN_PENDING as "Shutdown Pending",
                    ACTIVE_STATE as "Active State",
                    BLOCKED as "Blocked",                      		
                    PARALLEL as "Parallel",
                    ARCHIVER as "Archiver",
                    LOGINS as "Logins"
             from GV$INSTANCE);

Restore Point:
---------------------------

SELECT "Restore Point Name", "Restore Point Time", "Restore Point Type", "Storage Size", "Creation SCN" FROM(
SELECT 
              name as "Restore Point Name",
              DECODE(restore_point_time, NULL, TO_CHAR(time, 'MON DD, YYYY HH12:MI:SS PM'), TO_CHAR(restore_point_time, 'MON DD, YYYY HH12:MI:SS PM')) as "Restore Point Time", 
              DECODE(PRESERVED, 'YES', 'PRESERVED', 'NORMAL') as "Restore Point Type",
              storage_size as "Storage Size", 
              scn as "Creation SCN"
            FROM 
              v$restore_point
            ORDER BY time
);


Database Services:
----------------------------

SELECT "NAME", "NETWORK_NAME", "SERVICE_ID", "CREATION_DATE" FROM(
SELECT 
                      'SQLDEV:LINK:'||USER||':SERVICE:'||nvl(vs.NAME, ds.NAME)||':oracle.dbtools.raptor.dba.navigator.Drill.DBADrillLink' as NAME,
                      lower(nvl(vs.NETWORK_NAME, ds.NETWORK_NAME)) as NETWORK_NAME,
                      ds.SERVICE_ID, 
                      ds.CREATION_DATE
                    FROM 
                      CDB_SERVICES ds,
                      V$SERVICES vs
                    WHERE
                      ds.SERVICE_ID=vs.SERVICE_ID(+)
                      AND ds.NETWORK_NAME IS NOT NULL
                      AND (ds.CON_ID = 0 OR ds.CON_ID = sys_context('userenv','con_id'))
                    ORDER BY 1,2,3
);


Top CPU Utilization SQL
================================================

with sessions as
  (select /*+ materialize */  sess.inst_id, sess.sid, sess.serial#, sess.username,
                     stat.value cpu_used_by_this_session,
                     i.physical_reads, i.block_gets,
                     sess.command, sess.status, sess.lockwait, 
                     decode(sess.sql_hash_value, 0, sess.prev_hash_value, sess.sql_hash_value) sql_hash_value,
                     RawToHex(decode(sess.sql_address, '00', sess.prev_sql_addr, sess.sql_address)) sql_address
            from   gv$sesstat stat, gv$session sess,  gv$sess_io i
            where stat.statistic# = (select statistic# from v$statname where name = 'CPU used by this session')
            and stat.sid = sess.sid
            and stat.inst_id = sess.inst_id
            and (stat.value > :val1 or i.physical_reads > :val2 or i.block_gets > :val3)
            and sess.username is not null
            and i.sid = sess.sid
            and i.inst_id = sess.inst_id) ,
 sqlarea as
   (select inst_id, sql_fulltext sql_text, hash_value, RawToHex(Address) as Address
    from gv$sqlarea)
select *
from sessions, sqlarea
where sessions.inst_id = sqlarea.inst_id
and sessions.sql_hash_value = sqlarea.hash_value
and sessions.sql_address = sqlarea.address
order by cpu_used_by_this_session desc;


Top SQL
===============================

Top SQL by Buffer Gets:
-----------------------------------
SELECT "SQL", "CPU_Seconds", "Disk_Reads", "Buffer_Gets", "Executions", "Buffer_gets/rows_proc", "Buffer_gets/executions", "Elapsed_Seconds", "Module" FROM(
select substr(sql_text,1,500) "SQL",
                                      (cpu_time/1000000) "CPU_Seconds",
                                      disk_reads "Disk_Reads",
                                      buffer_gets "Buffer_Gets",
                                      executions "Executions",
                                      case when rows_processed = 0 then null
                                           else round((buffer_gets/nvl(replace(rows_processed,0,1),1))) 
                                           end "Buffer_gets/rows_proc",
                                      round((buffer_gets/nvl(replace(executions,0,1),1))) "Buffer_gets/executions",
                                      (elapsed_time/1000000) "Elapsed_Seconds",
                                      module "Module"
                                 from gv$sql s
                                order by buffer_gets desc nulls last
);



Top SQL by Buffer Gets/Rows Porc
--------------------------------------

SELECT "SQL", "CPU_Seconds", "Disk_Reads", "Buffer_Gets", "Executions", "Buffer_gets/rows_proc", "Buffer_gets/executions", "Elapsed_Seconds", "Module" FROM(
select substr(sql_text,1,500) "SQL",
                                      round((cpu_time/1000000),3) "CPU_Seconds",
                                      disk_reads "Disk_Reads",
                                      buffer_gets "Buffer_Gets",
                                      executions "Executions",
                                      case when rows_processed = 0 then null
                                           else round((buffer_gets/nvl(replace(rows_processed,0,1),1))) 
                                           end "Buffer_gets/rows_proc",
                                      round((buffer_gets/nvl(replace(executions,0,1),1))) "Buffer_gets/executions",
                                      (elapsed_time/1000000) "Elapsed_Seconds",
                                      module "Module"
                                 from gv$sql s
                                order by (buffer_gets/nvl(replace(rows_processed,0,1),1)) desc nulls last
);


TOP SQL BY CPU
------------------------------------

SELECT "SQL", "CPU_Seconds", "Disk_Reads", "Buffer_Gets", "Executions", "Buffer_gets/rows_proc", "Buffer_gets/executions", "Elapsed_Seconds", "Module" FROM(
select substr(sql_text,1,500) "SQL",
                                      (cpu_time/1000000) "CPU_Seconds",
                                      disk_reads "Disk_Reads",
                                      buffer_gets "Buffer_Gets",
                                      executions "Executions",
                                      case when rows_processed = 0 then null
                                           else round((buffer_gets/nvl(replace(rows_processed,0,1),1))) 
                                           end "Buffer_gets/rows_proc",
                                      round((buffer_gets/nvl(replace(executions,0,1),1))) "Buffer_gets/executions",
                                      (elapsed_time/1000000) "Elapsed_Seconds",
                                      module "Module"
                                 from gv$sql s
                                order by cpu_time desc nulls last
);


Top SQL by Disk Reads 
---------------------------------

SELECT "SQL", "CPU_Seconds", "Disk_Reads", "Buffer_Gets", "Executions", "Buffer_gets/rows_proc", "Buffer_gets/executions", "Elapsed_Seconds", "Module" FROM(
select substr(sql_text,1,500) "SQL",
                                      (cpu_time/1000000) "CPU_Seconds",
                                      disk_reads "Disk_Reads",
                                      buffer_gets "Buffer_Gets",
                                      executions "Executions",
                                      case when rows_processed = 0 then null
                                           else round((buffer_gets/nvl(replace(rows_processed,0,1),1))) 
                                           end "Buffer_gets/rows_proc",
                                      round((buffer_gets/nvl(replace(executions,0,1),1))) "Buffer_gets/executions",
                                      (elapsed_time/1000000) "Elapsed_Seconds",
                                      module "Module"
                                 from gv$sql s
                                order by disk_reads desc nulls last
);

Top SQL by Executions:
-----------------------------------

SELECT "SQL", "CPU_Seconds", "Disk_Reads", "Buffer_Gets", "Executions", "Buffer_gets/rows_proc", "Buffer_gets/executions", "Elapsed_Seconds", "Module" FROM(
select substr(sql_text,1,500) "SQL",
                                      (cpu_time/1000000) "CPU_Seconds",
                                      disk_reads "Disk_Reads",
                                      buffer_gets "Buffer_Gets",
                                      executions "Executions",
                                      case when rows_processed = 0 then null
                                           else round((buffer_gets/nvl(replace(rows_processed,0,1),1))) 
                                           end "Buffer_gets/rows_proc",
                                      round((buffer_gets/nvl(replace(executions,0,1),1))) "Buffer_gets/executions",
                                      (elapsed_time/1000000) "Elapsed_Seconds",
                                      module "Module"
                                 from gv$sql s
                                order by executions desc nulls last
);


----- TEMP and Backup tables:

SELECT 
    o.owner,
    o.object_name AS table_name,o.created,
    ROUND(s.bytes / 1024 / 1024 /1024, 2) AS size_gb
FROM 
    dba_segments s
JOIN 
    dba_objects o 
    ON s.owner = o.owner 
    AND s.segment_name = o.object_name
WHERE o.owner ='OBI_DW'
    AND  o.object_type = 'TABLE'
    AND (o.object_name LIKE '%TMP%'
    OR REGEXP_LIKE(o.object_name, '[0-9]')
    OR o.object_name like '%TEMP%')
   -- AND o.object_name not like 'TMP%'
ORDER BY 
    size_gb DESC;

Sessions count by OS_User:
--------------------------------------
SELECT "OS_User", "Count" FROM(
select osuser "OS_User",
                                      count(*) "Count"
                                 from gv$session
                                group by osuser
                                order by 1
);

Session count by Status:
---------------------------------

SELECT "Status", "OS_User", "Type", "Count" FROM(
select status "Status",osuser "OS_User",
                                      --count(distinct osuser) "Distinct_OS_Users",
                                      type "Type",count(*) "Count"
                                 from gv$session
                                group by status,type,osuser
                                order by 1;

Sessions by Module:
-------------------------
SELECT "Module", "Session_Count" FROM(
select nvl(module,'Unidentified') "Module",
                                      count(*) "Session_Count"
                                 from gv$session
                                 group by nvl(module,'Unidentified')
                                 order by 1
);


Sessions by Username:
-------------------------------

SELECT "Username", "Session_Count" FROM(
select nvl(username,'Unidentified') "Username",
                                      count(*) "Session_Count"
                                 from gv$session
                                group by nvl(username,'Unidentified')
                                order by 1
);                                

Database Status:
----------------------------
SELECT "Current Status", "Up Since", "Instance Name", "Database Version", "Database Status", "Shutdown Pending", "Active State", "Blocked", "Parallel", "Archiver", "Logins" FROM(
SELECT 
                    STATUS as "Current Status",
                    TO_CHAR(STARTUP_TIME, 'MON DD, YYYY HH12:MI:SS PM') as "Up Since",
                    INSTANCE_NAME as "Instance Name",
                    VERSION as "Database Version",
                    DATABASE_STATUS as "Database Status",
                    SHUTDOWN_PENDING as "Shutdown Pending",
                    ACTIVE_STATE as "Active State",
                    BLOCKED as "Blocked",                      		
                    PARALLEL as "Parallel",
                    ARCHIVER as "Archiver",
                    LOGINS as "Logins"
             from GV$INSTANCE;
);


Initialization Parameters:
----------------------------------------

SELECT "Parameter", "Value", "Comment", "Type", "Description", "Modified", "Dynamic", "Basic" FROM(
select /*+ no_parallel(V$SYSTEM_PARAMETER) */  name "Parameter",
            		   display_value "Value",
            		   update_comment "Comment",
            		   decode(type,1,'Boolean',2,' String',3,'Integer',4,'Parameter file',5,'Reserved',6,'Big integer') "Type" ,
            		   description "Description",
            		   decode(ISDEFAULT,'TRUE','No','FALSE','Yes') "Modified",
            		   decode(isinstance_modifiable,'TRUE','Yes','No') "Dynamic", 
            		   decode(ISBASIC,'TRUE','Yes','No') "Basic"
            		   from V$SYSTEM_PARAMETER Paramter order by 1
);

Restore Point:
---------------------------

SELECT "Restore Point Name", "Restore Point Time", "Restore Point Type", "Storage Size", "Creation SCN" FROM(
SELECT 
              'SQLDEV:LINK:'||USER||':RESTORE_POINT:'||name||':oracle.dbtools.raptor.dba.navigator.Drill.DBADrillLink' as "Restore Point Name",
              DECODE(restore_point_time, NULL, TO_CHAR(time, 'MON DD, YYYY HH12:MI:SS PM'), TO_CHAR(restore_point_time, 'MON DD, YYYY HH12:MI:SS PM')) as "Restore Point Time", 
              DECODE(PRESERVED, 'YES', 'PRESERVED', 'NORMAL') as "Restore Point Type",
              storage_size as "Storage Size", 
              scn as "Creation SCN"
            FROM 
              v$restore_point
            ORDER BY time
);


Database Services:
----------------------------

SELECT "NAME", "NETWORK_NAME", "SERVICE_ID", "CREATION_DATE" FROM(
SELECT 
                      'SQLDEV:LINK:'||USER||':SERVICE:'||nvl(vs.NAME, ds.NAME)||':oracle.dbtools.raptor.dba.navigator.Drill.DBADrillLink' as NAME,
                      lower(nvl(vs.NETWORK_NAME, ds.NETWORK_NAME)) as NETWORK_NAME,
                      ds.SERVICE_ID, 
                      ds.CREATION_DATE
                    FROM 
                      CDB_SERVICES ds,
                      V$SERVICES vs
                    WHERE
                      ds.SERVICE_ID=vs.SERVICE_ID(+)
                      AND ds.NETWORK_NAME IS NOT NULL
                      AND (ds.CON_ID = 0 OR ds.CON_ID = sys_context('userenv','con_id'))
                    ORDER BY 1,2,3
);

----Flashback info 

select name, value
from   v$parameter
where  name in ('db_flashback_retention_target', 'db_recovery_file_dest','db_recovery_file_dest_size')
order by name;

-----Database Block Corruption 


COLUMN owner FORMAT A30
COLUMN segment_name FORMAT A30

SELECT DISTINCT owner, segment_name
FROM   v$database_block_corruption dbc
       JOIN dba_extents e ON dbc.file# = e.file_id AND dbc.block# BETWEEN e.block_id and e.block_id+e.blocks-1
ORDER BY 1,2;


-----Diag info

SELECT *
FROM   v$diag_info;


SELECT value
FROM   v$diag_info
WHERE  name = 'Default Trace File';


---flashback data archives.

SELECT owner_name,
       flashback_archive_name,
       flashback_archive#,
       retention_in_days,
       TO_CHAR(create_time, 'DD-MON-YYYY HH24:MI:SS') AS create_time,
       TO_CHAR(last_purge_time, 'DD-MON-YYYY HH24:MI:SS') AS last_purge_time,
       status
FROM   dba_flashback_archive
ORDER BY owner_name, flashback_archive_name;


--flashback_archive_tables:

SELECT owner_name,
       table_name,
       flashback_archive_name,
       archive_table_name,
       status
FROM   dba_flashback_archive_tables
ORDER BY owner_name, table_name;

----flashback_archive_ts:

SELECT flashback_archive_name,
       flashback_archive#,
       tablespace_name,
       quota_in_mb
FROM   dba_flashback_archive_ts
ORDER BY flashback_archive_name;



-----Number of database :

echo 'Num of databases: ' `ps -ef|grep [p]mon|wc -l`


Execution Plan :


 select * from table(dbms_xplan.display_awr('ftx42pkt4yh0h'));

 Cursor: 

SELECT * FROM TABLE(DBMS_XPLAN.display_cursor('85wnyj5xypcuu'));


--------------current_cpu_queries.txt

col USERNAME for a10
col machine for a30
col Text for a50 wrap on

select 
se.SID, ss.serial#,
 ss.username, 
 ss.machine,
 ss.sql_id,
 to_char(s.last_active_time,'DD-MON-YY HH:MI:SS'),
 s.last_load_time, 
 VALUE/100 cpu_secs ,
 substr(s.sql_text,1,50) Text
from 
 v$session ss, 
 v$sesstat se, 
 v$statname sn,
 v$sql s
where 
 se.STATISTIC# = sn.STATISTIC# 
and 
 NAME like '%CPU used by this session%' 
and 
 se.SID = ss.SID 
--and 
 --ss.status='ACTIVE' 
--and 
-- ss.username is not null  and ss.username!='DBMANAGER'
and 
 ss.sql_id=s.sql_id
order by VALUE desc;


------PGA used by Session

select sysdate,vses.username,vses.inst_id,vsst.sid,vses.serial#,vses.machine,vstt.name, vses.osuser,vses.status,
         round(min(vsst.value)/1024/1024,2) MIN_MB,
         round(max(vsst.value)/1024/1024,2) MAX_MB,
         round(avg(vsst.value)/1024/1024,2) AVG_MB
from     sys.gv_$sesstat  vsst, 
         sys.gv_$statname vstt, 
         sys.gv_$session  vses
where    vstt.statistic# = vsst.statistic# 
     and vsst.sid = vses.sid 
     and vstt.name in ('session pga memory','session pga memory max','session uga memory','session uga memory max')
     and vses.username is not null group by  vses.status,vses.username, vses.inst_id, vsst.sid, vses.serial#,  vstt.name ,vses.machine,vses.osuser 
     order by MAX_MB desc
	 /

---Subject: there is a runaway process at at1oebsap03.onerheem.com:

col APPS_USER format a20
col module format a20
col OS_PROCESS_ID format a10
col description format a30
col "User Name" format a30

set lines 200
set trimspool on

select fu.user_name APPS_USER,fu.description "User Name",
    vs.sid DB_SID,
    vs.serial# DB_SERIAL#,
    fl.PROCESS_SPID OS_PROCESS_ID,
    vs.process FORMS_PROCESS_ID,
    vs.module MODULE,
    to_char(fl.start_time,'mm/dd/yyyy hh24:mi:ss') LOGIN
  from applsys.fnd_user fu,
       applsys.fnd_logins fl,
       gv$session vs,
       gv$process vp
  where fu.user_id = fl.user_id
  and fl.process_spid = vp.spid
  and fl.start_time is not null
  and fl.end_time is null
  and vp.pid=fl.pid
  and vs.paddr = vp.addr
  and vs.process = '&forms_process'
order by fl.start_time asc
/     

-----------AWR Snapshot info


select dbid from v$database;

select snap_interval, retention from dba_hist_wr_control;

select * from dba_hist_wr_control  where con_id is not null;

select * from dba_hist_wr_control;

select * from cdb_hist_wr_control;    


select con_id, instance_number, snap_id, begin_interval_time, end_interval_time from cdb_hist_snapshot order by 1,2,3;

SELECT * FROM SYS.WRM$_SNAPSHOT order by begin_interval_time asc;

SELECT MIN (snap_id) FROM SYS.WRM$_SNAPSHOT;

SELECT MAX (snap_id) FROM SYS.WRM$_SNAPSHOT;


---- SQL execution history from DBA_HIST_ACTIVE_SESS_HISTORY

select session_id,
       count(*) as session_count,
       sql_id,
       trunc(px_flags/2097152) as dop,
       program
from DBA_HIST_ACTIVE_SESS_HISTORY
where sql_id = 'gy6umxhdtn9pk'
group by session_id, sql_id, trunc(px_flags/2097152), program
order by session_count desc;




--------Identify Tablespace encrypted or not



select TABLESPACE_NAME, CONTENTS, ENCRYPTED from DBA_TABLESPACES where upper(encrypted)='YES' order by 1;

select b.name pdb_name,wrl_type,wrl_parameter,status,wallet_type,keystore_mode,fully_backed_up from v$encryption_wallet a,v$containers b where a.con_id = b.con_id(+);


set linesize 150
set pagesize 50
column pdb_name heading "PDB Name" format a15
column tablespace_name heading "Tablespace Name" format a30
column masterkeyid_base64 heading "Master Key ID" format a60
column encrypted heading "Encrypted" format a10
break on pdb_name skip 1
select pdb_name, 
tablespace_name,encrypted,
utl_raw.cast_to_varchar2( utl_encode.base64_encode('01'||substr(mkeyid,1,4))) || utl_raw.cast_to_varchar2( utl_encode.base64_encode(substr(mkeyid,5,length(mkeyid)))) masterkeyid_base64
FROM (select t.name tablespace_name,
z.name pdb_name,
t.con_id, encrypted,
RAWTOHEX(x.mkid) mkeyid 
from v$tablespace t, 
x$kcbtek x,
v$containers z,
cdb_tablespaces q 
where t.ts#=x.ts# 
and t.con_id=x.con_id 
and t.con_id=z.con_id
and t.con_id = q.con_id
and t.name = q.tablespace_name)
order by pdb_name,tablespace_name;


---------------------------------------AWR PT Reports -------------------------

--AWR:

WITH OS_HW_RANGES AS (
    SELECT 
        ENTRY_DATE,
        CPU_COUNT,
        HOST_NAME,
        LEAD(ENTRY_DATE) OVER (PARTITION BY HOST_NAME ORDER BY ENTRY_DATE) AS NEXT_DATE 
    FROM 
        RHEEM_OS_HW_HISTORY 
),
METRIC_DETAILS AS ( 
    SELECT 
        target_name,
        TO_CHAR(met.rollup_timestamp, 'DD-MON-YYYY') AS rollup_timestamp,
        ROUND(met.maximum, 0) AS MAX,
        ROUND(met.minimum, 0) AS MIN,
        ROUND(met.average, 0) AS AVG,
        COALESCE(
            (
                SELECT oh.CPU_COUNT 
                FROM OS_HW_RANGES oh 
                WHERE oh.HOST_NAME = met.target_name
                AND TO_CHAR(met.rollup_timestamp, 'DD-MON-YYYY') >= oh.ENTRY_DATE 
                AND (TO_CHAR(met.rollup_timestamp, 'DD-MON-YYYY') < oh.NEXT_DATE OR oh.NEXT_DATE IS NULL)
                ORDER BY oh.ENTRY_DATE DESC 
                FETCH FIRST 1 ROW ONLY
            ),
            (
                SELECT oh.CPU_COUNT 
                FROM OS_HW_RANGES oh 
                WHERE oh.HOST_NAME = met.target_name
                ORDER BY oh.ENTRY_DATE
                FETCH FIRST 1 ROW ONLY
            )
        ) AS CPU_COUNT 
    FROM 
        mgmt$metric_daily@AWR_TO_OEM.ONERHEEM.COM met
    WHERE 
        met.metric_name = 'Load'
        AND met.metric_column = 'cpuUtil' 
        AND met.target_type = 'host'
        AND TO_CHAR(met.rollup_timestamp, 'MM-YYYY') = '04-2024'
        AND met.target_name NOT LIKE 'v%'
)
SELECT * 
FROM METRIC_DETAILS 
ORDER BY target_name, rollup_timestamp;


--------to create job to run schedular


CREATE OR REPLACE PROCEDURE DBAMAINT.OMS_OS_HW_SUMMARY
IS
BEGIN
    INSERT INTO RHEEM_OS_HW_HISTORY (ENVIRONMENT, APPLICATION, HOST_NAME, CPU_COUNT, MEMORY_GB, ENTRY_DATE)
    SELECT 
        CASE 
            WHEN HOST_NAME LIKE 'p%' THEN 'PROD-APP'
            WHEN HOST_NAME LIKE 'oms1' THEN 'PROD-APP'
            WHEN HOST_NAME LIKE 'exap%' THEN 'PROD-DB'
            WHEN HOST_NAME LIKE 'n%' THEN 'NONPROD-APP'
            WHEN HOST_NAME LIKE 'exan%' THEN 'NONPROD-DB'
            WHEN HOST_NAME LIKE 'd%' THEN 'DR-APP'
            WHEN HOST_NAME LIKE 'exad%' THEN 'DR-DB'
            ELSE HOST_NAME 
        END AS ENVIRONMENT,
        CASE 
            WHEN HOST_NAME LIKE 'exadproddb01.onerheem.com' THEN 'DB'
            WHEN HOST_NAME LIKE 'exadproddb02.onerheem.com' THEN 'DB'
            WHEN HOST_NAME LIKE 'exanproddb01.onerheem.com' THEN 'DB'
            WHEN HOST_NAME LIKE 'exanproddb02.onerheem.com' THEN 'DB'
            WHEN HOST_NAME LIKE 'exaproddb01.onerheem.com' THEN 'DB'
            WHEN HOST_NAME LIKE 'exaproddb02.onerheem.com' THEN 'DB'
            WHEN HOST_NAME LIKE 'ndemap1.onerheem.com' THEN 'DEMANTRA'
            WHEN HOST_NAME LIKE 'ndemap2.onerheem.com' THEN 'DEMANTRA'
            WHEN HOST_NAME LIKE 'nebsap1.onerheem.com' THEN 'EBS'
            WHEN HOST_NAME LIKE 'nebsap2.onerheem.com' THEN 'EBS'
            WHEN HOST_NAME LIKE 'nebsax1.onerheem.com' THEN 'EBS'
            WHEN HOST_NAME LIKE 'nebscm1.onerheem.com' THEN 'EBS'
            WHEN HOST_NAME LIKE 'nebscm3.onerheem.com' THEN 'EBS'
            WHEN HOST_NAME LIKE 'noap1.onerheem.com' THEN 'OTM-SOA'
            WHEN HOST_NAME LIKE 'noap2.onerheem.com' THEN 'SOA-ODI-OBI'
            WHEN HOST_NAME LIKE 'noap3.onerheem.com' THEN 'IWAR-APCC-SPWA-APEX'
            WHEN HOST_NAME LIKE 'nobiap1.onerheem.com' THEN 'OBIEE'
            WHEN HOST_NAME LIKE 'nstatap1.onerheem.com' THEN 'STAT'
            WHEN HOST_NAME LIKE 'pdemap1.onerheem.com' THEN 'DEMANTRA'
            WHEN HOST_NAME LIKE 'pdemap2.onerheem.com' THEN 'DEMANTRA'
            WHEN HOST_NAME LIKE 'pebsap1.onerheem.com' THEN 'EBS'
            WHEN HOST_NAME LIKE 'pebsap2.onerheem.com' THEN 'EBS'
            WHEN HOST_NAME LIKE 'pebsax1.onerheem.com' THEN 'EBS'
            WHEN HOST_NAME LIKE 'pebscm1.onerheem.com' THEN 'EBS'
            WHEN HOST_NAME LIKE 'pebscm2.onerheem.com' THEN 'EBS'
            WHEN HOST_NAME LIKE 'pebscm3.onerheem.com' THEN 'EBS'
            WHEN HOST_NAME LIKE 'poap1.onerheem.com' THEN 'IWAR-APCC-SPWA-APEX'
            WHEN HOST_NAME LIKE 'pobiap1.onerheem.com' THEN 'OBIEE'
            WHEN HOST_NAME LIKE 'podiap1.onerheem.com' THEN 'ODI'
            WHEN HOST_NAME LIKE 'oms1' THEN 'OEM'
            WHEN HOST_NAME LIKE 'potmap1.onerheem.com' THEN 'OTM'
            WHEN HOST_NAME LIKE 'psoaap1.onerheem.com' THEN 'SOA'
            WHEN HOST_NAME LIKE 'psoaap2.onerheem.com' THEN 'SOA'
            WHEN HOST_NAME LIKE 'pstatap1.onerheem.com' THEN 'STAT'
            ELSE HOST_NAME 
        END AS APPLICATION,
        CASE 
            WHEN HOST_NAME = 'oms1' THEN 'poemap01.onerheem.com'
            ELSE HOST_NAME
        END AS HOST_NAME,
        CPU_COUNT,
        ROUND(MEM / 1024, 0) AS MEMORY_GB,
        TRUNC(SYSDATE) AS ENTRY_DATE
    FROM MGMT$OS_HW_SUMMARY@AWR_TO_OEM.ONERHEEM.COM
    WHERE HOST_NAME NOT LIKE 'v%'
    ORDER BY ENVIRONMENT DESC, HOST_NAME;
END;
/


---TO run Procedure


BEGIN
    OMS_OS_HW_SUMMARY;
END;
/

commit;

-- Step 2: Create and Schedule the Job

BEGIN
    DBMS_SCHEDULER.create_job (
        job_name        => 'JOB_OMS_OS_HW_SUMMARY',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN OMS_OS_HW_SUMMARY; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=6; BYMINUTE=0; BYSECOND=0',
        enabled         => TRUE
    );
END;
/

SELECT job_name, job_type, enabled,start_date,next_run_date, state FROM dba_scheduler_jobs where JOB_NAME like '%OMS%';

----- Report to combine table and mgm$metric_hourly
SELECT 
    md.rollup_timestamp,    rhh.ENTRY_DATE,    rhh.HOST_NAME,
    ROUND(md.maximum,0) AS MAX,    ROUND(md.minimum,0) AS MIN,    ROUND(md.average,0) AS AVG,
    rhh.CPU_COUNT,     ROUND(rhh.CPU_COUNT*md.maximum/100,2) OCPU_USED_COUNT
FROM 
    mgmt$metric_hourly@AWR_TO_OEM.ONERHEEM.COM md
JOIN 
    RHEEM_OS_HW_HISTORY rhh
ON 
    TRUNC(md.rollup_timestamp) = rhh.ENTRY_DATE
AND 
    md.target_name = rhh.HOST_NAME
WHERE 
    md.metric_name = 'Load'
    AND md.metric_column = 'cpuUtil' 
    AND md.target_type = 'host'
    AND TRUNC(md.rollup_timestamp) = TRUNC(SYSDATE - 1)
	AND md.target_name not like 'v%'
	--AND md.target_name = 'exaproddb01.onerheem.com' 
	--AND md.rollup_timestamp != rhh.ENTRY_DATE
	order by 1 desc;



    -------Hourly Metrics
--- Need to schedule job to sync every day night with SYSDATE-1 

CREATE OR REPLACE PROCEDURE OMS_CPU_Hourly_Metrics
AS
BEGIN
    INSERT INTO RHEEM_CPU_HOURLY_METRICS (
        ENVIRONMENT,
        APPLICATION,
        ROLLUP_TIMESTAMP,
        ENTRY_DATE,
        HOST_NAME,
        CPU_COUNT,
        MEMORY_GB,
        METRIC_COLUMN,
        MAX,
        MIN,
        AVG,
        ACTUAL_USED_VALUE
    )
    SELECT 
        rhh.ENVIRONMENT,
        rhh.APPLICATION,
        md.rollup_timestamp,
        rhh.ENTRY_DATE,    
        rhh.HOST_NAME,
        rhh.CPU_COUNT,
        rhh.MEMORY_GB,
        md.metric_column,
        ROUND(md.maximum, 0) AS MAX,
        ROUND(md.minimum, 0) AS MIN,
        ROUND(md.average, 0) AS AVG,
        CASE 
            WHEN md.metric_column = 'cpuUtil' THEN ROUND(rhh.CPU_COUNT * md.maximum / 100, 2) 
            WHEN md.metric_column = 'memUsedPct' THEN ROUND(rhh.MEMORY_GB * md.maximum / 100, 2) 
            ELSE NULL 
        END AS ACTUAL_USED_VALUE  
    FROM 
        mgmt$metric_hourly@AWR_TO_OEM.ONERHEEM.COM md
    JOIN 
        RHEEM_OS_HW_HISTORY rhh
    ON 
        TRUNC(md.rollup_timestamp) = rhh.ENTRY_DATE
        AND md.target_name = rhh.HOST_NAME
    WHERE 
        md.metric_name = 'Load'
        AND md.metric_column IN ('memUsedPct', 'cpuUtil')
        AND md.target_type = 'host'
        AND md.target_name NOT LIKE 'v%'
        AND TRUNC(md.rollup_timestamp) = TRUNC(SYSDATE - 1)
    ORDER BY 
        md.rollup_timestamp, 
        rhh.HOST_NAME;
        commit;
END;
/




BEGIN
    DBMS_SCHEDULER.create_job (
        job_name        => 'RUN_OMS_CPU_HOURLY_METRICS',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN OMS_CPU_Hourly_Metrics; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=23; BYMINUTE=0; BYSECOND=0',
        enabled         => TRUE
    );
END;


----- To view schedular of OMS jobs

SELECT job_name, job_type, enabled,repeat_interval,start_date,next_run_date, state FROM dba_scheduler_jobs where JOB_NAME like '%OMS%' order by NEXT_RUN_DATE;


DatabaseDetails:
-----------------------------

WITH 
rac AS (SELECT COUNT(*) instances, CASE COUNT(*) WHEN 1 THEN 'Single-instance' ELSE COUNT(*)||'-node RAC cluster' END db_type FROM gv$instance),
mem AS (SELECT SUM(value) target FROM gv$system_parameter2 WHERE name = 'memory_target'),
sga AS (SELECT SUM(value) target FROM gv$system_parameter2 WHERE name = 'sga_target'),
pga AS (SELECT SUM(value) target FROM gv$system_parameter2 WHERE name = 'pga_aggregate_target'),
db_block AS (SELECT value bytes FROM v$system_parameter2 WHERE name = 'db_block_size'),
db AS (SELECT name, platform_name FROM v$database),
 pdbs AS (SELECT * FROM v$pdbs), 
inst AS (SELECT  host_name, version db_version FROM v$instance),
data AS (SELECT  SUM(bytes) bytes, COUNT(*) files, COUNT(DISTINCT ts#) tablespaces FROM v$datafile),
temp AS (SELECT  SUM(bytes) bytes FROM v$tempfile),
log AS (SELECT SUM(bytes) * MAX(members) bytes FROM v$log),
control AS (SELECT  SUM(block_size * file_size_blks) bytes FROM v$controlfile),
 cell AS (SELECT COUNT(DISTINCT cell_name) cnt FROM v$cell_state),
core AS (SELECT  SUM(value) cnt FROM gv$osstat WHERE stat_name = 'NUM_CPU_CORES'),
cpu AS (SELECT  SUM(value) cnt FROM gv$osstat WHERE stat_name = 'NUM_CPUS'),
pmem AS (SELECT SUM(value) bytes FROM gv$osstat WHERE stat_name = 'PHYSICAL_MEMORY_BYTES')
SELECT 
       'Database name:' system_item, db.name system_value FROM db
UNION ALL
 SELECT '    pdb:'||name, 'Open Mode:'||open_mode FROM pdbs -- need 12c flag
  UNION ALL
SELECT 'Oracle Database version:', inst.db_version FROM inst
 UNION ALL
SELECT 'Database block size:', TRIM(TO_CHAR(db_block.bytes / POWER(2,10), '90'))||' KB' FROM db_block
 UNION ALL
SELECT 'Database size:', TRIM(TO_CHAR(ROUND((data.bytes + temp.bytes + log.bytes + control.bytes) / POWER(10,12), 3), '999,999,990.000'))||' TB'
  FROM db, data, temp, log, control
 UNION ALL
SELECT 'Datafiles:', data.files||' (on '||data.tablespaces||' tablespaces)' FROM data
 UNION ALL
SELECT 'Database configuration:', rac.db_type FROM rac
 UNION ALL
SELECT 'Database memory:',
CASE WHEN mem.target > 0 THEN 'MEMORY '||TRIM(TO_CHAR(ROUND(mem.target / POWER(2,30), 1), '999,990.0'))||' GB, ' END||
CASE WHEN sga.target > 0 THEN 'SGA '   ||TRIM(TO_CHAR(ROUND(sga.target / POWER(2,30), 1), '999,990.0'))||' GB, ' END||
CASE WHEN pga.target > 0 THEN 'PGA '   ||TRIM(TO_CHAR(ROUND(pga.target / POWER(2,30), 1), '999,990.0'))||' GB, ' END||
CASE WHEN mem.target > 0 THEN 'AMM' ELSE CASE WHEN sga.target > 0 THEN 'ASMM' ELSE 'MANUAL' END END
  FROM mem, sga, pga
 UNION ALL
 SELECT 'Hardware:', CASE WHEN cell.cnt > 0 THEN 'Engineered System '||
 CASE WHEN 'Intel(R) Xeon(R) CPU E5-2640 v3 @ 2.60GHz' LIKE '%5675%' THEN 'X2-2 ' END||
 CASE WHEN 'Intel(R) Xeon(R) CPU E5-2640 v3 @ 2.60GHz' LIKE '%2690%' THEN 'X3-2 ' END||
 CASE WHEN 'Intel(R) Xeon(R) CPU E5-2640 v3 @ 2.60GHz' LIKE '%2697%' THEN 'X4-2 ' END||
 CASE WHEN 'Intel(R) Xeon(R) CPU E5-2640 v3 @ 2.60GHz' LIKE '%2699%' THEN 'X5-2 or X-6 ' END||
 CASE WHEN 'Intel(R) Xeon(R) CPU E5-2640 v3 @ 2.60GHz' LIKE '%8160%' THEN 'X7-2 ' END||
 CASE WHEN 'Intel(R) Xeon(R) CPU E5-2640 v3 @ 2.60GHz' LIKE '%8870%' THEN 'X3-8 ' END||
 CASE WHEN 'Intel(R) Xeon(R) CPU E5-2640 v3 @ 2.60GHz' LIKE '%8895%' THEN 'X4-8 or X5-8 ' END||
 'with '||cell.cnt||' storage servers'
 ELSE 'Unknown' END FROM cell
  UNION ALL
SELECT 'Processor:', 'Intel(R) Xeon(R) CPU E5-2640 v3 @ 2.60GHz' FROM DUAL
 UNION ALL
SELECT 'Physical CPUs:', core.cnt||' cores'||CASE WHEN rac.instances > 0 THEN ', on '||rac.db_type END FROM rac, core
 UNION ALL
SELECT 'Oracle CPUs:', cpu.cnt||' CPUs (threads)'||CASE WHEN rac.instances > 0 THEN ', on '||rac.db_type END FROM rac, cpu
 UNION ALL
SELECT 'Physical RAM:', TRIM(TO_CHAR(ROUND(pmem.bytes / POWER(2,30), 1), '999,990.0'))||' GB'||CASE WHEN rac.instances > 0 THEN ', on '||rac.db_type END FROM rac, pmem
 UNION ALL
SELECT 'Operating system:', db.platform_name FROM db;


--------Mary Concurrent program query

select     f.request_id ,
       pt.user_concurrent_program_name user_conc_program_name,
       f.actual_start_date start_on,
       f.actual_completion_date end_on,
       floor(((f.actual_completion_date-f.actual_start_date)*24*60*60)/3600) || ' HOURS ' || 
           floor((((f.actual_completion_date-f.actual_start_date) *24*60*60) - floor(((f.actual_completion_date-f.actual_start_date) *24*60*60)/3600)*3600)/60) || ' MINUTES ' ||  
           round((((f.actual_completion_date-f.actual_start_date) *24*60*60) - floor(((f.actual_completion_date-f.actual_start_date) *24*60*60)/3600)*3600 - 
              (floor((((f.actual_completion_date-f.actual_start_date)*24*60*60) - floor(((f.actual_completion_date-f.actual_start_date)*24*60*60)/3600)*3600)/60)*60) )) || ' SECS ' time_difference, 
       ((f.actual_completion_date-f.actual_start_date)*24*60*60)/3600 "DURATION HOURS",
       p.concurrent_program_name concurrent_program_name,
       decode(f.phase_code,'R','Running','C','Complete',f.phase_code) Phase,
       f.status_code Status, fu.user_name,f.argument_text,  f.outfile_name,   f.logfile_name 
 from  apps.fnd_concurrent_programs p,
       apps.fnd_concurrent_programs_tl pt,
       apps.fnd_concurrent_requests f,
       apps.fnd_user fu
 where f.concurrent_program_id = p.concurrent_program_id
       and f.program_application_id = p.application_id
       and f.concurrent_program_id = pt.concurrent_program_id
       and f.program_application_id = pt.application_id
       AND pt.language = USERENV('Lang')
       and f.actual_start_date is not null
       and pt.user_concurrent_program_name like 'XXRHM iWarranty Claim Settlement%%' 
       and (argument_text is NULL or argument_text like '%%')
       --1113    SURESH.CHALLA
       --and f.requested_by = 89589
       --and pt.user_concurrent_program_name not like 'PO Output for Communication%'
       --and argument_text like 'Invoice%'
       AND fu.user_id = f.requested_by
       and ((f.actual_completion_date-f.actual_start_date)*24*60*60)/3600 >= .1
 order by
       f.actual_start_date desc;

---- Executions

   SELECT program,
         status_code,
         TO_CHAR (actual_start_date, 'YYYY-MM'),
         COUNT (*)
    FROM xxrhm.XXRHM_FND_CONC_REQ_SUMM_HIST
   WHERE     1 = 1
         AND actual_start_date > SYSDATE - 90
         AND program_application_id = 665
GROUP BY program, status_code, TO_CHAR (actual_start_date, 'YYYY-MM')
ORDER BY program, status_code, TO_CHAR (actual_start_date, 'YYYY-MM')      


/* DR lag query from OCI OEM DB as sysman user */
 
WITH qb_get_dgmetrics AS (

     select 
          target_name
          , MAX( case when column_label = 'Apply Lag (seconds)' then to_number(value) end ) as apply_lag
          , MAX( case when column_label = 'Transport Lag (seconds)' then to_number(value) end ) as transport_lag
          , collection_timestamp
     from mgmt$metric_current
     where metric_name like '%dataguard%'
     and metric_label = 'Data Guard Performance' 
     and column_label in ('Apply Lag (seconds)', 'Transport Lag (seconds)' )
     group by target_name, collection_timestamp
)
select
     target_name
     , apply_lag
     , transport_lag
     , collection_timestamp 
from qb_get_dgmetrics

--where apply_lag > 0 ;


WITH qb_get_dgmetrics AS (
     select 
          target_name
              , MAX( case when column_label = 'Apply Lag (seconds)' then to_number(value) end ) as apply_lag
          , MAX( case when column_label = 'Transport Lag (seconds)' then to_number(value) end ) as transport_lag
          , MAX( case when column_label = 'Apply Lag Data Refresh Time' then value end ) as Apply_Refresh_Time
          , MAX( case when column_label = 'Transport Lag Data Refresh Time' then value end ) as Transport_Refresh_Time
          , collection_timestamp
     from mgmt$metric_current
     where metric_name like '%dataguard%'
    and metric_label = 'Data Guard Performance' 
     and column_label in ('Apply Lag (seconds)', 'Transport Lag (seconds)','Apply Lag Data Refresh Time','Transport Lag Data Refresh Time' )
     group by target_name, collection_timestamp
)
select
     target_name
     , apply_lag
     , transport_lag
     , Apply_Refresh_Time
     , Transport_Refresh_Time
     , collection_timestamp 
from qb_get_dgmetrics order by target_name;



---Session info

SELECT 
    s.inst_id AS instance_id, s.sid AS session_id, s.serial# AS serial_number,  p.spid AS os_process_id,
	s.username AS user_name,   s.status AS session_status, s.program AS program_name, s.module AS module,s.action as action,s.command as command,    s.WAIT_CLASS AS WAIT_CLASS,s.WAIT_TIME as WAIT_TIME,s.SECONDS_IN_WAIT AS SECONDS_IN_WAIT,
    s.client_identifier as client_identifier, s.machine AS machine_name, s.sql_id,
    sql.sql_text AS current_sql_text
FROM 
    gv$session s
JOIN 
    gv$process p ON s.inst_id = p.inst_id AND s.paddr = p.addr
LEFT JOIN 
    gv$sql sql ON s.inst_id = sql.inst_id AND s.sql_id = sql.sql_id
WHERE 1=1 
    AND s.type = 'USER' -- Filter for user sessions
    --AND s.status = 'ACTIVE' -- Filter for active sessions
    AND s.client_identifier='ANURADHA.CHALLA'
    --AND s.module=''
    --AND s.action=''

   -------SQL monitoring execution time

   select a.instance_number inst_id, a.snap_id,a.plan_hash_value, to_char(begin_interval_time,'dd-mon-yy hh24:mi') btime, abs(extract(minute from (end_interval_time-begin_interval_time)) + extract(hour from (end_interval_time-begin_interval_time))*60 + extract(day from (end_interval_time-begin_interval_time))*24*60) minutes,
executions_delta executions, round(ELAPSED_TIME_delta/1000000/greatest(executions_delta,1),4) "avg duration (sec)" from dba_hist_SQLSTAT a, dba_hist_snapshot b
where sql_id='60qbpkk2h4hnc' and a.snap_id=b.snap_id
and a.instance_number=b.instance_number
order by BTIME desc, a.instance_number 

--EBS Session Monitoring with SID:

select fu.USER_NAME,
       fl.START_TIME,
       fl.END_TIME,
       fl.process_SPID,
       s.inst_id,
       s.Sid,
       s.serial#,
       p.pid,
       p.traceid,
       s.status,
       p.tracefile
   from fnd_user fu,
        fnd_logins fl,
        gv$session s,
        gv$process p
   where  1=1
     and  fl.user_id=fu.user_id
     and  p.pid=fl.pid
     and  p.ADDR=s.PADDR
     and  fu.USER_NAME='NARESH.SUNDARANEEDI' 
     order by 2 desc;   


SELECT
    l.*,
    u.user_name,
    s.status AS session_status,
    s.sid AS session_id,
    s.serial# AS session_serial
FROM
    apps.fnd_logins l
LEFT JOIN
    apps.fnd_user u
    ON l.user_id = u.user_id
LEFT JOIN
    gv$session s
    ON l.serial# = s.serial#
WHERE 1=1
   --and u.user_name = 'NARESH.SUNDARANEEDI'
ORDER BY
    l.start_time DESC;

  --------to enable SQL trace for EBS session at user level

  BEGIN FND_CTL.FND_SESS_CTL('','', '', 'TRUE','','ALTER SESSION SET TRACEFILE_IDENTIFIER='||''''||'Trace_Log_CZ_ANURADHA.CHALLA' ||''''||' EVENTS ='||''''||' 10046 TRACE NAME CONTEXT FOREVER, LEVEL 12 '||''''); END;

How To Trace and Debug Oracle Self Service Web Applications For EBS CRM (Doc ID 399229.1)

----- Enable trace at Session level
=====================================================================================================================
Enable:

EXEC DBMS_MONITOR.SESSION_TRACE_ENABLE(session_id => 3123, serial_num => 14221, waits => TRUE, binds => TRUE);

Locate the Trace File:

SELECT s.inst_id,s.sid, s.serial#, p.spid,
       'cd ' || d.value || '; ls -ltr *' || p.spid || '*.trc' AS trace_location
FROM gv$session s
JOIN gv$process p ON s.paddr = p.addr
JOIN gv$diag_info d ON d.name = 'Diag Trace'
WHERE s.sid = 3123;

Disable:

EXEC DBMS_MONITOR.SESSION_TRACE_DISABLE(session_id => 3123, serial_num => 14221);

Analyze the Trace File:

tkprof EBSPRODC2_ora_389876.trc EBSPRODC2_ora_389876.tkrpof sys=no waits=yes sort=exeela

=====================================================================================================================

Huge_pages:
=========================================================
[grid@exaprod01-ilup41 ~]$ grep Hugepagesize /proc/meminfo
Hugepagesize:       2048 kB


[grid@exaprod01-ilup41 ~]$ grep HugePages_Total /proc/meminfo
HugePages_Total:   220000




220000 *2048 /1024 /1024

grep HugePages /proc/meminfo


AWR:
==================
SELECT DBID,NAME as DBNAME,
    EXTRACT(day    FROM snap_interval) * 24 * 60 +
    EXTRACT(hour   FROM snap_interval) * 60 +
    EXTRACT(minute FROM snap_interval)        AS snapshot_interval_minutes,
    EXTRACT(day    FROM retention) * 24 * 60 +
    EXTRACT(hour   FROM retention) * 60 +
    EXTRACT(minute FROM retention)            AS retention_interval_minutes,
    ROUND(
      (
        EXTRACT(day    FROM retention) * 24 +
        EXTRACT(hour   FROM retention)
      ) / 24
    )                                         AS retention_days
FROM
    dba_hist_wr_control
    where dbid=(select dbid from v$database);

---include DBNAME
set lines 2000 pages 2000

SELECT
    awr.dbid,
    db.name AS dbname,
    EXTRACT(day    FROM awr.snap_interval) * 24 * 60 +
    EXTRACT(hour   FROM awr.snap_interval) * 60 +
    EXTRACT(minute FROM awr.snap_interval)        AS snapshot_interval_minutes,
    EXTRACT(day    FROM awr.retention) * 24 * 60 +
    EXTRACT(hour   FROM awr.retention) * 60 +
    EXTRACT(minute FROM awr.retention)            AS retention_interval_minutes,
    ROUND(
      (
        EXTRACT(day  FROM awr.retention) * 24 +
        EXTRACT(hour FROM awr.retention)
      ) / 24
    )                                             AS retention_days
FROM
    dba_hist_wr_control awr
JOIN
    v$database db
      ON awr.dbid = db.dbid;


--To get current value of retention and interval
select snap_interval, retention from dba_hist_wr_control;

-- to modify existing values of retention and interval
exec dbms_workload_repository.modify_snapshot_settings(interval => 60, retention => 43200);

--to get list of snapids available
SELECT snap_id, begin_interval_time, end_interval_time FROM dba_hist_snapshot  ORDER BY snap_id;

-- to take manual snapshot
exec dbms_workload_repository.create_snapshot;


--to generate AWR report
$ORACLE_HOME/rdbms/admin/awrrpt.sql

--to generate ADDM report
$ORACLE_HOME/rdbms/admin/addmrpt.sql

--to generate ASH report
$ORACLE_HOME/rdbms/admin/ashrpt.sql

=====================================================



1. AWR Snapshots and Reports can be created both at the CDB level and at the PDB level. AWR Snapshots can be generated only at the CDB level by default.

 

2. Manual creation of PDB AWR snapshot.
   

   SQL> connect <username>/<password> as sysdba
   SQL> alter session set container=PDB1;
   SQL> exec dbms_workload_repository.create_snapshot();


3. Configuration for automatic creation of PDB AWR snapshots.


SQL> alter session set container = CDB$ROOT;
SQL> alter system set AWR_PDB_AUTOFLUSH_ENABLED = TRUE;
SQL> alter system set AWR_SNAPSHOT_TIME_OFFSET=1000000; 

SQL> select * from cdb_hist_wr_control;    

      DBID SNAP_INTERVAL                            RETENTION                                TOPNSQL        CON_ID
---------- ---------------------------------------- ---------------------------------------- ---------- ----------
1793141417 +00000 01:00:00.0                        +00008 00:00:00.0                        DEFAULT             0
4182556862 +40150 00:01:00.0                        +00008 00:00:00.0                        DEFAULT             3  

The snap_interval for PDB is too long by default, so it is required to change it.


SQL> alter session set container=PDB1;
SQL> exec dbms_workload_repository.modify_snapshot_settings(interval => 30, dbid => 4182556862);

SQL> alter session set container = CDB$ROOT;
SQL> select * from cdb_hist_wr_control;

      DBID SNAP_INTERVAL                            RETENTION                                TOPNSQL        CON_ID
---------- ---------------------------------------- ---------------------------------------- ---------- ----------
1793141417 +00000 01:00:00.0                        +00008 00:00:00.0                        DEFAULT             0
4182556862 +00000 00:30:00.0                        +00008 00:00:00.0                        DEFAULT             3



4. You can find AWR snapshots(CDB,PDB) from cdb_hist_snapshot.


SQL> alter session set container=CDB$ROOT;
SQL> select con_id, instance_number, snap_id, begin_interval_time, end_interval_time from cdb_hist_snapshot order by 1,2,3;

    CON_ID INSTANCE_NUMBER    SNAP_ID BEGIN_INTERVAL_TIME              END_INTERVAL_TIME
---------- --------------- ---------- -------------------------------- --------------------------------
         0               1          1 28-FEB-19 06.26.06.000 PM        28-FEB-19 07.00.14.425 PM
         0               1          2 28-FEB-19 07.00.14.425 PM        28-FEB-19 08.00.30.362 PM
         0               1          3 28-FEB-19 08.00.30.362 PM        28-FEB-19 09.00.46.286 PM
         0               1          4 28-FEB-19 09.00.46.286 PM        28-FEB-19 10.00.02.598 PM
         0               1          5 28-FEB-19 10.00.02.598 PM        28-FEB-19 11.00.15.351 PM
         3               1          1 28-FEB-19 07.00.14.425 PM        28-FEB-19 07.30.36.225 PM   <<--- PDB snapshot
         3               1          2 28-FEB-19 07.30.36.225 PM        28-FEB-19 08.00.31.532 PM   <<--- PDB snapshot
         3               1          3 28-FEB-19 08.00.31.532 PM        28-FEB-19 08.30.10.270 PM   <<--- PDB snapshot

5. Creation of CDB AWR report


SQL> alter session set container=CDB$ROOT;
SQL> @?/rdbms/admin/awrrpt    



6. Creation of PDB AWR report


SQL> alter session set container=PDB1;
SQL> @?/rdbms/admin/awrrpt

Specify the Report Type
~~~~~~~~~~~~~~~~~~~~~~~
AWR reports can be generated in the following formats.  Please enter the name of the format at the prompt.  Default value is 'html'.

'html'          HTML format (default)
'text'          Text format
'active-html'   Includes Performance Hub active report

Enter value for report_type:

Specify the location of AWR Data
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
AWR_ROOT - Use AWR data from root (default)  
AWR_PDB  - Use AWR data from PDB          <<------- This can be chosen only if PDB snapshots have been created separately.
 
Enter value for awr_location:



------------------Locked Objects

SELECT lo.session_id AS sid,
       s.serial#,
       NVL(lo.oracle_username, '(oracle)') AS username,
       o.owner AS object_owner,
       o.object_name,
       Decode(lo.locked_mode, 0, 'None',
                             1, 'Null (NULL)',
                             2, 'Row-S (SS)',
                             3, 'Row-X (SX)',
                             4, 'Share (S)',
                             5, 'S/Row-X (SSX)',
                             6, 'Exclusive (X)',
                             lo.locked_mode) locked_mode,
       lo.os_user_name
FROM   v$locked_object lo
       JOIN dba_objects o ON o.object_id = lo.object_id
       JOIN v$session s ON lo.session_id = s.sid
ORDER BY 1, 2, 3, 4;


-----Redo Logs

SELECT l.thread#,
       lf.group#,
       lf.member,
       TRUNC(l.bytes/1024/1024) AS size_mb,
       l.status,
       l.archived,
       lf.type,
       lf.is_recovery_dest_file AS rdf,
       l.sequence#,
       l.first_change#,
       l.next_change#   
FROM   v$logfile lf
       JOIN v$log l ON l.group# = lf.group#
ORDER BY l.thread#,lf.group#, lf.member;

------To identify session generating huge redo and archives

SELECT 
    s.inst_id,
    s.sid,
    s.serial#,
    s.username,
    s.program,
    s.machine,
    s.status,
    ROUND(t.value / (1024 * 1024 * 1024), 2) AS redo_size_gb
FROM 
    gv$session s
JOIN 
    gv$sesstat t ON s.sid = t.sid
JOIN 
    gv$statname n ON t.statistic# = n.statistic#
WHERE 
    n.name = 'redo size'
ORDER BY 
    ROUND(t.value / (1024 * 1024 * 1024), 2) DESC
FETCH FIRST 50 ROWS ONLY; -

---Logops:

COLUMN sid FORMAT 999
COLUMN serial# FORMAT 9999999
COLUMN machine FORMAT A30
COLUMN progress_pct FORMAT 99999999.00
COLUMN elapsed FORMAT A10
COLUMN remaining FORMAT A10

SELECT s.inst_id,
       s.sid,
       s.serial#,
       s.machine,
       ROUND(sl.elapsed_seconds/60) || ':' || MOD(sl.elapsed_seconds,60) elapsed,
       ROUND(sl.time_remaining/60) || ':' || MOD(sl.time_remaining,60) remaining,
       ROUND(sl.sofar/sl.totalwork*100, 2) progress_pct
FROM   gv$session s,
       gv$session_longops sl
WHERE  s.sid     = sl.sid
AND    s.serial# = sl.serial#;

------SQL Monitor

SELECT s.sid,
       s.status,
       s.process,
       s.schemaname,
       s.osuser,
       a.sql_text,
       p.program
FROM   v$session s,
       v$sqlarea a,
       v$process p
WHERE  s.SQL_HASH_VALUE = a.HASH_VALUE
AND    s.SQL_ADDRESS = a.ADDRESS
AND    s.PADDR = p.ADDR
/


---Object Invalid Refernce :


Select a.object_id, a.object_type, a.object_name,
  b.owner ref_owner, b.object_type ref_type, b.object_name ref_name, b.object_id ref_id, b.status ref_status
from   sys.DBA_OBJECTS a,
       sys.DBA_OBJECTS b,
      (Select object_id, referenced_object_id
       from   (select object_id, referenced_object_id
               from   public_dependency
               where  referenced_object_id <> object_id) pd
       start with  object_id = :ObjID
       connect by nocycle prior referenced_object_id =  object_id) c
where a.object_id = c.object_id
and   b.object_id = c.referenced_object_id
and   a.owner not in ('SYS', 'SYSTEM')
and   b.owner not in ('SYS', 'SYSTEM')
and   a.object_name <> 'DUAL'
and   b.object_name <> 'DUAL';


-----MWA Sessions

SELECT 
    s.inst_id, 
    s.sid, 
    s.serial#, 
    s.status, 
    s.osuser, 
    s.machine, 
    s.port, 
    s.action, 
    s.client_identifier, 
    s.program, 
    s.module, 
    s.prev_sql_id, 
    prev_sql.sql_text AS prev_executed_sql, 
    s.sql_id, 
    curr_sql.sql_text AS current_executed_sql, 
    s.event, 
    s.logon_time, 
    s.last_call_et 
FROM gv$session s
LEFT JOIN gv$sql prev_sql ON s.prev_sql_id = prev_sql.sql_id AND s.inst_id = prev_sql.inst_id
LEFT JOIN gv$sql curr_sql ON s.sql_id = curr_sql.sql_id AND s.inst_id = curr_sql.inst_id
WHERE 1=1
AND s.program LIKE '%JDBC%'
AND s.module LIKE 'MWAJDBC%'
AND s.status = 'INACTIVE'
AND ROUND(s.last_call_et / 60) > &no_of_seconds
ORDER BY s.last_call_et DESC;




select SID,SERIAL#,STATUS,OSUSER,MACHINE,PORT,ACTION,CLIENT_IDENTIFIER,PROGRAM,MODULE,PREV_SQL_ID,SQL_ID,EVENT,LOGON_TIME,LAST_CALL_ET
from gv$session
where 1=1
--and process is NULL
and program like '%JDBC%'
and module like'MWAJDBC%'
and status = 'INACTIVE'
and round(last_call_et/60) > &no_of_seconds
--and machine like '%';

----Archive log FRA Space

set pages 2000 lines 2000
COL NAME FORMAT a15
SELECT 
    NAME, 
    ROUND(SPACE_LIMIT / 1024 / 1024 / 1024, 2) AS SPACE_LIMIT_GB, 
    ROUND(SPACE_USED / 1024 / 1024 / 1024, 2) AS SPACE_USED_GB, 
    ROUND(SPACE_RECLAIMABLE / 1024 / 1024 / 1024, 2) AS SPACE_RECLAIMABLE_GB, 
    ROUND((SPACE_USED / SPACE_LIMIT) * 100, 2) AS PERCENT_USED, 
    ROUND((SPACE_LIMIT - SPACE_USED) / 1024 / 1024 / 1024, 2) AS REMAINING_SPACE_GB, 
    NUMBER_OF_FILES, 
    CON_ID
FROM V$RECOVERY_FILE_DEST;


Archive log apply and deletion status:
==============================================

select NAME,SEQUENCE#,THREAD#,FIRST_TIME,NEXT_TIME,STANDBY_DEST,APPLIED,DELETED,COMPLETION_TIME from gv$ARCHIVED_LOG 
where 1=1
--and STANDBY_DEST='YES'
and DELETED='NO'
order by FIRST_TIME desc;


-------EBS ECC Version

select * from ECC.ECC_ENTITY_VERSIONS where entity_type = 'PRODUCT';



SSO Mail id:
======================

SELECT fu.USER_NAME,
       fu.EMAIL_ADDRESS,
       fu.START_DATE AS USER_START_DATE,
       fu.END_DATE AS USER_END_DATE
FROM   apps.FND_USER fu
where 1=1
AND upper(fu.email_address) like 'MARY.GREGORY%'
OR upper(fu.email_address) like 'SRAVAN.REDDY.CTR%' 
OR upper(fu.email_address) like 'PAVAN.VENKATA.CTR%'
OR upper(fu.email_address) like 'ASHOK.POTHURI%'
OR upper(fu.email_address) like 'NARESH.SUNDARANEEDI%'
ORDER BY 2;


SELECT fu.USER_NAME,
       fu.EMAIL_ADDRESS,
       fu.START_DATE AS USER_START_DATE,
       fu.END_DATE AS USER_END_DATE
FROM   apps.FND_USER fu
where 1=1
AND upper(fu.USER_NAME) like 'MICHAEL.HAYES%'
ORDER BY 2;

select user_name,email_address from apps.fnd_user where user_name = 'PAVAN.VENKATA.CTR';
 
UPDATE apps.fnd_user
SET email_address = 'pavan.venkata.ctr@Rheem.com-1'
WHERE user_name = 'PAVAN.VENKATA.CTR';
 
commit;

./retrieve_oci_user.sh_bkp --dom SSOPROD --pass webl0g1cSSO --dbname EBSPROD --usr MARK.RITZ
./retrieve_oci_user.sh_bkp --dom SSOPROD --pass webl0g1cSSO --dbname EBSPROD --usr MARKESHA.JACKSON

----------SR OWC performance queries

Execution History:

select ss.snap_id, ss.instance_number node, begin_interval_time, sql_id, plan_hash_value,s.sql_profile,
nvl(executions_delta,0) execs,
(elapsed_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000 avg_etime,
(buffer_gets_delta/decode(nvl(buffer_gets_delta,0),0,1,executions_delta)) avg_lio,module
from DBA_HIST_SQLSTAT S, DBA_HIST_SNAPSHOT SS
where sql_id = '&sql_id'
and ss.snap_id = S.snap_id
and ss.instance_number = S.instance_number
and executions_delta > 0
order by 1, 2, 3;


select inst_id,sid,serial#,sql_id,username,blocking_session,final_blocking_session,final_blocking_instance from gv$session where 
event like '%TX - row lock%';

---Blocking Session DELETE

SELECT gvs.inst_id,DECODE (request, 0, 'Holder: ', 'waiter:') || gvl.sid     sess,
         status,
         id1,
         id2,
         lmode,
         request,
         gvl.TYPE
    FROM gv$lock gvl, gv$session gvs
   WHERE     (id1, id2, gvl.TYPE) IN (SELECT id1, id2, TYPE
                                        FROM gv$lock
                                       WHERE request > 0)
         AND gvl.sid = gvs.sid and gvl.inst_id=gvs.inst_id
ORDER BY id1, request;



select inst_id,sql_id,child_number,executions,buffer_gets/executions,elapsed_time/1000000/executions ,rows_processed/executions,plan_hash_value,sql_profile from gv$sql
where sql_id='dyj1qtuwxv16w' and executions>0
/

-----Clear SQL from shared pool

select INST_ID,ADDRESS, HASH_VALUE from GV$SQLAREA where SQL_ID='81s9rzc25t88q';

SELECT 'exec DBMS_SHARED_POOL.purge('||''''||address||','||hash_value||''''||','||''''||'C'||''''||');',sql_id,
       address,
       hash_value
FROM   v$sqlarea where sql_id='81s9rzc25t88q';


---Clear session DELETE

select 'ALTER SYSTEM KILL SESSION '||''''||sid||','||serial#||',@'||inst_id||''''||' immediate;' from gv$session 
where sql_id='81s9rzc25t88q';


slect sql_id,count(*) from gv$session where event like 'latch: cache buffers chains%' group by sql_id order by 2 desc;




select event,count(*) from gv$session group by event order by 2 desc;


select sql_id,count(*) from GV$ACTIVE_SESSION_HISTORY where event like 'enq: TX - row lock contention%' group by sql_id order by 2 desc;

select count(*),SQL_ID,SQL_PLAN_HASH_VALUE from GV$ACTIVE_SESSION_HISTORY GROUP BY SQL_ID,SQL_PLAN_HASH_VALUE order by 1 desc;

--nitor SQL EXECUTION
select sql_id,event,inst_id,last_call_ET,row_wait_obj# from gv$session where inst_id=2 and sid=2478;


--- DB Backup History from OEM

SELECT TARGET_NAME,
           START_TIME,
           END_TIME,
           COLLECTION_TIMESTAMP,
           INPUT_BYTES_DISPLAY,
           OUTPUT_BYTES_DISPLAY,
           INCREMENTAL_LEVEL,
           --CONTAINER,
           INPUT_TYPE,
           NAME,
           --TAG,
           STATUS,
           TIME_TAKEN_DISPLAY
    FROM MGMT$DB_BACKUP_HISTORY
    WHERE INPUT_TYPE LIKE 'DB INCR%'
      AND INCREMENTAL_LEVEL =0
      AND TARGET_NAME ='OBIPROD_ASH'
      --AND TRUNC(START_TIME) = TRUNC(SYSDATE - 1)
      order by START_TIME desc;


 ICX_Sessoion count:
 ========================

 SELECT 
    TRUNC(FIRST_CONNECT) AS SESSION_DATE,
    COUNT(*) AS SESSION_COUNT
FROM 
    XXRHM.XXRHM_ICX_SESSIONS
    --where HOME_URL like '%vsso%'
GROUP BY 
    TRUNC(FIRST_CONNECT)
ORDER BY 
    SESSION_DATE desc;     

---Real time SQL MONITORING

SELECT inst_id, sql_id, SUBSTR(sql_text, 1, 100) AS short_sql_text, 
       status, sid, session_serial# , cpu_time, elapsed_time, buffer_gets, disk_reads, 
       sql_exec_start, 
       CASE 
           WHEN status = 'EXECUTING' THEN SYSDATE 
           ELSE last_refresh_time 
       END AS sql_exec_end, 
       CASE 
           WHEN status = 'EXECUTING' THEN ROUND((SYSDATE - sql_exec_start) * 24 * 60 , 2)  -- Convert to minutes
           ELSE ROUND((last_refresh_time - sql_exec_start) * 24 * 60 , 2)  -- Convert to minutes
       END AS total_execution_time_minutes, 
       px_servers_allocated, user_io_wait_time, cluster_wait_time, concurrency_wait_time, 
       application_wait_time, fetches, service_name, CLIENT_IDENTIFIER, program, module, action
FROM GV$SQL_MONITOR 
ORDER BY cpu_time DESC 
FETCH FIRST 10 ROWS ONLY;


----EBS Patch applied/not  --> EXPLICIT/IMPLICIT

select Bugs.Bug_Number as PATCH, langs.language as LANG,
decode(Ad_Patch.Is_Patch_Applied('R12',-1,bugs.bug_Number,langs.language),'EXPLICIT','APPLIED','NOT APPLIED') as APPLIED
From
(select '29259045' as bug_number from dual
--  union all select '30628681' as bug_number from dual 
) Bugs,
(select 'US' as language from dual union all
select 'AR' as language from dual union all
select 'D' as language from dual union all
select 'ESA' as language from dual union all
select 'FRC' as language from dual union all 
select 'NL' as language from dual union all
select 'PTB' as language from dual
) langs;

----- adop session 

SELECT
  ADOP_SESSION_ID,
  PID,
  PREPARE_START_DATE,
  PREPARE_END_DATE,
  ROUND((PREPARE_END_DATE - PREPARE_START_DATE) * 1440, 2) AS PREPARE_DURATION_MIN,
  APPLY_START_DATE,
  APPLY_END_DATE,
  ROUND((APPLY_END_DATE - APPLY_START_DATE) * 1440, 2) AS APPLY_DURATION_MIN,
  FINALIZE_START_DATE,
  FINALIZE_END_DATE,
  ROUND((FINALIZE_END_DATE - FINALIZE_START_DATE) * 1440, 2) AS FINALIZE_DURATION_MIN,
  CUTOVER_START_DATE,
  CUTOVER_END_DATE,
  ROUND((CUTOVER_END_DATE - CUTOVER_START_DATE) * 1440, 2) AS CUTOVER_DURATION_MIN,
  CLEANUP_START_DATE,
  CLEANUP_END_DATE,
  ROUND((CLEANUP_END_DATE - CLEANUP_START_DATE) * 1440, 2) AS CLEANUP_DURATION_MIN,
  ABORT_START_DATE,
  ABORT_END_DATE,
  ROUND((ABORT_END_DATE - ABORT_START_DATE) * 1440, 2) AS ABORT_DURATION_MIN
FROM
  AD_ADOP_SESSIONS
WHERE
  ADOP_SESSION_ID IS NOT NULL
ORDER BY
  ADOP_SESSION_ID DESC;

---AD_ADOP_SESSION_PATCHES

  SELECT
  ADOP_SESSION_ID,
  BUG_NUMBER,
  NODE_NAME,
  DRIVER_FILE_NAME,
  AUTOCONFIG_STATUS,
  SESSION_TYPE,
  START_DATE,
  END_DATE,
  ROUND((END_DATE - START_DATE) * 1440, 2) AS PATCH_DURATION_MIN
FROM
  AD_ADOP_SESSION_PATCHES
WHERE
  START_DATE IS NOT NULL 
  AND END_DATE IS NOT NULL
 --AND BUG_NUMBER like '%37923872%'
ORDER BY
  ADOP_SESSION_ID DESC, BUG_NUMBER;

  ------Resource Limit:

  SELECT inst_id,
       resource_name,
       current_utilization,
       max_utilization,
       limit_value,
       ROUND((current_utilization / limit_value) * 100, 2) AS pct_used
FROM gv$resource_limit
WHERE resource_name IN ('processes','sessions');

from AWR:

SELECT sn.begin_interval_time,
       rl.instance_number,
       rl.resource_name,
       rl.current_utilization,
       rl.max_utilization,
       rl.limit_value,
       ROUND((rl.current_utilization / rl.limit_value) * 100, 2) pct_used
FROM dba_hist_resource_limit rl,
     dba_hist_snapshot sn
WHERE rl.snap_id = sn.snap_id
  AND rl.dbid = sn.dbid
  AND rl.instance_number = sn.instance_number
  AND rl.resource_name IN ('processes','sessions')
  AND sn.begin_interval_time > SYSDATE - 7
ORDER BY sn.begin_interval_time;

================ETLs=========================================

-----Rows Proceesed forn insert

SELECT sql_id,
       snap_id,
       executions_delta,
       rows_processed_delta,
       rows_processed_delta/NULLIF(executions_delta,0) AS rows_per_exec
  FROM dba_hist_sqlstat
WHERE sql_id IN ('6n2nz2t41zb91','dj9b07hn7cs9x')
   AND rows_processed_delta > 0
ORDER BY snap_id;


--------SQL id from history for partucilar LP session  ( this is from DBA_HIST)
 
 WITH ash_base AS (
    SELECT 
        h.sql_id,
        h.sql_exec_id,
        h.sql_opname,
        h.sql_plan_hash_value,
        h.top_level_sql_id,
        h.instance_number,
        h.sql_exec_start,
        h.sample_time,
        h.session_state,
        h.wait_class,
        h.event,
        h.delta_read_io_bytes,
        h.delta_write_io_bytes,
        h.delta_read_io_requests,
        h.delta_write_io_requests,
        h.pga_allocated,
        h.temp_space_allocated,
        h.machine,
        h.program,
        h.module,
        h.action,
        h.user_id,
        -- Identify QC (coordinator) vs PX slave
        -- QC has no px_flags or its program won't have (Pxxx) pattern
        CASE 
            WHEN REGEXP_LIKE(h.program, '\(P[0-9A-F]{3}\)$') THEN 'PX_SLAVE'
            ELSE 'QC'
        END AS session_role,
        h.session_id,
        h.session_serial#
    FROM dba_hist_active_sess_history h
    WHERE 
        h.sample_time BETWEEN 
            TO_DATE('04/03/2026 04:30:00', 'MM/DD/YYYY HH24:MI:SS') AND 
            TO_DATE('04/03/2026 14:30:00', 'MM/DD/YYYY HH24:MI:SS')
        AND h.action      LIKE '%9167745969%'
        AND h.sql_exec_start IS NOT NULL
),
-- Count wait events per execution (collapsed across all PX slaves)
wait_counts AS (
    SELECT 
        sql_id,
        sql_exec_id,
        instance_number,
        event,
        COUNT(*) AS event_count
    FROM ash_base
    WHERE event IS NOT NULL
    GROUP BY 
        sql_id,
        sql_exec_id,
        instance_number,
        event
),
-- Pick dominant wait per execution
dominant_wait AS (
    SELECT 
        sql_id,
        sql_exec_id,
        instance_number,
        MAX(event) KEEP (DENSE_RANK LAST ORDER BY event_count) AS dominant_wait_event
    FROM wait_counts
    GROUP BY 
        sql_id,
        sql_exec_id,
        instance_number
),
-- Get QC session details (coordinator row only, for display)
qc_info AS (
    SELECT 
        sql_id,
        sql_exec_id,
        instance_number,
        MAX(session_id)     AS qc_session_id,
        MAX(session_serial#) AS qc_serial#,
        MAX(machine)        AS machine,
        MAX(program)        AS program
    FROM ash_base
    WHERE session_role = 'QC'
    GROUP BY sql_id, sql_exec_id, instance_number
)
-- Main aggregation: one row per sql_id + sql_exec_id + instance
SELECT 
    a.sql_id,
    a.sql_exec_id,
    a.sql_opname,
    a.sql_plan_hash_value,
    a.top_level_sql_id,
    qc.qc_session_id                                            AS qc_session_id,
    qc.qc_serial#                                               AS qc_serial#,
    a.instance_number                                           AS inst_id,
    du.username,
    qc.machine,
    qc.program                                                  AS qc_program,
    a.module,
    a.action,
    a.sql_exec_start                                            AS sql_start_time,
    MIN(a.sample_time)                                          AS first_seen_sample,
    MAX(a.sample_time)                                          AS last_seen_sample,
    ROUND(
        (CAST(MAX(a.sample_time) AS DATE) - CAST(a.sql_exec_start AS DATE)) * 1440, 2
    )                                                           AS duration_minutes,
    COUNT(DISTINCT a.session_id || ',' || a.session_serial#)    AS parallel_degree   -- distinct PX slaves + QC seen
--    COUNT(*)                                                    AS total_ash_samples,
--    COUNT(*) * 10                                               AS est_active_seconds,
--    -- Wait breakdown (aggregated across ALL slaves)
--    SUM(CASE WHEN a.session_state = 'ON CPU'     THEN 1 ELSE 0 END) AS cpu_samples,
--    SUM(CASE WHEN a.wait_class    = 'User I/O'   THEN 1 ELSE 0 END) AS user_io_samples,
--    SUM(CASE WHEN a.wait_class    = 'System I/O' THEN 1 ELSE 0 END) AS system_io_samples,
--    SUM(CASE WHEN a.wait_class    NOT IN ('User I/O','System I/O')
--              AND a.session_state <> 'ON CPU'    THEN 1 ELSE 0 END) AS other_wait_samples,
--    -- I/O aggregates across all PX slaves
--    ROUND(SUM(a.delta_read_io_bytes)  / 1024 / 1024, 2)         AS total_read_io_mb,
--    ROUND(SUM(a.delta_write_io_bytes) / 1024 / 1024, 2)         AS total_write_io_mb,
--    SUM(a.delta_read_io_requests)                                AS total_read_io_reqs,
--    SUM(a.delta_write_io_requests)                               AS total_write_io_reqs,
--    -- Memory peaks across all slaves
--    ROUND(MAX(a.pga_allocated)        / 1024 / 1024, 2)          AS peak_pga_mb,
--    ROUND(MAX(a.temp_space_allocated) / 1024 / 1024, 2)          AS peak_temp_mb,
--    dw.dominant_wait_event
FROM 
    ash_base a
LEFT JOIN dba_users    du  ON a.user_id        = du.user_id
LEFT JOIN dominant_wait dw ON a.sql_id         = dw.sql_id
                           AND a.sql_exec_id   = dw.sql_exec_id
                           AND a.instance_number = dw.instance_number
LEFT JOIN qc_info       qc ON a.sql_id         = qc.sql_id
                           AND a.sql_exec_id   = qc.sql_exec_id
                           AND a.instance_number = qc.instance_number
GROUP BY
    a.sql_id,
    a.sql_exec_id,
    a.sql_opname,
    a.sql_plan_hash_value,
    a.top_level_sql_id,
    a.instance_number,
    du.username,
    qc.qc_session_id,
    qc.qc_serial#,
    qc.machine,
    qc.program,
    a.module,
    a.action,
    a.sql_exec_start,
    dw.dominant_wait_event
ORDER BY 
    a.sql_exec_start DESC,
    duration_minutes  DESC;



--------SQL id from active session  for partucilar LP session  ( this is from active_session_hist)

 WITH ash_base AS (
    SELECT 
        h.sql_id,
        h.sql_exec_id,
        h.sql_opname,
        h.sql_plan_hash_value,
        h.top_level_sql_id,
        h.inst_id                   AS instance_number,   -- GV$ uses inst_id not instance_number
        h.sql_exec_start,
        h.sample_time,
        h.session_state,
        h.wait_class,
        h.event,
        h.delta_read_io_bytes,
        h.delta_write_io_bytes,
        h.delta_read_io_requests,
        h.delta_write_io_requests,
        h.pga_allocated,
        h.temp_space_allocated,
        h.machine,
        h.program,
        h.module,
        h.action,
        h.user_id,
        CASE 
            WHEN REGEXP_LIKE(h.program, '\(P[0-9A-F]{3}\)$') THEN 'PX_SLAVE'
            ELSE 'QC'
        END AS session_role,
        h.session_id,
        h.session_serial#
    FROM gv$active_session_history h    -- << in-memory ASH
    WHERE 
        h.sample_time >= SYSDATE - (30/1440)   -- last 30 minutes; adjust as needed Last 30 min → SYSDATE - (30/1440)
                         --Last 1 hour → SYSDATE - (1/24)
                         --Last 2 hours → SYSDATE - (2/24)
        AND h.action      LIKE '%9229178969%'
        AND h.sql_exec_start IS NOT NULL
),
wait_counts AS (
    SELECT 
        sql_id,
        sql_exec_id,
        instance_number,
        event,
        COUNT(*) AS event_count
    FROM ash_base
    WHERE event IS NOT NULL
    GROUP BY 
        sql_id,
        sql_exec_id,
        instance_number,
        event
),
dominant_wait AS (
    SELECT 
        sql_id,
        sql_exec_id,
        instance_number,
        MAX(event) KEEP (DENSE_RANK LAST ORDER BY event_count) AS dominant_wait_event
    FROM wait_counts
    GROUP BY 
        sql_id,
        sql_exec_id,
        instance_number
),
qc_info AS (
    SELECT 
        sql_id,
        sql_exec_id,
        instance_number,
        MAX(session_id)      AS qc_session_id,
        MAX(session_serial#) AS qc_serial#,
        MAX(machine)         AS machine,
        MAX(program)         AS program
    FROM ash_base
    WHERE session_role = 'QC'
    GROUP BY sql_id, sql_exec_id, instance_number
)
SELECT 
    a.sql_id,
    a.sql_exec_id,
    a.sql_opname,
    a.sql_plan_hash_value,
    a.top_level_sql_id,
    qc.qc_session_id,
    qc.qc_serial#,
    a.instance_number                                            AS inst_id,
    du.username,
    qc.machine,
    qc.program                                                   AS qc_program,
    a.module,
    a.action,
    a.sql_exec_start                                             AS sql_start_time,
    MIN(a.sample_time)                                           AS first_seen_sample,
    MAX(a.sample_time)                                           AS last_seen_sample,
    ROUND(
        (CAST(MAX(a.sample_time) AS DATE) - CAST(a.sql_exec_start AS DATE)) * 1440, 2
    )                                                            AS duration_minutes,
    -- Real elapsed so far from sql_exec_start to NOW
    ROUND(
        (SYSDATE - CAST(a.sql_exec_start AS DATE)) * 1440, 2
    )                                                            AS elapsed_so_far_minutes,
    COUNT(DISTINCT a.session_id || ',' || a.session_serial#)     AS parallel_degree
--    COUNT(*)                                                     AS total_ash_samples,
--    COUNT(*) * 1                                                 AS est_active_seconds,  -- GV$ASH samples every 1 sec
--    SUM(CASE WHEN a.session_state = 'ON CPU'     THEN 1 ELSE 0 END) AS cpu_samples,
--    SUM(CASE WHEN a.wait_class    = 'User I/O'   THEN 1 ELSE 0 END) AS user_io_samples,
--    SUM(CASE WHEN a.wait_class    = 'System I/O' THEN 1 ELSE 0 END) AS system_io_samples,
--    SUM(CASE WHEN a.wait_class    NOT IN ('User I/O','System I/O')
--              AND a.session_state <> 'ON CPU'    THEN 1 ELSE 0 END) AS other_wait_samples,
--    ROUND(SUM(a.delta_read_io_bytes)  / 1024 / 1024, 2)          AS total_read_io_mb,
--    ROUND(SUM(a.delta_write_io_bytes) / 1024 / 1024, 2)          AS total_write_io_mb,
--    SUM(a.delta_read_io_requests)                                 AS total_read_io_reqs,
--    SUM(a.delta_write_io_requests)                                 AS total_write_io_reqs,
--    ROUND(MAX(a.pga_allocated)        / 1024 / 1024, 2)           AS peak_pga_mb,
--    ROUND(MAX(a.temp_space_allocated) / 1024 / 1024, 2)           AS peak_temp_mb,
--    dw.dominant_wait_event
FROM 
    ash_base a
LEFT JOIN dba_users     du ON a.user_id          = du.user_id
LEFT JOIN dominant_wait dw ON a.sql_id           = dw.sql_id
                           AND a.sql_exec_id     = dw.sql_exec_id
                           AND a.instance_number = dw.instance_number
LEFT JOIN qc_info       qc ON a.sql_id           = qc.sql_id
                           AND a.sql_exec_id     = qc.sql_exec_id
                           AND a.instance_number = qc.instance_number
GROUP BY
    a.sql_id,
    a.sql_exec_id,
    a.sql_opname,
    a.sql_plan_hash_value,
    a.top_level_sql_id,
    a.instance_number,
    du.username,
    qc.qc_session_id,
    qc.qc_serial#,
    qc.machine,
    qc.program,
    a.module,
    a.action,
    a.sql_exec_start,
    dw.dominant_wait_event
ORDER BY 
    a.sql_exec_start DESC,
    duration_minutes  DESC;   

 --------Object Details

 SELECT 
    t.owner,
    t.table_name,
    t.tablespace_name,
    t.default_collation,
    o.status,
    t.global_stats,
    t.monitoring,
    t.segment_created,
    t.num_rows,
    t.blocks,
    ROUND(s.bytes/1024/1024/1024, 2) AS size_gb,
    t.avg_row_len,
    t.sample_size,
    t.last_analyzed,
    t.ini_trans,
    t.max_trans,
    t.initial_extent,
    t.next_extent,
    t.min_extents,
    t.max_extents,
    t.pct_free,
    t.freelists AS num_freelist_blocks,
    t.avg_space_freelist_blocks,
    t.chain_cnt,
    t.degree,
    t.instances,
    t.buffer_pool,
    t.flash_cache,
    t.cell_flash_cache,
    t.result_cache,
    t.row_movement,
    t.compression,
    t.inmemory,
    s.extents,
    s.blocks AS segment_blocks,
    s.bytes
FROM dba_tables t
LEFT JOIN dba_segments s
    ON t.owner = s.owner
   AND t.table_name = s.segment_name
   AND s.segment_type = 'TABLE'
LEFT JOIN dba_objects o
    ON t.owner = o.owner
   AND t.table_name = o.object_name
   AND o.object_type = 'TABLE'
WHERE t.owner = 'OBI_DW'
  AND t.table_name = 'W_SALES_ORDER_LINE_F';   


  ----- Objects in Tablespace and there respective sizes and table

   SELECT s.segment_name,
       s.segment_type,
       ROUND(s.bytes/1024/1024/1024, 4)  AS gb,
       s.tablespace_name,
       -- Map to owning table
       CASE s.segment_type
         WHEN 'TABLE'      THEN s.segment_name
         WHEN 'LOBSEGMENT' THEN l.table_name
         WHEN 'LOBINDEX'   THEN li.table_name
         ELSE 'UNKNOWN'
       END                               AS table_name,
       -- Map to LOB column name
       CASE s.segment_type
         WHEN 'LOBSEGMENT' THEN l.column_name
         WHEN 'LOBINDEX'   THEN li.column_name
         ELSE NULL
       END                               AS lob_column
FROM   dba_segments s
-- Join for LOBSEGMENT → table + column
LEFT   JOIN dba_lobs l
         ON l.segment_name = s.segment_name
        AND l.owner        = s.owner
        AND s.segment_type = 'LOBSEGMENT'
-- Join for LOBINDEX → table + column
LEFT   JOIN dba_lobs li
         ON li.index_name  = s.segment_name
        AND li.owner       = s.owner
        AND s.segment_type = 'LOBINDEX'
WHERE  s.owner          = 'ODIPRD12C_ODI_REPO'
AND    s.tablespace_name = 'TEMP_REORG_DELETE'
ORDER  BY s.bytes DESC; 

--------Full details of objects for schema

WITH lob_map AS
(
    SELECT
        owner,
        table_name,
        column_name,
        segment_name
    FROM dba_lobs
    UNION ALL
    SELECT
        owner,
        table_name,
        column_name,
        index_name AS segment_name
    FROM dba_lobs
),
idx_cols AS
(
    SELECT
        index_owner,
        index_name,
        LISTAGG(column_name, ', ')
            WITHIN GROUP (ORDER BY column_position) AS index_columns
    FROM
        dba_ind_columns
    GROUP BY
        index_owner,
        index_name
)
SELECT
    s.owner,
    CASE
        WHEN s.segment_type LIKE 'LOB%'
            THEN l.table_name
        WHEN s.segment_type = 'INDEX'
            THEN i.table_name
        ELSE s.segment_name
    END AS object_name,
    s.segment_type,
    s.segment_name,
    l.column_name AS lob_column,
    ic.index_columns,
    s.tablespace_name,
    ROUND(s.bytes/1024/1024/1024, 2) AS size_gb,
    t.num_rows
FROM
    dba_segments s
LEFT JOIN lob_map l
    ON s.owner = l.owner
   AND s.segment_name = l.segment_name
LEFT JOIN dba_indexes i
    ON s.owner = i.owner
   AND s.segment_name = i.index_name
LEFT JOIN idx_cols ic
    ON i.owner = ic.index_owner
   AND i.index_name = ic.index_name
LEFT JOIN dba_tables t
    ON t.owner =
        CASE
            WHEN s.segment_type LIKE 'LOB%' THEN l.owner
            WHEN s.segment_type = 'INDEX' THEN i.table_owner
            ELSE s.owner
        END
   AND t.table_name =
        CASE
            WHEN s.segment_type LIKE 'LOB%' THEN l.table_name
            WHEN s.segment_type = 'INDEX' THEN i.table_name
            ELSE s.segment_name
        END
WHERE
    s.owner = UPPER('OBI_BIA_ODIREPO')
    AND s.segment_type IN ('TABLE','INDEX','LOBSEGMENT','LOBINDEX')
ORDER BY
    size_gb DESC;