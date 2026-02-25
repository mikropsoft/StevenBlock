# 🛡️ StevenBlock | Changelog & History

Welcome to the official release history for **StevenBlock**. Stay up-to-date with all the latest features, improvements, and bug fixes we bring to your digital guardian.

## 🤝 Official Support & Community

Looking for support, the latest news, or want to connect with other users?  
Join our official group to stay in the loop and engage with the StevenBlock community!

> 💬 **[Join us on Telegram](https://t.me/stevenblockmodule)** — This is the *only* official support channel for this module. We'd love to see you there!

---

## 🚀 Release Notes

### **v3.0** — *The Premium WebUI Update* (Latest)
*The biggest update yet, bringing a complete UI overhaul and next-gen stability.*

✨ **New Features:**
- **Brand New WebUI:** Added a gorgeous, Glassmorphism-inspired Web dashboard accessible directly from your Root Manager's (Magisk/KSU/APatch) "Action" button. No extra APK needed!
- **On-Demand Customization:** Switch seamlessly between **StevenBlack** (Default) and **Energized** (Spark, Blu, Ultimate) lists via the new UI.
- **Delayed Apply Mechanism:** To ensure maximum system stability and prevent connection drops, lists are now securely downloaded and applied *only* upon the next system reboot.
- **Built-in Hosts Checker:** View your live protection status and the exact number of blocked malicious domains with fluid animations directly in the dashboard.

⚡ **Improvements & Fixes:**
- **Zero Battery Drain:** Switched to a purely systemless API-based approach. Absolute zero background usage.
- **Next-Gen Root Support:** Flawless compatibility and auto-detection for Magisk, KernelSU, and APatch environments.
- **Busybox Integration:** The module now utilizes the internal `busybox httpd` for the WebUI, eliminating external dependencies.

---

### **v2.0** — *The Energized Expansion*
✨ **New Features:**
- Integrated the highly requested **EnergizedProtection** lists (Spark, Blu, Ultimate) for users needing more aggressive ad-blocking.
- Added native systemless hosts routing specifically tailored for KernelSU users.

⚡ **Improvements & Fixes:**
- Updated the main StevenBlack list to the latest upstream version, blocking an additional 15,000+ new malware domains.
- Optimized shell script execution time during the boot process.
- Fixed a rare issue where some specific tracking domains were bypassing the systemless hosts mount.

---

### **v1.0** — *The Beginning*
✨ **New Features:**
- Birth of StevenBlock! 🛡️
- Standard systemless hosts implementation using the robust StevenBlack Unified list.
- Successfully blocks intrusive ads, malware, and spyware domains system-wide.
- Extremely lightweight with a minimal system footprint.