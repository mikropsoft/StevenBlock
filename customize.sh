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
  ui_print "⚠️ Please do NOT use this module together with AdAway or other systemless hosts modules."
  ui_print ""
  ui_print "❗ If you experience issues with 1Hosts (Pro) or 1Hosts (Xtra), consider switching to the recommended Steven Black's List or 1Hosts (Lite)."
  ui_print ""
  ui_print "🗂️ Select your preferred hosts file:"
  ui_print ""
  ui_print "1️ Steven Black's List (Recommended)"
  ui_print "2️ 1Hosts (Lite) — For Issues"
  ui_print "3️ 1Hosts (Pro) — Strong Protection"
  ui_print "4️ 1Hosts (Xtra) — Max Protection"
  ui_print "5️ ❌ Exit Installation"
  ui_print ""
  ui_print "🔼 Volume Up: Navigate | 🔽 Volume Down: Confirm"
  ui_print "==========================================="
  ui_print ""

  print_current_selection() {
    case "$SELECTION" in
      1) ui_print "👉 Steven Black's List (Recommended)" ;;
      2) ui_print "👉 1Hosts (Lite) — For Issues" ;;
      3) ui_print "👉 1Hosts (Pro) — Strong Protection" ;;
      4) ui_print "👉 1Hosts (Xtra) — Max Protection" ;;
      5) ui_print "👉 Selection: ❌ Exit Installation" ;;
    esac
  }

  print_current_selection

  while true; do
    wait_for_keypress
    key_result=$?

    if [ "$key_result" -eq 1 ]; then
      SELECTION=$((SELECTION + 1))
      [ "$SELECTION" -gt 5 ] && SELECTION=1
      print_current_selection
    elif [ "$key_result" -eq 0 ]; then
      case "$SELECTION" in
        1)
          SELECTED_HOSTS="stevenblack_hosts"
          SELECTED_NAME="Steven Black's List (Recommended)"
          break
          ;;
        2)
          SELECTED_HOSTS="1hosts_lite"
          SELECTED_NAME="1Hosts (Lite) — For Issues"
          break
          ;;
        3)
          SELECTED_HOSTS="1hosts_pro"
          SELECTED_NAME="1Hosts (Pro) — Strong Protection"
          break
          ;;
        4)
          SELECTED_HOSTS="1hosts_xtra"
          SELECTED_NAME="1Hosts (Xtra) — Max Protection"
          break
          ;;
        5)
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
  rm -rf $MODPATH/hosts 
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