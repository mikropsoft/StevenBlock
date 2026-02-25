#!/system/bin/sh
ui_print " "
ui_print "🛡️ StevenBlock | Anti-Malware & Ad Blocker v3.0"
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
curl -s -k -L -o $MODPATH/system/etc/hosts "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" || echo "127.0.0.1 localhost\n::1 localhost" > $MODPATH/system/etc/hosts
ui_print "✅ Setup Complete!"
ui_print "🌐 Use the 'Action' button in your Root Manager to open WebUI."
ui_print " "