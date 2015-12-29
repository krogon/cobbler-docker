#!/bin/bash

# recreating files in case of empty volumes attached
if rpm -V cobbler | grep -q missing; then
  yum reinstall -q -y cobbler
elif rpm -V cobbler-web | grep -q missing; then
  yum reinstall -q -y cobbler-web
elif rpm -V tftp-server | grep -q missing; then
  yum reinstall -q -y tftp-server
elif rpm -V dhcp | grep -q missing; then
  yum reinstall -q -y dhcp
fi


/usr/sbin/apachectl
/usr/bin/cobblerd

cobbler sync > /dev/null 2>&1

pkill cobblerd

/usr/sbin/dhcpd -cf /etc/dhcp/dhcpd.conf -user dhcpd -group dhcpd --no-pid
#enable tftp in /etc/xinet.d/tftp if needed
/usr/sbin/xinetd -stayalive -pidfile /var/run/xinetd.pid
/usr/bin/cobblerd -F