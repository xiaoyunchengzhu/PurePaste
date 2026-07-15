<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0%2B-blue" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-5.0-orange" alt="Swift">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
  <a href="https://www.xiaoniubuniu.com/products/actionsense/"><img src="https://img.shields.io/badge/Download-xiaoniubuniu.com-ff69b4" alt="Download"></a>
</p>

<p align="center"><b>English</b> | <a href="README_zh.md">中文</a></p>

# ActionSense

<p align="center"><b>macOS Smart Clipboard Assistant</b> — understands what you copy, not just what it says.</p>

<p align="center">
  <a href="https://www.xiaoniubuniu.com/products/actionsense/">Product Page & Download</a>
</p>

---

## Why I Built This

I got tired of the same manual steps after every copy. Copy a URL → open a browser → paste → Enter. Copy a hex color → open a color picker just to see it. Copy a math expression → reach for Calculator. ActionSense automates that second step.

## What is ActionSense?

ActionSense is a macOS menu bar app that watches your clipboard and acts on what you copy. Two modes:

- **Plain Text Mode** — automatically strips rich formatting, cleans up whitespace and CJK spacing
- **PasteFlow Mode** — detects the *type* of content you copied (URL, email, color, math expression...) and pops up a floating action panel at your mouse cursor. One click or <kbd>Enter</kbd> to act.

All processing is local. Your clipboard never leaves your machine.

## Features

### PasteFlow — Intent-Aware Clipboard

When you copy something, PasteFlow detects what it is and offers relevant actions:

| Type | Example | Actions |
|------|---------|---------|
| URL | `https://www.xiaoniubuniu.com` | Open in Browser |
| Email | `xiaoyunchengzhu@gmail.com` | Compose Mail |
| Phone | `13812345678` | Call |
| Address | `北京市海淀区...` | Open in Maps |
| IP | `192.168.1.1` | Ping |
| Color | `#FF5733` / `rgb(255,87,51)` | Copy HEX / Copy RGB |
| Date/Time | `2024-01-15 14:00` | Add to Calendar |
| Math | `(35+47)*1.2` | Copy Result (custom recursive descent parser) |
| Coordinates | `39.9042, 116.4074` | Open in Maps |
| Tracking | `SF123456789012` | Track Package |
| JSON | `{"key": "value"}` | Format / Minify |
| Git URL | `github.com/user/repo` | Open in Browser + Open Repo |
| Rich HTML | Web content with formatting | Convert to Markdown / Plain Text |

- <kbd>Enter</kbd> triggers the action directly when there's only one button
- <kbd>Esc</kbd> or click outside to dismiss

### Plain Text Mode

Strips RTF/HTML formatting, collapses excess newlines, removes unnecessary spaces between CJK characters, compresses multiple spaces into one. Keeps English word spacing intact.

### Intent History

Every clipboard change is recorded with metadata:
- 🟢 Intent fulfilled (action taken)
- 🟠 Detected but not acted upon
- ⚪ Plain text / unrecognized

Filter by type, mode, or keyword. Search across up to 5000 entries. All stored locally at `~/Library/Application Support/ActionSense/history.json`.

## Screenshot

![ActionSense Demo](screenshot/demo.gif)

### PasteFlow — Smart Detection

| URL Detection | Color Preview | Math Calculation |
|:---:|:---:|:---:|
| ![URL](screenshot/url-detect.png) | ![Color](screenshot/color-detect.png) | ![Math](screenshot/math-detect.png) |

### Intent History

![History](screenshot/history.png)

## Installation

**Option 1: Build from Source (free, no Apple Developer account needed)**
```bash
git clone https://github.com/xiaoyunchengzhu/ActionSense.git
cd ActionSense
open ActionSense.xcodeproj
# Cmd+R to run
```

**Option 2: Download DMG**
Download the latest build from [xiaoniubuniu.com/products/actionsense](https://www.xiaoniubuniu.com/products/actionsense/), drag to `/Applications`. Right-click → Open on first launch to bypass Gatekeeper.

## Architecture

```
ActionSense/
├── ActionSenseApp.swift              # MenuBarExtra entry point
├── ActionSenseViewModel.swift        # State coordinator (DI-ready)
├── ClipboardMonitor.swift            # NSPasteboard polling (P3: extracted)
├── DetectorProtocol.swift            # ContentDetecting protocol + Registry
├── Detectors/
│   ├── BasicDetectors.swift          # URL / Email / Phone / IP
│   ├── ColorDetector.swift           # Hex / RGB color parsing
│   ├── MathDetector.swift            # Recursive descent parser
│   └── TextDetectors.swift           # Address / Tracking / Date / JSON / Geo / HTML
├── ContentDetector.swift             # DetectedContent + PasteFlowAction enums
├── ActionExecutor.swift              # Action dispatcher
├── FloatingPanelView.swift           # SwiftUI panel UI
├── FloatingPanelController.swift     # NSWindow manager
├── StoreManager.swift                # StoreKit 2 IAP (daily limit + Pro)
├── HistoryEntry.swift / HistoryStore.swift / HistoryView.swift / HistoryWindowController.swift
├── Localization.swift                # L10n with String(localized:) + fallback
├── Localizable.xcstrings             # 88-key String Catalog (en + zh-Hans)
├── PrivacyInfo.xcprivacy             # App Store privacy manifest
└── Info.plist
```

**Data Flow:**

```
Clipboard Change
      │
      ▼
 ClipboardMonitor (Timer + NSPasteboard, 0.5s poll)
      │
      ▼
 DetectorRegistry.detect() (13 detectors, protocol-based priority chain)
      │
      ├── Detected? ──► FloatingPanel (NSWindow .nonactivatingPanel)
      │                        │
      │                        ▼
      │                 PasteFlowAction dispatch
      │                        │
      │                        ▼
      │                 ActionExecutor (URL→Browser, Color→Copy, etc.)
      │
      └── Not detected ──► Plain Text Mode (strip formatting) or no-op
```

Key design decisions:

- **Detector protocol**: each content type is an independent `ContentDetecting` implementation registered at startup. Add a new type without touching core code.
- **Dead-loop prevention**: `internalWriteFlag` + `lastChangeCount` dual guard in `ClipboardMonitor`
- **Math evaluator**: hand-written recursive descent parser (avoids `NSExpression` format-string traps)
- **Floating panel**: `NSWindow.borderless` + `.nonactivatingPanel` — appears near cursor, dismisses on app switch or 5s timeout
- **Dependency injection**: ViewModel receives dependencies via init (defaults to `.shared`); overridable for testing
- **History**: in-memory filtering on JSON-loaded entries, no database dependency

## Tech Stack

SwiftUI · AppKit · MenuBarExtra · NSPasteboard · Combine · SMAppService

## Limitations

- **macOS 14.0+ only** — relies on `MenuBarExtra` and modern SwiftUI APIs
- **English & Chinese only** — Japanese planned for a future release
- **No cloud / AI features** — all processing is local by design. That's the point.
- **Not on the Mac App Store** — requires a $99/year Apple Developer account for notarization
- **Some Chinese-specific detections** (address keywords, tracking numbers) are less useful for international users
- **Floating panel dismiss** — panel closes on app switch or 5s timeout (no global mouse monitor, sandbox-compliant)

## License

MIT — see [LICENSE](LICENSE).
