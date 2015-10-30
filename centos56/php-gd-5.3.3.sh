#!/bin/bash
. "$COMPONENT_INC_SH" || exit 1

component require php-common
component require libX11
component require libXpm
component require freetype
component require libjpeg
component require libpng

rpm=php-gd-5.3.3
rpm -q "${rpm}" >/dev/null 2>&1 && exit 0
rpm -U \
"ftp://rpmfind.net/linux/centos/6.7/updates/x86_64/Packages/${rpm}-46.el6_6.x86_64.rpm"
