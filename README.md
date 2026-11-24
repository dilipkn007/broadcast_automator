# Broadcast Automator 📢⚡

An open-source, privacy-first Android app for automating user-initiated WhatsApp broadcast campaigns with dynamic contact variables, local SQLite persistence, and zero tracking.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android-green.svg)](https://developer.android.com/)
[![GitHub Release](https://img.shields.io/github/v/release/dilipkn007/broadcast_automator?color=success&include_prereleases)](https://github.com/dilipkn007/broadcast_automator/releases/latest)
[![Obtainium](https://img.shields.io/badge/Install%20via-Obtainium-purple.svg)](https://github.com/ImranR98/Obtainium)

---

## 🚀 Download & Installation

### Option 1: Direct APK Download (Quickest)
1. Download the latest **[BroadcastAutomator-v1.0.0.apk](https://github.com/dilipkn007/broadcast_automator/releases/latest)** from [GitHub Releases](https://github.com/dilipkn007/broadcast_automator/releases).
2. Tap the downloaded file to install on your Android device (enable *"Install unknown apps"* if prompted).

### Option 2: Automatic Updates with Obtainium (Recommended)
[Obtainium](https://github.com/ImranR98/Obtainium) allows you to install and automatically receive background updates directly from GitHub Releases without needing the Google Play Store:

1. Install **Obtainium** on your Android phone ([Obtainium GitHub](https://github.com/ImranR98/Obtainium/releases/latest)).
2. Open Obtainium and tap **"Add App"** (`+`).
3. Paste the repository URL:
   ```text
   https://github.com/dilipkn007/broadcast_automator
   ```
4. Tap **Add**. Obtainium will automatically fetch the latest release, install the app, and notify you whenever a new version is released!

---

## ✨ Features

- **⚡ WhatsApp Automation Service**: Native Android Accessibility Service (`WhatsAppAutomationService.kt`) sends queued broadcast messages without requiring third-party cloud APIs.
- **🔒 100% Offline & Private**: All contact lists, campaign logs, and broadcast reports are stored securely in local SQLite on your device. Zero external analytics or trackers.
- **🏷️ Dynamic Template Variables**: Insert `{{Name}}`, `{{Phone}}`, or any custom CSV column using the interactive `@` variable picker.
- **🔁 Retry Failed Messages**: One-tap automated retry for any contacts that failed due to temporary network issues.
- **➡️ Manual Single-Tap Fallback**: Tap `Send ->` next to any failed recipient to open their pre-filled chat in WhatsApp; automatically returns to Broadcast Automator upon sending.
- **📂 Flexible Contact Importing**: Import contacts directly from `.csv` files, system contact multi-picker, or quick text paste.
- **⏱️ Smart Timing & Anti-Spam Controls**: Customizable random delays, pre-send countdowns, and scheduled auto-pauses to protect your WhatsApp account.

---

## 🛠️ Required Permissions

To automate WhatsApp dispatches safely, the app requires:
1. **Accessibility Service**: Used locally on-device to click the WhatsApp send button for user-approved broadcasts.
2. **Display over other apps (Overlay)**: Displays the live sending progress overlay on top of WhatsApp so you can monitor or pause campaigns at any time.

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
