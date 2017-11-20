Oracle DB Monitor
====================

#### This is command line Oracle DB Monitoring tool. Alternative to Oracle Enterprise Manager (OEM). 

- It presents key metrics from multiple OEM Pages in single pane of glass. <br />
- It does not require browser/GUI. It only need access to port 22 or 1521 on Oracle db host. <br />
- It works for Real Application Cluster and Single node configuration. <br />
- It is best to run on clients where Cssh is available (MacOS or Linux). 
- It does not replace OEM, but it is very useful tool where OEM is not available. 

<img src="readme/oracle-db-monitor-icon.png" width="200">

## Installation

### For MacOS clients: 

```Shell
# install csshX
git clone https://github.com/brockgr/csshx.git

# install oracle-db-monitor
git clone https://github.com/AVM-Consulting/oracle-db-monitor.git

# copy .sql file to db host.. in RAC configuration, can copy file to any single rac node.
scp oracle-db-monitor/oramonitor__*.sql  amoseyev@mydbhost1:/tmp

# spin 8 ssh session to the node
csshx/csshX oracle@mydbhost{1,1,1,1,1,1,1,1}.mycompany.com
```

In each open ssh session run oramonitor__*.sql script: 8 sessions, 8 scripts. <br />
(Argument 5, is monitoring window of 5 seconds)

In session 1:
```Shell
oracle@mydbhost1:~$ sqlplus -s / as sysdba @/tmp/oramonitor__1_DB_ash.sql 5
```

In session 2:
```Shell
oracle@mydbhost1:~$ sqlplus -s / as sysdba @/tmp/oramonitor__2_DB_top_events.sql 5
```

and so on..

### For Debian/Ubuntu clients:

Only difference is cssh install: 

```Shell
sudo apt-get install clusterssh
```

Results will be similar as on screenshot below

## Linking Oracle DB Monitor Metrics to OEM metrics.

Check screenshots below. First screenshot is Oracle DB Monitor, and other screenshots are from OEM. <br /> 
What is marked in RED   - is direct translation between OEM metrics and Oracle DB Monitor Metrics. <br />
What is marked in GREEN - are metrics, which we think are very useful metrics, but are not easily accessible in OEM. 

### Screenshot of Oracle DB Monitor
<img src="readme/z_oramonitor_screenshot.png?raw=true">

### Screenshot of OEM
<img src="readme/z_oracle_oem_performance_home_throughput_tab_page_screenshot.png?raw=true">
<img src="readme/z_oracle_oem_performance_home_io_tab_page_screenshot.png?raw=true">
<img src="readme/z_oracle_oem_performance_home_top_activity_page_screenshot.png?raw=true">
<img src="readme/z_oracle_oem_performance_home_global_cache_metrics_screenshot.png?raw=true">

## Type of monitoring

 - **oramonitor__x_DB_*.sql** scripts track DB level numbers
 - **oramonitor__x_SESSION_*.sql** scripts track details down to SESSION/PROCESS level
 - **oramonitor__x_SQL_*.sql** scripts track number on SQL level 

## Common script modification scenarios:

 - By default Oracle DB Monitor covers all RAC instances. But if you need stats only from particular instance(s) -  modify following line in scripts: 
```SQL
define inst_clause='and inst_id in (1,2,3,4,5,6)'
```

 - In scripts oramonitor__{6,7,8}*.sql you can change output columns. Just open script, comment column you do not need, uncomment columns you need. 

 - Change really anything... It is just SQL scripts. 


## Common reasons when OEM is not available, or not practical to use

 - OEM is just simply not installed.
 - In DMZ setup, OEM is under Network Address Translation (NAT) and OEM https port is not forwarded. ssh forwarding is too much work.
 - OEM is accessible only via public Internet (Common for Cloud installations), and default OEM self-signed certificates are prohibited for security reasons.


