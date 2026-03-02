#!/system/bin/sh
export PATH=/sbin:/system/bin:/system/xbin:/vendor/bin:/data/adb/magisk:/data/adb/ksu/bin:/data/adb/ap/bin:$PATH
echo "Content-Type: application/json"
echo "Access-Control-Allow-Origin: *"
echo ""
MODDIR="/data/adb/modules/StevenBlock"
ACTION=$(echo "$QUERY_STRING" | sed -n 's/.*action=\([^&]*\).*/\1/p')
LIST=$(echo "$QUERY_STRING" | sed -n 's/.*list=\([^&]*\).*/\1/p')
DOMAIN=$(echo "$QUERY_STRING" | sed -n 's/.*domain=\([^&]*\).*/\1/p' | tr -d '[:space:]')
TYPE=$(echo "$QUERY_STRING" | sed -n 's/.*type=\([^&]*\).*/\1/p')
URL_STEVEN="https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
URL_SPARK="https://raw.githubusercontent.com/mikropsoft/StevenBlock/refs/heads/main/hosts/energized_spark_hosts"
URL_BLU="https://raw.githubusercontent.com/mikropsoft/StevenBlock/refs/heads/main/hosts/energized_blu_hosts"
URL_ULTIMATE="https://raw.githubusercontent.com/mikropsoft/StevenBlock/refs/heads/main/hosts/energized_ultimate_hosts"
get_url() {
[ "$1" = "steven" ] && echo "$URL_STEVEN"
[ "$1" = "spark" ] && echo "$URL_SPARK"
[ "$1" = "blu" ] && echo "$URL_BLU"
[ "$1" = "ultimate" ] && echo "$URL_ULTIMATE"
}
download_file() {
if command -v curl >/dev/null 2>&1; then
curl -s -k -L -o "$2" "$1"
elif command -v wget >/dev/null 2>&1; then
wget -q -O "$2" "$1" --no-check-certificate
else
BB=$(find /data/adb -name busybox -type f -executable | head -n 1)
$BB wget -q -O "$2" "$1" --no-check-certificate
fi
}
get_json_array() {
f=$1
c=$2
j="["
fi=1
if [ -f "$f" ]; then
while read -r l; do
[ -z "$l" ] && continue
d=$(echo "$l" | awk "{print \$$c}")
[ "$fi" = "1" ] && fi=0 || j="$j,"
j="$j\"$d\""
done < "$f"
fi
j="$j]"
echo "$j"
}
if [ "$ACTION" = "status" ]; then
LINES=$(wc -l < /system/etc/hosts 2>/dev/null || echo "0")
PENDING="false"
[ -f "$MODDIR/pending_hosts" ] || [ -f "$MODDIR/pending_rules" ] && PENDING="true"
CURRENT=$(cat "$MODDIR/current_list.txt" 2>/dev/null || echo "steven")
DISABLED="false"
[ "$CURRENT" = "none" ] && DISABLED="true"
echo "{\"lines\":\"$LINES\",\"pending\":$PENDING,\"active\":\"$CURRENT\",\"disabled\":$DISABLED}"
elif [ "$ACTION" = "update" ]; then
CURRENT=$(cat "$MODDIR/current_list.txt" 2>/dev/null || echo "steven")
if [ "$CURRENT" = "$LIST" ]; then
echo "{\"success\":false,\"message\":\"⚠️ This shield is already active!\"}"
exit 0
fi
URL=$(get_url "$LIST")
if [ "$URL" != "" ]; then
download_file "$URL" "$MODDIR/pending_hosts.tmp"
if [ -s "$MODDIR/pending_hosts.tmp" ]; then
mv -f "$MODDIR/pending_hosts.tmp" "$MODDIR/pending_hosts"
echo "$LIST" > "$MODDIR/pending_list.txt"
echo "{\"success\":true,\"message\":\"Shield applied! Reboot system. 🔄\"}"
else
rm -f "$MODDIR/pending_hosts.tmp"
echo "{\"success\":false,\"message\":\"Download Failed! ❌\"}"
fi
fi
elif [ "$ACTION" = "update_current" ]; then
CURRENT=$(cat "$MODDIR/current_list.txt" 2>/dev/null || echo "steven")
if [ "$CURRENT" = "none" ]; then
echo "{\"success\":false,\"message\":\"Blocker is currently disabled! 🛑\"}"
exit 0
fi
URL=$(get_url "$CURRENT")
download_file "$URL" "$MODDIR/pending_hosts.tmp"
if [ -s "$MODDIR/pending_hosts.tmp" ]; then
LINES_OLD=$(wc -l < "$MODDIR/base_hosts" 2>/dev/null || echo "0")
LINES_NEW=$(wc -l < "$MODDIR/pending_hosts.tmp" 2>/dev/null || echo "0")
if [ "$LINES_OLD" = "$LINES_NEW" ]; then
rm -f "$MODDIR/pending_hosts.tmp"
echo "{\"success\":true,\"message\":\"Shield is already up to date! ✨\"}"
else
mv -f "$MODDIR/pending_hosts.tmp" "$MODDIR/pending_hosts"
echo "$CURRENT" > "$MODDIR/pending_list.txt"
echo "{\"success\":true,\"message\":\"Shield updated! Reboot system. 🔄\"}"
fi
else
rm -f "$MODDIR/pending_hosts.tmp"
echo "{\"success\":false,\"message\":\"Download Failed! ❌\"}"
fi
elif [ "$ACTION" = "disable" ]; then
echo "127.0.0.1 localhost\n::1 localhost" > "$MODDIR/pending_hosts"
echo "none" > "$MODDIR/pending_list.txt"
echo "{\"success\":true,\"message\":\"Blocker disabled! Reboot system. 🔄\"}"
elif [ "$ACTION" = "enable" ]; then
URL=$(get_url "steven")
download_file "$URL" "$MODDIR/pending_hosts.tmp"
if [ -s "$MODDIR/pending_hosts.tmp" ]; then
mv -f "$MODDIR/pending_hosts.tmp" "$MODDIR/pending_hosts"
echo "steven" > "$MODDIR/pending_list.txt"
echo "{\"success\":true,\"message\":\"Blocker enabled! Reboot system. 🔄\"}"
else
rm -f "$MODDIR/pending_hosts.tmp"
echo "{\"success\":false,\"message\":\"Download Failed! ❌\"}"
fi
elif [ "$ACTION" = "add_rule" ]; then
if [ -n "$DOMAIN" ]; then
if grep -q "[[:space:]]${DOMAIN}$" "$MODDIR/blacklist.txt" 2>/dev/null || grep -q "^${DOMAIN}$" "$MODDIR/whitelist.txt" 2>/dev/null; then
echo "{\"success\":false,\"message\":\"Domain already listed! ⚠️\"}"
else
if [ "$TYPE" = "black" ]; then
echo "0.0.0.0 $DOMAIN" >> "$MODDIR/blacklist.txt"
else
echo "$DOMAIN" >> "$MODDIR/whitelist.txt"
fi
sort -u "$MODDIR/blacklist.txt" -o "$MODDIR/blacklist.txt" 2>/dev/null
sort -u "$MODDIR/whitelist.txt" -o "$MODDIR/whitelist.txt" 2>/dev/null
touch "$MODDIR/pending_rules"
echo "{\"success\":true,\"message\":\"Rule saved! Reboot system. 🔄\"}"
fi
else
echo "{\"success\":false,\"message\":\"Invalid Domain! ⚠️\"}"
fi
elif [ "$ACTION" = "delete_rule" ]; then
if [ -n "$DOMAIN" ]; then
if [ "$TYPE" = "black" ]; then
sed -i "/[[:space:]]${DOMAIN}$/d" "$MODDIR/blacklist.txt" 2>/dev/null
else
sed -i "/^${DOMAIN}$/d" "$MODDIR/whitelist.txt" 2>/dev/null
fi
touch "$MODDIR/pending_rules"
echo "{\"success\":true,\"message\":\"Rule removed! Reboot system. 🔄\"}"
else
echo "{\"success\":false,\"message\":\"Error removing rule! ⚠️\"}"
fi
elif [ "$ACTION" = "get_rules" ]; then
BLACK=$(get_json_array "$MODDIR/blacklist.txt" 2)
WHITE=$(get_json_array "$MODDIR/whitelist.txt" 1)
echo "{\"black\":$BLACK,\"white\":$WHITE}"
fi