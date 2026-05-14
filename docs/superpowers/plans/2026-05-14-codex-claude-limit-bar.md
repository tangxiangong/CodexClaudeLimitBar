# Codex Claude Limit Bar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS menu bar app that displays Codex and Claude Code 5-hour and weekly subscription limit remaining percentages.

**Architecture:** A SwiftPM executable hosts the SwiftUI `MenuBarExtra`. A small core library owns credential loading, token refresh, endpoint requests, response parsing, and unit-testable formatting.

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
