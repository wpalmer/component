#!/bin/bash
. "$COMPONENT_INC_SH" || exit 1

component require git
component require gcc
component require fuse
component require fuse-devel

REPOS=https://github.com/rpodgorny/unionfs-fuse.git
[[ -x /sbin/mount.unionfs ]] && exit 0

TEMP=
eval "$(component tempdir TEMP)"
[[ -n "$TEMP" ]] || exit 1
cd "$TEMP" || exit 1

git clone "$REPOS" "$TEMP/unionfs-fuse.git"
if make -C "$TEMP"/unionfs-fuse.git; then
	sed \
		's#mount\.fuse#/sbin/mount\.fuse#' \
		"$TEMP/unionfs-fuse.git/mount.unionfs" \
		> /sbin/mount.unionfs &&
	cp \
		"$TEMP/unionfs-fuse.git/src/unionfs" \
		"$TEMP/unionfs-fuse.git/src/unionfsctl" \
		/usr/bin/ &&
	chmod a+x \
		/sbin/mount.unionfs \
		/usr/bin/unionfs \
		/usr/bin/unionfsctl &&
	exit 0
fi

exit 1
