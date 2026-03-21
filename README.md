# 🛡️ **StevenBlock**: The Zero-Bloat Digital Guardian 🛡️

![Downloads](https://img.shields.io/github/downloads/mikropsoft/StevenBlock/total?color=green&style=for-the-badge)
![Release](https://img.shields.io/github/v/release/mikropsoft/StevenBlock?style=for-the-badge)
![Stars](https://img.shields.io/github/stars/mikropsoft/StevenBlock?style=for-the-badge)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Magisk](https://img.shields.io/badge/Magisk-8A2BE2?style=for-the-badge&logo=magisk&logoColor=white)
![KernelSU](https://img.shields.io/badge/KernelSU-199116?style=for-the-badge&logo=kernelsu&logoColor=white)
![APatch](https://img.shields.io/badge/APatch-3086F8?style=for-the-badge&logo=apatch&logoColor=white)

Welcome to the unapologetic, raw power of **StevenBlock**. We looked at the current landscape of mobile adblockers—heavy applications, resource-hogging web dashboards, and battery-draining background services—and decided to throw it all in the trash. 

StevenBlock is a return to absolute efficiency. It is a system-wide, ultra-lightweight shield against intrusive ads, invisible trackers, and malicious telemetry. How does it work? By utilizing a rock-solid, purely optimized `/system/etc/hosts` file managed entirely through a fast, interactive command-line interface. 

Zero background processes. Zero active RAM usage. We kill bad connections at the DNS level before they even have a chance to request a single byte of your data.

## 🚀 **Why StevenBlock Demolishes the Competition**

-   **💻 Pure Terminal Configuration**: Say goodbye to extra APKs and delayed web interfaces. Everything from installation to list updates is handled through a brutally fast CLI via your root manager's Action menu.
-   **🛑 System-Wide Annihilation**: Unlike browser-only extensions, StevenBlock covers your entire operating system. It neutralizes pop-ups, clinging banners, and hidden app telemetry globally.
-   **🎛️ Interactive Hardware Installation**: Flashing the module? You don't need a screen setup. Use your physical **Volume Keys** (or standard terminal input for KSU/APatch users) right during the flash process to choose your exact level of protection.
-   **📅 Live Repository Intelligence**: Before you commit to downloading a blocklist, our script communicates directly with GitHub repositories to fetch the exact last-commit dates. You are never left guessing how fresh your digital armor is.
-   **🧹 Aggressive Automated Cleanup**: StevenBlock doesn't just download files; it sanitizes them. It automatically strips dead domains, removes unnecessary localhost mappings, optimizes the structure, and relentlessly flushes your Android DNS cache (`ndc resolver`) to ensure your new rules apply instantaneously.
-   **🔋 Absolute Zero Battery Drain**: By relying solely on a static host file and on-demand terminal scripts, StevenBlock does its heavy lifting without ever keeping your device's CPU awake.

## 🎯 **Choose Your Shield: The Elite Blocklists**

We understand that every user's browsing habits are different. Whether you want a silent guardian or an aggressive bouncer, you can select your preferred weapon during installation or anytime via the Action menu:

-   **🟢 [1] Default (StevenBlack Main)**: The undeniable gold standard. A perfectly balanced, highly recommended blocklist that provides excellent daily protection without breaking the functionality of your favorite websites.
-   **⚡ [2] Light (Energized Spark)**: Essential, uncompromised protection with the absolute minimum system footprint. Fast, incredibly lean, and highly compatible with almost everything.
-   **🔵 [3] Medium (Energized Blu)**: The perfect sweet spot. It offers significantly expanded protection against a much wider range of malicious domains and sneaky telemetry networks. 
-   **🔥 [4] Aggressive (Energized Ultimate)**: Total, uncompromising lockdown. A massive, comprehensive list designed for the truly paranoid who demand maximum security. *Fair warning: Its strict nature might break some legitimate sites.*

## 🛠️ **The Art of Defense: Installation & Usage**

Ready to ditch the bloatware and embrace the terminal? Here is how you wield this tool:

### **Initial Setup**
1.  **Flash It**: Open your preferred root manager (**Magisk**, **KernelSU**, or **APatch**), navigate to the Modules section, tap 'Install from storage', and select the **StevenBlock** `.zip` file.
2.  **Make Your Choice**: Keep your eyes on the screen! The interactive installer will prompt you to select your blocklist. Use your **Volume UP/DOWN** keys (Magisk) or simply type your choice (KSU/APatch) to lock in your preferred list.
3.  **Reboot**: Perform a quick reboot to cement your new hosts file into the system.

### **Commanding the Action Menu**
Want to switch your blocklist or force an update? There is absolutely no need to reflash the module!
1. Open your Root Manager's module list.
2. Tap the **Action** (or Settings/Gear) icon located next to StevenBlock.
3. A terminal window will instantly deploy our custom CLI. Your options:
   - `[1]` Reconfigure your setup and choose a completely different list.
   - `[2]` Force a real-time update of your currently active list.
   - `[3]` View your live status matrix (Active list name, total domains blocked, and the exact timestamp of your last update).
   - `[4]` Exit the interface cleanly.

## 🧠 **F.A.Q. & Advanced Troubleshooting**

> [!TIP]
> **❔: Do I need to run other adblockers alongside this?**
>
> **Absolutely not.** If you are running StevenBlock, you must disable "Systemless Hosts" options in your root manager and uninstall apps like AdAway. Running multiple hosts-based blockers simultaneously will only create system conflicts and utter chaos. Let StevenBlock handle the heavy lifting.

> [!TIP]
> **❔: I'm using KernelSU/APatch, but Google Chrome is still showing ads!**
>
> Chromium-based browsers have a nasty habit of ignoring standard system mounts to serve you ads. 
> **The Fix:** It's simple. Open your **KernelSU/APatch app → Go to the Superuser tab → Select Chrome (or Brave) → Choose Custom → UNCHECK 'umount modules'**. Restart your browser, and the ads will vanish.

> [!WARNING]
> **❔: Why am I still seeing video ads inside the official YouTube app?**
>
> Because those specific ads are injected directly from the exact same servers as the actual video content. A hosts file cannot block those without breaking the video playback entirely. StevenBlock is powerful, but it's not magic. For YouTube, you need a dedicated, modded client (like ReVanced). StevenBlock will handle literally everything else on your device.

## 🙌 **Standing on the Shoulders of Giants**

StevenBlock's ruthless efficiency and vast databases wouldn't be possible without the tireless work of these incredible open-source projects:

-   **[StevenBlack](https://github.com/StevenBlack)**: The original hosts file visionary powering our flawlessly balanced default list.
-   **[EnergizedProtection](https://github.com/EnergizedProtection)**: The architects behind the massive, unyielding databases that fuel our Spark, Blu, and Ultimate packs.

## 💖 **Support the Rebellion 💖**

Building, maintaining, and refining zero-bloat tools takes countless hours and an unhealthy amount of caffeine. If StevenBlock has successfully preserved your sanity and extended your battery life, consider fueling the development!

<p align="left">
  <a href="https://buymeacoffee.com/mikropsoft">
    <img src="https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" />
  </a>
</p>

Are you running into terminal output errors, or do you just want to hang out with fellow performance purists? Join our **[Telegram group](https://t.me/stevenblockmodule)** and step into the community!

---

## 🏆 **Watch Us Grow!**

![Activities](https://repobeats.axiom.co/api/embed/359376e8fd59201ac45b1f13f73201c3be069b62.svg)

---

## ⭐ **Our Rising Star**

[![Star History Chart](https://api.star-history.com/svg?repos=mikropsoft/StevenBlock,Magisk-Modules-Alt-Repo/StevenBlock&type=Date)](https://star-history.com/#mikropsoft/StevenBlock&Magisk-Modules-Alt-Repo/StevenBlock&Date)

---

<img src="https://raw.githubusercontent.com/matfantinel/matfantinel/master/waves.svg" width="100%" height="100">
