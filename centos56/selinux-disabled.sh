#!/bin/bash
. "$COMPONENT_INC_SH" || exit 1

echo 0 >/selinux/enforce
sed -i 's#^SELINUX=enforcing#SELINUX=permissive#' /etc/selinux/config
