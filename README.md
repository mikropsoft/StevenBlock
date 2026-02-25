# 🛡️ **StevenBlock**: Your Digital Guardian 🛡️

![Downloads](https://img.shields.io/github/downloads/mikropsoft/StevenBlock/total?color=green&style=for-the-badge)
![Release](https://img.shields.io/github/v/release/mikropsoft/StevenBlock?style=for-the-badge)
![Stars](https://img.shields.io/github/stars/mikropsoft/StevenBlock?style=for-the-badge)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Magisk](https://img.shields.io/badge/Magisk-8A2BE2?style=for-the-badge&logo=magisk&logoColor=white)
![KernelSU](https://img.shields.io/badge/KernelSU-199116?style=for-the-badge&logo=kernelsu&logoColor=white)
![APatch](https://img.shields.io/badge/APatch-3086F8?style=for-the-badge&logo=apatch&logoColor=white)

Hey there, digital explorer! 👋 Ready to reclaim your online experience? Say hello to **StevenBlock v3.0**, your ultimate weapon in the fight against pesky ads, trackers, and sneaky malware. Now supercharged with a brand-new **Web-based UI**! Let's dive into how this little powerhouse can transform your digital life!

## **🚀 What Makes StevenBlock Your Digital Superhero?**

-   **🌐 Sleek WebUI Dashboard**: No extra APKs cluttering your app drawer! StevenBlock now features a gorgeous, Glassmorphism-inspired WebUI accessible directly from your root manager's "Action" button.
-   **🛑 Ad Annihilator**: Wave goodbye to annoying pop-ups, intrusive video ads, and clingy banners. **StevenBlock** makes them vanish system-wide.
-   **🎯 On-Demand Customization**: You are in total control! Open the WebUI anytime to seamlessly switch between multiple blocklists—from light to aggressive—to perfectly match your needs.
-   **🔍 Built-in Hosts Checker**: Want to know if you're protected? Use the WebUI's integrated status checker to see exactly how many thousands of malicious lines are currently blocked, complete with slick, fluid animations!
-   **🛡️ Maximum Stability (Delayed Apply)**: To prevent any system hiccups or active connection crashes, your chosen lists are downloaded securely and applied **only upon the next system reboot**.
-   **🔋 Battery Friendly**: **StevenBlock** is a lean, mean, blocking machine. It's a system-level module, meaning it does its job silently at the DNS level without draining your battery.
-   **🤝 Broad Root Support**: Whether you're using **Magisk**, **KernelSU**, or **APatch**, **StevenBlock** integrates flawlessly. We've got your back.

## **🎯 Choose Your Shield: Premium Blocklists**

Through our modern WebUI, you can select the perfect hosts file that suits your browsing style:

-   **🟢 StevenBlack — Unified Main List (Default)**: The classic, highly recommended balanced blocklist. A great starting point for most users, offering robust daily protection with excellent compatibility.
-   **⚡ Energized Spark — Lightweight Protection**: Ideal for users who want essential protection with the lowest possible impact on system resources. Fast, light, and effective.
-   **🔵 Energized Blu — Medium Protection**: A great all-rounder that offers extended protection against a wider range of threats. The perfect middle ground.
-   **🔥 Energized Ultimate — Aggressive Protection**: For the user who wants maximum security. This list is extensive, providing an absolute shield against ads, trackers, and malware domains.

## **📊 The Numbers Game: How We Protect You**

> [!WARNING]
> Brace yourself: Depending on the list you choose, **StevenBlock** acts as a bouncer for your device, blocking **hundreds of thousands** of troublemakers (malware, ad, and spyware domains). Check the live counter in your WebUI to see the exact number of blocked connections!

## **🧠 Knowledge is Power: F.A.Q. Time!**

> [!TIP]
> **❔: What's this "hosts file" and where is it?**
>
> Think of the hosts file as your device's VIP bouncer list. It lives in `/system/etc/hosts` and tells your device which bad connections to immediately drop before they even load.

> [!TIP]
> **❔: How does StevenBlock actually work?**
>
> It's a master of misdirection. When an app or website tries to connect to a blocked domain, **StevenBlock** redirects that request to a digital dead end (`0.0.0.0` or `127.0.0.1`). 

> [!TIP]
> **❔: How do I know if the module is active?**
>
> Open your root manager, go to Modules, and tap the **Action** button on StevenBlock. In the WebUI, tap **"🔍 Check Hosts Status"**. An animation will instantly show you exactly how many malicious lines are currently blocked!

## **🛠️ Let's Get This Party Started: Installation Guide**

Ready to level up your digital defense? It's as easy as 1-2-3-4:

1.  **Flash It**: Open your root manager (**Magisk**, **KernelSU**, or **APatch**), head to the Modules section, tap 'Install from storage', and select the **StevenBlock v3.0** `.zip` file.
2.  **First Reboot**: Reboot your device once. *Note: The module will automatically apply the default StevenBlack Unified list during this first boot.*
3.  **Launch WebUI**: Go back to your Root Manager's module list and tap the **Action** (or Settings) icon next to StevenBlock. The beautifully designed WebUI will pop up!
4.  **Customize**: Select your preferred shield (Spark, Blu, Ultimate, etc.). Wait for the success toast, and do one final quick reboot to lock in your new ultimate protection. Enjoy!

## **💖 Support the Project 💖**

Enjoying a cleaner, ad-free digital life thanks to **StevenBlock**? Consider supporting its development! Every coffee you buy helps keep the project alive, updated, and continuously improving.

<p align="left">
  <a href="https://buymeacoffee.com/mikropsoft">
    <img src="https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" />
  </a>
</p>

Got questions or want to hang out? Join our **[Telegram group](https://t.me/stevenblockmodule)** and get help from the community!

## **🔔 Hot Off the Press: Updates & Pro Tips**

> [!IMPORTANT]
> If you're already using a root solution like **Magisk**, **KernelSU**, or **APatch**, you **do not** need any other "systemless hosts" modules. **StevenBlock** handles everything perfectly. For best results, avoid using it alongside **AdAway** to prevent conflicts.

> [!TIP]
> **Using KernelSU/APatch and still seeing ads in Chrome?** This is a common Chromium restriction. 
> 
> **How to fix:** Go to the **KernelSU/APatch app → Superuser tab → Select Chrome/Brave → Custom → and uncheck 'umount modules'**. This ensures the hosts file applies correctly to your web browser.

> [!NOTE]
> While we're pros at blocking domains, some ads served directly by the same server as the content (like official YouTube app video ads) cannot be blocked via Hosts file. We're incredibly powerful, but we recommend dedicated modded apps for YouTube!

## **🙌 Standing on the Shoulders of Giants**

A huge shoutout to these amazing projects for making **StevenBlock** possible:

-   **[StevenBlack](https://github.com/StevenBlack)** for being the original hosts file guru and our default provider.
-   **[EnergizedProtection](https://github.com/EnergizedProtection)** for the excellent Spark, Blu, and Ultimate packs that power our advanced options.
-   A special thanks to **[ZG089](https://github.com/ZG089)** for their incredible support and contributions to the project.

---

## **🏆 Watch Us Grow!**

![Activities](https://repobeats.axiom.co/api/embed/359376e8fd59201ac45b1f13f73201c3be069b62.svg)

---

## **⭐ Our Rising Star**

[![Star History Chart](https://api.star-history.com/svg?repos=mikropsoft/StevenBlock,Magisk-Modules-Alt-Repo/StevenBlock&type=Date)](https://star-history.com/#mikropsoft/StevenBlock&Magisk-Modules-Alt-Repo/StevenBlock&Date)

---

<img src="https://raw.githubusercontent.com/matfantinel/matfantinel/master/waves.svg" width="100%" height="100">