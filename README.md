# 🛡️ StevenBlock: The Zero-Bloat Digital Guardian 🛡️

![Downloads](https://img.shields.io/github/downloads/mikropsoft/StevenBlock/total?color=green&style=for-the-badge)
![Release](https://img.shields.io/github/v/release/mikropsoft/StevenBlock?style=for-the-badge)
![Stars](https://img.shields.io/github/stars/mikropsoft/StevenBlock?style=for-the-badge)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Magisk](https://img.shields.io/badge/Magisk-8A2BE2?style=for-the-badge&logo=magisk&logoColor=white)
![KernelSU](https://img.shields.io/badge/KernelSU-199116?style=for-the-badge&logo=kernelsu&logoColor=white)
![APatch](https://img.shields.io/badge/APatch-3086F8?style=for-the-badge&logo=apatch&logoColor=white)

Welcome to **StevenBlock v1.0** — the zero-bloat ad blocker for rooted Android, rebuilt from the ground up. 🚀

StevenBlock blocks ads, trackers and malware **across your entire device** with one carefully built `/system/etc/hosts` file. Your root manager mounts it **systemlessly**, so `/system` is never touched. There is no VPN to keep alive, no extra app to install and **no permanent background process** — just a clean hosts file and a polished WebUI to control it.

Pick from **7 curated blocklists**, add your own **Allow / Block rules**, update with one tap and watch every step in real time. Every change is downloaded, verified, optimized and installed with **automatic backups and rollback**, so a bad download can never leave you with a broken hosts file. 🛟

> [!NOTE]
> **v1.0 is a complete rewrite.** The terminal menu, volume-key installer and Energized lists of v5.0 are gone. Installation is now fully automatic and everything is managed from the new WebUI. Coming from v5.0? Read [⬆️ Upgrading from v5.0](#upgrading-from-v50).

## 📑 Table of Contents

- [🚀 Why StevenBlock](#why-stevenblock)
- [⚖️ How It Compares](#how-it-compares)
- [🎯 Blocklists](#blocklists)
- [📱 Compatibility](#compatibility)
- [🛠️ Installation](#installation)
- [🖥️ WebUI Tour](#webui-tour)
- [🧩 Domain Rules Guide](#domain-rules-guide)
- [🛟 Safety Net](#safety-net)
- [🔒 Privacy & Security](#privacy-security)
- [⬆️ Upgrading from v5.0](#upgrading-from-v50)
- [🗑️ Uninstall](#uninstall)
- [🧠 FAQ](#faq)
- [🩺 Troubleshooting](#troubleshooting)
- [🙌 Credits](#credits)
- [📄 License](#license)
- [💖 Support](#support)
- [💬 Community](#community)
- [🏆 Watch Us Grow](#watch-us-grow)
- [⭐ Star History](#star-history)

<a id="why-stevenblock"></a>

## 🚀 Why StevenBlock

- **🖥️ A real WebUI.** Switch lists, update, manage domain rules, check status and read logs from a fast, modern interface with dark and light themes. It opens right inside KernelSU, KernelSU Next, SukiSU and APatch, and from the Action button on Magisk.
- **🔋 Zero permanent background processes.** Blocking is a static hosts file. The local WebUI server only runs while you use it and shuts itself down after 10 minutes without activity. At boot, StevenBlock tidies up leftovers in a moment and exits.
- **🎯 7 curated blocklists.** From the gentle, battle-tested StevenBlack list to HaGeZi Ultimate, each with a clear strength level, live entry count and last-update date.
- **🧩 Your own domain rules.** Always allow a domain a list blocks by mistake, or always block one the list misses. Paste a full URL and StevenBlock extracts the domain for you.
- **🛟 Backed-up, atomic updates.** Every download is validated before it can touch your hosts file. The new file is written next to the old one and swapped in a single step, then verified. If anything fails, the previous file is restored automatically.
- **🧪 Applied-state check.** StevenBlock compares the live `/system/etc/hosts` with its own file and tells you plainly: ✅ Applied, 🟡 Not applied yet — reboot required, or ⚠️ Overridden by another module.
- **🔒 Private by design.** Local only, token-protected, zero telemetry, and the WebUI loads nothing from the internet — not even fonts.
- **⚙️ Fully automatic install.** No questions, no volume keys. StevenBlock detects your root manager, checks for conflicts, cleans up old versions and installs the default list on its own.
- **🛡️ Safe by construction.** Every entry from every list is rewritten to `0.0.0.0`, so a list can only ever block a domain — it can never redirect you somewhere else.

<a id="how-it-compares"></a>

## ⚖️ How It Compares

Every approach has trade-offs. Here is an honest look at how a systemless hosts file stacks up against the other common ways to block ads on Android:

| | 🛡️ StevenBlock (hosts) | 🔐 VPN-based blockers | 🌐 Private DNS | 🧭 Browser extensions |
|---|---|---|---|---|
| **System-wide** | ✅ Yes, for apps that use Android's resolver | ✅ Yes, for traffic routed through the VPN | ✅ Yes, for apps that use Android's resolver | ❌ Only inside that browser |
| **VPN slot** | ✅ Stays free | ❌ Occupied, so no other VPN at the same time | ✅ Stays free | ✅ Stays free |
| **Battery** | ✅ No background service | ⚠️ A service handles traffic all the time | ✅ Negligible | ✅ Minimal |
| **Customization** | ✅ 7 lists plus allow and block rules | ✅ Usually extensive | ⚠️ Depends on the provider | ✅ Extensive, including cosmetic filtering |
| **Root required** | ⚠️ Yes | ✅ No | ✅ No | ✅ No |

> [!TIP]
> A hosts file blocks whole domains. It can't hide page elements (cosmetic filtering) or block ads served from the same domain as the content. A browser with a built-in or extension-based blocker is a great companion for that — it works alongside StevenBlock.

<a id="blocklists"></a>

## 🎯 Blocklists

All lists are downloaded straight from their official sources. Pick one in **📋 Lists** — the WebUI shows each list's live entry count and last-update date, read from the list's own header without downloading the whole file.

| # | List | Type | Level | Approx. entries* | Best for |
|---|---|---|---|---|---|
| 1 | **StevenBlack Main** | Unified list (default) | 🟢 Balanced | Varies | Everyone. The safe, battle-tested default. |
| 2 | **hBlock** | Mixed list built from many sources | 🔵 Mixed | Varies | Broad coverage from many public lists in one file. |
| 3 | **HaGeZi Light** | Basic protection | 🟢 Basic | Varies | Zero-hassle blocking that shouldn't break anything. |
| 4 | **HaGeZi Normal** | All-round protection | 🔵 All-round | Varies | Stronger everyday protection, rarely breaks anything. |
| 5 | **HaGeZi Pro** | Extended protection | 🟡 Extended | Varies | Power users who don't mind an occasional allow rule. |
| 6 | **HaGeZi Pro++** | Aggressive | 🟠 Aggressive | Varies | Experienced users. Some legitimate sites may break. |
| 7 | **HaGeZi Ultimate** | Most aggressive | 🔴 Maximum | Varies | Maximum blocking. Can restrict app and site features. |

<sub>*As of October 2026. Lists update often, so the WebUI always shows the current numbers.</sub>

> [!WARNING]
> 🟠 Pro++ and 🔴 Ultimate are strict on purpose. If something stops working, add the affected domain as an **✅ Allow** rule or step down to a lighter list.

<a id="compatibility"></a>

## 📱 Compatibility

| Root manager | WebUI | Action button | How to open the WebUI |
|---|---|---|---|
| **Magisk v28+** | 🌐 In your browser | ✅ | Tap **Action ▶️** on the StevenBlock card. The WebUI opens in your browser through a private local server. |
| **KernelSU** | ✅ Built in | ✅ | Tap **WebUI** on the StevenBlock card. |
| **KernelSU Next** | ✅ Built in | ✅ | Tap **WebUI** on the StevenBlock card. |
| **SukiSU** | ✅ Built in | ✅ | Tap **WebUI** on the StevenBlock card. |
| **APatch** | ✅ Built in | ✅ | Tap **WebUI** on the StevenBlock card. |

- 🌐 **Magisk** (including the current v31.1) has no built-in module WebUI. The **Action** button (Magisk v28+) starts a private server on `127.0.0.1:9090` and opens the WebUI in your browser. You can also open the WebUI natively with **KsuWebUI**, **MMRL** or **WebUI X**.
- ▶️ On **KernelSU, KernelSU Next, SukiSU and APatch** the Action button works too: it opens the same WebUI in your browser.
- 🧰 StevenBlock uses the BusyBox that ships with your root manager. It downloads with `curl` when available, otherwise with BusyBox `wget`.

<a id="installation"></a>

## 🛠️ Installation

1. **📥 Download** `StevenBlock.zip` from the [StevenBlock repository](https://github.com/mikropsoft/StevenBlock).
2. **📦 Install** it from your root manager: **Modules → Install from storage** → select the zip.
3. **☕ Sit back.** The installer runs on its own:
   - ✅ detects your root manager and BusyBox,
   - 🧩 warns you about conflicting hosts blockers (installation continues),
   - 🧹 removes leftovers from StevenBlock v5.0,
   - 💾 keeps a copy of your original hosts file,
   - ⬇️ downloads, verifies and installs **StevenBlack Main**.
4. **🔁 Reboot.** Your new hosts file is active after the restart.
5. **🖥️ Open the WebUI** — see [📱 Compatibility](#compatibility) for your root manager.

> [!TIP]
> **No internet during install? No problem.** StevenBlock writes a clean localhost-only hosts file and finishes the installation anyway. After you reboot, it retries the download automatically as soon as you're online — and you can also tap **⬇️ Download now** in the WebUI.

> [!NOTE]
> Updating from an earlier v1.x release keeps your selected list, your domain rules and your enabled or disabled state.

<a id="webui-tour"></a>

## 🖥️ WebUI Tour

### 🛡️ Header

The StevenBlock logo, the version and a live status badge: **🟢 Active**, **🔴 Disabled** or **🟡 Reboot required**. The 🌙 / ☀️ button switches between the dark (default) and light themes and remembers your choice. Right below, quick links jump to every section.

### 🔁 Reboot banner

Whenever saved changes are waiting for a reboot, a banner appears at the top with a **🔁 Reboot now** button. It always asks for confirmation first.

### 📊 Protection overview

The number of blocked domains, the active list with its level, your rule counts, when the list was last updated and whether the hosts file is actually applied to the system.

### 📋 Lists

Every list as a card with its name, a short description, a level badge (🟢 / 🔵 / 🟡 / 🟠 / 🔴), the entry count and the last-update date. The active list is highlighted with a **✅ Active** badge and a colored border.

- **⬇️ Use this list** opens a confirmation with the list's details, then shows live progress: **⬇️ Download → 🔍 Verify → 🧹 Optimize → 📦 Install**, with percentage, size and speed whenever the server reports the file size.
- **✖️ Cancel** stops a download safely — nothing is changed.
- **🔽 Hide** tucks the progress into a small bar at the bottom while you keep exploring. Close the WebUI and come back later — a running task is still shown.
- **🔄 Refresh** re-reads entry counts and dates. They are cached for 6 hours.
- If a count can't be fetched, the card says **❌ Couldn't fetch entry count** with a **🔁 Retry** button.

### 🧩 Domain Rules

Type a domain or paste a full URL, then tap **✅ Allow Domain** or **⛔ Block Domain**. Your rules appear in two tabs with a 🗑️ button to remove each one. See the [🧩 Domain Rules Guide](#domain-rules-guide).

### ⚡ Actions

- **🔄 Update Current List** — checks whether the list changed (by its ETag, or the date in its header) and only downloads when there's something new. Otherwise you'll see **✅ Already up to date**.
- **📊 Check Status** — the active list, enabled state, total blocked domains, allow and block rule counts, last update, whether a reboot is pending, your root manager, the module version and the applied state of `/system/etc/hosts`.
- **⏻ Disable / Enable Blocker** — Disable swaps in a clean localhost-only hosts file but keeps your list and rules. Enable rebuilds the hosts file from the cached list instantly, without downloading again. Both take effect after a reboot. While the blocker is disabled, switching or updating lists is paused.

### 📜 Logs

Every operation is logged with a timestamp and a level — **ℹ️ INFO**, **⚠️ WARN** or **❌ ERROR** — color-coded and scrolled to the newest entry. **🧹 Clear logs** asks for confirmation. The log keeps the latest 500 lines.

### 🙌 Credits

Links to the developer's GitHub and the Telegram group, plus the blocklist and font projects StevenBlock is built on. Links open in your browser.

<a id="domain-rules-guide"></a>

## 🧩 Domain Rules Guide

Domain rules sit on top of whichever list you use, and they stay when you switch lists.

| You want to… | Rule | Example |
|---|---|---|
| Unblock a domain your list blocks by mistake | ✅ Allow | `links.newsletter-service.com` |
| Block a domain your list doesn't cover | ⛔ Block | `ads.annoying-site.net` |

- 🔗 **Paste anything.** `https://Shop.Example.com/cart?id=42` becomes `shop.example.com` automatically.
- 🔡 **Lowercase is automatic**, and international domain names are converted to their `xn--` form.
- 🚫 **Not accepted:** spaces, ports (`example.com:8080`), wildcards (`*.example.com`) and IP addresses.
- ⚖️ **One list per domain.** A domain can't be in both Allow and Block — StevenBlock tells you which list already has it.

> [!IMPORTANT]
> Hosts files have **no wildcard support**. A rule matches **exactly** the domain you enter: allowing `example.com` does not allow `cdn.example.com`, and blocking `ads.example.com` does not block `tracker.ads.example.com`. Add each subdomain you need as its own rule.

After a rule change, StevenBlock rebuilds the hosts file from its cached copy of your list — no download needed — and asks for a reboot only if the hosts file actually changed.

<a id="safety-net"></a>

## 🛟 Safety Net

Your hosts file is too important to gamble with, so StevenBlock checks everything twice:

1. **🔒 One task at a time.** A lock file (with stale-lock detection) prevents two operations from colliding. Busy buttons are disabled while a task runs.
2. **💾 Free space check** before every download.
3. **🔍 Download validation.** The server must answer **HTTP 200**, the file can't be empty or an HTML error page, it must contain **at least 1,000 valid entries**, and its size must match `Content-Length`. If any check fails, your hosts file is never touched.
4. **🧹 One-pass normalization** with `awk`: comments, blank lines and CRLF line endings are removed, every redirect becomes `0.0.0.0`, system entries (localhost, broadcasthost, ip6-*) are skipped, invalid domains are dropped, and everything is lowercased and de-duplicated.
5. **🗂️ Backups.** The current hosts file is backed up before every write. The last 3 backups are kept.
6. **⚛️ Atomic write.** The new file is written next to the old one under a temporary name and moved into place in one step, so a half-written hosts file can't happen.
7. **✅ Verification.** The new file must exist, be non-empty, contain the `127.0.0.1 localhost` and `::1 localhost ip6-localhost` lines and have exactly the expected number of entries. If not, the backup is restored automatically.
8. **🧽 DNS cache flush.** StevenBlock tries the `ndc resolver` methods your Android version supports. If none is available, that's only logged — the reboot clears the cache anyway.
9. **📜 Nothing fails silently.** Every error appears in the WebUI and in the log.

<a id="privacy-security"></a>

## 🔒 Privacy & Security

- 🏠 **Local only.** When you open the WebUI with the Action button, its server listens on `127.0.0.1:9090` only — never on your network — and only while you use it. The built-in WebUI of KernelSU, KernelSU Next, SukiSU and APatch needs no server at all.
- 🔑 **Token protected.** Every Action press creates a fresh random session token. Requests without the right token are rejected, so other apps on your phone can't control StevenBlock.
- 🧱 **Locked-down backend.** The WebUI can only call a fixed list of commands. It never sends URLs, file paths or shell commands, and every input is validated again on the device.
- 📵 **Zero telemetry.** No analytics, no tracking, no accounts.
- 🔤 **No external requests from the WebUI.** Fonts, icons and code are all bundled in the module.
- 🌐 **The only network traffic** is downloading the blocklists — and reading their headers for entry counts and dates — from their official sources.
- 🎯 **Lists can only block.** Every entry is rewritten to `0.0.0.0`, so even a tampered list can't redirect a domain to another server.
- 🗄️ **Systemless.** StevenBlock never writes to `/system`. Its data lives in `/data/adb/stevenblock/` and is readable by root only.

<a id="upgrading-from-v50"></a>

## ⬆️ Upgrading from v5.0

StevenBlock v1.0 replaces v5.0. Because it's a complete rewrite, the version numbering starts fresh at **v1.0** — and its version code (1000) is higher than v5.0's (500), so your root manager offers it as a normal update.

**What changed**

| v5.0 | v1.0 |
|---|---|
| 💻 Terminal menu in the Action screen | 🖥️ Full WebUI |
| 🎛️ Volume-key list selection during install | ⚙️ Fully automatic install |
| ⚡ Energized Spark, Blu and Ultimate | 🎯 StevenBlack, hBlock and five HaGeZi lists |
| — | 🧩 Allow and block rules, 🛟 backups and rollback, 🧪 applied-state check, 📜 logs |

**What happens to your old setup**

- 🧹 The v5.0 files `config.txt`, `hosts.bak` and `hosts.tmp` in `/data/adb/stevenblock/` are removed automatically during installation, and the old terminal menu is replaced by the new module files.
- 🎯 Energized lists are no longer offered, so every v5.0 user starts with **StevenBlack Main**. Switch to any other list from the WebUI after rebooting.

<a id="uninstall"></a>

## 🗑️ Uninstall

1. Open your root manager → **Modules** → StevenBlock → **Remove**.
2. **Reboot.**

On removal StevenBlock stops its WebUI server, deletes `/data/adb/stevenblock/` and its temporary files. Because `/system` was never modified, your original hosts file is back after the reboot — no traces left.

<a id="faq"></a>

## 🧠 FAQ

<details>
<summary>❔ Can I use StevenBlock together with AdAway or Magisk's “Systemless hosts”?</summary>

Please don't. Only one module can provide `/system/etc/hosts`, so two hosts-based blockers fight over the same file. Turn off **Systemless hosts** in Magisk (it creates a module called “Systemless Hosts” — remove it in the Modules tab) and don't use AdAway's root (hosts) mode alongside StevenBlock. The installer and **📊 Check Status** warn you when they spot a conflict.

</details>

<details>
<summary>❔ I use KernelSU, KernelSU Next, SukiSU or APatch and still see ads in Chrome. Why?</summary>

These managers can hide module changes from apps that aren't granted root — the **umount modules** option. If it's active for your browser, the browser sees the original hosts file instead of StevenBlock's.

**Fix:** open your root manager → **Superuser** → select **Chrome** (or Brave, Edge…) → **Custom** → **uncheck “umount modules”**. Then fully close and reopen the browser.

</details>

<details>
<summary>❔ Do browsers with “Secure DNS” bypass the hosts file?</summary>

They can. Chromium-based browsers (Chrome, Brave, Edge and others) have a built-in **Secure DNS** (DNS-over-HTTPS) option that can resolve domains on its own instead of through Android's resolver, which means your hosts file may be skipped.

**Fix in Chrome:** **Settings → Privacy and security → Use secure DNS → turn it off.** Other Chromium browsers have the same option in their privacy or security settings. Android's own **Private DNS** setting is different: it doesn't bypass the hosts file, so you can keep using it.

</details>

<details>
<summary>❔ Why does the official YouTube app still show video ads?</summary>

Those ads are served from the same servers as the videos themselves. A hosts file blocks whole domains, so blocking them would also block the videos. That's a limitation of every hosts-based blocker. For ad-free YouTube, use a client with built-in ad blocking such as ReVanced. StevenBlock keeps handling everything else on your device.

</details>

<details>
<summary>❔ Why do my changes need a reboot?</summary>

Your root manager mounts StevenBlock's hosts file over `/system/etc/hosts` at boot. When StevenBlock installs a new hosts file, it swaps in a complete new file atomically — but the mount keeps showing the previous file until the next boot. Your current protection keeps working in the meantime. After the reboot, **📊 Check Status** shows ✅ Applied.

</details>

<details>
<summary>❔ A website or app broke. What now?</summary>

1. 🧪 Find out whether StevenBlock is the cause: **⏻ Disable Blocker**, reboot and try again. (Enable it again afterwards.)
2. 🔍 Identify the blocked domain — the error message, a browser's network inspector or the app's support pages often name it.
3. ✅ Add that domain as an **Allow** rule. Remember that rules match the exact domain only.
4. 🎚️ Using 🟠 Pro++ or 🔴 Ultimate? Step down to 🟡 Pro or 🔵 Normal — the stricter lists trade compatibility for blocking power.

</details>

<details>
<summary>❔ Does StevenBlock slow down my phone or drain my battery?</summary>

No background service runs for blocking — it's a static file read by Android's resolver. Downloading and processing a list takes a few seconds and only happens when you switch or update. The WebUI server only runs while you use it.

</details>

<a id="troubleshooting"></a>

## 🩺 Troubleshooting

| Symptom | Solution |
|---|---|
| 🟡 “Not applied yet — reboot required” | Reboot. Saved changes become active after the restart. |
| ⚠️ “Overridden by another module” | Another module provides `/system/etc/hosts` (often Magisk's Systemless hosts or AdAway). Remove or disable it and reboot. **📊 Check Status** lists the conflicting modules. |
| 🔌 “WebUI server stopped” in the browser | The server stops after 10 minutes without activity. Tap **Action ▶️** again. |
| 🔑 “Session expired” or “Secure session required” | Open the WebUI from the **Action ▶️** button — each press creates a new secure link. |
| ❌ “Port 9090 is already in use by another app” | Another app is using port 9090. Close it (or reboot) and press **Action ▶️** again. |
| ❌ “BusyBox httpd isn't available” | Your BusyBox lacks `httpd`. Open the WebUI with KsuWebUI, MMRL or WebUI X instead. |
| 🌐 “Couldn't reach the list server” | Check your connection and try again. Your previous hosts file stays in place. |
| 🧱 “The server sent a web page instead of a hosts list” | A captive portal or network filter answered instead of the list server. Sign in to the network or switch networks, then retry. |
| ⏳ “Setup pending” after installing offline | Connect to the internet — StevenBlock retries automatically after boot — or tap **⬇️ Download now**. |
| ❌ “Couldn't fetch entry count” on a card | Tap **🔁 Retry** on the card or **🔄 Refresh** at the top of the list section. |
| 📺 Ads still show in a browser | See the FAQ entries on **umount modules** and **Secure DNS**. |

Still stuck? Check **📜 Logs** in the WebUI and ask in the [Telegram group](https://t.me/stevenblockmodule).

<a id="credits"></a>

## 🙌 Credits

StevenBlock stands on the shoulders of these outstanding open-source projects:

- **[StevenBlack](https://github.com/StevenBlack/hosts)** — the unified hosts list behind our default, StevenBlack Main.
- **[hBlock](https://github.com/hectorm/hblock)** — merges many reputable blocklists into one hosts file.
- **[HaGeZi](https://github.com/hagezi/dns-blocklists)** — the Light, Normal, Pro, Pro++ and Ultimate lists.
- **[Inter](https://github.com/rsms/inter)** by Rasmus Andersson — the typeface of the WebUI, bundled under the SIL Open Font License 1.1.

<a id="license"></a>

## 📄 License

StevenBlock is released under the **GNU General Public License v2.0** — see [LICENSE](LICENSE). The blocklists belong to their maintainers and are downloaded directly from their official sources. The Inter font is distributed under the SIL Open Font License 1.1; its license is included in `webroot/fonts/LICENSE.txt`.

<a id="support"></a>

## 💖 Support

StevenBlock is built and maintained in spare time. If it keeps your phone clean, fast and private, you can help:

- ⭐ **Star the repository** — it helps others find StevenBlock.
- 📣 **Share it** with friends who root their phones.
- 🐞 **Report bugs** with a screenshot of **📊 Check Status** and the relevant **📜 Logs** entries.

<a id="community"></a>

## 💬 Community

Questions, ideas or just want to hang out with fellow performance purists? Join our **[Telegram group](https://t.me/stevenblockmodule)**! 🎉

---

<a id="watch-us-grow"></a>

## 🏆 Watch Us Grow

![Activities](https://repobeats.axiom.co/api/embed/359376e8fd59201ac45b1f13f73201c3be069b62.svg)

---

<a id="star-history"></a>

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=mikropsoft/StevenBlock,Magisk-Modules-Alt-Repo/StevenBlock&type=Date)](https://star-history.com/#mikropsoft/StevenBlock&Magisk-Modules-Alt-Repo/StevenBlock&Date)

---

<img src="https://raw.githubusercontent.com/matfantinel/matfantinel/master/waves.svg" width="100%" height="100">
