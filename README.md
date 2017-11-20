Oracle DB Monitor
====================

#### This is command line Oracle DB Monitoring tool. Alternative to Oracle Enterprise Manager (OEM). 

It presents key metrics from multiple OEM Pages in single pane of glass. <br />
It does not require browser/GUI. It only need access to port 22 or 1521 on Oracle machine. <br />
It works for Real Application Cluster and Single node configuration. <br />
It is best to run on platforms where Cssh is available (macOS or Linux). 

<img src="readme/oracle-db-monitor-icon.png" width="200">

### Installation (single script mode)

If cssh is not availble. you can run one script at a time. 

```Shell
git clone https://github.com/AVM-Consulting/oracle-db-monitor
cd oracle-db-monitor
scp oramonitor*.sql mydbhost1:/tmp
ssh mydbhost1
oracle@mydbhost1:/tmp$ sqlplus -s / as sysdba @/tmp/oramonitor_xxx.sql 5
```

### Common reasons when OEM is not available, or not practical to use

 - OEM is just simply not installed.
 - In DMZ setup, OEM is under NAT and OEM port is not forwarded. ssh forwarding is too much work. 
 - OEM is accessible via public internet, and OEM self-signed certificates are prohibited for security reasons.


