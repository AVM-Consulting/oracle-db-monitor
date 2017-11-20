-- Copyright (c) 2017 AVM Consulting inc. All Rights Reserved.
-- Licensed under the GNU General Public License v3 or any later version
-- See license text at http://www.gnu.org/licenses/gpl.txt

set lines 200
set verify off
set feedback off
---set list of RAC instances to look at.
define inst_clause='and inst_id in (1,2,3,4,5,6)'
---how long wait between sampels
define seconds_to_monitor=&1
prompt
--prompt &&inst_clause
--prompt

prompt REPORT DESCRIPTION: The Report Shows major stats for last &&seconds_to_monitor seconds (stats based)
prompt

set serveroutput on
declare
 wait_sec number:=&&seconds_to_monitor;
 type num_list_type is table of number index by pls_integer;
 type varchar_list_type is table of varchar2(100) index by pls_integer;
 totw1 num_list_type; 
 totw2 num_list_type; 
 wtt1  num_list_type; 
 wtt2  num_list_type; 
 p_event_name varchar_list_type;
begin
 p_event_name(1) :='redo size';
 p_event_name(2) :='user commits';
 p_event_name(3) :='physical read bytes';
 p_event_name(4) :='physical read total bytes';
 p_event_name(5) :='physical write total bytes';
 p_event_name(6) :='physical read total IO requests';
 p_event_name(7) :='physical write total IO requests';
 p_event_name(8) :='gc cr blocks received';
 p_event_name(9) :='gc current blocks received';

for i in 1..p_event_name.count loop
 select sum(value) into totw1(i) from gv$sysstat where name=p_event_name(i) &&inst_clause;
end loop;
dbms_lock.sleep(wait_sec);
for i in 1..p_event_name.count loop
 select sum(value) into totw2(i) from gv$sysstat where name=p_event_name(i) &&inst_clause;
end loop;

for i in 1..p_event_name.count loop
 dbms_output.put_line(rpad(p_event_name(i), 35,' ')||' = '||rpad(round((totw2(i)-totw1(i))/(wait_sec),1),14,' ')||' /sec.');
end loop;
dbms_output.put_line('--');
end;
/
exit
