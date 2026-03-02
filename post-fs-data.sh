#!/system/bin/sh
MODDIR=${0%/*}
if [ -f "$MODDIR/pending_hosts" ]; then
    mv -f "$MODDIR/pending_hosts" "$MODDIR/base_hosts"
    [ -f "$MODDIR/pending_list.txt" ] && mv -f "$MODDIR/pending_list.txt" "$MODDIR/current_list.txt"
fi
[ ! -f "$MODDIR/base_hosts" ] && cp -f "$MODDIR/system/etc/hosts" "$MODDIR/base_hosts"
cp -f "$MODDIR/base_hosts" "$MODDIR/working_hosts"
if [ -f "$MODDIR/whitelist.txt" ]; then
    awk 'FNR==NR{a[$1];next} !($2 in a)' "$MODDIR/whitelist.txt" "$MODDIR/working_hosts" > "$MODDIR/working_hosts.tmp"
    mv -f "$MODDIR/working_hosts.tmp" "$MODDIR/working_hosts"
fi
if [ -f "$MODDIR/blacklist.txt" ]; then
    cat "$MODDIR/blacklist.txt" >> "$MODDIR/working_hosts"
fi
cp -f "$MODDIR/working_hosts" "$MODDIR/system/etc/hosts"
chmod 644 "$MODDIR/system/etc/hosts"
rm -f "$MODDIR/working_hosts"
rm -f "$MODDIR/pending_rules"