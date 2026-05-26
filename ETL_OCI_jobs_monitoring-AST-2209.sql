--ETL loads Monitoring:
--=============================

--https://www.clearpeaks.com/etl-monitoring-dashboard-in-obiee-using-odi-tables/ 

----Tables :
--ODI11GPROD_BIA_ODIREPO.SNP_SESSION 
--ODI11GPROD_BIA_ODIREPO.SNP_STEP_LOG
--ODI11GPROD_BIA_ODIREPO.SNP_SESS_TASK_LOG
--ODI11GPROD_BIA_ODIREPO.SNP_SESS_TASK
--ODI11GPROD_BIA_ODIREPO.SNP_SESS_STEP

--ODI11GPROD_BIA_ODIREPO.SNP_LP_INST
--ODI11GPROD_BIA_ODIREPO.SNP_LPI_RUN
--ODI11GPROD_BIA_ODIREPO.SNP_LPI_STEP_LOG

----Session name : SDE_ORAR122_ADAPTOR_SDE_ORA_BOMITEMFACT_HEADER

--Session monitoring with session name: (compare with previosu time)
----------------------------------------------------------------------
select SESS_NO,SESS_NAME,SCEN_VERSION,
TO_CHAR(SESS_BEG,'DD-MON-YYYY:HH24:MI:SS') SESSION_START_DATE ,
TO_CHAR(SESS_END,'DD-MON-YYYY:HH24:MI:SS') SESSION_END_DATE,
SESS_DUR,
(nvl(SESS_END,sysdate)-SESS_BEG)*1440 "Time Spent(MINS)",
DECODE(SESS_STATUS, 'D', 'Done', 'E', 'Error', 'M', 'Warning', 'Q', 'Queued', 'R', 'Running', 'W', 'Waiting',SESS_STATUS) AS SESS_STATUS_DESC,
FIRST_DATE,LAST_DATE 
from ODI11GPROD_BIA_ODIREPO.SNP_SESSION  
where SESS_NAME='RHM_PLP_DAILY_INVENTORY_AGGREGATE' order by SESS_BEG desc;

--Combine with other tables:
----------------------------

SELECT SS.SESS_NO, 
   SS.SCEN_NAME,
   SS.SCEN_VERSION,
   SS.SESS_NAME,
   SS.PARENT_SESS_NO,
   SS.SESS_BEG,
   SS.SESS_END,
   SS.SESS_STATUS,
   DECODE(SS.SESS_STATUS, 'D', 'Done', 'E', 'Error', 'M', 'Warning', 'Q', 'Queued', 'R', 'Running', 'W', 'Waiting', SS.SESS_STATUS) AS SESS_STATUS_DESC,
   SSL.NNO,
   SSTL.NB_RUN,
   SST.TASK_TYPE,
   DECODE(SST.TASK_TYPE, 'C', 'Loading', 'J', 'Mapping', 'S', 'Procedure', 'V', 'Variable', SST.TASK_TYPE) AS TASK_TYPE_DESC,
   SST.EXE_CHANNEL,
   DECODE(SST.EXE_CHANNEL, 'B', 'Oracle Data Integrator Scripting', 'C', 'Oracle Data Integrator Connector', 'J', 'JDBC', 'O', 'Operating System', 'Q', 'Queue', 'S', 'Oracle Data Integrator Command', 'T', 'Topic', 'U', 'XML Topic', SST.EXE_CHANNEL) AS EXE_CHANNEL_DESC,
   SSTL.SCEN_TASK_NO,
   SST.TASK_NAME1,
   SST.TASK_NAME2,
   SST.TASK_NAME3,
   SSTL.TASK_DUR,
   SSTL.NB_ROW,
   SSTL.NB_INS,
   SSTL.NB_UPD,
   SSTL.NB_DEL,
   SSTL.NB_ERR,
   SSS.LSCHEMA_NAME || '.' || SSS.RES_NAME AS TARGET_TABLE,
   CASE WHEN SST.COL_TECH_INT_NAME IS NOT NULL AND SST.COL_LSCHEMA_NAME IS NOT NULL THEN SST.COL_TECH_INT_NAME || '.' || SST.COL_LSCHEMA_NAME
     ELSE NULL
     END AS TARGET_SCHEMA,
     SSTL.DEF_TXT AS TARGET_COMMAND,
     CASE WHEN SST.DEF_TECH_INT_NAME IS NOT NULL AND SST.DEF_LSCHEMA_NAME IS NOT NULL THEN SST.DEF_TECH_INT_NAME || '.' || SST.DEF_LSCHEMA_NAME
     ELSE NULL
     END AS SOURCE_SCHEMA,
     SSTL.COL_TXT AS SOURCE_COMMAND
     FROM ODI11GPROD_BIA_ODIREPO.SNP_SESSION SS
    INNER JOIN ODI11GPROD_BIA_ODIREPO.SNP_STEP_LOG SSL
    ON SS.SESS_NO = SSL.SESS_NO
    INNER JOIN ODI11GPROD_BIA_ODIREPO.SNP_SESS_TASK_LOG SSTL
    ON SS.SESS_NO = SSTL.SESS_NO
    INNER JOIN ODI11GPROD_BIA_ODIREPO.SNP_SESS_TASK SST
    ON SSTL.SESS_NO = SST.SESS_NO
    AND SSTL.SCEN_TASK_NO = SST.SCEN_TASK_NO
    AND SSL.NNO = SSTL.NNO
    AND SSTL.NNO = SST.NNO
    AND SSL.NB_RUN = SSTL.NB_RUN
    LEFT JOIN ODI11GPROD_BIA_ODIREPO.SNP_SESS_STEP SSS
    ON SST.SESS_NO = SSS.SESS_NO
    AND SST.NNO = SSS.NNO
    WHERE 1 = 1
    --AND SS.SESS_NO = 1552388969
    --AND SS.SESS_NAME='RHM_SDE_ORA_COST_HISTORY_V_PROD'
    --AND SS.SESS_STATUS  IN ('D', 'R')
    --AND SST.EXE_CHANNEL IN ('B', 'C', 'J', 'S')
    --AND (UPPER(SSTL.DEF_TXT) LIKE '%SELECT%' OR UPPER(SSTL.DEF_TXT) LIKE '%MERGE%' OR UPPER(SSTL.DEF_TXT) LIKE '%INSERT%')
    --AND SST.TASK_TYPE NOT IN ('V') --VARIABLE
    --AND SSTL.NB_ROW > 0
    --AND LENGTH(SS.SCEN_VERSION) > 3
    ORDER BY SS.SESS_NO DESC, SSL.NNO, SSL.NB_RUN, SSTL.SCEN_TASK_NO;

 
 -----Table Size

SELECT 
    o.owner,
    o.object_name AS table_name,o.object_type,o.created,
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
    
 --- avoid having "$" in tablename   
SELECT 
    o.owner,
    o.object_name AS table_name,
    o.object_type,
    o.created,
    ROUND(s.bytes / 1024 / 1024 / 1024, 2) AS size_gb
FROM 
    dba_segments s
JOIN 
    dba_objects o 
    ON s.owner = o.owner 
    AND s.segment_name = o.object_name
WHERE 
    o.owner = 'OBI_DW'
    AND o.object_type = 'TABLE'
    AND (
        o.object_name LIKE '%TMP%'
        OR REGEXP_LIKE(o.object_name, '[0-9]')
        OR o.object_name LIKE '%TEMP%'
    )
    AND o.object_name NOT LIKE '%$%'
ORDER BY 
    size_gb DESC;
    
 
 --RUNNING ETL Loads
 --------------------------------------
 
 select SLI.I_LP_INST as Load_ID ,SLI.LOAD_PLAN_NAME,SLR.NB_RUN,SLR.START_DATE,SLR.END_DATE,SLR.DURATION/60 as Duration_MINUTES,SLR.STATUS
from ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI 
inner join ODI11GPROD_BIA_ODIREPO.SNP_LPI_RUN SLR on
 SLI.I_LP_INST=SLR.I_LP_INST --and SLR.STATUS='R' 
 --and TRUNC(SLR.START_DATE) ='05/08/2024%';
 
 
 -------ETL RUN Duration History


SELECT 
    SLI.I_LP_INST        AS LOAD_ID,
    SLI.LOAD_PLAN_NAME,
    MIN(SLR.NB_RUN) || '-' || MAX(SLR.NB_RUN) AS NB_RUN_RANGE,
    (MAX(SLR.NB_RUN) - 1) AS RESTART_COUNT,
    CASE 
        WHEN MAX(SLR.NB_RUN) = 1 THEN 'Single Run'
        ELSE 'Restarted ' || (MAX(SLR.NB_RUN) - 1) || ' times'
    END AS RUN_TYPE,
    -- ?? Final Status
    CASE 
        WHEN MAX(CASE WHEN SLR.STATUS = 'R' THEN 1 ELSE 0 END) = 1 
        THEN 'RUNNING'
        ELSE 'COMPLETED'
    END AS FINAL_STATUS,
     -- ?? Dates
    TRUNC(MIN(SLR.START_DATE)) AS RUN_DATE,
     -- ?? Day Name
    TO_CHAR(MIN(SLR.START_DATE), 'DAY') AS DAY_NAME,
    MIN(SLR.START_DATE)        AS DAY_START_DATE,
    CASE 
        WHEN MAX(CASE WHEN SLR.STATUS = 'R' THEN 1 ELSE 0 END) = 1 
        THEN NULL
        ELSE MAX(SLR.END_DATE)
    END AS DAY_END_DATE,
    CASE 
        WHEN MAX(CASE WHEN SLR.STATUS = 'R' THEN 1 ELSE 0 END) = 1 
        THEN NULL
        ELSE ROUND(SUM(SLR.DURATION)/60, 2)
    END AS TOTAL_DURATION_MINS
FROM ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI
JOIN ODI11GPROD_BIA_ODIREPO.SNP_LPI_RUN SLR
    ON SLI.I_LP_INST = SLR.I_LP_INST
WHERE SLI.LOAD_PLAN_NAME = 'BI Apps All Modules LoadPlan_INCR'
  AND SLR.START_DATE > SYSDATE - 20
GROUP BY 
    SLI.I_LP_INST,
    SLI.LOAD_PLAN_NAME
ORDER BY DAY_START_DATE DESC;
 
-------Full load plan session/tasks with duration and tasj duration (here only filter with insert/create index,gather stat 
       --- add more or comment if yu need full list 

SELECT 
    SLI.I_LP_INST AS Load_ID,
    SLI.LOAD_PLAN_NAME,
    -- SESSION DETAILS
    SS.SESS_NO,
    SS.SESS_NAME,
    SLSL.STATUS,
    TO_CHAR(SLSL.START_DATE, 'DD-MON-YYYY HH24:MI:SS') AS SESSION_START_DATE,
    TO_CHAR(SLSL.END_DATE,   'DD-MON-YYYY HH24:MI:SS') AS SESSION_END_DATE,
        -- TASK DETAILS (I$ LOAD)
    SSTL.TASK_NAME3,
    TO_CHAR(SSTL.TASK_BEG, 'DD-MON-YYYY HH24:MI:SS') AS TASK_START_DATE,
    TO_CHAR(SSTL.TASK_END, 'DD-MON-YYYY HH24:MI:SS') AS TASK_END_DATE,
    ROUND((NVL(SSTL.TASK_END, SYSDATE) - SSTL.TASK_BEG) * 1440,2) AS TASK_MINS,
    ROUND((NVL(SLSL.END_DATE, SYSDATE) - SLSL.START_DATE) * 1440,2) AS TOTAL_SESSION_MINS
    --SSTL.TASK_DUR AS TASK_DUR_SEC
/*   -- DB SESSION DETAILS
   , S.INST_ID,
    S.SID,
    S.SERIAL#,
    S.SQL_ID,
    Q.CHILD_NUMBER,
    ROUND(Q.CPU_TIME/1000000/60, 2)     AS CPU_MIN,
    ROUND(Q.ELAPSED_TIME/1000000/60, 2) AS ELAPSED_MIN,
    Q.EXECUTIONS,
    Q.ROWS_PROCESSED,
    S.USERNAME,
    S.STATUS AS DB_STATUS,
    S.MACHINE,
    S.MODULE,
    S.ACTION,
    S.CLIENT_INFO,
    DBMS_LOB.SUBSTR(Q.SQL_TEXT, 4000, 1) AS SQL_TEXT */
FROM ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI
JOIN ODI11GPROD_BIA_ODIREPO.SNP_LPI_STEP_LOG SLSL
    ON SLI.I_LP_INST = SLSL.I_LP_INST
JOIN ODI11GPROD_BIA_ODIREPO.SNP_SESSION SS
    ON SLSL.SESS_NO = SS.SESS_NO
JOIN ODI11GPROD_BIA_ODIREPO.SNP_SESS_TASK_LOG SSTL
    ON SLSL.SESS_NO = SSTL.SESS_NO
-- ?? ROBUST DB SESSION JOIN
--LEFT JOIN GV$SESSION S
--    ON S.USERNAME = 'OBI_DW'
--   AND S.STATUS = 'ACTIVE'
--   AND (
--          S.ACTION       LIKE '%' || SLSL.SESS_NO || '%'
--       OR S.CLIENT_INFO  LIKE '%' || SLSL.SESS_NO || '%'
--       OR S.MODULE       LIKE 'ODI%'
--       OR S.LOGON_TIME  >= SLSL.START_DATE - (1/24)   -- time correlation (1 hour buffer)
--       )
--LEFT JOIN GV$SQL Q
--    ON S.SQL_ID = Q.SQL_ID
--   AND S.INST_ID = Q.INST_ID
--   AND S.SQL_CHILD_NUMBER = Q.CHILD_NUMBER
WHERE 
    SLI.LOAD_PLAN_NAME = 'BI Apps All Modules LoadPlan_INCR'
    --AND SLSL.START_DATE > SYSDATE - 1
    AND SLI.I_LP_INST='&Load_plan_id'
    -- ?? ONLY I$ INSERT TASK
    --AND SSTL.TASK_NAME3 in('Insert flow into I$ table','Create indexes','Gather stats','Pre load analyze target table')
    -- ?? ONLY INSERT / CTAS SQL
--    AND (
--          Q.SQL_TEXT IS NULL
--       OR UPPER(DBMS_LOB.SUBSTR(Q.SQL_TEXT, 4000, 1)) LIKE '%INSERT%'
--       OR UPPER(DBMS_LOB.SUBSTR(Q.SQL_TEXT, 4000, 1)) LIKE '%CREATE%'
--    )
ORDER BY SSTL.TASK_BEG ASC NULLS LAST
--ORDER BY SESSION_MINS DESC NULLS LAST;
 
 
 SELECT 
    SLI.I_LP_INST AS Load_ID,
    SLI.LOAD_PLAN_NAME,
    SLR.NB_RUN,
    SLR.START_DATE,
    SLR.END_DATE,
    SLR.DURATION / 60 AS Duration_MINUTES,
    SLR.STATUS
FROM 
    ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI
INNER JOIN 
    ODI11GPROD_BIA_ODIREPO.SNP_LPI_RUN SLR
    ON SLI.I_LP_INST = SLR.I_LP_INST
WHERE 
    SLR.STATUS in ( 'E','D','R')
    AND SLI.LOAD_PLAN_NAME ='BI Apps All Modules LoadPlan_INCR'
    AND TRUNC(SLR.START_DATE) = TO_DATE('04/13/2026', 'MM/DD/YYYY')
    order by SLR.START_DATE desc;
    
SELECT 
    SLI.I_LP_INST AS Load_ID,
    SLI.LOAD_PLAN_NAME,
    SLR.NB_RUN,
    SLR.START_DATE,
    SLR.END_DATE,
    ROUND(SLR.DURATION / 60, 2) AS Duration_MINUTES,
    SLR.STATUS
FROM 
    ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI
INNER JOIN 
    ODI11GPROD_BIA_ODIREPO.SNP_LPI_RUN SLR
    ON SLI.I_LP_INST = SLR.I_LP_INST
WHERE 
    SLR.STATUS IN ('E', 'D')
    --AND SLI.LOAD_PLAN_NAME = 'BI Apps All Modules LoadPlan_INCR'
    AND SLR.START_DATE BETWEEN TO_DATE('04/10/2026 21:00:00', 'MM/DD/YYYY HH24:MI:SS')
                          AND TO_DATE('04/13/2026 09:01:00', 'MM/DD/YYYY HH24:MI:SS')
ORDER BY 
    SLR.START_DATE DESC;

SELECT 
    SLI.I_LP_INST AS Load_ID,
    SLI.LOAD_PLAN_NAME,
    SLR.NB_RUN,
    TO_CHAR(SLR.START_DATE, 'DD-MON-YYYY HH24:MI:SS') AS start_date,
    TO_CHAR(SLR.START_DATE, 'DAY') AS start_day,
    TO_CHAR(SLR.END_DATE, 'DD-MON-YYYY HH24:MI:SS') AS completion_date,
    TO_CHAR(SLR.END_DATE, 'DAY') AS end_day,
    SLR.STATUS,
    ROUND(SLR.DURATION / 60, 2) AS Duration_MINUTES
    FROM 
    ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI
INNER JOIN 
    ODI11GPROD_BIA_ODIREPO.SNP_LPI_RUN SLR
    ON SLI.I_LP_INST = SLR.I_LP_INST
WHERE 
    SLR.STATUS IN ('E', 'D')
   AND SLI.LOAD_PLAN_NAME = 'BI Apps All Modules LoadPlan_INCR'
    AND SLR.START_DATE BETWEEN TO_DATE('06/02/2026 21:00:00', 'MM/DD/YYYY HH24:MI:SS')
                          AND TO_DATE('04/15/2026 09:01:00', 'MM/DD/YYYY HH24:MI:SS')
ORDER BY 
    SLR.START_DATE ASC;    
    

 
 SELECT
    SLI.I_LP_INST AS Load_ID,
    SLR.NB_RUN,
    SLI.LOAD_PLAN_NAME,
    SLR.STATUS,
    SLR.START_DATE,
    SLR.END_DATE,
    (SYSDATE - SLR.START_DATE) * 24 * 60 AS Total_Duration_Minutes
FROM
    ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI
INNER JOIN
    ODI11GPROD_BIA_ODIREPO.SNP_LPI_RUN SLR
ON
    SLI.I_LP_INST = SLR.I_LP_INST
WHERE
    SLR.STATUS = 'R';
 
 
-- Completed Loads:
 
 select SLI.I_LP_INST as Load_ID ,SLI.LOAD_PLAN_NAME,SLR.NB_RUN,SLR.START_DATE,SLR.END_DATE,SLR.DURATION/60 as Duration_MINUTES,SLR.STATUS
from ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI 
inner join ODI11GPROD_BIA_ODIREPO.SNP_LPI_RUN SLR on
 SLI.I_LP_INST=SLR.I_LP_INST and SLR.STATUS in ('D','E')
 where SLI.LOAD_PLAN_NAME  in ('BI Apps All Modules LoadPlan_INCR') order by SLR.START_DATE desc;
 
 --- alternative:
 
 SELECT
    SLI.I_LP_INST AS Load_ID,
    SLI.LOAD_PLAN_NAME,
    SLR.STATUS,
    SLR.START_DATE,
    SLR.END_DATE,
    (SLR.END_DATE - SLR.START_DATE) * 24 * 60 AS Total_Duration_Minutes
FROM
    ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI
INNER JOIN
    ODI11GPROD_BIA_ODIREPO.SNP_LPI_RUN SLR
ON
    SLI.I_LP_INST = SLR.I_LP_INST
WHERE 1=1
   -- AND SLR.STATUS = 'D'
    order by SLR.START_DATE desc;

9200243969/6/1/53
9200243969/6/1/53
9200243969/6/1/53
9200254969/4/1/15
9200263969/1/1/21
9200365969/1/1/22
9200243969/6/1/53
9200243969/6/1/53


9200171969 --> RHM_PLP_INVENTORYTURNFACT_LOAD

9200243969  --> RHM_PLP_SALESCYCLELINESFACT_LOAD

9200365969 --> RHM_PLP_PURCHASECYCLELINESAGGREGATE_DERIVE

9200254969 --> RHM_SIL_HJ_TRANSACTION_FACT


--ODI11GPROD_BIA_ODIREPO.SNP_LP_INST
 
 
 --RUN ETL Loads with session info:
 ---------------------------------------------------
select SLI.I_LP_INST as Load_ID ,SLI.LOAD_PLAN_NAME,SS.SESS_NO,
TO_CHAR(SLSL.START_DATE,'DD-MON-YYYY:HH24:MI:SS') SESSION_START_DATE ,
TO_CHAR(SLSL.END_DATE,'DD-MON-YYYY:HH24:MI:SS') SESSION_END_DATE,
SLSL.SESS_NO,SS.SESS_NAME,SLSL.STATUS,SLSL.DURATION,
(nvl(SLSL.END_DATE,sysdate)-SLSL.START_DATE)*1440 "Time Spent(MINS)"
from ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI
inner join  ODI11GPROD_BIA_ODIREPO.SNP_LPI_STEP_LOG SLSL
on SLI.I_LP_INST=SLSL.I_LP_INST and SLSL.STATUS='R'
inner join  ODI11GPROD_BIA_ODIREPO.SNP_SESSION SS on SLSL.SESS_NO=SS.SESS_NO
where SLSL.START_DATE > sysdate-1;

----DB Session and sql  info

SELECT s.inst_id,
       s.sid,
       s.serial#,
       s.sql_id,
       q.child_number,
       ROUND(q.cpu_time/1000000/60, 2)     AS cpu_min,
       ROUND(q.elapsed_time/1000000/60, 2) AS elapsed_min,
       q.executions,
       q.rows_processed,
       s.username,
       s.status,
       s.machine,
       s.action,
       DBMS_LOB.SUBSTR(q.sql_text, 4000, 1) AS sql_text
FROM gv$session s
JOIN gv$sql q
  ON s.sql_id           = q.sql_id
AND s.inst_id          = q.inst_id
AND s.sql_child_number = q.child_number
WHERE s.sql_id   IS NOT NULL
  AND s.username = 'OBI_DW'
  AND s.status   = 'ACTIVE'
  AND s.action   LIKE '%&lp_sess_no%'
--  AND (
--        UPPER(DBMS_LOB.SUBSTR(q.sql_text, 4000, 1)) LIKE '%INSERT%'
--     OR UPPER(DBMS_LOB.SUBSTR(q.sql_text, 4000, 1)) LIKE '%CREATE%'
--      )
ORDER BY q.cpu_time DESC
FETCH FIRST 100 ROWS ONLY;

------ETL Session sub steps and timing

select SLI.I_LP_INST as Load_ID ,SLI.LOAD_PLAN_NAME,
--TO_CHAR(SLSL.START_DATE,'DD-MON-YYYY:HH24:MI:SS') SESSION_START_DATE ,
--TO_CHAR(SLSL.END_DATE,'DD-MON-YYYY:HH24:MI:SS') SESSION_END_DATE,
SLSL.SESS_NO,SS.SESS_NAME,SLSL.STATUS,SSTL.TASK_NAME3,
TO_CHAR(SSTL.TASK_BEG,'DD-MON-YYYY:HH24:MI:SS') TASK_START_DATE,
TO_CHAR(SSTL.TASK_END,'DD-MON-YYYY:HH24:MI:SS') TASK_START_DATE,
(nvl(SSTL.TASK_END,sysdate)-SSTL.TASK_BEG)*1440 "Total TASK  (MINS)",
SSTL.TASK_DUR "TASK_DUR(Sec)",
(nvl(SLSL.END_DATE,sysdate)-SLSL.START_DATE)*1440 "Total Session (MINS)"
from ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI
inner join  ODI11GPROD_BIA_ODIREPO.SNP_LPI_STEP_LOG SLSL
on SLI.I_LP_INST=SLSL.I_LP_INST
--and SLSL.STATUS='D'
--and SLSL.SESS_NO='6433713969'
inner join  ODI11GPROD_BIA_ODIREPO.SNP_SESSION SS on SLSL.SESS_NO=SS.SESS_NO
inner join ODI11GPROD_BIA_ODIREPO.SNP_SESS_TASK_LOG SSTL on SLSL.SESS_NO=SSTL.SESS_NO
/*WHERE  SS.SESS_NAME in ('RHM_SIL_GLREVENUEFACT_DIFFMANLOAD','RHM_PLP_INVENTORYTURNFACT_LOAD','SILOS_SIL_APTRANSACTIONFACT_GRFAGGRPREDERIVE',
'RHM_SIL_HJ_TRANSACTION_FACT','RHM_SIL_GLBALANCEFACT','RHM_SIL_INVENTORYAGINGFACT_CLOSE','RHM_SIL_INVENTORYAGINGFACT','RHM_COST_LKUP_SDE_CST_ITEM_COSTS') */
where  1=1 --SLI.I_LP_INST in ('31719969') 
--and SS.SESS_NAME='RHM_EEMAX_COMMISSION_UPDATE'
--and SS.SESS_NAME like '%CLOSE%'
and SLI.I_LP_INST=48903969
--and SLI.I_LP_INST like '48903969%'
and SLSL.SESS_NO=9309489969
--order by 9 desc
--and  SSTL.TASK_BEG > sysdate -1
--TO_CHAR(SSTL.TASK_BEG,'DD-MON-YYYY:HH24:MI:SS')
--and   TRUNC(SSTL.TASK_BEG) = TO_DATE('04/14/2026', 'MM/DD/YYYY')
--AND SESS_BEG >= TRUNC(SYSDATE-1)
--  AND SESS_BEG < TRUNC(SYSDATE)
--and SLSL.START_DATE > sysdate -1
ORDER BY TRUNC(SSTL.TASK_BEG) desc;

SELECT NUM_ROWS, BLOCKS
FROM DBA_TABLES
WHERE TABLE_NAME='W_SALES_CYCLE_LINE_F';

SELECT COUNT(DISTINCT XACT_TYPE_WID) FROM W_SALES_CYCLE_LINE_F;

select * from ODI11GPROD_BIA_ODIREPO.SNP_SESSION where SESS_NAME='RHM_SIL_INVENTORYAGINGFACT_CLOSE';

SELECT 
   *
FROM ODI11GPROD_BIA_ODIREPO.SNP_SESSION
WHERE SESS_NAME = 'RHM_SIL_SALESORDERLINESFACT'
AND SESS_BEG >= TRUNC(SYSDATE-2)
--ORDER BY SESS_BEG DESC;

SELECT
    ts.tablespace_name,
    ts.status AS tb_status,
    ts.encrypted AS is_encrypted,
    --et.masterkeyid,
    et.encryptionalg,
    et.status AS encryption_status
FROM dba_tablespaces ts
LEFT JOIN v$tablespace vt
    ON ts.tablespace_name = vt.name
LEFT JOIN v$encrypted_tablespaces et
    ON vt.ts# = et.ts#
WHERE ts.contents  in ('TEMPORARY','UNDO')
and ts.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')


--Session monitoring with session name: (compare with previosu time)
----------------------------------------------------------------------
select SESS_NO,SESS_NAME,SCEN_VERSION,
TO_CHAR(SESS_BEG,'DD-MON-YYYY:HH24:MI:SS') SESSION_START_DATE ,
TO_CHAR(SESS_END,'DD-MON-YYYY:HH24:MI:SS') SESSION_END_DATE,
SESS_DUR,
(nvl(SESS_END,sysdate)-SESS_BEG)*1440 "Time Spent(MINS)",
DECODE(SESS_STATUS, 'D', 'Done', 'E', 'Error', 'M', 'Warning', 'Q', 'Queued', 'R', 'Running', 'W', 'Waiting',SESS_STATUS) AS SESS_STATUS_DESC,
FIRST_DATE,LAST_DATE 
from ODI11GPROD_BIA_ODIREPO.SNP_SESSION  
where SESS_NAME='RHM_EEMAX_COMMISSION_UPDATE' order by SESS_BEG desc;


SLI.I_LP_INST as Load_ID

---Including task name for step:
---------------------------------
select SLI.I_LP_INST as Load_ID ,SLI.LOAD_PLAN_NAME,
TO_CHAR(SLSL.START_DATE,'DD-MON-YYYY:HH24:MI:SS') SESSION_START_DATE ,
TO_CHAR(SLSL.END_DATE,'DD-MON-YYYY:HH24:MI:SS') SESSION_END_DATE,
SLSL.SESS_NO,SS.SESS_NAME,SLSL.STATUS,SSTL.TASK_NAME3,SLSL.DURATION,
(nvl(SLSL.END_DATE,sysdate)-SLSL.START_DATE)*1440 "Time Spent(MINS)"
from ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI
inner join  ODI11GPROD_BIA_ODIREPO.SNP_LPI_STEP_LOG SLSL
on SLI.I_LP_INST=SLSL.I_LP_INST --and SLSL.STATUS='R'
inner join  ODI11GPROD_BIA_ODIREPO.SNP_SESSION SS on SLSL.SESS_NO=SS.SESS_NO
inner join ODI11GPROD_BIA_ODIREPO.SNP_SESS_TASK_LOG SSTL on SLSL.SESS_NO=SSTL.SESS_NO
where 1=1
  AND SS.SESS_NAME ='9309489969';


--ALL steps for paarticular load: 

--I_LP_INST -- Instance ID(Plan_ID)
-----------------------------------------
 select SLSL.I_LP_INST,SLSL.SESS_NO,SS.SESS_NAME,SLSL.Status,SLSL.START_DATE,SLSL.END_DATE,
 (nvl(SLSL.END_DATE,sysdate)-SLSL.START_DATE)* 24 * 60 "Time Spent(MINS)" 
 from ODI11GPROD_BIA_ODIREPO.SNP_SESSION SS 
 inner join ODI11GPROD_BIA_ODIREPO.SNP_LPI_STEP_LOG SLSL
 on SLSL.I_LP_INST in ('48874969') and SLSL.Status in ('D','A','R') --and SLSL.sess_no like '%1%' 
 --and SS.SESS_NAME like '%GATHER%'
 and SLSL.SESS_NO=SS.SESS_NO order by 7 desc;


--------Load Plan with Hirearchy steps

SELECT
  LP.I_LOAD_PLAN,
  LP.LOAD_PLAN_NAME,
  LPI.I_LP_INST,
  LPLOG.NB_RUN,
  ROW_NUMBER() OVER (ORDER BY SH.STEP_PATH) - 1 AS LPSTEPNUM,
  SH.LVL,
  LPAD(' ', 2 * SH.LVL - 1,' ') || LPS.LP_STEP_NAME STEP_HIERARCHY,
  --LPLOG.STATUS,
  CASE 
  WHEN LPLOG.STATUS IS NULL THEN 'Not Started'
  WHEN LPLOG.STATUS = 'D' THEN 'Done'
  WHEN LPLOG.STATUS = 'E' THEN 'Error'
  WHEN LPLOG.STATUS = 'M' THEN 'Warning'
  WHEN LPLOG.STATUS = 'R' THEN 'Running'
  WHEN LPLOG.STATUS = 'W' THEN 'Waiting'
  WHEN LPLOG.STATUS = 'A' THEN 'Already Done'
  ELSE LPLOG.STATUS
END AS STATUS,
  LPLOG.NB_ROW,
  LPLOG.SESS_NO,
  -- ? LIVE DURATION (handles running steps)
  CASE 
    WHEN LPLOG.SESS_NO IS NOT NULL THEN 
      TRUNC((NVL(SESS.SESS_END, SYSDATE) - SESS.SESS_BEG)*24*60)||':'||
      LPAD(TRUNC(MOD((NVL(SESS.SESS_END, SYSDATE) - SESS.SESS_BEG)*24*60*60,60)),2,'0')
    ELSE 
      TRUNC((NVL(LPLOG.END_DATE, SYSDATE) - LPLOG.START_DATE)*24*60)||':'||
      LPAD(TRUNC(MOD((NVL(LPLOG.END_DATE, SYSDATE) - LPLOG.START_DATE)*24*60*60,60)),2,'0')
  END DURATION_FORMATTED,
  CASE 
    WHEN LPLOG.SESS_NO IS NOT NULL THEN 
      TRUNC((NVL(SESS.SESS_END, SYSDATE) - SESS.SESS_BEG)*24*60*60)
    ELSE 
      TRUNC((NVL(LPLOG.END_DATE, SYSDATE) - LPLOG.START_DATE)*24*60*60)
  END DURATION_SEC,
  TO_CHAR(NVL(SESS.SESS_BEG, LPLOG.START_DATE),'MM-DD-YYYY HH24:MI:SS') START_TIME,
  TO_CHAR(NVL(SESS.SESS_END, LPLOG.END_DATE),'MM-DD-YYYY HH24:MI:SS') END_TIME,
  NVL(LPS.SCEN_NAME,LPS.VAR_NAME) SCEN_VAR_NAME,
  LPS.LP_STEP_TYPE,
  CASE WHEN LPS.IND_ENABLED =1 THEN 'Y' ELSE 'N' END IS_ENABLED,
  LPS.I_LP_STEP,
  LPS.PAR_I_LP_STEP
FROM ODI11GPROD_BIA_ODIREPO.SNP_LOAD_PLAN LP
JOIN ODI11GPROD_BIA_ODIREPO.SNP_LP_INST LPI
  ON LPI.I_LOAD_PLAN = LP.I_LOAD_PLAN
JOIN (
    SELECT 
        I_LOAD_PLAN,
        I_LP_STEP,
        LP_STEP_NAME,
        STEP_PATH,
        LVL,
        STEP_ORDER
    FROM (
        SELECT  
            I_LOAD_PLAN,
            I_LP_STEP,
            LP_STEP_NAME,
            SYS_CONNECT_BY_PATH(LP_STEP_NAME, '->') STEP_PATH,
            SYS_CONNECT_BY_PATH(LP_STEP_TYPE, '->') STEP_TYPE_PATH,
            LEVEL LVL,
            STEP_ORDER
        FROM ODI11GPROD_BIA_ODIREPO.SNP_LP_STEP
        START WITH PAR_I_LP_STEP IS NULL
        CONNECT BY PRIOR I_LP_STEP = PAR_I_LP_STEP
        AND PRIOR I_LOAD_PLAN = I_LOAD_PLAN
        ORDER SIBLINGS BY STEP_ORDER
    )
    WHERE SUBSTR(STEP_TYPE_PATH,1,4) != '->EX'
) SH
  ON LP.I_LOAD_PLAN = SH.I_LOAD_PLAN
LEFT JOIN ODI11GPROD_BIA_ODIREPO.SNP_LPI_STEP LPS
  ON LPI.I_LP_INST = LPS.I_LP_INST
  AND LPS.I_LP_STEP = SH.I_LP_STEP
LEFT JOIN ODI11GPROD_BIA_ODIREPO.SNP_LPI_STEP_LOG LPLOG
  ON LPLOG.I_LP_INST = LPS.I_LP_INST
  AND LPLOG.I_LP_STEP = LPS.I_LP_STEP
--LEFT JOIN ODI11GPROD_BIA_ODIREPO.SNP_LPI_STEP_LOG LPLOG
--  ON LPLOG.I_LP_INST = LPS.I_LP_INST
--  AND LPLOG.I_LP_STEP = LPS.I_LP_STEP
--  AND LPLOG.NB_RUN = (
--        SELECT MAX(NB_RUN)
--        FROM ODI11GPROD_BIA_ODIREPO.SNP_LPI_RUN
--        WHERE I_LP_INST = LPI.I_LP_INST
--  )
LEFT JOIN ODI11GPROD_BIA_ODIREPO.SNP_SESSION SESS
  ON LPLOG.SESS_NO = SESS.SESS_NO
WHERE LPI.I_LP_INST = &LOAD_PLAN_INSTANCE_ID
-- ? Latest Run
AND LPLOG.NB_RUN = (
    SELECT MAX(NB_RUN)
    FROM ODI11GPROD_BIA_ODIREPO.SNP_LPI_RUN
    WHERE I_LP_INST = LPI.I_LP_INST
)
-- ? ONLY RUNNING STEPS
--AND LPLOG.STATUS IN ('R')
--AND (
-- (NVL(LPLOG.END_DATE, SYSDATE) - LPLOG.START_DATE)*24*60
--) > 20
--AND LPS.LP_STEP_TYPE='RS'
-- ? Optional: filter specific phase
AND SH.STEP_PATH LIKE '%Warehouse Load Phase%'
ORDER BY SH.STEP_PATH;
 
 
 select SLI.I_LP_INST as Load_ID ,SLI.LOAD_PLAN_NAME,SS.SESS_NO,
TO_CHAR(SLSL.START_DATE,'DD-MON-YYYY:HH24:MI:SS') SESSION_START_DATE ,
TO_CHAR(SLSL.END_DATE,'DD-MON-YYYY:HH24:MI:SS') SESSION_END_DATE,
SLSL.SESS_NO,SS.SESS_NAME,SLSL.STATUS,SLSL.DURATION,
(nvl(SLSL.END_DATE,sysdate)-SLSL.START_DATE)*1440 "Time Spent(MINS)"
from ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI
inner join  ODI11GPROD_BIA_ODIREPO.SNP_LPI_STEP_LOG SLSL
on SLI.I_LP_INST=SLSL.I_LP_INST and SLSL.STATUS in ('R','D') and SLSL.I_LP_INST in ('48222969')
inner join  ODI11GPROD_BIA_ODIREPO.SNP_SESSION SS on SLSL.SESS_NO=SS.SESS_NO
where SLSL.START_DATE > sysdate-7;
 
 --- working one with more details:
 
 SELECT 
    SSL.I_LP_INST AS Load_ID,
    SSL.I_LP_STEP AS Step_ID,
    SSL.NB_RUN AS Run_Number,
    SSL.START_DATE AS Step_Start,
    SSL.END_DATE AS Step_End,
    (NVL(SSL.END_DATE, SYSDATE) - SSL.START_DATE) * 1440 AS "Time Spent (MINS)",
    SSL.STATUS AS Step_Status,
    SSL.RETURN_CODE,
    SSL.SESS_NO AS Session_Number,
    SSL.NB_ROW AS Rows_Processed,
    SSL.NB_INS AS Inserts,
    SSL.NB_UPD AS Updates,
    SSL.NB_DEL AS Deletes,
    SSL.NB_ERR AS Errors,
    SSL.ERROR_MESSAGE,
    SS.SESS_NAME AS Session_Name
FROM 
    ODI11GPROD_BIA_ODIREPO.SNP_LPI_STEP_LOG SSL
JOIN
    ODI11GPROD_BIA_ODIREPO.SNP_SESSION SS ON SSL.SESS_NO = SS.SESS_NO
WHERE 
    SSL.I_LP_INST = '48222969'
   -- and SSL.STATUS in ('D','R') --order by SSL.START_DATE desc;
    
 ---- more details like source table... scenario .. load time
 
 SELECT SLSL.I_LP_INST,SLI.Load_plan_name as "Load Plan Name",
      --SUBSTR(SLR.CONTEXT_CODE, 9, 5) AS "Source System",
      SLS.LP_STEP_NAME AS "Target Table",
      SLS.scen_name as "scenario name",
      SLSL.STATUS as "Status",
     TRUNC(SUM(SSTL.TASK_DUR) / 3600) || ':' ||
             LPAD(TRUNC(MOD(SUM(SSTL.TASK_DUR), 3600) / 60), 2, 0) || 
            ':' || LPAD(MOD(SUM(SSTL.TASK_DUR), 60), 2, 0) AS "Load Time"
     ,(SLSL.End_date - SLSL.start_date) * 24 * 60 AS Total_Duration_Minutes       
     , SST.SESS_NO AS "Session Number"
     , SLSL.start_date as "Start Time"
     , SLSL.End_date as "End Time"
     , sum(sstl.nb_ins) as "Rows Inserted"
     , sum(sstl.nb_upd) as "Rows Updated"
     , sum(sstl.nb_del) as "Rows Deleted"
     , sum(sstl.nb_err) as "Rows Errors"
     , case 
        when (sum(sstl.nb_ins) + sum(sstl.nb_upd)) > 0 then trunc(sum(sstl.task_dur)/(sum(sstl.nb_ins) + sum(sstl.nb_upd)) ,4)
        else 0
       end as "Throughput"
  FROM ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI
  JOIN ODI11GPROD_BIA_ODIREPO.SNP_LPI_STEP SLS 
                  ON SLI.I_LP_INST = SLS.I_LP_INST
  JOIN ODI11GPROD_BIA_ODIREPO.SNP_LPI_STEP_LOG SLSL
        ON SLS.I_LP_STEP = SLSL.I_LP_STEP
      AND SLS.I_LP_INST = SLSL.I_LP_INST
  JOIN ODI11GPROD_BIA_ODIREPO.SNP_SESS_TASK SST
            ON SST.SESS_NO = SLSL.SESS_NO
  JOIN ODI11GPROD_BIA_ODIREPO.SNP_SESS_TASK_LOG SSTL
            ON SSTL.SCEN_TASK_NO = SST.SCEN_TASK_NO 
           AND SST.SESS_NO = SSTL.SESS_NO
  JOIN ODI11GPROD_BIA_ODIREPO.SNP_LPI_RUN  SLR 
            on SLI.I_LP_INST = SLR.I_LP_INST
 WHERE (1=1)
  AND SLSL.I_LP_INST = 48728969
   AND SLS.LP_STEP_TYPE = 'RS'
    --AND SLSL.STATUS IN ('R') 
    --AND SLSL.STATUS IN ('R')
   --AND SLSL.START_DATE > sysdate-10
   --AND SLS.scen_name like 'SDE_ORAR122_ADAPTOR_SDE_ORA_EMPLOYEEDIMENSION_NONEMP_PRIMARY%'
 GROUP BY SUBSTR(SLR.CONTEXT_CODE, 9, 5),
           SLSL.I_LP_INST,SLSL.start_date,SLSL.end_date,SLI.load_plan_name,
          SLS.scen_name,SLS.LP_STEP_NAME, SST.SESS_NO, SLSL.STATUS;   
 
 
--for all running and done
--------------------------
select SLSL.SESS_NO,SS.SESS_NAME,SLSL.START_DATE,SLSL.END_DATE,SLSL.Status,
 (nvl(SLSL.END_DATE,sysdate)-SLSL.START_DATE)*1440 "Time Spent(MINS)" 
 from ODI11GPROD_BIA_ODIREPO.SNP_SESSION SS 
 inner join ODI11GPROD_BIA_ODIREPO.SNP_LPI_STEP_LOG SLSL
 on SLSL.I_LP_INST='48237969' and SLSL.Status in ('D','R') and SLSL.sess_no like '%1%' and SLSL.SESS_NO=SS.SESS_NO order by 6 desc;
 

--About last updated ETL load:
--=========================================
select * from ODI11GPROD_BIA_ODIREPO.SNP_LOAD_PLAN where LOAD_PLAN_NAME='BI Apps All Modules LoadPlan_INCR';

select I_LOAD_PLAN,LOAD_PLAN_NAME,INT_VERSION,FIRST_DATE,
FIRST_USER,LAST_DATE,LAST_USER
 from ODI11GPROD_BIA_ODIREPO.SNP_LOAD_PLAN where LOAD_PLAN_NAME='BI Apps All Modules LoadPlan_INCR';
 
 
 
 -------------------------DB Session monitoring---------------------------------
 
  SELECT 
        --ROUND (BITAND (s.ownerid, 65535))               parent_session_sid,
         --ROUND (BITAND (s.ownerid, 16711680) / 65536)    parent_session_instid,
         --RAWTOHEX (SADDR)                                AS saddr,
         s.SID,
         s.SERIAL#,
         --s.AUDSID,
         --RAWTOHEX (PADDR)                                AS paddr,
         s.USER#,
         s.USERNAME,
         to_char(s.logon_time,'DD-MON-YYYY HH24:MI:SS') logon_time,
         --s.COMMAND,
         --s.OWNERID,
         --s.TADDR,
         s.LOCKWAIT,
         s.STATUS,
         s.SERVER,
         s.SCHEMA#,
         s.SCHEMANAME,
         s.OSUSER,
         s.PROCESS,
         s.MACHINE,
         s.PORT,
         s.TERMINAL,
         UPPER (s.PROGRAM)                               PROGRAM,
         s.TYPE,
         s.SQL_ADDRESS,
         s.SQL_HASH_VALUE,
         s.SQL_ID,
         s.SQL_CHILD_NUMBER,
         s.SQL_EXEC_START,
         s.SQL_EXEC_ID,
         s.PREV_SQL_ADDR,
         s.PREV_HASH_VALUE,
         s.PREV_SQL_ID,
         s.PREV_CHILD_NUMBER,
         s.PREV_EXEC_START,
         s.PREV_EXEC_ID,
         s.PLSQL_ENTRY_OBJECT_ID,
         s.PLSQL_ENTRY_SUBPROGRAM_ID,
         s.PLSQL_OBJECT_ID,
         s.PLSQL_SUBPROGRAM_ID,
         s.MODULE,
         s.MODULE_HASH,
         s.ACTION,
         s.ACTION_HASH,
         s.CLIENT_INFO,
         s.FIXED_TABLE_SEQUENCE,
         s.ROW_WAIT_OBJ#,
         s.ROW_WAIT_FILE#,
         s.ROW_WAIT_BLOCK#,
         s.ROW_WAIT_ROW#,
         s.TOP_LEVEL_CALL#,
         s.LOGON_TIME,
         s.LAST_CALL_ET,
         s.PDML_ENABLED,
         s.FAILOVER_TYPE,
         s.FAILOVER_METHOD,
         s.FAILED_OVER,
         s.RESOURCE_CONSUMER_GROUP,
         s.PDML_STATUS,
         s.PDDL_STATUS,
         s.PQ_STATUS,
         s.CURRENT_QUEUE_DURATION,
         s.CLIENT_IDENTIFIER,
         s.BLOCKING_SESSION_STATUS,
         s.BLOCKING_INSTANCE,
         s.BLOCKING_SESSION,
         s.FINAL_BLOCKING_SESSION_STATUS,
         s.FINAL_BLOCKING_INSTANCE,
         s.FINAL_BLOCKING_SESSION,
         s.SEQ#,
         s.EVENT#,
         s.EVENT,
         s.P1TEXT,
         s.P1,
         s.P1RAW,
         s.P2TEXT,
         s.P2,
         s.P2RAW,
         s.P3TEXT,
         s.P3,
         s.P3RAW,
         s.WAIT_CLASS_ID,
         s.WAIT_CLASS#,
         s.WAIT_CLASS,
         s.WAIT_TIME,
         s.SECONDS_IN_WAIT,
         s.STATE,
         s.WAIT_TIME_MICRO,
         s.TIME_REMAINING_MICRO,
         s.TIME_SINCE_LAST_WAIT_MICRO,
         s.SERVICE_NAME,
         s.SQL_TRACE,
         s.SQL_TRACE_WAITS,
         s.SQL_TRACE_BINDS,
         s.SQL_TRACE_PLAN_STATS,
         s.SESSION_EDITION_ID,
         s.CREATOR_ADDR,
         s.CREATOR_SERIAL#,
         s.ECID,
         s.SQL_TRANSLATION_PROFILE_ID,
         s.PGA_TUNABLE_MEM,
         s.CON_ID,
         s.EXTERNAL_NAME
    FROM gV$SESSION S
   WHERE (    (s.USERNAME IS NOT NULL)
          AND (s.USERNAME <> 'DBSNMP') 
          AND (NVL (s.osuser, 'x') <> 'SYSTEM')
          AND (s.TYPE <> 'BACKGROUND')
		  --AND (s.STATUS = 'ACTIVE')
		  --AND (s.USERNAME = 'OBI_DW')
		  AND (s.USERNAME = 'OBIEBS')
		  )
ORDER BY "USERNAME", OWNERID, "STATUS" DESC;


 SELECT 
        --ROUND (BITAND (s.ownerid, 65535))               parent_session_sid,
         --ROUND (BITAND (s.ownerid, 16711680) / 65536)    parent_session_instid,
         --RAWTOHEX (SADDR)                                AS saddr,
         S.INST_ID,
         s.SID,
         s.SERIAL#,
         --s.AUDSID,
         --RAWTOHEX (PADDR)                                AS paddr,
         s.USER#,
         s.USERNAME,
         to_char(s.logon_time,'DD-MON-YYYY HH24:MI:SS') logon_time,
         --s.COMMAND,
         --s.OWNERID,
         --s.TADDR,
         s.LOCKWAIT,
         s.STATUS,
         s.SERVER,
         s.SCHEMA#,
         s.SCHEMANAME,
         s.OSUSER,
         s.PROCESS,
         s.MACHINE,
         s.PORT,
         s.TERMINAL,
         UPPER (s.PROGRAM)                               PROGRAM,
         s.TYPE,
         s.SQL_ADDRESS,
         s.SQL_HASH_VALUE,
         s.SQL_ID,
         s.ACTION,
         s.SQL_CHILD_NUMBER,
         s.SQL_EXEC_START,
         s.SQL_EXEC_ID,
         s.PREV_SQL_ADDR,
         s.PREV_HASH_VALUE,
         s.PREV_SQL_ID,
         s.PREV_CHILD_NUMBER,
         s.PREV_EXEC_START,
         s.PREV_EXEC_ID,
         s.PLSQL_ENTRY_OBJECT_ID,
         s.PLSQL_ENTRY_SUBPROGRAM_ID,
         s.PLSQL_OBJECT_ID,
         s.PLSQL_SUBPROGRAM_ID,
         s.MODULE,
         s.MODULE_HASH,
         s.ACTION,
         s.ACTION_HASH,
         s.CLIENT_INFO,
         s.FIXED_TABLE_SEQUENCE,
         s.ROW_WAIT_OBJ#,
         s.ROW_WAIT_FILE#,
         s.ROW_WAIT_BLOCK#,
         s.ROW_WAIT_ROW#,
         s.TOP_LEVEL_CALL#,
         s.LOGON_TIME,
         s.LAST_CALL_ET,
         s.PDML_ENABLED,
         s.FAILOVER_TYPE,
         s.FAILOVER_METHOD,
         s.FAILED_OVER,
         s.RESOURCE_CONSUMER_GROUP,
         s.PDML_STATUS,
         s.PDDL_STATUS,
         s.PQ_STATUS,
         s.CURRENT_QUEUE_DURATION,
         s.CLIENT_IDENTIFIER,
         s.BLOCKING_SESSION_STATUS,
         s.BLOCKING_INSTANCE,
         s.BLOCKING_SESSION,
         s.FINAL_BLOCKING_SESSION_STATUS,
         s.FINAL_BLOCKING_INSTANCE,
         s.FINAL_BLOCKING_SESSION,
         s.SEQ#,
         s.EVENT#,
         s.EVENT,
         s.P1TEXT,
         s.P1,
         s.P1RAW,
         s.P2TEXT,
         s.P2,
         s.P2RAW,
         s.P3TEXT,
         s.P3,
         s.P3RAW,
         s.WAIT_CLASS_ID,
         s.WAIT_CLASS#,
         s.WAIT_CLASS,
         s.WAIT_TIME,
         s.SECONDS_IN_WAIT,
         s.STATE,
         s.WAIT_TIME_MICRO,
         s.TIME_REMAINING_MICRO,
         s.TIME_SINCE_LAST_WAIT_MICRO,
         s.SERVICE_NAME,
         s.SQL_TRACE,
         s.SQL_TRACE_WAITS,
         s.SQL_TRACE_BINDS,
         s.SQL_TRACE_PLAN_STATS,
         s.SESSION_EDITION_ID,
         s.CREATOR_ADDR,
         s.CREATOR_SERIAL#,
         s.ECID,
         s.SQL_TRANSLATION_PROFILE_ID,
         s.PGA_TUNABLE_MEM,
         s.CON_ID,
         s.EXTERNAL_NAME
    FROM GV$SESSION S
   WHERE (    (s.USERNAME IS NOT NULL)
          AND (s.USERNAME <> 'DBSNMP') 
          AND (NVL (s.osuser, 'x') <> 'SYSTEM')
          AND (s.TYPE <> 'BACKGROUND')
		  AND (s.STATUS = 'ACTIVE')
		  AND (s.USERNAME = 'OBI_DW')
		  --AND (s.USERNAME = 'OBIEBS')
		  --AND Action like '%9200171969%'
		  AND s.service_name like '%ETL%'
		  )
ORDER BY "USERNAME", OWNERID, "STATUS" DESC;


9200243969

SELECT COUNT(*)/2 AS DOP
FROM GV$PX_SESSION;

SELECT EVENT, COUNT(*)
FROM gV$SESSION
WHERE USERNAME='OBI_DW'
GROUP BY EVENT;

9182503969

select * from gv$session where username='OBI_DW' and status='ACTIVE'  and Action like '%9199978969%' --<<Action = Session_id of load>>;

----------query from v$active_session_history---

select sql_id,sql_fulltext from v$sql where sql_fulltext like '%XXOBIEE_LKP_CST_COSTS%';

select * from gv$sql where sql_id='3h20yh2mn16ss';

select INST_ID, sid, serial#, action, program, client_identifier, to_char(logon_time,'DD-MON-YYYY HH24:MI:SS') logon_time, sql_id, status from gv$session where sql_id='f029bqnhd766x';

select * from gV$ACTIVE_SESSION_HISTORY where sql_id='3h20yh2mn16ss';

SELECT SESSION_ID, program, module , sample_time, event,sql_id ,TIME_WAITED,SESSION_STATE 
FROM  gv$active_session_history
WHERE sql_id='dnp73qgy8g3rd';

------BOM Module EBS Side-------------------

--Total number of BOM'S to explode
select count(1) from BOM.OBIA_W_BOM_HEADER_DS 

-- Count of BOM'S exploded

select count(distinct TOP_BILL_SEQUENCE_ID) from BOM.OBIA_BOM_EXPLOSION

--single query for BOM Exploded

SELECT 
  A.CNT_HEADER,
  B.CNT_EXPLOSION,
  (A.CNT_HEADER - B.CNT_EXPLOSION) AS DIFFERENCE
FROM 
  (SELECT COUNT(1) CNT_HEADER 
   FROM BOM.OBIA_W_BOM_HEADER_DS) A,
  (SELECT COUNT(DISTINCT TOP_BILL_SEQUENCE_ID) CNT_EXPLOSION 
   FROM BOM.OBIA_BOM_EXPLOSION) B;


---- More Queries:

--- To check all loads with their statuses, start/end dates, and total duration
SELECT
    SLI.I_LP_INST AS Load_ID,
    SLI.LOAD_PLAN_NAME,
    SLR.STATUS,
    SLR.START_DATE,
    SLR.END_DATE,
    (SLR.END_DATE - SLR.START_DATE) * 24 * 60 AS Total_Duration_Minutes
FROM
    ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI
INNER JOIN
    ODI11GPROD_BIA_ODIREPO.SNP_LPI_RUN SLR
ON
    SLI.I_LP_INST = SLR.I_LP_INST order by SLR.START_DATE desc;


-----Query to monitor loads with their statuses, start/end dates, and total duration within the last 24 hours:

SELECT
    SLI.I_LP_INST AS Load_ID,
    SLI.LOAD_PLAN_NAME,
    SLR.STATUS,
    SLR.START_DATE,
    SLR.END_DATE,
    (SLR.END_DATE - SLR.START_DATE) * 24 * 60 AS Total_Duration_Minutes
FROM
    ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI
INNER JOIN
    ODI11GPROD_BIA_ODIREPO.SNP_LPI_RUN SLR
ON
    SLI.I_LP_INST = SLR.I_LP_INST
WHERE
    SLR.START_DATE > SYSDATE - 1;


---- Query to monitor loads with their statuses, start/end dates, and total duration that are currently running:

SELECT
    SLI.I_LP_INST AS Load_ID,
    SLI.LOAD_PLAN_NAME,
    SLR.STATUS,
    SLR.START_DATE,
    SLR.END_DATE,
    (SYSDATE - SLR.START_DATE) * 24 * 60 AS Total_Duration_Minutes
FROM
    ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI
INNER JOIN
    ODI11GPROD_BIA_ODIREPO.SNP_LPI_RUN SLR
ON
    SLI.I_LP_INST = SLR.I_LP_INST
WHERE
    SLR.STATUS = 'R';





===========================New for Compare==================================

SELECT 
    SS.SESS_NAME,
    TO_CHAR(TRUNC(SLSL.START_DATE),'DD-MON') AS SESSION_DATE,
    ROUND(SUM((NVL(SLSL.END_DATE, SYSDATE) - SLSL.START_DATE) * 1440),2) AS TIME_SPENT
FROM ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI
JOIN ODI11GPROD_BIA_ODIREPO.SNP_LPI_STEP_LOG SLSL
    ON SLI.I_LP_INST = SLSL.I_LP_INST
JOIN ODI11GPROD_BIA_ODIREPO.SNP_SESSION SS
    ON SLSL.SESS_NO = SS.SESS_NO
WHERE SLSL.STATUS IN ('R','D')
  AND SLI.LOAD_PLAN_NAME = 'BI Apps All Modules LoadPlan_INCR'
  AND SLSL.START_DATE > SYSDATE - 30
GROUP BY SS.SESS_NAME, TRUNC(SLSL.START_DATE)
ORDER BY SS.SESS_NAME, SESSION_DATE;


SET SERVEROUTPUT ON
DECLARE
    v_sql   CLOB;
    v_cols  CLOB;
    v_days  NUMBER := 45;  -- change to 30 if needed
BEGIN
    -- Build dynamic date columns (FIXED)
    SELECT LISTAGG(
           'DATE ''' || TO_CHAR(TRUNC(SYSDATE - LEVEL + 1),'YYYY-MM-DD') || ''' AS "' ||
           TO_CHAR(TRUNC(SYSDATE - LEVEL + 1),'DD-MON') || '"', ','
           ) WITHIN GROUP (ORDER BY LEVEL DESC)
    INTO v_cols
    FROM DUAL
    CONNECT BY LEVEL <= v_days;
    -- Build SQL
    v_sql := '
    SELECT *
    FROM (
        SELECT 
            SS.SESS_NAME,
            TRUNC(SLSL.START_DATE) AS SESSION_DATE,
            ROUND((NVL(SLSL.END_DATE, SYSDATE) - SLSL.START_DATE) * 1440, 2) AS TIME_SPENT
        FROM ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI
        JOIN ODI11GPROD_BIA_ODIREPO.SNP_LPI_STEP_LOG SLSL
            ON SLI.I_LP_INST = SLSL.I_LP_INST
        JOIN ODI11GPROD_BIA_ODIREPO.SNP_SESSION SS
            ON SLSL.SESS_NO = SS.SESS_NO
        WHERE SLSL.STATUS IN (''R'',''D'')
          AND SLI.LOAD_PLAN_NAME = ''BI Apps All Modules LoadPlan_INCR''
          AND SLSL.START_DATE > SYSDATE - ' || v_days || '
    )
    PIVOT (
        SUM(TIME_SPENT)
        FOR SESSION_DATE IN (' || v_cols || ')
    )
    ORDER BY SESS_NAME';
    -- Debug (optional)
    DBMS_OUTPUT.PUT_LINE(v_sql);
    -- Execute
    EXECUTE IMMEDIATE v_sql;
END;
/


   SELECT *
    FROM (
        SELECT 
            SS.SESS_NAME,
            TRUNC(SLSL.START_DATE) AS SESSION_DATE,
            ROUND((NVL(SLSL.END_DATE, SYSDATE) - SLSL.START_DATE) * 1440, 2) AS TIME_SPENT
        FROM ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI
        JOIN ODI11GPROD_BIA_ODIREPO.SNP_LPI_STEP_LOG SLSL
            ON SLI.I_LP_INST = SLSL.I_LP_INST
        JOIN ODI11GPROD_BIA_ODIREPO.SNP_SESSION SS
            ON SLSL.SESS_NO = SS.SESS_NO
        WHERE SLSL.STATUS IN ('R','D')
          AND SLI.LOAD_PLAN_NAME = 'BI Apps All Modules LoadPlan_INCR'
          AND SLSL.START_DATE > SYSDATE - 45
    )
    PIVOT (
        SUM(TIME_SPENT)
        FOR SESSION_DATE IN (DATE '2026-03-16' AS "16-MAR",DATE '2026-03-17' AS "17-MAR",DATE '2026-03-18' AS "18-MAR",DATE '2026-03-19' AS "19-MAR",DATE '2026-03-20' AS "20-MAR",DATE '2026-03-21' AS "21-MAR",DATE '2026-03-22' AS "22-MAR",DATE '2026-03-23' AS "23-MAR",DATE '2026-03-24' AS "24-MAR",DATE '2026-03-25' AS "25-MAR",DATE '2026-03-26' AS "26-MAR",DATE '2026-03-27' AS "27-MAR",DATE '2026-03-28' AS "28-MAR",DATE '2026-03-29' AS "29-MAR",DATE '2026-03-30' AS "30-MAR",DATE '2026-03-31' AS "31-MAR",DATE '2026-04-01' AS "01-APR",DATE '2026-04-02' AS "02-APR",DATE '2026-04-03' AS "03-APR",DATE '2026-04-04' AS "04-APR",DATE '2026-04-05' AS "05-APR",DATE '2026-04-06' AS "06-APR",DATE '2026-04-07' AS "07-APR",DATE '2026-04-08' AS "08-APR",DATE '2026-04-09' AS "09-APR",DATE '2026-04-10' AS "10-APR",DATE '2026-04-11' AS "11-APR",DATE '2026-04-12' AS "12-APR",DATE '2026-04-13' AS "13-APR",DATE '2026-04-14' AS "14-APR",DATE '2026-04-15' AS "15-APR",DATE '2026-04-16' AS "16-APR",DATE '2026-04-17' AS "17-APR",DATE '2026-04-18' AS "18-APR",DATE '2026-04-19' AS "19-APR",DATE '2026-04-20' AS "20-APR",DATE '2026-04-21' AS "21-APR",DATE '2026-04-22' AS "22-APR",DATE '2026-04-23' AS "23-APR",DATE '2026-04-24' AS "24-APR",DATE '2026-04-25' AS "25-APR",DATE '2026-04-26' AS "26-APR",DATE '2026-04-27' AS "27-APR",DATE '2026-04-28' AS "28-APR",DATE '2026-04-29' AS "29-APR")
    )
    ORDER BY SESS_NAME
    

VAR rc REFCURSOR;
DECLARE
    v_sql   CLOB;
    v_cols  CLOB;
    v_days  NUMBER := 15;
BEGIN
    -- Dynamic date columns
    SELECT LISTAGG(
           'DATE ''' || TO_CHAR(TRUNC(SYSDATE - LEVEL + 1),'YYYY-MM-DD') || ''' AS "' ||
           TO_CHAR(TRUNC(SYSDATE - LEVEL + 1),'DD-MON') || '"', ','
           ) WITHIN GROUP (ORDER BY LEVEL DESC)
    INTO v_cols
    FROM DUAL
    CONNECT BY LEVEL <= v_days;
    -- Build SQL
    v_sql := '
    WITH base_data AS (
        SELECT SS.SESS_NAME,
               TRUNC(SLSL.START_DATE) SESSION_DATE,
               ROUND((NVL(SLSL.END_DATE, SYSDATE) - SLSL.START_DATE) * 1440,2) TIME_SPENT,
               DECODE(SS.SESS_STATUS,
                      ''D'',''Done'',
                      ''E'',''Error'',
                      ''M'',''Warning'',
                      ''Q'',''Queued'',
                      ''R'',''Running'',
                      ''W'',''Waiting'',
                      SS.SESS_STATUS) STATUS
        FROM ODI11GPROD_BIA_ODIREPO.SNP_LP_INST SLI
        JOIN ODI11GPROD_BIA_ODIREPO.SNP_LPI_STEP_LOG SLSL
          ON SLI.I_LP_INST = SLSL.I_LP_INST
        JOIN ODI11GPROD_BIA_ODIREPO.SNP_SESSION SS
          ON SLSL.SESS_NO = SS.SESS_NO
        WHERE SLSL.STATUS IN (''R'',''D'')
          AND SLI.LOAD_PLAN_NAME = ''BI Apps All Modules LoadPlan_INCR''
          AND SLSL.START_DATE > SYSDATE - ' || v_days || '
    ),
    pivot_data AS (
        SELECT *
        FROM base_data
        PIVOT (
            SUM(TIME_SPENT)
            FOR SESSION_DATE IN (' || v_cols || ')
        )
    ),
    today_status AS (
        SELECT 
            SESS_NAME,
            MAX(STATUS) AS STATUS
        FROM base_data
        WHERE SESSION_DATE = TRUNC(SYSDATE)
        GROUP BY SESS_NAME
    )
    SELECT p.*,
           NVL(t.STATUS, ''NOT RUN'') AS TODAY_STATUS
    FROM pivot_data p
    LEFT JOIN today_status t
      ON p.SESS_NAME = t.SESS_NAME
    ORDER BY p.SESS_NAME';
    OPEN :rc FOR v_sql;
END;
/
PRINT rc;    