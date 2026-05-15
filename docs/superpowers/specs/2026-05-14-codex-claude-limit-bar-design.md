# Codex Claude Limit Bar Design

## Goal

Build a native macOS menu bar app that shows Codex and Claude Code subscription usage limits: the 5-hour window and the weekly/7-day window.

## Data Sources

Codex reads `~/.codex/auth.json`, calls `https://chatgpt.com/backend-api/wham/usage`, and falls back to `https://chatgpt.com/backend-api/codex/usage`. If the Codex endpoint returns 401, the app refreshes tokens through `https://auth.openai.com/oauth/token` using the Codex client id and writes the updated tokens back to the auth file.

Claude reads Claude Code credentials from `~/.claude/.credentials.json`, with a macOS Keychain fallback for the `Claude Code-credentials` generic password. It calls `https://api.anthropic.com/api/oauth/usage` with the `oauth-2025-04-20` beta header.

## Refresh Policy

The monitor uses provider-specific refresh schedules instead of polling every source at the same cadence.

- Codex refreshes every 120 seconds, and user-initiated refreshes force Codex to refresh immediately.
- Claude refreshes every 10 minutes after a successful response.
- Claude waits 5 minutes after a non-rate-limit error.
- Claude waits 30 minutes after an HTTP 429 or a recognizable rate-limit response.
- Per-provider next-refresh timestamps are persisted in `UserDefaults` using `providerRefresh.nextAllowed.<provider>`.
- A provider with no recorded usage or error is always eligible for the first fetch.

## UI

The app is menu-bar-only and uses SwiftUI `MenuBarExtra`.

The menu bar label is rendered as a single template `NSImage`. It contains one segment per visible provider: a provider-specific SVG menu bar icon plus the lowest remaining percentage across that provider's available windows. It does not show provider names in the menu bar because the icons carry that identity.

The popover UI is in Chinese. The usage page shows:

- a summary header with last refresh time, severity, minimum remaining percentage, and visible provider count;
- one provider card per visible provider;
- official color logo assets for Codex and Claude Code;
- 5-hour and weekly progress rows with remaining percentage, used percentage, and Chinese reset countdowns;
- credit balance when the provider returns one;
- sanitized Chinese error states instead of raw JSON payloads.

The footer actions are `刷新`, `设置`, and `退出`. Provider usage-page hyperlinks are intentionally not included in the footer.

The settings UI is a page inside the same popover, reached through `设置`, not a separate Settings scene. It controls visibility for the Codex and Claude Code usage components. Visibility affects the menu bar label, summary metrics, and provider cards. The settings page persists choices through `@AppStorage`/`UserDefaults` and disables the last visible provider toggle so the app never hides all usage components.

## Privacy

All credentials stay local. The app only sends bearer tokens to the original OpenAI/Anthropic endpoints used by the respective clients. No telemetry, sync service, or third-party backend is included.

## Risk

Both providers rely on client/internal usage endpoints rather than stable public APIs. The implementation keeps provider code isolated so endpoint changes are localized.

Claude's usage endpoint may reject frequent polling with HTTP 429. The app does not attempt to bypass this server-side limit; it displays a friendly Chinese rate-limit message and backs off before querying Claude again.
