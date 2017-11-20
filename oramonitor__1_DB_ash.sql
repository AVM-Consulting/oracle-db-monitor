-- Copyright (c) 2017 AVM Consulting inc. All Rights Reserved.
-- Licensed under the GNU General Public License v3 or any later version
-- See license text at http://www.gnu.org/licenses/gpl.txt

set lines 1000
set verify off
set feedback off
define inst_clause='and inst_id in (1,2,3,4,5,6)'
---how long wait between sampels
define seconds_to_monitor=&1
--prompt
--prompt &&inst_clause
prompt

prompt REPORT DESCRIPTION: The Report Shows ASH for last hour from gv$active_session_history and gv$sysmetric_history. (ash based)
prompt
prompt columns CPU+BCPU  - Total Cpu (background+user) what oracle asked for.
prompt column CPU_ORA_WAIT - is how much was not satisfied from what oracle askef for.. 

---remove delay if needed. 
exec dbms_lock.sleep(&&seconds_to_monitor); 

COLUMN time1           HEADING 'TIME'          format a10
COLUMN cpu             HEADING 'CPU'           format 999.9
COLUMN bcpu            HEADING 'BCPU'          format 999.9
COLUMN cpu_ora_wait    HEADING 'CPU|ORA|WAIT'  format 999.9
COLUMN scheduler       HEADING 'SCHE|DUL|ER'   format 999.9
COLUMN uio             HEADING 'UIO'           format 999.9
COLUMN sio             HEADING 'SIO'           format 999.9
COLUMN concurrency     HEADING 'CON|CURR|ENCY' format 999.9
COLUMN application     HEADING 'APP|LICA|TION' format 999.9
COLUMN COMMIT          HEADING 'COMM|IT'       format 999.9
COLUMN configuration   HEADING 'CONFI|GURA|TION'  format 999.9
COLUMN administrative  HEADING 'ADMI|NISTR|ATIVE' format 999.9
COLUMN network         HEADING 'NETW|ORK'         format 999.9
COLUMN queueing        HEADING 'QUEU|EING'        format 999.9
COLUMN clust           HEADING 'CLUS|TER' format 999.9
COLUMN other           HEADING 'OTHER' format 999.9
select * from
  (
  select * from 
     (
     SELECT to_char(sysmetric_history.sample_time,'hh24:mi:ss') time1,
       round(cpu/60,1) AS cpu,
       round(bcpu/60,1) AS bcpu,
       round(DECODE(SIGN((cpu+bcpu)/60-cpu_ora_consumed), -1, 0, ((cpu+bcpu)/60-cpu_ora_consumed)),1) AS cpu_ora_wait,
       round(scheduler/60,1) AS scheduler,
       round(uio/60,1) AS uio,
       round(sio/60,1) AS sio,
       round(concurrency/60,1) AS concurrency,
       round(application/60,1) AS application,
       round(COMMIT/60,2) AS COMMIT,
       round(configuration/60,1) AS configuration,
       round(administrative/60,1) AS administrative,
       round(network/60,1) AS network,
       round(queueing/60,1) AS queueing,
       round(clust/60,1) AS clust,
       round(other/60,1) AS other
     FROM
       (SELECT
          TRUNC(sample_time,'MI') AS sample_time,
          DECODE(session_state,'ON CPU',DECODE(session_type,'BACKGROUND','BCPU','ON CPU'), wait_class) AS wait_class
        FROM gv$active_session_history
        WHERE sample_time>sysdate-INTERVAL '1' HOUR
        AND sample_time<=TRUNC(SYSDATE,'MI')
        &&inst_clause
        ) ash
        PIVOT (COUNT(*) FOR wait_class IN ('ON CPU' AS cpu,'BCPU' AS bcpu,'Scheduler' AS scheduler,'User I/O' AS uio,'System I/O' AS sio,
        'Concurrency' AS concurrency,'Application' AS application,'Commit' AS COMMIT,'Configuration' AS configuration,
        'Administrative' AS administrative,'Network' AS network,'Queueing' AS queueing,'Cluster' AS clust,'Other' AS other)) ash,
        (SELECT 
           TRUNC(begin_time,'MI') AS sample_time,
           sum(VALUE/100) AS cpu_ora_consumed
         FROM gv$sysmetric_history
         WHERE GROUP_ID=2
         AND metric_name='CPU Usage Per Sec'
         &&inst_clause
         group by TRUNC(begin_time,'MI')) sysmetric_history
     WHERE ash.sample_time (+)=sysmetric_history.sample_time
     ORDER BY sysmetric_history.sample_time desc
     )
  where rownum<28 
  ) 
order by time1
;
exit

