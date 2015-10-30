#!/bin/bash
. "$COMPONENT_INC_SH" || exit 1

component require apache-httpd
component require php-common

rpm=php-5.3.3
rpm -q "${rpm}" >/dev/null 2>&1 && exit 0
rpm -U \
"ftp://rpmfind.net/linux/centos/6.7/updates/x86_64/Packages/${rpm}-46.el6_6.x86_64.rpm"

/sbin/service httpd restart
