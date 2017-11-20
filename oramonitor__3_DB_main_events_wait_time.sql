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

prompt REPORT DESCRIPTION: The Report Shows latencines/counts for last &&seconds_to_monitor seconds for major events. (stats based)
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
 p_event_name(1) :='db file sequential read';
 p_event_name(2) :='db file scattered read';
 p_event_name(3) :='direct path read';
 p_event_name(4) :='log file sync';
 p_event_name(5) :='log file parallel write';
 p_event_name(6) :='Disk file operations I/O';
 p_event_name(7) :='gc current grant busy';
 p_event_name(8) :='gc current block 2-way';
 p_event_name(9) :='gc cr block 2-way';
for i in 1..p_event_name.count loop
 select sum(total_waits),sum(time_waited_micro) into totw1(i),wtt1(i) from gv$system_event where event=p_event_name(i) &&inst_clause;
end loop;
dbms_lock.sleep(wait_sec);
for i in 1..p_event_name.count loop
 select sum(total_waits),sum(time_waited_micro) into totw2(i),wtt2(i) from gv$system_event where event=p_event_name(i) &&inst_clause;
end loop;

for i in 1..p_event_name.count loop
 dbms_output.put_line
(
   rpad(p_event_name(i), 35,' ')||' = '
 ||rpad(round((wtt2(i)-wtt1(i))/(case totw2(i)-totw1(i) when 0 then 1 else totw2(i)-totw1(i) end)/1000,1),10,' ')||' ms. Waits: '
 ||rpad(totw2(i)-totw1(i),6,' ')||' Waits/sec: '||(round(totw2(i)-totw1(i))/wait_sec)
);
end loop;
end;
/
exit
