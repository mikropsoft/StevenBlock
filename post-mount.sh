#!/system/bin/sh
MODDIR=${0%/*}
[ "$MODDIR" = "$0" ] && MODDIR=.
sh "$MODDIR/sb.sh" _mount > /dev/null 2>&1
