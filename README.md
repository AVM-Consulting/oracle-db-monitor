Oracle DB Monitor
====================

This is command line Oracle DB Monitoring tool. Alternative to Oracle Enterprise Manager (OEM). 

It presents key metrics from multiple OEM Pages in single pane of glass.
It does not require browser/GUI. It only need access to port 22 or 1521 on Oracle machine.
It is best to run on platforms where Cssh is available (macOS or Linux).

![Oracle DB Monitor](/readme/oracle-db-monitor-icon.png)



### Common reasons when OEM is not available, or not practical to use

 - OEM is just simply not installed.
 - In DMZ setup, OEM is under NAT and OEM port is not forwarded. ssh forwarding is too much work. 
 - OEM is accessible via public internet, and OEM self-signed certificates are prohibited for security reasons.


