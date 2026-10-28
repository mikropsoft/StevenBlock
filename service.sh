#!/system/bin/sh
# StevenBlock: clears stale locks and temporary files after boot, makes sure the hosts file is
# mounted (a second check after post-mount.sh), starts a pending first download if the install
# happened offline, then exits.
MODDIR=${0%/*}
[ "$MODDIR" = "$0" ] && MODDIR=.
sh "$MODDIR/sb.sh" _boot > /dev/null 2>&1
