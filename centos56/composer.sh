#!/bin/bash
. "$COMPONENT_INC_SH" || exit 1
component require php-cli
component require php-dom

TEMP=
eval "$(component tempdir TEMP)"
[[ -n "$TEMP" ]] || exit 1
cd "$TEMP" || exit 1

[[ -x /usr/bin/composer ]] || {
	curl -sS https://getcomposer.org/installer | {
		cd / &&
		php -- --filename=/usr/bin/composer
	}
}
