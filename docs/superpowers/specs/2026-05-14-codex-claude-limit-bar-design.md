# Codex Claude Limit Bar Design

## Goal

Build a native macOS menu bar app that shows Codex and Claude Code subscription usage limits: the 5-hour window and the weekly/7-day window.

## Data Sources

Codex reads `~/.codex/auth.json`, calls `https://chatgpt.com/backend-api/wham/usage`, and falls back to `https://chatgpt.com/backend-api/codex/usage`. If the Codex endpoint returns 401, the app refreshes tokens through `https://auth.openai.com/oauth/token` using the Codex client id and writes the updated tokens back to the auth file.

Claude reads Claude Code credentials from `~/.claude/.credentials.json`, with a macOS Keychain fallback for the `Claude Code-credentials` generic password. It calls `https://api.anthropic.com/api/oauth/usage` with the `oauth-2025-04-20` beta header.

## UI

The app is menu-bar-only and uses SwiftUI `MenuBarExtra`. The compact title shows each provider as `CX fiveHourRemaining/weeklyRemaining` and `CL fiveHourRemaining/weeklyRemaining`. The popover shows progress bars, reset countdowns, refresh state, source notes, and quick links to the official usage pages.

## Privacy

All credentials stay local. The app only sends bearer tokens to the original OpenAI/Anthropic endpoints used by the respective clients. No telemetry, sync service, or third-party backend is included.

## Risk

Both providers rely on client/internal usage endpoints rather than stable public APIs. The implementation keeps provider code isolated so endpoint changes are localized.
