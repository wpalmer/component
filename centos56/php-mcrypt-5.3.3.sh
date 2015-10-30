#!/bin/bash
. "$COMPONENT_INC_SH" || exit 1

component require php-common
component require libmcrypt

rpm=php-mcrypt-5.3.3
rpm -q "${rpm}" >/dev/null 2>&1 && exit 0
rpm -U \
"ftp://rpmfind.net/linux/epel/6/x86_64/${rpm}-4.el6.x86_64.rpm"
