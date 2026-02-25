#!/system/bin/sh
MODDIR=${0%/*}
if [ -f "$MODDIR/pending_hosts" ]; then
    cp -f "$MODDIR/pending_hosts" "$MODDIR/system/etc/hosts"
    chmod 644 "$MODDIR/system/etc/hosts"
    rm -f "$MODDIR/pending_hosts"
fi