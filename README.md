# ARB Pay Script & Bot

Automated buying bot and companion mobile application for the ARBPay platform.

## Overview

This repository contains tools for automating interactions with ARBPay, specifically focusing on the "Buy Center" to automate order purchasing within specified limits. It is designed to bypass common anti-bot protections by injecting API calls directly through an automated browser session.

The project is split into two main parts:

1. **Python Automation Scripts**
2. **Flutter Mobile Application (`arbpay_apk`)**

## 1. Python Automation Scripts

The root directory contains the core logic built with Python and Selenium.

*   **`ARBPay_python_script.py`**: The primary bot script. It launches an automated Chrome or Edge browser, logs into ARBPay, captures authentication tokens from `localStorage`, and runs a high-speed loop fetching orders and attempting purchases within user-defined amount limits.
*   **`ARBPay_python_script_for_apk.py`**: A variant of the script adapted for specific mobile/APK integrations or alternative flows.

### Key Features
*   **Headless/GUI Modes**: Can run visibly or entirely in the background.
*   **Browser Fetch Injection**: Executes API requests (`/ar-wallet/buyCenter/buyList`, `buy`, etc.) via synchronous JavaScript `XMLHttpRequest` directly inside the Selenium browser context to mitigate Cloudflare and CORS blocking.
*   **Customizable Ranges**: Users can set minimum and maximum transaction amounts.
*   **QR Code Extraction**: Detects successful purchases and captures payment QR codes.

### Requirements
*   Python 3.x
*   Selenium WebDriver (`pip install selenium`)
*   Chrome/Edge browser installed

## 2. Flutter Mobile Application (`arbpay_apk`)

A dedicated mobile app providing a beautiful and easy-to-use interface for the bot.

Located in the `arbpay_apk/` directory, this Flutter project wraps the automation capabilities into an Android/Web/Windows application.

### Screenshots
*(Placeholders for actual app screenshots - you can add them to an `assets/screenshots/` folder and link them here)*

<div style="display: flex; justify-content: space-between;">
  <img src="arbpay_apk/assets/screenshots/dashboard.png" width="30%" alt="Dashboard Screenshot" />
  <img src="arbpay_apk/assets/screenshots/settings.png" width="30%" alt="Settings Screenshot" />
  <img src="arbpay_apk/assets/screenshots/logs.png" width="30%" alt="Logs Screenshot" />
</div>

### Key Features
*   **Built-in WebView**: Utilizes `flutter_inappwebview` to handle background sessions and interactions securely.
*   **Settings Management**: Easy UI to configure Minimum/Maximum buy amounts and execution speeds.
*   **Live Log Panel**: Real-time console output visible directly on the mobile screen.
*   **Status Dashboard**: Visual indicators for connection status, active tokens, and current bot state.

### Building the App
Make sure you have [Flutter](https://flutter.dev/) installed.

```bash
cd arbpay_apk
flutter pub get

# To run on an emulator or connected device
flutter run

# To build the Android APK
flutter build apk
```

*(Note: When building the APK, remember to increment the version number in `pubspec.yaml` and `lib/screens/home_screen.dart` as per the repository rules).*

## Disclaimer

This project is for educational and personal use. Usage of automated bots on trading platforms may violate their Terms of Service. Use at your own risk.
