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
  ui_print "❗ The most trouble-free and lightweight blocklist to use on your device is StevenBlack. If you experience issues with other lists, use this one instead."
  ui_print ""
  ui_print "🗂️ Select your preferred hosts file:"
  ui_print ""
  ui_print "1️ ⭐ Steven Black's List — Main daily list"
  ui_print "2️ 🍃 Hagezi's Multi LIGHT — Basic protection"
  ui_print "3️ ⚖️ Hagezi's Multi NORMAL — All-round protection"
  ui_print "4️ 🛡️ Hagezi's Multi PRO — Extended protection"
  ui_print "5 💎 Hagezi's Multi PRO++ — Maximum protection"
  ui_print "6 🚀 Hagezi's Multi ULTIMATE — Aggressive protection"
  ui_print "7 ❌ Exit Installation"
  ui_print ""
  ui_print "🔼 Volume Up: Navigate | 🔽 Volume Down: Confirm"
  ui_print "==========================================="
  ui_print ""

  print_current_selection() {
    case "$SELECTION" in
      1) ui_print "👉 [Steven Black — Main Daily List]" ;;
      2) ui_print "👉 [Hagezi's LIGHT — Basic Protection]" ;;
      3) ui_print "👉 [Hagezi's NORMAL — All-round Protection]" ;;
      4) ui_print "👉 [Hagezi's PRO — Extended Protection]" ;;
      5) ui_print "👉 [Hagezi's PRO++ — Maximum Protection]" ;;
      6) ui_print "👉 [Hagezi's ULTIMATE — Aggressive Protection]" ;;
      7) ui_print "👉 [Exit Installation]" ;;
    esac
  }

  print_current_selection

  while true; do
    wait_for_keypress
    key_result=$?

    if [ "$key_result" -eq 1 ]; then
      SELECTION=$((SELECTION + 1))
      [ "$SELECTION" -gt 7 ] && SELECTION=1
      print_current_selection
    elif [ "$key_result" -eq 0 ]; then
      case "$SELECTION" in
        1)
          SELECTED_HOSTS="stevenblack_hosts"
          SELECTED_NAME="Steven Black's List"
          break
          ;;
        2)
          SELECTED_HOSTS="hagezi_light"
          SELECTED_NAME="Hagezi's Multi LIGHT"
          break
          ;;
        3)
          SELECTED_HOSTS="hagezi_normal"
          SELECTED_NAME="Hagezi's Multi NORMAL"
          break
          ;;
        4)
          SELECTED_HOSTS="hagezi_pro"
          SELECTED_NAME="Hagezi's Multi PRO"
          break
          ;;
        5)
          SELECTED_HOSTS="hagezi_pro_plus"
          SELECTED_NAME="Hagezi's Multi PRO++"
          break
          ;;
        6)
          SELECTED_HOSTS="hagezi_ultimate"
          SELECTED_NAME="Hagezi's Multi ULTIMATE"
          break
          ;;
        7)
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