#!/system/bin/sh
# StevenBlock: runs right after the root manager (or its metamodule) mounts modules.
# If Android isn't using StevenBlock's hosts file, it bind-mounts the file directly, then exits.
MODDIR=${0%/*}
[ "$MODDIR" = "$0" ] && MODDIR=.
sh "$MODDIR/sb.sh" _mount > /dev/null 2>&1
