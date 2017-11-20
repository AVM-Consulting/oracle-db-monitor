-- Copyright (c) 2017 AVM Consulting inc. All Rights Reserved.
-- Licensed under the GNU General Public License v3 or any later version
-- See license text at http://www.gnu.org/licenses/gpl.txt

set lines 1000
set pages 50
set verify off
set feedback off
---list of instances to include
define inst_clause='and inst_id in (1,2,3,4,5,6)'
---how long wait between sampels
define seconds_to_monitor=&1
prompt
--prompt &&inst_clause
--prompt

prompt REPORT DESCRIPTION: The Report Shows top process for last &&seconds_to_monitor seconds (ash based)
prompt
prompt Uncomment/Comment columns in SELECT and ORDER BY clauses as needed.

---remove delay if needed. 
exec dbms_lock.sleep(&&seconds_to_monitor); 

COLUMN sess#           HEADING 'SESS#'         format a15
COLUMN program         HEADING 'PROGRAM'       format a14 trunc
COLUMN machine         HEADING 'MACHINE'       format a15 trunc
COLUMN db_user_name    HEADING 'DB|USR|NAME'   format a10 trunc
COLUMN service_name    HEADING 'SRVC|NAME'     format a10 trunc
COLUMN top_sql_id      HEADING 'SQL_ID'        format a13 

COLUMN PCNT_ACTIVE     HEADING 'PCT|ACT|IVE'   format 999
COLUMN cpu             HEADING 'CPU'           format 9.9
COLUMN scheduler       HEADING 'SCH|DUL|ER'    format 9.9
COLUMN uio             HEADING 'UIO'           format 9.9
COLUMN sio             HEADING 'SIO'           format 9.9
COLUMN concurrency     HEADING 'CON|CUR|ENC'   format 9.9
COLUMN application     HEADING 'APP|LIC|TON'   format 9.9
COLUMN COMMIT          HEADING 'COM|IT'        format 9.9
COLUMN configuration   HEADING 'CON|FGR|TON'   format 9.9
COLUMN administrative  HEADING 'ADM|NST|RTV'   format 9.9
COLUMN network         HEADING 'NET|WOR'       format 9.9
COLUMN queueing        HEADING 'QUE|ING'       format 9.9
COLUMN clust           HEADING 'CLU|STR'       format 9.9
COLUMN other           HEADING 'OTH|ER'        format 9.9

COLUMN iops            HEADING 'IO|PS'       format 9999
COLUMN MBSEC           HEADING 'MB|SEC'      format 999
COLUMN mbsec_interc    HEADING 'MB|SEC|ICNT' format 999
COLUMN pga_gb          HEADING 'PGA|GB'      format 9.99
COLUMN temp_gb         HEADING 'TMP|GB'      format 9.99

select * from
  (
  select * from 
     (
     SELECT ash.session_id||','||ash.SESSION_SERIAL#||',@'||ash.inst_id sess#,
       substr(ash.program,-14,14) AS program,
--       ash.machine,
--       ash.db_user_name,
--       ash.service_name,
       ash1.top_sql_id,
       round(ash1.pcnt_active,2) AS pcnt_active,
       round(cpu/&&seconds_to_monitor,2) AS cpu,
--       round(scheduler/&&seconds_to_monitor,2) AS scheduler,
       round(uio/&&seconds_to_monitor,2) AS uio,
       round(sio/&&seconds_to_monitor,2) AS sio,
       round(concurrency/&&seconds_to_monitor,2) AS concurrency,
       round(application/&&seconds_to_monitor,2) AS application,
       round(COMMIT/&&seconds_to_monitor,2) AS COMMIT,
--       round(configuration/&&seconds_to_monitor,2) AS configuration,
--       round(administrative/&&seconds_to_monitor,2) AS administrative,
--       round(network/&&seconds_to_monitor,2) AS network,
--       round(queueing/&&seconds_to_monitor,2) AS queueing,
       round(clust/&&seconds_to_monitor,2) AS clust,
       round(other/&&seconds_to_monitor,2) AS other,
       round(ash1.iops*ash1.pcnt_active/100,2) AS iops,
       round(ash1.mbsec*ash1.pcnt_active/100,2) AS mbsec,
       round(ash1.mbsec_interc*ash1.pcnt_active/100,2) AS mbsec_interc,
       round(ash1.pga/1024/1024/1024,2) AS pga_gb,
       round(ash1.temp/1024/1024/1024,2) AS temp_gb
     FROM
       ---breakdown by wait_class using pivot
       (
          SELECT
            session_id,SESSION_SERIAL#,inst_id,program,machine,
            (select username from dba_users u where u.user_id=s.user_id) db_user_name, 
            (select ss.name from dba_services ss where ss.name_hash=s.service_hash and rownum<2) service_name,
            DECODE(session_state,'ON CPU','ON CPU', wait_class) AS wait_class
          FROM gv$active_session_history s
          WHERE sample_time>sysdate-(&&seconds_to_monitor/24/60/60)
                &&inst_clause
          ) ash
          PIVOT (COUNT(*) FOR wait_class IN ('ON CPU' AS cpu,'Scheduler' AS scheduler,'User I/O' AS uio,'System I/O' AS sio,
          'Concurrency' AS concurrency,'Application' AS application,'Commit' AS COMMIT,'Configuration' AS configuration,
          'Administrative' AS administrative,'Network' AS network,'Queueing' AS queueing,'Cluster' AS clust,'Other' AS other)
        ) ash,
        ---group by sid to get mb/sec and iops on process level.
        (
          select 
            session_id,SESSION_SERIAL#,inst_id,
            round(100*count(1)/&&seconds_to_monitor,2) pcnt_active,
            avg(1000000*(DELTA_READ_IO_REQUESTS+DELTA_WRITE_IO_REQUESTS)/delta_time) iops,
            avg(        (DELTA_READ_IO_bytes+DELTA_WRITE_IO_bytes)/delta_time) mbsec,
            avg(        (DELTA_INTERCONNECT_IO_BYTES             )/delta_time) mbsec_interc,
            avg(PGA_ALLOCATED) pga,
            avg(TEMP_SPACE_ALLOCATED) temp,
            min(case when sql_count_rank=1 then nvl(sql_id,' ') else 'zzzzzzzz' end) top_sql_id
          from (select ss.*, 
                       ---get sql_id which got spotted in most snapshots (rank=1)
                       DENSE_RANK() OVER (PARTITION BY session_id,SESSION_SERIAL#,inst_id ORDER BY sql_id_count DESC NULLS LAST) sql_count_rank
                  from 
                      (select sss.*, 
                              ---get count of each sql_id per session
                              count(1) OVER (PARTITION BY session_id,SESSION_SERIAL#,inst_id,sql_id) sql_id_count  
                         from gv$active_session_history sss
                         where sample_time>sysdate-(&&seconds_to_monitor/24/60/60) 
                               &&inst_clause
                      ) ss
               ) s 
          group by session_id,SESSION_SERIAL#,inst_id
        ) ash1
     WHERE ash.session_id=ash1.session_id
       and ash.SESSION_SERIAL#=ash1.SESSION_SERIAL#
       and ash.inst_id=ash1.inst_id
     ORDER BY 
      mbsec desc,
      mbsec_interc desc,
      iops desc,
      pcnt_active desc,
      pga desc,
      temp desc,
      cpu desc
     )
  where rownum<8 
  )
;
exit

