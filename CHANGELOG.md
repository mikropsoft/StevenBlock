# 🛡️ StevenBlock v2.0

v2.0 keeps everything v1.0 does and removes its biggest wait: the reboot. Changes now go live the moment you make them, lists can be stacked, updates can run on a schedule, and the whole module checks and repairs itself. Your list, rules and settings are carried over automatically.

## 🚀 Highlights

- ⚡ **Live apply** — new lists and rules take effect without a reboot whenever your device allows it, with an honest “Reboot required” fallback.
- ➕ **Add-ons** — stack 14 optional lists (content categories, security feeds, device tracker lists) on top of your main list.
- 🔗 **Your own lists** — add up to 8 custom HTTPS lists by address.
- 🔄 **Auto-update** — optional daily, 3-day or weekly schedule that only downloads what changed.
- ✳️ **Wildcard allow rules** — `*.example.com` allows a domain together with all of its subdomains.
- 🔍 **Domain lookup** — find out whether and why a domain is blocked, search by keyword and fix it with one tap.
- 📥 **Rule import and export** — move your rules in and out as plain text.
- 🩺 **Health Check and 🛠️ Repair** — verify the whole setup and rebuild it from the cache.
- 🔏 **Private DNS guard** — your Private DNS provider is never blocked.
- 🗜️ **Compressed downloads** — about 75–79% less data in our measurements.

## ⚡ Live apply

- ✍️ The hosts file is written in place into the file that is already mounted, so Android sees the new content immediately.
- 🔍 After every change StevenBlock compares the live `/system/etc/hosts` with its own file and only then reports “Active now”.
- 🔗 If Android is using a stale copy and no other module provides a hosts file, StevenBlock bind-mounts its own file right away instead of waiting for the next boot.
- 🔁 If the change can't be made live — another module owns the hosts file, or the mount point can't be replaced — the familiar reboot banner appears. Nothing is ever reported as applied when it isn't.
- 🧱 **Settings → ⚡ Live apply** turns it off and restores the v1.0 behaviour: atomic swap, then reboot.
- 🧽 The DNS cache flush now runs after a live change, when it actually matters, instead of before a reboot.
- 🟢 Disabling and enabling the blocker is live as well.

## ➕ Add-ons and custom lists

- 🎭 **Content categories** from StevenBlack: Fake news, Gambling, Adult content, Social networks.
- 🔐 **Security** from HaGeZi: Encrypted DNS bypass, Threat Intelligence.
- 📱 **Device & app trackers** from HaGeZi: Xiaomi, Samsung, Huawei, OPPO & Realme, Vivo, Amazon, TikTok, Microsoft.
- ✨ The tracker add-on that matches your device's brand is marked **For your device**.
- 🧮 Lists are merged and de-duplicated across all sources. Every add-on shows how many of its entries are new on top of your main list.
- 🧩 Flip several switches, review the changes — including warnings for large or strict add-ons — and apply them in one task with per-list progress (“2 of 3”).
- 🔗 Custom lists accept hosts files, plain domain lists and simple `||domain^` lists, up to 64 MB each.
- 🛟 If a new add-on can't be downloaded, nothing changes. If an existing add-on can't be refreshed during an update, its previous version stays in use and you're told.
- ♻️ Switching the main list keeps your add-ons and only downloads the new main list.

## 🔄 Auto-update

- 🕒 Off by default. Daily, every 3 days or weekly.
- 😴 One sleeping shell process, started only while the setting is on, wakes up every 15 minutes to see whether a check is due.
- 🔎 A check reads the first 8 KB of each list. Full downloads only happen for lists that changed.
- 🛑 After a failed attempt it waits about an hour.
- ⚡ Updated lists go live without a reboot.

## 🧩 Domain rules

- ✳️ Wildcard allow rules: `*.example.com` covers the domain and every subdomain.
- ⚖️ Contradictions are caught, including wildcard ones: blocking a domain that a wildcard allows, or allowing a wildcard that covers one of your block rules.
- 🔍 **Check this domain** explains whether a domain is blocked, by which list, add-on or rule, how many of its subdomains are blocked, and offers the matching fix. A keyword lists the blocked domains that contain it.
- 📥 **Import rules** understands `allow` / `block` lines, hosts lines, `+domain` / `-domain` and plain domains, previews how many entries are valid, and can add to or replace your rules. The whole import is one rebuild and is rolled back if it fails.
- 📤 **Export rules** shows every rule as copyable text.
- 🔎 A filter box appears once a rule list gets long.
- ⏱️ Quick rule changes that arrive at the same time now wait for each other instead of failing with “Another task is still running”.

## 🩺 Health Check, Repair and status

- 🩺 **Health Check** verifies the hosts file line by line and by checksum, the mount, conflicting modules, the cache, list age, the scheduler, the downloader, the connection to the list server, BusyBox, free storage and your Private DNS provider.
- 📋 **Report** turns status, health check and the latest log lines into text for a bug report.
- 🛠️ **Repair** rebuilds the hosts file from the cache, records a new checksum and mounts the file if needed — without downloading anything.
- 🔏 **Private DNS guard**: when Android's Private DNS uses a provider hostname, that hostname is left out of the blocklist. Your own Block rule still wins.
- 📊 **Check Status** now also shows add-ons, auto-update, live apply, the Private DNS provider and the hosts file size.
- 🕒 The overview warns when your lists are more than a week old.

## 🖥️ WebUI

- ⚙️ New **Settings** sheet for live apply and auto-update.
- ➕ New **Add-ons** section with switches, groups and an apply bar.
- 📜 Logs can be filtered by warnings or errors and copied.
- 🏷️ Overview tags for live apply, auto-update and the Private DNS guard.
- ⬇️ Progress shows which list is being downloaded and its real size, even for compressed transfers.
- ⌨️ Dialogs keep keyboard focus inside them, and every control has an accessible name.
- 📱 Layout fixes for narrow screens down to 320 px.
- 🎨 Same look, same emoji, same dark and light themes.

## 💻 Command line

- 🧾 Every WebUI action is a documented command of `sb.sh` with one line of JSON as output and a meaningful exit status.
- ⏳ New `wait` command blocks until the running task has finished — ideal for scripts.
- ❓ New `help` command.

## 🚄 Performance

Measured on the same x86-64 test machine with BusyBox 1.36 and the real HaGeZi Ultimate list (614,141 entries); medians of three runs. Phones are slower, but the ratios carry over.

| | v1.0 | v2.0 |
|---|---|---|
| Install HaGeZi Ultimate | 5.1 s | 5.1 s |
| Add a block rule | 1.2 s | 1.2 s |
| `status` call | 29 ms | 20 ms |
| `lists` call | 36 ms | 18 ms |
| Data directory | 55.6 MB | 17.1 MB |
| Download size of HaGeZi Ultimate | 21.2 MB | 4.5 MB |

- 🗜️ `curl` downloads are compressed in transit: 75–79% less data for the three lists we measured.
- 🗂️ Backups are compressed and only taken before list changes, which is where most of the storage saving comes from.
- 🍴 Status and list requests start far fewer helper processes.
- 🧹 The list normalizer is about 25% faster on its own (HaGeZi Ultimate: 5.0 s → 3.8 s) with byte-identical output on all 22 real lists we compared. That time is reinvested in the new checksums, merging and verification, so installing a list takes about as long as before.
- 🧵 Building the hosts file is split into a merge step, which only runs when your lists change, and a streaming step for rule changes that needs about 12 MB of memory regardless of list size. A rule change on a 1.6-million-entry setup takes about 5 seconds on the test machine.
- 🔗 The applied-state check recognises the mounted file by identity before falling back to a byte comparison.

## 🐛 Fixed

- 🧰 Requests from the browser WebUI ran on Android's system shell and tools instead of the root manager's BusyBox, so they could behave differently from every other code path or fail on devices without a system `awk`. Every process now switches to BusyBox on its own.
- 🔢 Task results could stop appearing in the WebUI after a reinstall, because the task counter restarted while the WebUI remembered a higher number. The counter is now time-based.
- 🗂️ Backups 2 and 3 were kept but never used. Recovery now tries all three.
- 🔁 A first download that failed five times stayed failed until you retried by hand. It is now retried at every boot.
- 🌐 Domains whose name starts with `ip6-` were silently dropped from every list. Only real system names are skipped now.
- 🕒 For lists whose server sends neither an ETag nor a date header, the update check didn't fall back to `Last-Modified` and downloaded them again every time.
- 🧾 Verification only counted block entries, so stray lines in the hosts file went unnoticed. The line count is now exact, the health check validates every line, and a checksum is compared at every boot.
- 🔗 A “conflict” or “mount failed” state could stick for the rest of the session after the hosts file had been applied.
- 🧭 A leftover KernelSU or APatch file on a Magisk device could make StevenBlock report the wrong root manager.
- ✂️ Cancelling a BusyBox `wget` download left its TLS helper running for a moment.
- 📝 Two tasks writing to the log at the same moment could clobber each other while the log was being trimmed.
- 🧮 A stored value that ended in `=` lost that character when it was read back. Settings and state files are now parsed without field splitting.
- 📭 A list server that answers a size probe with HTTP 416 is handled instead of being reported as an error.
- 📄 `README.md` referred to a `LICENSE` file that was missing from the zip. It is included now.

## 🔒 Security

- ✋ A multi-line argument passed from a root shell or the root manager bridge could slip an unvalidated line into a rule list. Arguments with line breaks are rejected, and rule lists are written by a single validating engine.
- 🔐 `curl` is restricted to HTTPS, including redirects.
- 🐘 Downloads are capped at 64 MB, both by the announced size and by the size on disk.
- 📮 The browser WebUI sends its token in the request body with `POST`. `Host`, `Referer` and the request method are checked, and API responses carry `X-Frame-Options`, `nosniff` and `no-store`.
- 🖼️ In a browser, the WebUI refuses to run inside another page.
- 🧱 Identifiers, settings values and custom list addresses are validated against strict patterns before they are used. Custom lists must be HTTPS addresses with a real domain name.
- 🧾 The session token is created with private permissions from the start.
- 🧨 Background helpers started by a download are stopped together with it.

## 🔁 Changed

- 🧾 The hosts file no longer has a comment header. It contains the two localhost lines and block entries only.
- 🗂️ Backups are compressed and created before list changes, not before rule changes.
- 🔄 “Update Current List” is now **Update Lists** and covers add-ons too.
- 🧩 The minimum number of valid entries is set per list: 1,000 for main lists, lower for the small add-ons.
- 📜 The update manifest now points to `CHANGELOG.md`.
- 🧹 `CHANGELOG.md`, `LICENSE` and `update.json` are not copied to the device.
- 💬 Messages say “Active now” when a change is live and “Reboot to apply” only when it isn't.

## ⬆️ Upgrading from v1.0

- ♻️ Your main list, domain rules and enabled or disabled state are kept. The cached list is moved to the new layout, so nothing is downloaded again.
- 🔌 All v1.0 commands and their JSON fields still exist. New fields were added, none were removed.
- ⚡ Live apply starts **on**, auto-update starts **off**.
- 🔁 Reboot once after installing the update.

## 🧪 Quality

- 🧪 About 900 automated backend checks, run in each of five simulated environments: Magisk-, KernelSU- and APatch-style setups with BusyBox ash, BusyBox `wget` instead of `curl`, and a setup without any root manager BusyBox (mksh, toybox, one-true-awk).
- 🧮 Every embedded `awk` program is unit-tested against four `awk` implementations.
- 🧫 Covered: fresh, offline, recovery and upgrade installs, every command, download failures, cancellation, concurrency, boot-time repair, the scheduler, the local server and its request checks, hostile input, and live apply on bind mounts, overlay mounts, stale copies and conflicting modules.
- 🌐 End-to-end browser tests of the WebUI in both the local-server mode and the root-manager bridge mode.
- 📥 Real downloads from GitHub for the main lists and all add-ons. hBlock's server couldn't be reached from the test environment, so that list was exercised with a simulated copy only.
- ⚠️ These tests ran in a simulated Android environment on Linux. A run on a physical device is not part of them.

---

# 🛡️ StevenBlock v1.0

StevenBlock was rewritten from scratch, so this brand-new architecture started a fresh version line at v1.0.

- 🖥️ Brand-new WebUI for lists, updates, domain rules, status and logs.
- ⚙️ Fully automatic install with root manager detection, conflict checks and cleanup of older versions.
- 🔋 No permanent background processes; the local WebUI server only runs while you use it.
- 🛟 Validated downloads, backups, atomic writes and post-write verification with automatic restore.
- 🧪 Applied-state check, and a direct mount when the root manager doesn't mount the hosts file.
- 🎯 Seven blocklists: StevenBlack Main, hBlock and HaGeZi Light, Normal, Pro, Pro++ and Ultimate.
- 🧩 Allow and block rules for single domains.
- 🔒 Local only, token-protected, no telemetry.
- ⬆️ Replaced the terminal menu, volume-key installer and Energized lists of v5.0.
