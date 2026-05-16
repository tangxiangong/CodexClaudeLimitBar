# UI Beautification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign LimitPanelView and SettingsView with branded, colorful cards per provider (Codex blue/purple, Claude coral/orange), gradient progress bars, and light/dark mode adaptation.

**Architecture:** New `ProviderTheme` struct centralizes all per-provider color values and switches between light/dark palettes via `ColorScheme`. Views read the theme to apply brand-tinted backgrounds, borders, gradients, and text colors. The header card is removed; provider sections become the top-level content.

**Tech Stack:** SwiftUI, macOS 14+, Swift 6

---

### Task 1: Create ProviderTheme

**Files:**
- Create: `Sources/CodexClaudeLimitBar/Views/ProviderTheme.swift`

- [ ] **Step 1: Create the ProviderTheme struct**

Create `Sources/CodexClaudeLimitBar/Views/ProviderTheme.swift` with the full theme definition:

```swift
import CodexClaudeLimitCore
import SwiftUI

struct ProviderTheme {
    let cardBackground: LinearGradient
    let cardBorder: Color
    let iconGradient: LinearGradient
    let barGradient: LinearGradient
    let barTrack: Color
    let accentText: Color
    let badgeBackground: Color

    static func theme(for provider: UsageProviderKind, colorScheme: ColorScheme) -> ProviderTheme {
        switch (provider, colorScheme) {
        case (.codex, .dark):
            ProviderTheme(
                cardBackground: LinearGradient(
                    colors: [Color(hex: 0x1a1635), Color(hex: 0x151230)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                cardBorder: Color(hex: 0x6366f1).opacity(0.125),
                iconGradient: LinearGradient(
                    colors: [Color(hex: 0x818cf8), Color(hex: 0x6366f1)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                barGradient: LinearGradient(
                    colors: [Color(hex: 0x6366f1), Color(hex: 0xa5b4fc)],
                    startPoint: .leading, endPoint: .trailing
                ),
                barTrack: Color.white.opacity(0.03),
                accentText: Color(hex: 0xa5b4fc),
                badgeBackground: Color(hex: 0x6366f1).opacity(0.094)
            )
        case (.codex, .light):
            ProviderTheme(
                cardBackground: LinearGradient(
                    colors: [Color(hex: 0xeef2ff), Color(hex: 0xe8ecff)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                cardBorder: Color(hex: 0xc7d2fe),
                iconGradient: LinearGradient(
                    colors: [Color(hex: 0x818cf8), Color(hex: 0x6366f1)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                barGradient: LinearGradient(
                    colors: [Color(hex: 0x6366f1), Color(hex: 0xa5b4fc)],
                    startPoint: .leading, endPoint: .trailing
                ),
                barTrack: Color(hex: 0xc7d2fe).opacity(0.375),
                accentText: Color(hex: 0x4f46e5),
                badgeBackground: Color(hex: 0xe0e7ff)
            )
        case (.claude, .dark):
            ProviderTheme(
                cardBackground: LinearGradient(
                    colors: [Color(hex: 0x2e1a13), Color(hex: 0x22130c)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                cardBorder: Color(hex: 0xe8795a).opacity(0.125),
                iconGradient: LinearGradient(
                    colors: [Color(hex: 0xe8795a), Color(hex: 0xcc6044)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                barGradient: LinearGradient(
                    colors: [Color(hex: 0xcc6044), Color(hex: 0xf4a589)],
                    startPoint: .leading, endPoint: .trailing
                ),
                barTrack: Color.white.opacity(0.03),
                accentText: Color(hex: 0xf4a589),
                badgeBackground: Color(hex: 0xe8795a).opacity(0.094)
            )
        case (.claude, .light):
            ProviderTheme(
                cardBackground: LinearGradient(
                    colors: [Color(hex: 0xfef3ee), Color(hex: 0xfdf0ea)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                cardBorder: Color(hex: 0xf9c9b3),
                iconGradient: LinearGradient(
                    colors: [Color(hex: 0xe8795a), Color(hex: 0xcc6044)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                barGradient: LinearGradient(
                    colors: [Color(hex: 0xcc6044), Color(hex: 0xf4a589)],
                    startPoint: .leading, endPoint: .trailing
                ),
                barTrack: Color(hex: 0xf9c9b3).opacity(0.375),
                accentText: Color(hex: 0xc05030),
                badgeBackground: Color(hex: 0xfee4d6)
            )
        @unknown default:
            theme(for: provider, colorScheme: .dark)
        }
    }

    func effectiveBarGradient(remainingPercent: Double) -> LinearGradient {
        if remainingPercent <= 15 {
            return LinearGradient(colors: [.red], startPoint: .leading, endPoint: .trailing)
        }
        if remainingPercent <= 35 {
            return LinearGradient(colors: [.orange], startPoint: .leading, endPoint: .trailing)
        }
        return barGradient
    }

    func effectiveAccentText(remainingPercent: Double) -> Color {
        if remainingPercent <= 15 {
            return .red
        }
        if remainingPercent <= 35 {
            return .orange
        }
        return accentText
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

Run: `swift build 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/CodexClaudeLimitBar/Views/ProviderTheme.swift
git commit -m "feat: add ProviderTheme with brand colors for Codex and Claude"
```

---

### Task 2: Strip Header and Dead Code from LimitPanelView

**Files:**
- Modify: `Sources/CodexClaudeLimitBar/Views/LimitPanelView.swift`

- [ ] **Step 1: Remove the header reference from usagePage**

In `LimitPanelView.swift`, replace the `usagePage` computed property (lines 25-37) with:

```swift
    private var usagePage: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 10) {
                ForEach(visibleStatuses) { status in
                    ProviderSectionView(status: status)
                }
            }

            actionBar
        }
    }
```

- [ ] **Step 2: Remove the header computed property**

Delete the entire `header` computed property (lines 39-76).

- [ ] **Step 3: Remove refreshText, minimumRemainingText, visibleOverallSeverity, and refreshFormatter**

Delete these properties that were only used by the header:
- `refreshText` (lines 78-84)
- `minimumRemainingText` (lines 86-93)
- `visibleOverallSeverity` (lines 134-149)
- `refreshFormatter` (lines 151-156)

- [ ] **Step 4: Remove StatusSummaryView and SummaryMetricView**

Delete the private structs:
- `StatusSummaryView` (lines 164-186)
- `SummaryMetricView` (lines 188-209)

- [ ] **Step 5: Remove the LimitSeverity.localizedTitle extension**

Delete the extension at lines 512-525 (it was only used by StatusSummaryView):

```swift
private extension LimitSeverity {
    var localizedTitle: String { ... }
}
```

- [ ] **Step 6: Build to verify it compiles**

Run: `swift build 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 7: Commit**

```bash
git add Sources/CodexClaudeLimitBar/Views/LimitPanelView.swift
git commit -m "refactor: remove header card and dead code from LimitPanelView"
```

---

### Task 3: Redesign ProviderSectionView with Brand Theming

**Files:**
- Modify: `Sources/CodexClaudeLimitBar/Views/LimitPanelView.swift`

- [ ] **Step 1: Replace ProviderSectionView**

Replace the entire `ProviderSectionView` struct (originally lines 211-293, but line numbers will have shifted after Task 2) with:

```swift
struct ProviderSectionView: View {
    let status: ProviderStatus
    @Environment(\.colorScheme) private var colorScheme

    private var theme: ProviderTheme {
        .theme(for: status.provider, colorScheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(theme.iconGradient)
                    BrandLogoView(provider: status.provider, size: 22)
                }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 3) {
                    Text(status.provider.productDisplayName)
                        .font(.subheadline.weight(.semibold))

                    Text(statusSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if status.isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                } else if let usage = status.usage {
                    RemainingBadge(percent: usage.lowestRemainingPercent, theme: theme)
                }
            }

            if let usage = status.usage {
                VStack(spacing: 8) {
                    ForEach(primaryWindows(from: usage)) { window in
                        LimitWindowRow(window: window, theme: theme)
                    }
                }

                if let credits = usage.credits?.balance {
                    HStack {
                        Label("余额", systemImage: "creditcard")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(credits)
                            .monospacedDigit()
                    }
                    .font(.caption)
                }
            } else if status.isRefreshing {
                Text("正在刷新...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ProviderErrorView(message: status.errorMessage)
            }
        }
        .padding(12)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(theme.cardBorder, lineWidth: 1)
        }
    }

    private var statusSubtitle: String {
        if let planName = status.usage?.planName, !planName.isEmpty {
            return "套餐 \(planName)"
        }

        return status.provider.providerSubtitle
    }

    private func primaryWindows(from usage: ProviderUsage) -> [LimitWindow] {
        [usage.fiveHour, usage.weekly].compactMap { $0 }
    }
}
```

Key changes:
- Icon container uses `theme.iconGradient` fill instead of `.background.opacity(0.72)`, sized 34x34 with 22pt logo
- Card background uses `theme.cardBackground` gradient
- Card border uses `theme.cardBorder` color
- Corner radius bumped to 10
- `sourceDescription` label removed
- `RemainingBadge` and `LimitWindowRow` now receive `theme`

- [ ] **Step 2: Replace RemainingBadge**

Replace the existing `RemainingBadge` struct with:

```swift
private struct RemainingBadge: View {
    let percent: Double?
    let theme: ProviderTheme

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(textColor)
            .monospacedDigit()
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(badgeBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var text: String {
        guard let percent else {
            return "--"
        }

        return "剩余 \(Int(percent.rounded()))%"
    }

    private var textColor: Color {
        guard let percent else {
            return .secondary
        }

        return theme.effectiveAccentText(remainingPercent: percent)
    }

    private var badgeBackground: Color {
        guard percent != nil else {
            return .secondary.opacity(0.1)
        }

        return theme.badgeBackground
    }
}
```

- [ ] **Step 3: Replace LimitWindowRow**

Replace the existing `LimitWindowRow` struct with:

```swift
struct LimitWindowRow: View {
    let window: LimitWindow
    let theme: ProviderTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(window.localizedTitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("剩余 \(window.roundedRemaining)%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.effectiveAccentText(remainingPercent: window.remainingPercent))
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(theme.barTrack)

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(theme.effectiveBarGradient(remainingPercent: window.remainingPercent))
                        .frame(width: max(0, geo.size.width * window.remainingPercent / 100))
                }
            }
            .frame(height: 6)
            .accessibilityLabel(window.localizedTitle)
            .accessibilityValue("剩余 \(window.roundedRemaining)%")

            HStack {
                Text("已用 \(window.roundedUsed)%")
                Spacer()
                Text(resetText)
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .monospacedDigit()
        }
    }

    private var resetText: String {
        guard let resetDate = window.resetDate else {
            return "重置时间未知"
        }

        return "\(resetDate.chineseRelativeLimitDescription()) 后重置"
    }
}
```

Key changes:
- Takes `theme` parameter
- `ProgressView` replaced with `GeometryReader`-based gradient bar
- Severity color uses `theme.effectiveAccentText` / `theme.effectiveBarGradient`
- The old `severityColor` computed property is removed

- [ ] **Step 4: Build to verify it compiles**

Run: `swift build 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 5: Commit**

```bash
git add Sources/CodexClaudeLimitBar/Views/LimitPanelView.swift
git commit -m "feat: redesign provider cards with branded themes and gradient bars"
```

---

### Task 4: Apply Brand Tints to SettingsView

**Files:**
- Modify: `Sources/CodexClaudeLimitBar/Views/SettingsView.swift`

- [ ] **Step 1: Update ProviderVisibilityRow to use brand tints**

Replace the `ProviderVisibilityRow` struct (lines 141-169) with:

```swift
private struct ProviderVisibilityRow: View {
    let provider: UsageProviderKind
    @Binding var isOn: Bool
    let isDisabled: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var theme: ProviderTheme {
        .theme(for: provider, colorScheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(theme.iconGradient)
                BrandLogoView(provider: provider, size: 20)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(provider.settingsTitle)
                    .font(.body.weight(.medium))

                Text(provider.settingsSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .disabled(isDisabled)
        }
        .padding(.vertical, 10)
    }
}
```

Key change: the logo container now uses `theme.iconGradient` fill with a 34x34 rounded rect, matching the panel card style.

- [ ] **Step 2: Build to verify it compiles**

Run: `swift build 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/CodexClaudeLimitBar/Views/SettingsView.swift
git commit -m "feat: apply branded icon styling to settings provider rows"
```

---

### Task 5: Build, Run, and Visually Verify

**Files:** None (verification only)

- [ ] **Step 1: Full clean build**

Run: `swift build 2>&1 | tail -10`
Expected: `Build complete!` with no warnings related to our changes.

- [ ] **Step 2: Run the app and verify visually**

Run: `swift run CodexClaudeLimitBar &`

Check:
1. Click the menu bar item — the panel opens
2. Provider cards have brand-colored gradient backgrounds (blue/purple for Codex, coral/orange for Claude)
3. Progress bars show brand-colored gradients
4. No header card (no "限额监控" summary section)
5. No source description links (no "🔗 platform.openai.com" lines)
6. Toggle macOS appearance (System Settings → Appearance) — cards adapt between dark and light palettes
7. Click Settings — provider rows show brand-colored icon backgrounds
8. All existing functionality works: refresh, settings toggles, quit

- [ ] **Step 3: Kill the test process**

Run: `kill %1` (or the appropriate job number)

- [ ] **Step 4: Commit any final adjustments if needed**

If visual verification revealed spacing or color tweaks, apply and commit them.
