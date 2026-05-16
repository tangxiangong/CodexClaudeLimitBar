# CodexClaudeLimitBar

Native macOS menu bar app for monitoring remaining OpenAI Codex and Claude Code usage.

The app is local-only: it reads the same credentials used by the official CLIs, queries the provider endpoints directly, and renders a compact menu bar summary plus a Chinese usage popover.

## Features

- Menu bar status uses provider SVG template icons with readable lowest remaining percentages, for example Codex `62%` and Claude Code `94%`.
- The popover uses Chinese UI text and shows the minimum remaining percentage, visible provider count, 5-hour and weekly windows, reset countdowns, credit balance when available, and friendly error summaries.
- Official color logo assets are used in the popover; dedicated SVG template assets are used in the menu bar so macOS can tint them correctly.
- `设置` opens an in-panel page, not a separate Settings window. It controls whether Codex and Claude Code usage components are visible, persists the choices in `UserDefaults`, and prevents hiding both providers at the same time.
- The settings page also provides a macOS login item toggle so the menu bar monitor can launch automatically after login.
- The footer contains only `刷新`, `设置`, and `退出`; provider website links are intentionally not shown there.

## Data Sources

- Codex: reads `~/.codex/auth.json`, calls `https://chatgpt.com/backend-api/wham/usage`, falls back to `https://chatgpt.com/backend-api/codex/usage`, and refreshes Codex OAuth tokens on 401 through `https://auth.openai.com/oauth/token`.
- Claude Code: reads OAuth credentials from `~/.claude/.credentials.json`, falls back to the macOS Keychain generic password service `Claude Code-credentials`, and calls `https://api.anthropic.com/api/oauth/usage` with the `oauth-2025-04-20` beta header.

Credentials stay local and are only sent to OpenAI or Anthropic endpoints.

## Refresh Policy

- Codex refreshes every 120 seconds. A manual refresh also refreshes Codex.
- Claude Code is queried more conservatively because the usage endpoint can return HTTP 429. After a successful Claude response the next query is delayed for 10 minutes; after a non-rate-limit error it waits 5 minutes; after a rate-limit response it waits 30 minutes.
- Claude cooldowns are persisted in `UserDefaults`, so reopening the app does not immediately hammer the endpoint after a 429.
- A first run with no data still attempts to fetch both providers.

## Build And Run

```bash
swift build
swift run CodexClaudeLimitBar
```

To stage and launch a local `.app` bundle:

```bash
./script/build_and_run.sh
```

The script writes `dist/CodexClaudeLimitBar.app`, copies the SwiftPM resource bundle, and supports `run`, `--debug`, `--logs`, `--telemetry`, and `--verify` modes.
