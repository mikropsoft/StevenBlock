#!/system/bin/sh

PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=true

ui_print() {
  echo "$1" > /proc/self/fd/$OUTFD
}

keytest() {
  timeout 0.1 getevent -lc 1 2>&1 | grep VOLUME | grep " DOWN" | head -1
}

wait_for_keypress() {
  local timeout_count=0
  while [ $timeout_count -lt 100 ]; do
    local key=$(keytest)
    if echo "$key" | grep -q "VOLUMEUP"; then
      return 1
    elif echo "$key" | grep -q "VOLUMEDOWN"; then
      return 0
    fi
    sleep 0.1
    timeout_count=$((timeout_count + 1))
  done
  return 2
}

interactive_menu() {
  SELECTION=1

  ui_print "==========================================="
  ui_print "🛡️      StevenBlock AdBlock Module       🛡️"
  ui_print "==========================================="
  ui_print ""
  ui_print "👋 Welcome to the StevenBlock family! We're thrilled to have you."
  ui_print ""
  ui_print "💬 Join our Telegram group for support and to connect with the community:"
  ui_print "➡️ t.me/stevenblockmodule"
  ui_print ""
  ui_print "⚠️ Make sure the systemless hosts module is not installed when enabling this module. Also, remove modules such as Adaway and BindHosts, as they will conflict with this module."
  ui_print ""
  ui_print "💡 Note: Larger lists offer more protection but may consume more RAM"
  ui_print "   and potentially impact device performance. Choose based on your needs."
  ui_print ""
  ui_print "🗂️ Select your preferred hosts file:"
  ui_print ""
  ui_print "1️ ⭐ StevenBlack — Main Recommended List (~100k+ entries)"
  ui_print "2️ 🍃 1Hosts (Lite) — Average Protection (~200k+ entries)"
  ui_print "3️ 🛡️ hBlock — Comprehensive but Non-Aggressive (~400k+ entries)"
  ui_print "4️ ❌ Exit Installation"
  ui_print ""
  ui_print "🔼 Volume Up: Navigate | 🔽 Volume Down: Confirm"
  ui_print "==========================================="
  ui_print ""

  print_current_selection() {
    case "$SELECTION" in
      1) ui_print "👉 [StevenBlack — Main Recommended List]" ;;
      2) ui_print "👉 [1Hosts (Lite) — Average Protection]" ;;
      3) ui_print "👉 [hBlock — Comprehensive but Non-Aggressive]" ;;
      4) ui_print "👉 [Exit Installation]" ;;
    esac
  }

  print_current_selection

  while true; do
    wait_for_keypress
    key_result=$?

    if [ "$key_result" -eq 1 ]; then
      SELECTION=$((SELECTION + 1))
      [ "$SELECTION" -gt 4 ] && SELECTION=1
      print_current_selection
    elif [ "$key_result" -eq 0 ]; then
      case "$SELECTION" in
        1)
          SELECTED_HOSTS="stevenblack_hosts"
          SELECTED_NAME="StevenBlack's List"
          break
          ;;
        2)
          SELECTED_HOSTS="1hosts_lite"
          SELECTED_NAME="1Hosts (Lite)"
          break
          ;;
        3)
          SELECTED_HOSTS="hblock_hosts"
          SELECTED_NAME="hBlock List"
          break
          ;;
        4)
          abort "🚫 Installation cancelled by user"
          ;;
      esac
    else
      abort "⌛ No input received, installation timeout"
    fi

    sleep 0.2
  done
}

install_module() {
  ui_print "⚙️ Installing StevenBlock Module..."
  mkdir -p "$MODPATH/system/etc"
  mv "$MODPATH/hosts/$SELECTED_HOSTS" "$MODPATH/system/etc/hosts"
  chmod 644 "$MODPATH/system/etc/hosts"
  echo "$SELECTED_HOSTS" > "$MODPATH/selected_hosts"
  echo "$SELECTED_NAME" > "$MODPATH/selected_name"
  ui_print "✅ Successfully installed: $SELECTED_NAME"
  rm -rf "$MODPATH/hosts"
}

main() {
  ui_print "🚀 Starting StevenBlock installation..."
  sleep 1
  
  interactive_menu
  install_module
  
  ui_print " "
  ui_print "============================================"
  ui_print "🎉 Installation Completed Successfully! 🎉"
  ui_print "🔄 Module will activate on next reboot 🔄"
  ui_print "============================================"
}

main