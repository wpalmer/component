#!/bin/bash
. "$COMPONENT_INC_SH" || exit 1

rpm=mysql-server
rpm -q "${rpm}" >/dev/null 2>&1 && exit 0
yum install -q -y "${rpm}"

chkconfig --level 345 mysqld on
/sbin/service mysqld restart
