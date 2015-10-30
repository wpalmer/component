#!/bin/bash
. "$COMPONENT_INC_SH" || exit 1

component require unionfs

[[ -x /usr/bin/mkunion ]] && exit 0
cat > /usr/bin/mkunion <<'SHELL'
[[ -n "$UNIONFS_OPTIONS" ]] && UNIONFS_OPTIONS=",${UNIONFS_OPTIONS}"
if [[ $# -lt 1 ]] || [[ $# -gt 3 ]]; then
	printf 'Usage: ensure-union.sh <source> <new-writeable-destination> [<working directory>]' >&2
	exit 1
fi

ro_source="$1"
[[ -d "$ro_source" ]] || { printf 'Non-existant readonly source %s' "'$ro_source'\n" >&2; exit 1; }
tag="${ro_source##*/}"
[[ $# -ge 2 ]] && rw_target="$2" || rw_target="/var/unionfs/$tag/u"
[[ $# -ge 3 ]] && rw_work="$3" || rw_work="/var/unionfs/$tag/rw"

grep -q -e "^unionfs $rw_target" /etc/mtab && exit 0

[[ -d "$rw_work" ]] || mkdir -p "$rw_work"
[[ -d "$rw_target" ]] || mkdir -p "$rw_target"
chmod a+rwx "$rw_work" "$rw_target"

sed -i '\!^unionfs#.*'"$rw_target"'!d' /etc/fstab
echo "unionfs#${rw_work}=rw:${ro_source}=ro ${rw_target} fuse cow,nonempty,allow_other${UNIONFS_OPTIONS} 0 0" >> /etc/fstab
mount "$rw_target"
SHELL

chmod a+x /usr/bin/mkunion
