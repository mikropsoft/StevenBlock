#!/system/bin/sh
# StevenBlock: clears stale locks and temporary files after boot,
# starts a pending first download if the install happened offline, then exits.
MODDIR=${0%/*}
sh "$MODDIR/sb.sh" _boot > /dev/null 2>&1
