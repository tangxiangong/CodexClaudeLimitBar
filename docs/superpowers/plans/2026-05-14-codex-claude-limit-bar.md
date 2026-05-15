# Codex Claude Limit Bar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS menu bar app that displays Codex and Claude Code 5-hour and weekly subscription limit remaining percentages.

**Architecture:** A SwiftPM executable hosts the SwiftUI `MenuBarExtra`. A small core library owns credential loading, token refresh, endpoint requests, response parsing, and unit-testable formatting. The app target owns the branded menu bar renderer, Chinese popover UI, provider visibility settings, and refresh scheduling.

**Tech Stack:** Swift 6, SwiftUI, AppKit, URLSession, Swift Testing.

---

### Task 1: Scaffold SwiftPM App

**Files:**
- Create: `Package.swift`
- Create: `Sources/CodexClaudeLimitBar/App/CodexClaudeLimitBarApp.swift`
- Create: `Sources/CodexClaudeLimitCore/Models/LimitWindow.swift`

- [x] **Step 1: Create SwiftPM package layout**

Create an executable target for the app and a library target for provider logic.

- [x] **Step 2: Add menu bar app entry**

Use `MenuBarExtra` and `NSApplicationDelegateAdaptor` to keep the app menu-bar-only.

### Task 2: Implement Provider Core

**Files:**
- Create: `Sources/CodexClaudeLimitCore/Services/CodexUsageProvider.swift`
- Create: `Sources/CodexClaudeLimitCore/Services/ClaudeUsageProvider.swift`
- Create: `Sources/CodexClaudeLimitCore/Stores/CodexAuthStore.swift`
- Create: `Sources/CodexClaudeLimitCore/Stores/ClaudeCredentialStore.swift`

- [x] **Step 1: Load local credentials**

Read Codex OAuth data from `~/.codex/auth.json` and Claude credentials from file or Keychain.

- [x] **Step 2: Fetch provider usage**

Call Codex and Claude usage endpoints with the local OAuth bearer token.

- [x] **Step 3: Refresh Codex token on 401**

Use OpenAI Codex OAuth refresh parameters and persist returned tokens.

### Task 3: Implement UI and Build Verification

**Files:**
- Create: `Sources/CodexClaudeLimitBar/App/LimitMonitor.swift`
- Create: `Sources/CodexClaudeLimitBar/Views/LimitPanelView.swift`

- [x] **Step 1: Add aggregation model**

Fetch both providers concurrently and retain per-provider errors.

- [x] **Step 2: Add menu bar and popover UI**

Render compact remaining values in the menu bar and detailed progress in the popover.

- [x] **Step 3: Verify with SwiftPM build**

Build the SwiftPM executable. The local Command Line Tools install does not expose Swift Testing or XCTest modules, so `swift build` is the available verification path in this environment.

### Task 4: Redesign Branded Chinese UI

**Files:**
- Update: `Sources/CodexClaudeLimitBar/Views/MenuBarLabelView.swift`
- Update: `Sources/CodexClaudeLimitBar/Views/BrandLogoView.swift`
- Update: `Sources/CodexClaudeLimitBar/Views/LimitPanelView.swift`
- Add: `Sources/CodexClaudeLimitBar/Resources/Logos/*`
- Add: `Sources/CodexClaudeLimitBar/Resources/MenuBarLogos/*`

- [x] **Step 1: Replace text-only menu bar output**

Render each visible provider as a menu bar SVG icon followed by the lowest remaining percentage. Avoid unreadable paired values such as `80/63`.

- [x] **Step 2: Use provider logo assets in the correct context**

Use color logo assets inside the popover cards and SVG template assets in the menu bar so macOS can apply the current menu bar tint cleanly.

- [x] **Step 3: Localize the primary UI to Chinese**

Use Chinese text for the popover header, provider card labels, progress rows, reset countdowns, error states, and footer actions.

- [x] **Step 4: Remove footer provider links**

Keep the footer focused on app actions: refresh, settings, and quit.

### Task 5: Add Provider Display Settings

**Files:**
- Add: `Sources/CodexClaudeLimitBar/App/ProviderVisibilityPreferences.swift`
- Add: `Sources/CodexClaudeLimitBar/Views/SettingsView.swift`
- Update: `Sources/CodexClaudeLimitBar/Views/MenuBarLabelView.swift`
- Update: `Sources/CodexClaudeLimitBar/Views/LimitPanelView.swift`
- Update: `Sources/CodexClaudeLimitBar/App/CodexClaudeLimitBarApp.swift`

- [x] **Step 1: Implement settings as an in-panel page**

Open `设置` inside the main popover and return to the usage page through the same panel. Do not use a separate Settings scene or independent window.

- [x] **Step 2: Persist provider visibility**

Store Codex and Claude Code visibility in `UserDefaults` through `@AppStorage`.

- [x] **Step 3: Apply visibility consistently**

Filter the menu bar label, summary metrics, and provider cards using the same visibility rules.

- [x] **Step 4: Prevent an empty dashboard**

Normalize invalid all-hidden state back to both visible and disable the last visible provider toggle in the settings page.

### Task 6: Handle Claude Usage Rate Limits

**Files:**
- Update: `Sources/CodexClaudeLimitBar/App/LimitMonitor.swift`
- Update: `Sources/CodexClaudeLimitBar/Views/LimitPanelView.swift`
- Update: `Sources/CodexClaudeLimitCore/Services/UsageAggregator.swift`

- [x] **Step 1: Fetch providers selectively**

Allow the monitor to request only the providers that are due instead of always querying Codex and Claude together.

- [x] **Step 2: Add Claude backoff**

Keep Codex on a 120-second cadence. Delay Claude for 10 minutes after success, 5 minutes after a non-rate-limit error, and 30 minutes after HTTP 429 or recognizable rate-limit responses.

- [x] **Step 3: Persist refresh schedule**

Store each provider's next allowed refresh time in `UserDefaults` so relaunching the app respects Claude cooldowns.

- [x] **Step 4: Show friendly Chinese errors**

Summarize Claude HTTP 429 as `请求过于频繁` with a short retry-later explanation instead of showing raw API JSON.
