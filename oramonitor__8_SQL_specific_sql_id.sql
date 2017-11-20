-- Copyright (c) 2017 AVM Consulting inc. All Rights Reserved.
-- Licensed under the GNU General Public License v3 or any later version
-- See license text at http://www.gnu.org/licenses/gpl.txt

set lines 200
set verify off
set feedback off
---set list of RAC instances to look at.
define inst_clause='and inst_id in (1,2,3,4,5,6)'
---set below to 15 to not show SQL_TEXT
define sql_text_lenth=100
---how much seconds back to look in ash to find top io consumers
define seconds_to_look_back=&1
---how long wait between sampels
define seconds_to_monitor=&&seconds_to_look_back
prompt
--prompt &&inst_clause
--prompt

prompt REPORT DESCRIPTION: The Report Shows stats for last &&seconds_to_monitor seconds for specific SQL_IDs (stats based)
prompt

set serveroutput on
declare
 wait_sec number:=&&seconds_to_monitor;
 type num_list_type is table of number index by pls_integer;
 type varchar_list_type is table of varchar2(&&sql_text_lenth) index by pls_integer;
 exec1 num_list_type; 
 exec2 num_list_type; 
 gets1  num_list_type; 
 gets2  num_list_type; 
 dread1  num_list_type; 
 dread2  num_list_type; 
 rows1  num_list_type; 
 rows2  num_list_type; 
 sess1  num_list_type; 
 sess2  num_list_type; 
 p_sql_id   varchar_list_type;
 p_sql_text varchar_list_type;
begin
 p_sql_id(1) :='bxrtmfdz4rq2d'; --SQL1
 p_sql_id(2) :='cng304njd33fr'; --SQL2
				--Add more SQL if needed..
for i in 1..p_sql_id.count loop
 select sum(executions),sum(rows_processed),sum(buffer_gets),sum(physical_read_bytes),sum(elapsed_time),max(substr(sql_text,1,&&sql_text_lenth)) into exec1(i),rows1(i),gets1(i),dread1(i),sess1(i),p_sql_text(i) from gv$sqlstats where sql_id=p_sql_id(i) &&inst_clause;
end loop;
---show SQL_TEXT
if (&&sql_text_lenth!=15) then 
for i in 1..p_sql_id.count loop
 dbms_output.put_line(rpad(p_sql_id(i), 15,' ')||p_sql_text(i));
end loop;
dbms_output.put_line(CHR(10));
end if;
dbms_lock.sleep(wait_sec);
for i in 1..p_sql_id.count loop
 select sum(executions),sum(rows_processed),sum(buffer_gets),sum(physical_read_bytes),sum(elapsed_time),max(substr(sql_text,1,&&sql_text_lenth)) into exec2(i),rows2(i),gets2(i),dread2(i),sess2(i),p_sql_text(i) from gv$sqlstats where sql_id=p_sql_id(i) &&inst_clause;
end loop;

for i in 1..p_sql_id.count loop
 dbms_output.put_line(rpad(p_sql_id(i), 15,' ')
---!!!comment below lines if metric is not needed
 ||' exec = '       ||rpad(exec2(i)-exec1(i),5,' ')
 ||' gets/exec= '   ||rpad(round((gets2(i)-gets1(i))/       (case exec2(i)-exec1(i) when 0 then 1 else exec2(i)-exec1(i) end),1),10,' ')
 ||' KB/exec= '     ||rpad(round((dread2(i)-dread1(i))/1024/(case exec2(i)-exec1(i) when 0 then 1 else exec2(i)-exec1(i) end),1),10,' ')
-- ||' KB/sec= '      ||rpad(round((dread2(i)-dread1(i))/1024/wait_sec                                                         ,1),10,' ')
 ||' rows/exec= '   ||rpad(round((rows2(i)-rows1(i))/       (case exec2(i)-exec1(i) when 0 then 1 else exec2(i)-exec1(i) end),1),10,' ')
-- ||' gets/row= '    ||rpad(round((gets2(i)-gets1(i))/       (case rows2(i)-rows1(i) when 0 then 1 else rows2(i)-rows1(i) end),1),10,' ')
 ||' sess_cnt= '    ||rpad(round((sess2(i)-sess1(i))/1000000/wait_sec                                                        ,1),5 ,' ')
 );
end loop;
end;
/
exit

