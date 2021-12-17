# Indicators of compromise

## Processes

- Process name with [ ]
- Process of Apache2 user which is not apache2 or httpd
- Process listening or opening a RAW socket (listenable with lsof but not with ss or netstat)
- Socket opened by bash (/dev/tcp/XXX/YYY)
- Presence of netcat (nc), ...



## Files

- Presence of *.ssh/authorized_keys*
- Files writable for all
- Files with no user
- Files with SUID or SGID unknown



## Users

- Users with empty password (/etc/shadow)
- Service accounts with shell (neither /bin/false nor /bin/nologin)
- Users with sudo entries



## Kernel

- Unknown module loaded (lsmod + modinfo)




