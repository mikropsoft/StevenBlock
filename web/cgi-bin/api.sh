#!/system/bin/sh
echo "Content-Type: application/json"
echo "Access-Control-Allow-Origin: *"
echo ""
MODDIR="/data/adb/modules/StevenBlock"
ACTION=$(echo "$QUERY_STRING" | sed -n 's/.*action=\([^&]*\).*/\1/p')
LIST=$(echo "$QUERY_STRING" | sed -n 's/.*list=\([^&]*\).*/\1/p')
URL_STEVEN="https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
URL_SPARK="https://raw.githubusercontent.com/mikropsoft/StevenBlock/refs/heads/main/hosts/energized_spark_hosts"
URL_BLU="https://raw.githubusercontent.com/mikropsoft/StevenBlock/refs/heads/main/hosts/energized_blu_hosts"
URL_ULTIMATE="https://raw.githubusercontent.com/mikropsoft/StevenBlock/refs/heads/main/hosts/energized_ultimate_hosts"
if [ "$ACTION" = "status" ]; then
    LINES=$(wc -l < /system/etc/hosts 2>/dev/null || echo "0")
    PENDING="false"
    [ -f "$MODDIR/pending_hosts" ] && PENDING="true"
    echo "{\"lines\":\"$LINES\",\"pending\":$PENDING}"
elif [ "$ACTION" = "update" ]; then
    URL=""
    [ "$LIST" = "steven" ] && URL="$URL_STEVEN"
    [ "$LIST" = "spark" ] && URL="$URL_SPARK"
    [ "$LIST" = "blu" ] && URL="$URL_BLU"
    [ "$LIST" = "ultimate" ] && URL="$URL_ULTIMATE"
    if [ "$URL" != "" ]; then
        curl -s -k -L -o "$MODDIR/pending_hosts" "$URL"
        if [ $? -eq 0 ]; then
            echo "{\"success\":true,\"message\":\"Downloaded! Reboot system to apply. 🔄\"}"
        else
            echo "{\"success\":false,\"message\":\"Download Failed! ❌\"}"
        fi
    else
        echo "{\"success\":false,\"message\":\"Invalid List! ⚠️\"}"
    fi
elif [ "$ACTION" = "disable" ]; then
    echo "127.0.0.1 localhost\n::1 localhost" > "$MODDIR/pending_hosts"
    echo "{\"success\":true,\"message\":\"Disabled! Reboot system to apply. 🔄\"}"
fi