# Broadcast Automator 📢⚡

An open-source, privacy-first Android app for automating user-initiated WhatsApp broadcast campaigns with dynamic contact variables, local SQLite persistence, and zero tracking.

<p align="left">
  <a href="https://apps.obtainium.imranr.dev/redirect?r=obtainium%3A%2F%2Fapp%2F%257B%2522id%2522%253A%2522com.makhanchor.broadcastautomator%2522%252C%2522url%2522%253A%2522https%253A%2F%2Fgithub.com%2Fdilipkn007%2Fbroadcast_automator%2522%252C%2522author%2522%253A%2522dilipkn007%2522%252C%2522name%2522%253A%2522Broadcast%2520Automator%2522%252C%2522additionalSettings%2522%253A%257B%257D%257D">
    <img src="assets/graphics/badge_obtainium.png" alt="Get it on Obtainium" height="55">
  </a>
</p>

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android-green.svg)](https://developer.android.com/)
[![GitHub Release](https://img.shields.io/github/v/release/dilipkn007/broadcast_automator?color=success&include_prereleases)](https://github.com/dilipkn007/broadcast_automator/releases/latest)

---

## 🚀 Download & Installation

### Option 1: One-Click Install with Obtainium (Recommended)
[Obtainium](https://github.com/ImranR98/Obtainium) allows you to install and automatically receive background updates directly from GitHub Releases without needing the Google Play Store.

Tap the button below on your Android device to add Broadcast Automator directly:

<p align="left">
  <a href="https://apps.obtainium.imranr.dev/redirect?r=obtainium%3A%2F%2Fapp%2F%257B%2522id%2522%253A%2522com.makhanchor.broadcastautomator%2522%252C%2522url%2522%253A%2522https%253A%2F%2Fgithub.com%2Fdilipkn007%2Fbroadcast_automator%2522%252C%2522author%2522%253A%2522dilipkn007%2522%252C%2522name%2522%253A%2522Broadcast%2520Automator%2522%252C%2522additionalSettings%2522%253A%257B%257D%257D">
    <img src="assets/graphics/badge_obtainium.png" alt="Get it on Obtainium" height="50">
  </a>
</p>

*Or manually in Obtainium:*
1. Install **Obtainium** on your Android phone ([Obtainium Releases](https://github.com/ImranR98/Obtainium/releases/latest)).
2. Open Obtainium and tap **"Add App"** (`+`).
3. Paste the repository URL:
   ```text
   https://github.com/dilipkn007/broadcast_automator
   ```
4. Tap **Add**. Obtainium will automatically fetch the latest release, install the app, and notify you whenever a new version is released!

### Option 2: Direct APK Download
1. Download the latest **[BroadcastAutomator-v1.0.0.apk](https://github.com/dilipkn007/broadcast_automator/releases/latest)** from [GitHub Releases](https://github.com/dilipkn007/broadcast_automator/releases).
2. Tap the downloaded file to install on your Android device (enable *"Install unknown apps"* if prompted).

---

## ✨ Features

- **⚡ WhatsApp Automation Service**: Native Android Accessibility Service (`WhatsAppAutomationService.kt`) sends queued broadcast messages without requiring third-party cloud APIs.
- **🔒 100% Offline & Private**: All contact lists, campaign logs, and broadcast reports are stored securely in local SQLite on your device. Zero external analytics or trackers.
- **🏷️ Dynamic Template Variables**: Insert `{{Name}}`, `{{Phone}}`, or any custom CSV column using the interactive `@` variable picker.
- **🔁 Retry Failed Messages**: One-tap automated retry for any contacts that failed due to temporary network issues.
- **➡️ Manual Single-Tap Fallback**: Tap `Send ->` next to any failed recipient to open their pre-filled chat in WhatsApp; automatically returns to Broadcast Automator upon sending.
- **📂 Flexible Contact Importing**: Import contacts directly from `.csv` files, system contact multi-picker, or quick text paste with **automatic phone deduplication** and **alphabetical ($A \to Z$) sorting**.
- **⏱️ Smart Timing & Anti-Spam Controls**: Customizable delays, pre-send countdowns, **pause after $X$ messages**, and **automatic countdown resume** after rest periods to protect your WhatsApp account.

---

## 💖 Support & Sponsor the Project

Broadcast Automator is completely free, privacy-first, and open source. If this app saves you time or streamlines your communication, consider backing its ongoing development!

<p align="left">
  <a href="https://github.com/sponsors/dilipkn007">
    <img src="https://img.shields.io/badge/Sponsor%20on-GitHub%20Sponsors-EA4AAA?style=for-the-badge&logo=github-sponsors&logoColor=white" alt="GitHub Sponsors" />
  </a>
  &nbsp;
  <a href="https://buymeacoffee.com/dilipkn007">
    <img src="https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me A Coffee" />
  </a>
  &nbsp;
  <a href="https://patreon.com/dilipkn007">
    <img src="https://img.shields.io/badge/Patreon-FF424D?style=for-the-badge&logo=patreon&logoColor=white" alt="Patreon" />
  </a>
  &nbsp;
  <a href="https://opencollective.com/broadcast_automator">
    <img src="https://img.shields.io/badge/Open%20Collective-7FADF2?style=for-the-badge&logo=open-collective&logoColor=white" alt="Open Collective" />
  </a>
</p>

---

## 🛠️ Required Permissions

To automate WhatsApp dispatches safely, the app requires:
1. **Accessibility Service**: Used locally on-device to click the WhatsApp send button for user-approved broadcasts.
2. **Display over other apps (Overlay)**: Displays the live sending progress overlay on top of WhatsApp so you can monitor or pause campaigns at any time.

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
