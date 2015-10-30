#!/bin/bash
. "$COMPONENT_INC_SH" || exit 1

component require epel

rpm=libmcrypt
rpm -q "${rpm}" >/dev/null 2>&1 && exit 0
yum install -q -y "${rpm}"
