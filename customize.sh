#!/system/bin/sh
export PATH=/sbin:/system/bin:/system/xbin:/vendor/bin:/data/adb/magisk:/data/adb/ksu/bin:/data/adb/ap/bin:$PATH
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
ui_print " "
ui_print "🛡️ StevenBlock | Anti-Malware & Ad Blocker"
ui_print "👤 Developer: mikropsoft"
ui_print "🔗 GitHub: https://github.com/mikropsoft"
ui_print " "
ui_print "✨ Preparing Environment..."
mkdir -p $MODPATH/web/cgi-bin
mkdir -p $MODPATH/system/etc
set_perm_recursive $MODPATH/web 0 0 0755 0755
set_perm $MODPATH/web/cgi-bin/api.sh 0 0 0755
set_perm $MODPATH/system/etc/hosts 0 0 0644
ui_print "📥 Fetching Default List (StevenBlack)..."
download_file "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" "$MODPATH/system/etc/hosts"
if [ ! -s "$MODPATH/system/etc/hosts" ]; then
ui_print "⚠️ Download failed! Applying default empty hosts."
printf "127.0.0.1 localhost\n::1 localhost\n" > "$MODPATH/system/etc/hosts"
else
echo "steven" > "$MODPATH/current_list.txt"
cp -f "$MODPATH/system/etc/hosts" "$MODPATH/base_hosts"
fi
ui_print "✅ Setup Complete!"
ui_print "🌐 Use the 'Action' button in your Root Manager to open WebUI."
ui_print " "