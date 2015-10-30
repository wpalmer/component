#!/bin/bash
. "$COMPONENT_INC_SH" || exit 1

rpm=httpd
rpm -q "${rpm}" >/dev/null 2>&1 && exit 0
yum install -q -y "${rpm}"

chkconfig --level 345 httpd on
/sbin/service httpd restart
/sbin/iptables \
	-I INPUT $(service iptables status | grep 'dpt:22' | head -1 | awk '{ print $1+1; }') \
	-p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
/sbin/iptables \
	-I INPUT $(service iptables status | grep 'dpt:22' | head -1 | awk '{ print $1+1; }') \
	-p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
/sbin/iptables-save > /etc/sysconfig/iptables
/sbin/service iptables restart
