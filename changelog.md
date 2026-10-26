# 🛡️ StevenBlock v1.0

StevenBlock was rewritten from scratch, so this brand-new architecture starts a fresh version line at v1.0.

## 🚀 Highlights

- 🖥️ **Brand-new WebUI** — switch lists, update, manage domain rules, check status and read logs from one polished interface.
- ⚙️ **Fully automatic install** — no questions, no volume keys. The installer detects your root manager, checks for conflicts, cleans up old versions and installs the default list.
- 🔋 **Zero permanent background processes** — blocking is a static hosts file, and the local WebUI server only runs while you use it.
- 🛟 **Backed-up, atomic updates** — downloads are validated before they can touch your hosts file, and every write can be rolled back.
- 🧪 **Applied-state check** — see at a glance whether your hosts file is ✅ Applied, 🟡 Not applied yet or ⚠️ Overridden by another module.
- 🔒 **Private by design** — local only, token-protected, no telemetry, no external requests from the WebUI.

## 🎯 New blocklists

- 🟢 **StevenBlack Main** — the balanced default 
- 🔵 **hBlock** — a mixed list built from many sources
- 🟢 **HaGeZi Light** — basic protection 
- 🔵 **HaGeZi Normal** — all-round protection 
- 🟡 **HaGeZi Pro** — extended protection 
- 🟠 **HaGeZi Pro++** — aggressive, may break some sites 
- 🔴 **HaGeZi Ultimate** — the most aggressive option 
- 📊 Live entry counts and last-update dates, read from each list's header without downloading the whole file

## 🖥️ WebUI

- 📋 **Lists** — level badges, entry counts, dates and a clearly marked active list
- ⬇️ **Live progress** — download, verify, optimize and install steps with percentage, size, speed and a ✖️ Cancel button
- 🧩 **Domain Rules** — ✅ Allow and ⛔ Block single domains; paste a full URL and the domain is extracted for you
- ⚡ **Actions** — 🔄 Update Current List, 📊 Check Status and ⏻ Disable / Enable Blocker
- 📜 **Logs** — timestamped, color-coded entries (ℹ️ INFO, ⚠️ WARN, ❌ ERROR)
- 🔁 **Reboot banner** — appears whenever saved changes are waiting for a reboot
- 🌙 **Dark and ☀️ light themes**, built for phones from 360 px up to tablets
- 📱 Opens inside KernelSU, KernelSU Next, SukiSU and APatch, and from the Action button on Magisk v28+ (or with KsuWebUI, MMRL and WebUI X)

## 🛟 Safety net

- 🔍 Every download must return HTTP 200, can't be empty or an HTML page, must contain at least 1,000 valid entries and must match its Content-Length
- 🧹 One-pass normalization: every entry becomes 0.0.0.0, duplicates and invalid domains are removed
- 💾 The last 3 hosts files are kept as backups
- ⚛️ Atomic writes and post-write verification with automatic restore
- 🔒 One task at a time, with stale-lock detection
- 🌐 Offline install? StevenBlock finishes installing and downloads your list automatically after the next boot

## ⬆️ Upgrading from v5.0

- 💻 The terminal menu, 🎛️ volume-key installer and ⚡ Energized lists have been removed
- 🧹 v5.0 leftovers (config.txt, hosts.bak, hosts.tmp) are cleaned up automatically
- 🎯 Everyone starts on StevenBlack Main — pick any other list in the WebUI after rebooting
- 🔁 Reboot after the update to activate StevenBlock v1.0
