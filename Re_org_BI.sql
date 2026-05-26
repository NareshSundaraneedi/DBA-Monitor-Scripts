SELECT
    t.owner,
    t.table_name,
    ROUND(s.bytes/(1024*1024*1024), 2)                          AS segment_gb,
    ROUND((t.blocks - t.empty_blocks)
           * (SELECT value FROM v$parameter
              WHERE name='db_block_size')/(1024*1024*1024), 2)   AS used_gb,
    ROUND(t.num_rows * t.avg_row_len / (1024*1024*1024), 2)    AS actual_gb,
    ROUND(s.bytes/(1024*1024*1024)
          - t.num_rows * t.avg_row_len / (1024*1024*1024), 2)  AS waste_gb,
    ROUND((1 - (t.num_rows * t.avg_row_len)
              / NULLIF(s.bytes,0)) * 100, 1)           AS waste_pct,
    t.num_rows,
    t.blocks,
    t.empty_blocks,
    t.chain_cnt,
    t.avg_row_len,
    TO_CHAR(t.last_analyzed,'YYYY-MM-DD HH24:MI')     AS last_analyzed,
    m.inserts,
    m.updates,
    m.deletes,
    CASE
      WHEN ROUND((1 - (t.num_rows * t.avg_row_len)
                    / NULLIF(s.bytes,0)) * 100, 1) > 30
           AND m.deletes > 100000 THEN 'HIGH BLOAT + HEAVY DELETE'
      WHEN ROUND((1 - (t.num_rows * t.avg_row_len)
                    / NULLIF(s.bytes,0)) * 100, 1) > 30 THEN 'HIGH BLOAT'
      WHEN t.chain_cnt > 10000                         THEN 'ROW CHAINING'
      WHEN t.empty_blocks > t.blocks * 0.3            THEN 'HIGH HWM WASTE'
      WHEN m.deletes > 500000                         THEN 'HEAVY ETL DELETES'
      ELSE 'MONITOR'
    END                                                AS reorg_reason
FROM
    dba_tables        t
    JOIN dba_segments s ON s.owner = t.owner
                       AND s.segment_name = t.table_name
                       AND s.segment_type = 'TABLE'
    LEFT JOIN dba_tab_modifications m
                       ON m.table_owner = t.owner
                       AND m.table_name = t.table_name                        
WHERE
    t.owner IN ('OBI_DW')  -- ? adjust schemas
    --AND t.table_name in ('W_SALES_INVOICE_LINE_F' ,'W_SALES_ORDER_LINE_F','W_INV_AGING_F','W_AR_XACT_F','W_AP_XACT_F','W_GL_BALANCE_F')
    --AND t.num_rows   > 10000         -- skip trivial tables
    AND t.avg_row_len > 0
    --AND s.bytes      > 10*1048576    -- > 10 MB segments only
--    AND (
--         ROUND((1 - (t.num_rows * t.avg_row_len)
--                   / NULLIF(s.bytes,0)) * 100, 1) > 20   -- >20% waste
--      OR t.chain_cnt  > 5000
--      OR t.empty_blocks > t.blocks * 0.25
--      OR m.deletes    > 100000
--    )
ORDER BY
    waste_gb DESC NULLS LAST
      --waste_pct desc
FETCH FIRST 400 ROWS ONLY;



----

SELECT
    t.owner,
    t.table_name,
    ROUND(s.bytes/ (1024*1024*1024), 2)   AS segment_gb,
    ROUND((t.blocks - t.empty_blocks)
           * (SELECT value FROM v$parameter
              WHERE name='db_block_size')/1/ (1024*1024*1024), 2)    AS used_gb,
    ROUND(t.num_rows * t.avg_row_len / (1024*1024*1024), 2)     AS actual_gb,
    ROUND(s.bytes/ (1024*1024*1024)
          - t.num_rows * t.avg_row_len / (1024*1024*1024), 2)   AS waste_gb,
    ROUND((1 - (t.num_rows * t.avg_row_len)
               / NULLIF(s.bytes,0)) * 100, 1)           AS waste_pct,
    t.num_rows,
    t.blocks,
    t.empty_blocks,
    t.chain_cnt,
    t.avg_row_len,
    TO_CHAR(t.last_analyzed,'YYYY-MM-DD HH24:MI')      AS last_analyzed,
    m.inserts,
    m.updates,
    m.deletes,
    CASE
      WHEN ROUND((1 - (t.num_rows * t.avg_row_len)
                     / NULLIF(s.bytes,0)) * 100, 1) > 30
           AND m.deletes > 100000 THEN 'HIGH BLOAT + HEAVY DELETE'
      WHEN ROUND((1 - (t.num_rows * t.avg_row_len)
                     / NULLIF(s.bytes,0)) * 100, 1) > 30 THEN 'HIGH BLOAT'
      WHEN t.chain_cnt    > 10000                        THEN 'ROW CHAINING'
      WHEN t.empty_blocks > t.blocks * 0.3              THEN 'HIGH HWM WASTE'
      WHEN m.deletes      > 500000                      THEN 'HEAVY ETL DELETES'
      ELSE 'MONITOR'
    END                                                 AS reorg_reason
FROM
    dba_tables   t
    JOIN dba_segments s
        ON  s.owner        = t.owner
        AND s.segment_name = t.table_name
        AND s.segment_type = 'TABLE'
    LEFT JOIN dba_tab_modifications m
        ON  m.table_owner  = t.owner
        AND m.table_name   = t.table_name
WHERE
    t.owner      IN ('OBI_DW')
    AND t.table_name IN (                              -- ? filter here
        'W_SALES_INVOICE_LINE_F',
        'W_SALES_ORDER_LINE_F',
        'W_INV_AGING_F',
        'W_AR_XACT_F',
        'W_AP_XACT_F',
        'W_GL_BALANCE_F'    
    )
    AND t.num_rows    > 10000
    AND t.avg_row_len > 0
    AND s.bytes       > 10*1048576
ORDER BY
    waste_gb DESC NULLS LAST;




--------

-- ============================================================
-- UNIFIED REORG QUERY - NO TEMP TABLE REQUIRED
-- TABLE + LOB (via segment stats) + INDEX + RECYCLEBIN
-- LOB waste: uses actual segment blocks vs extent allocation
-- Run first: EXEC DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO;
-- ============================================================

SET LINES 250 PAGES 200 TRIMOUT ON TRIMSPOOL ON

COL owner          FOR A20
COL object_name    FOR A50
COL object_type    FOR A22
COL segment_gb     FOR 99990.000  HEA "SEG_GB"
COL actual_gb      FOR 99990.000  HEA "ACTUAL_GB"
COL waste_gb       FOR 99990.000  HEA "WASTE_GB"
COL waste_pct      FOR 990.0      HEA "WASTE_%"
COL num_rows       FOR 9999999999 HEA "NUM_ROWS"
COL last_analyzed  FOR A20
COL deletes        FOR 999999999  HEA "DELETES"
COL priority       FOR 99         HEA "PRI"
COL reorg_reason   FOR A30
COL reorg_action   FOR A60

WITH
-- ----------------------------------------------------------------
-- CTE 1: DB block size (avoid repeated subquery in SELECT)
-- ----------------------------------------------------------------
db_block AS (
    SELECT TO_NUMBER(value) AS block_size
    FROM   v$parameter
    WHERE  name = 'db_block_size'
),
-- ----------------------------------------------------------------
-- CTE 2: LOB segment stats from V$SEGMENT_STATISTICS
-- logical_reads proxy for LOB activity
-- physical_reads tells us how much is actually accessed
-- ----------------------------------------------------------------
lob_seg_stats AS (
    SELECT
        owner,
        object_name                                AS segment_name,
        SUM(CASE WHEN statistic_name = 'physical reads'
                 THEN value ELSE 0 END)            AS phys_reads,
        SUM(CASE WHEN statistic_name = 'logical reads'
                 THEN value ELSE 0 END)            AS logical_reads
    FROM
        v$segment_statistics
    WHERE
        object_type = 'LOB'
    GROUP BY
        owner, object_name
),
-- ----------------------------------------------------------------
-- CTE 3: LOB extent map
-- Counts actual used extents vs allocated extents
-- This is the closest to waste without scanning rows
-- ----------------------------------------------------------------
lob_extents AS (
    SELECT
        owner,
        segment_name,
        COUNT(*)                                   AS total_extents,
        SUM(blocks)                                AS total_blocks,
        SUM(bytes)  / (1024*1024*1024)             AS extent_gb
    FROM
        dba_extents
    WHERE
        owner       IN ('OBI_DW','ODI11GPRE_BIA_ODIREPO')  -- << ADJUST
        AND segment_type LIKE 'LOB%'
    GROUP BY
        owner, segment_name
)
-- ================================================================
-- MAIN QUERY
-- ================================================================
SELECT
    owner,
    object_name,
    object_type,
    ROUND(segment_gb,  3)   AS segment_gb,
    ROUND(actual_gb,   3)   AS actual_gb,
    ROUND(waste_gb,    3)   AS waste_gb,
    ROUND(waste_pct,   1)   AS waste_pct,
    num_rows,
    last_analyzed,
    deletes,
    priority,
    reorg_reason,
    reorg_action
FROM (

    -- ------------------------------------------------------------
    -- ARM 1: TABLE SEGMENTS
    -- ------------------------------------------------------------
    SELECT
        t.owner,
        t.table_name                                            AS object_name,
        'TABLE'                                                 AS object_type,
        s.bytes              / (1024*1024*1024)                 AS segment_gb,
        t.num_rows * t.avg_row_len / (1024*1024*1024)           AS actual_gb,
        s.bytes              / (1024*1024*1024)
            - t.num_rows * t.avg_row_len / (1024*1024*1024)     AS waste_gb,
        (1-(t.num_rows*t.avg_row_len / NULLIF(s.bytes,0)))*100  AS waste_pct,
        t.num_rows,
        TO_CHAR(t.last_analyzed,'YYYY-MM-DD HH24:MI')           AS last_analyzed,
        NVL(m.deletes, 0)                                       AS deletes,
        CASE
          WHEN (1-(t.num_rows*t.avg_row_len/NULLIF(s.bytes,0)))*100 > 30
               AND NVL(m.deletes,0) > 100000  THEN 'HIGH BLOAT + HEAVY DELETE'
          WHEN (1-(t.num_rows*t.avg_row_len/NULLIF(s.bytes,0)))*100 > 30
                                              THEN 'HIGH BLOAT'
          WHEN t.chain_cnt    > 10000         THEN 'ROW CHAINING'
          WHEN t.empty_blocks > t.blocks*0.3  THEN 'HIGH HWM WASTE'
          WHEN NVL(m.deletes,0) > 500000      THEN 'HEAVY ETL DELETES'
          WHEN (  UPPER(t.table_name) LIKE '%TMP%'
               OR UPPER(t.table_name) LIKE '%TEMP%'
               OR UPPER(t.table_name) LIKE '%STG%'
               OR UPPER(t.table_name) LIKE 'E$%')
               AND (1-(t.num_rows*t.avg_row_len
                      /NULLIF(s.bytes,0)))*100 > 50
                                              THEN 'STAGING - TRUNCATE'
          ELSE 'MONITOR'
        END                                                     AS reorg_reason,
        CASE
          WHEN (1-(t.num_rows*t.avg_row_len/NULLIF(s.bytes,0)))*100 > 30
               AND NVL(m.deletes,0) > 100000  THEN 1
          WHEN (1-(t.num_rows*t.avg_row_len/NULLIF(s.bytes,0)))*100 > 30
                                              THEN 2
          WHEN t.chain_cnt    > 10000         THEN 2
          WHEN NVL(m.deletes,0) > 500000      THEN 3
          WHEN t.empty_blocks > t.blocks*0.3  THEN 3
          ELSE                                     5
        END                                                     AS priority,
        CASE
          WHEN t.partitioned = 'YES'
                                       THEN 'SHRINK SPACE per PARTITION'
          WHEN  UPPER(t.table_name) LIKE '%TMP%'
             OR UPPER(t.table_name) LIKE 'E$%'
                                       THEN 'TRUNCATE TABLE then MOVE'
          ELSE 'ENABLE ROW MOVEMENT + SHRINK CASCADE'
        END                                                     AS reorg_action
    FROM
        dba_tables   t
        JOIN dba_segments s
            ON  s.owner        = t.owner
            AND s.segment_name = t.table_name
            AND s.segment_type = 'TABLE'
        LEFT JOIN dba_tab_modifications m
            ON  m.table_owner  = t.owner
            AND m.table_name   = t.table_name
    WHERE
        t.owner        IN ('OBI_DW','ODI11GPRE_BIA_ODIREPO')   -- << ADJUST
        AND t.avg_row_len > 0
        AND s.bytes       > 100 * 1024*1024                    -- > 100 MB

    UNION ALL

    -- ------------------------------------------------------------
    -- ARM 2: LOB SEGMENTS
    -- Waste = segment size - (chunk_size * estimated_used_blocks)
    -- used_blocks estimated from DBA_EXTENTS actual allocation
    -- vs DBA_SEGMENTS header allocation
    -- Chunk size tells minimum allocation unit per LOB value
    -- Over-allocation = (allocated_blocks - used_extents*chunk_blocks)
    -- FILTER: only where segment_gb > extent_gb * 1.25 (25% overhead)
    -- ------------------------------------------------------------
    SELECT
        l.owner,
        l.table_name || '.' || l.column_name                   AS object_name,
        CASE WHEN l.securefile = 'YES'
             THEN 'LOB-SECUREFILE'
             ELSE 'LOB-BASICFILE'  END                         AS object_type,
        -- allocated segment size
        s.bytes / (1024*1024*1024)                             AS segment_gb,
        -- actual used: extent map gives real allocated extents
        -- chunk = minimum LOB page size; used as proxy for data density
        ROUND(
            le.total_blocks
            * (SELECT block_size FROM db_block)
            * CASE
                -- SECUREFILE: typically 60-80% utilization when healthy
                WHEN l.securefile = 'YES' THEN 0.75
                -- BASICFILE: chunk-aligned, typically 50-70% when healthy
                ELSE 0.60
              END
            / (1024*1024*1024)
        , 6)                                                   AS actual_gb,
        -- waste = segment - actual proxy
        s.bytes / (1024*1024*1024)
        - ROUND(
            le.total_blocks
            * (SELECT block_size FROM db_block)
            * CASE WHEN l.securefile='YES' THEN 0.75 ELSE 0.60 END
            / (1024*1024*1024)
          , 6)                                                 AS waste_gb,
        -- waste pct
        ROUND((1 - (
            le.total_blocks
            * (SELECT block_size FROM db_block)
            * CASE WHEN l.securefile='YES' THEN 0.75 ELSE 0.60 END
            / NULLIF(s.bytes, 0)
        )) * 100, 1)                                           AS waste_pct,
        t.num_rows,
        TO_CHAR(t.last_analyzed,'YYYY-MM-DD HH24:MI')          AS last_analyzed,
        NVL(m.deletes, 0)                                      AS deletes,
        CASE
          WHEN (1-(le.total_blocks*(SELECT block_size FROM db_block)
                  *CASE WHEN l.securefile='YES' THEN 0.75 ELSE 0.60 END
                  /NULLIF(s.bytes,0)))*100 > 60
               AND s.bytes > 10*1024*1024*1024  THEN 'LOB CRITICAL BLOAT'
          WHEN (1-(le.total_blocks*(SELECT block_size FROM db_block)
                  *CASE WHEN l.securefile='YES' THEN 0.75 ELSE 0.60 END
                  /NULLIF(s.bytes,0)))*100 > 50 THEN 'LOB HIGH BLOAT'
          WHEN (1-(le.total_blocks*(SELECT block_size FROM db_block)
                  *CASE WHEN l.securefile='YES' THEN 0.75 ELSE 0.60 END
                  /NULLIF(s.bytes,0)))*100 > 30 THEN 'LOB MODERATE BLOAT'
          ELSE                                       'LOB MONITOR'
        END                                                    AS reorg_reason,
        CASE
          WHEN (1-(le.total_blocks*(SELECT block_size FROM db_block)
                  *CASE WHEN l.securefile='YES' THEN 0.75 ELSE 0.60 END
                  /NULLIF(s.bytes,0)))*100 > 60
               AND s.bytes > 10*1024*1024*1024  THEN 1
          WHEN (1-(le.total_blocks*(SELECT block_size FROM db_block)
                  *CASE WHEN l.securefile='YES' THEN 0.75 ELSE 0.60 END
                  /NULLIF(s.bytes,0)))*100 > 50 THEN 2
          WHEN (1-(le.total_blocks*(SELECT block_size FROM db_block)
                  *CASE WHEN l.securefile='YES' THEN 0.75 ELSE 0.60 END
                  /NULLIF(s.bytes,0)))*100 > 30 THEN 3
          ELSE                                       5
        END                                                    AS priority,
        CASE WHEN l.securefile = 'YES'
             THEN 'ALTER TABLE ' || l.owner || '.' || l.table_name
                  || ' MODIFY LOB (' || l.column_name || ') (SHRINK SPACE)'
             ELSE 'MOVE TABLE (BASICFILE needs offline move)'
        END                                                    AS reorg_action
    FROM
        dba_lobs        l
        JOIN dba_segments s
            ON  s.owner        = l.owner
            AND s.segment_name = l.segment_name
            AND s.segment_type LIKE 'LOB%'
        JOIN lob_extents le
            ON  le.owner        = l.owner
            AND le.segment_name = l.segment_name
        JOIN dba_tables t
            ON  t.owner        = l.owner
            AND t.table_name   = l.table_name
        LEFT JOIN dba_tab_modifications m
            ON  m.table_owner  = l.owner
            AND m.table_name   = l.table_name
        LEFT JOIN lob_seg_stats ls
            ON  ls.owner       = l.owner
            AND ls.segment_name = l.segment_name
    WHERE
        l.owner   IN ('OBI_DW','ODI11GPRE_BIA_ODIREPO')        -- << ADJUST
        AND s.bytes > 100 * 1024*1024                          -- > 100 MB
        -- KEY: only report where segment materially exceeds extent usage
        AND s.bytes / (1024*1024*1024)
            > le.extent_gb * 1.25                              -- 25% overhead threshold

    UNION ALL

    -- ------------------------------------------------------------
    -- ARM 3: INDEX SEGMENTS
    -- ------------------------------------------------------------
    SELECT
        i.owner,
        i.index_name || ' ON ' || i.table_name                 AS object_name,
        'INDEX-' || i.index_type                               AS object_type,
        s.bytes / (1024*1024*1024)                             AS segment_gb,
        s.bytes / (1024*1024*1024)
            * CASE WHEN i.blevel >= 4 THEN 0.7
                   WHEN i.blevel >= 3 THEN 0.8
                   ELSE 0.9 END                                AS actual_gb,
        s.bytes / (1024*1024*1024)
            * CASE WHEN i.blevel >= 4 THEN 0.3
                   WHEN i.blevel >= 3 THEN 0.2
                   ELSE 0.1 END                                AS waste_gb,
        CASE WHEN i.blevel >= 4 THEN 30
             WHEN i.blevel >= 3 THEN 20
             ELSE 10 END                                       AS waste_pct,
        i.num_rows,
        TO_CHAR(i.last_analyzed,'YYYY-MM-DD HH24:MI')          AS last_analyzed,
        0                                                      AS deletes,
        CASE
          WHEN i.status  = 'UNUSABLE'   THEN 'INDEX UNUSABLE'
          WHEN i.blevel >= 5            THEN 'INDEX VERY DEEP BTREE'
          WHEN i.blevel >= 4            THEN 'INDEX DEEP BTREE'
          WHEN i.blevel >= 3
           AND i.leaf_blocks > 100000  THEN 'INDEX DEEP + LARGE'
          ELSE                              'INDEX MONITOR'
        END                                                    AS reorg_reason,
        CASE
          WHEN i.status  = 'UNUSABLE'   THEN 1
          WHEN i.blevel >= 5            THEN 2
          WHEN i.blevel >= 4            THEN 3
          ELSE                               5
        END                                                    AS priority,
        CASE
          WHEN i.status     = 'UNUSABLE'
                             THEN 'ALTER INDEX '||i.index_name||' REBUILD'
          WHEN i.partitioned = 'YES'
                             THEN 'ALTER INDEX '||i.index_name||' REBUILD PARTITION'
          ELSE                    'ALTER INDEX '||i.index_name||' REBUILD ONLINE'
        END                                                    AS reorg_action
    FROM
        dba_indexes  i
        JOIN dba_segments s
            ON  s.owner        = i.owner
            AND s.segment_name = i.index_name
            AND s.segment_type LIKE 'INDEX%'
    WHERE
        i.owner   IN ('OBI_DW','ODI11GPRE_BIA_ODIREPO')        -- << ADJUST
        AND s.bytes > 100 * 1024*1024
        AND (
            i.status    = 'UNUSABLE'
         OR i.blevel   >= 3
         OR i.leaf_blocks > 50000
        )

    UNION ALL

    -- ------------------------------------------------------------
    -- ARM 4: RECYCLE BIN
    -- ------------------------------------------------------------
    SELECT
        owner,
        original_name                                          AS object_name,
        'RECYCLEBIN-' || type                                  AS object_type,
        SUM(space) * (SELECT block_size FROM db_block)
                   / (1024*1024*1024)                          AS segment_gb,
        0                                                      AS actual_gb,
        SUM(space) * (SELECT block_size FROM db_block)
                   / (1024*1024*1024)                          AS waste_gb,
        100                                                    AS waste_pct,
        NULL, NULL, 0,
        'RECYCLE BIN - PURGE'                                  AS reorg_reason,
        1                                                      AS priority,
        'PURGE RECYCLEBIN'                                     AS reorg_action
    FROM
        dba_recyclebin
    WHERE
        owner IN ('OBI_DW','ODI11GPRE_BIA_ODIREPO')            -- << ADJUST
    GROUP BY
        owner, original_name, type
    HAVING
        SUM(space) * (SELECT block_size FROM db_block)
                   > 100 * 1024*1024
)
WHERE reorg_reason NOT IN ('MONITOR','LOB MONITOR','INDEX MONITOR')
ORDER BY
    priority ASC,
    waste_gb DESC NULLS LAST;