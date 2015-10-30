#!/bin/bash
. "$COMPONENT_INC_SH" || exit 1
component require php-common

set -e
[[ -e /etc/php.d/20-ioncube.ini ]] && exit 0
curl -sS http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz |
	gzip -d -c |
	tar x -C /usr/local

mkdir -p /etc/php.d
echo 'zend_extension = /usr/local/ioncube/ioncube_loader_lin_5.3.so' \
	> /etc/php.d/20-ioncube.ini
