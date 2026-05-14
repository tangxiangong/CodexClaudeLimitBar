# CodexClaudeLimitBar

Native macOS menu bar app for Codex and Claude Code subscription limit windows.

The menu bar text uses the compact form:

```text
CX 72/54 · CL 61/38
```

The first number is 5-hour remaining percentage and the second is weekly/7-day remaining percentage.

## Data Sources

- Codex: reads `~/.codex/auth.json`, calls the ChatGPT Codex usage endpoint, and refreshes Codex OAuth tokens on 401.
- Claude: reads Claude Code OAuth credentials from `~/.claude/.credentials.json` or macOS Keychain, then calls `https://api.anthropic.com/api/oauth/usage`.

Credentials stay local and are only sent to OpenAI or Anthropic endpoints.

## Build

```bash
swift build
./script/build_and_run.sh
```
