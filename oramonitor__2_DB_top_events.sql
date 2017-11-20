-- Copyright (c) 2017 AVM Consulting inc. All Rights Reserved.
-- Licensed under the GNU General Public License v3 or any later version
-- See license text at http://www.gnu.org/licenses/gpl.txt

set lines 1000
set pages 30
set verify off
set feedback off
define inst_clause='and inst_id in (1,2,3,4,5,6) '
---how long wait between sampels
define seconds_to_monitor=&1
prompt
--prompt &&inst_clause
--prompt

prompt REPORT DESCRIPTION: The Report Shows Top EVENTS for last &&seconds_to_monitor seconds (from gv$active_session_history). (ash based)
prompt
prompt only "ACT_SESS_CNT" are per event. all other metrics are GLOBAL. 
prompt "ON CPU" is what oracle asked for (not what it got)

---remove delay if needed. 
exec dbms_lock.sleep(&&seconds_to_monitor); 

COLUMN event1             HEADING 'EVENT'         format a45 trunc
COLUMN active_sess        HEADING 'ACTV|SESS|CNT' format 999.9 
COLUMN sql_cnt            HEADING 'ON|SQL|CNT'    format 999.9 
COLUMN plsql_cnt          HEADING 'ON|PLSQL|CNT'  format 999.9 
COLUMN java_cnt           HEADING 'ON|JAVA|CNT'   format 999.9 
COLUMN parse_cnt          HEADING 'ON|PARSE|CNT'  format 999.9 
COLUMN seq_load_cnt       HEADING 'SEQ|LOAD|CNT'  format 999.9 
COLUMN blocked_cnt        HEADING 'BLCKD|CNT'     format 999.9 
COLUMN fts_cnt            HEADING 'FTS|CNT'       format 999.9 
COLUMN act_tot_cnt        HEADING 'TOT|ACTV|SESS' format 999.9 

select * from
  (
  select * from 
     (
    select case when event is null then session_state else event end event1,
    round(count(1)/max(samples_cnt),1) active_sess,
    round(max(sql_cnt)/max(samples_cnt),1) sql_cnt,
    round(max(plsql_cnt)/max(samples_cnt),1) plsql_cnt,
    round(max(java_cnt)/max(samples_cnt),1) java_cnt,
    round(max(parse_cnt)/max(samples_cnt),1) parse_cnt,
    round(max(seq_load_cnt)/max(samples_cnt),1) seq_load_cnt,
    round(max(blocked_cnt)/max(samples_cnt),1) blocked_cnt,
    round(max(fts_cnt)/max(samples_cnt),1) fts_cnt,
    round(max(act_sess_cnt)/max(samples_cnt),1) act_tot_cnt
    from (
    select SESSION_STATE,event,
    &&seconds_to_monitor samples_cnt,   ---how many samples total should be done. (should be every seconds. but if acvitity is low some can be skiped. this counts even for skipped samples)
    count(1)                                                over (PARTITION by null) act_sess_cnt, 
    sum(case when s.in_sql_execution='Y' then 1 else 0 end) over (PARTITION by null) sql_cnt, 
    sum(case when s.in_plsql_execution='Y' or s.in_plsql_rpc='Y' or s.in_plsql_compilation='Y' then 1 else 0 end) over (PARTITION by null) plsql_cnt, 
    sum(case when s.in_java_execution='Y' then 1 else 0 end) over (PARTITION by null) java_cnt, 
    sum(case when s.in_hard_parse='Y' then 1 else 0 end) over (PARTITION by null) parse_cnt, 
    sum(case when s.in_sequence_load='Y' then 1 else 0 end) over (PARTITION by null) seq_load_cnt, 
    sum(case when s.blocking_inst_id is not null then 1 else 0 end) over (PARTITION by null) blocked_cnt, 
    sum(case when s.sql_plan_operation='TABLE ACCESS' and s.sql_plan_options='FULL' then 1 else 0 end) over (PARTITION by null) fts_cnt
    from gV$ACTIVE_SESSION_HISTORY s
    where SAMPLE_TIME>sysdate-(&&seconds_to_monitor/24/60/60) ---for last X seconds.
    &&inst_clause
    ) 
    group by SESSION_STATE,event
    order by active_sess desc
     )
  where rownum<7
  ) 
;
exit
