#!/system/bin/sh
# StevenBlock: starts the local WebUI server on 127.0.0.1:9090 and opens it in your browser.
# The server stops by itself after 10 minutes without activity.
MODDIR=${0%/*}
sh "$MODDIR/sb.sh" _action
