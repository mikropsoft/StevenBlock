#!/system/bin/sh
MODDIR=${0%/*}
[ "$MODDIR" = "$0" ] && MODDIR=.
sh "$MODDIR/sb.sh" _boot > /dev/null 2>&1
