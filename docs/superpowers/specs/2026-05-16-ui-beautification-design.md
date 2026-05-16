# UI Beautification Design

## Goal

Redesign the LimitPanelView and SettingsView with a branded, colorful visual identity that uses each provider's real brand colors and logos, follows the system light/dark appearance, and removes the summary header card for a more compact layout.

## Design Decisions

- **Style**: Branded & colorful — each provider gets its own color-tinted card
- **Appearance**: Follows macOS system light/dark mode (no forced dark)
- **Progress bars**: Gradient from brand base color to a lighter shade
- **Header card**: Removed — provider cards are the top-level content
- **Scope**: LimitPanelView (usage page + action bar) and SettingsView

## Brand Colors

### Codex (blue/purple)
- Dark mode card background: `linear-gradient(135deg, #1a1635, #151230)`
- Dark mode card border: `#6366f120`
- Icon gradient: `linear-gradient(135deg, #818cf8, #6366f1)`
- Progress bar gradient: `linear-gradient(90deg, #6366f1, #a5b4fc)`
- Dark mode text accent: `#a5b4fc`
- Dark mode badge background: `#6366f118`
- Light mode card background: `linear-gradient(135deg, #eef2ff, #e8ecff)`
- Light mode card border: `#c7d2fe`
- Light mode text accent: `#4f46e5`
- Light mode badge background: `#e0e7ff`
- Light mode bar track: `#c7d2fe60`

### Claude Code (coral/orange)
- Dark mode card background: `linear-gradient(135deg, #2e1a13, #22130c)`
- Dark mode card border: `#e8795a20`
- Icon gradient: `linear-gradient(135deg, #e8795a, #cc6044)`
- Progress bar gradient: `linear-gradient(90deg, #cc6044, #f4a589)`
- Dark mode text accent: `#f4a589`
- Dark mode badge background: `#e8795a18`
- Light mode card background: `linear-gradient(135deg, #fef3ee, #fdf0ea)`
- Light mode card border: `#f9c9b3`
- Light mode text accent: `#c05030`
- Light mode badge background: `#fee4d6`
- Light mode bar track: `#f9c9b360`

### Severity Colors (unchanged logic, used for status badge only)
- Normal (>35%): green `#22c55e` / `#4ade80` (dark) or `#16a34a` (light)
- Warning (15-35%): orange — reuse existing behavior
- Danger (<=15%): red — reuse existing behavior

## Panel Background
- Dark mode: solid dark `#111119` (or use SwiftUI `.background` with dark material)
- Light mode: light gray `#f5f5f7` (or use SwiftUI default window background)

## LimitPanelView Changes

### Remove header section
Remove the entire `header` computed property (the card with "限额监控", StatusSummaryView, and SummaryMetricView). The `usagePage` body becomes just the provider cards list + action bar.

### Provider cards (ProviderSectionView)
Each card gets:
1. **Brand-tinted background** — gradient fill using provider's color palette, switching between dark/light values based on `colorScheme`
2. **Brand-tinted border** — subtle colored border instead of generic `.separator`
3. **Logo icon** — use existing `BrandLogoView` in a gradient-filled rounded rect (34x34pt icon container with 8pt corner radius)
4. **Remaining badge** — pill with brand-tinted background and brand-colored text, replacing the current `RemainingBadge` dot+text
5. **Gradient progress bars** — `LinearGradient` from brand base to brand light instead of flat `.tint()` color. Bar height: 6pt with 3pt corner radius
6. **Source link** — remove the `sourceDescription` label (the 🔗 platform.openai.com / api.anthropic.com line)

### LimitWindowRow changes
- Replace `ProgressView` with a custom `GeometryReader`-based bar that draws a `RoundedRectangle` fill with `LinearGradient`
- The gradient uses the provider's brand colors (the provider kind needs to be passed down or read from environment)
- **Severity vs. brand color rule**: progress bars and percentage text use brand colors when remaining > 35% (normal). When remaining <= 35% (warning), switch to orange. When remaining <= 15% (danger), switch to red. This ensures low-quota states are visually alarming regardless of brand color.

### Action bar
- Keep current layout and behavior
- Style remains `.borderless` button with `.caption` font — no visual changes needed here

## SettingsView Changes

### Section cards
- Apply the same brand-tinted card treatment to the provider visibility section
- Each `ProviderVisibilityRow` gets a subtle brand tint behind the logo area
- The "Launch at Login" section keeps neutral styling (no brand color)

### Navigation header
- Keep the back button + "显示设置" title layout unchanged

## Implementation Approach

### Theme system
Create a `ProviderTheme` struct that holds all color values for a provider. A static method returns the appropriate theme given `UsageProviderKind` and `ColorScheme`:

```
struct ProviderTheme {
    let cardBackground: LinearGradient
    let cardBorder: Color
    let iconGradient: LinearGradient
    let barGradient: LinearGradient
    let barTrack: Color
    let accentText: Color
    let badgeBackground: Color
}
```

This keeps color logic centralized and avoids scattering hex values across views.

### Passing provider context to LimitWindowRow
Currently `LimitWindowRow` only receives a `LimitWindow` and derives severity color independently. To apply brand-colored gradients, pass the `ProviderTheme` (or just the gradient) down. Options:
- Add a `theme: ProviderTheme` parameter to `LimitWindowRow` (simplest, recommended)
- Use SwiftUI environment (more complex than needed)

### Custom gradient progress bar
Replace `ProgressView(value:total:).tint()` with:
```swift
GeometryReader { geo in
    ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(theme.barTrack)
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(theme.barGradient)
            .frame(width: geo.size.width * (value / total))
    }
}
.frame(height: 6)
```

### Color scheme adaptation
Use `@Environment(\.colorScheme)` in `ProviderSectionView` and `SettingsView` to select between dark/light theme variants. The `ProviderTheme` factory method handles the switch.

## Files to Modify

1. **New file**: `Sources/CodexClaudeLimitBar/Views/ProviderTheme.swift` — theme struct + factory
2. **LimitPanelView.swift** — remove header, update `ProviderSectionView`, update `LimitWindowRow`, delete dead private types (`StatusSummaryView`, `SummaryMetricView`, `LimitSeverity` extensions if unused)
3. **SettingsView.swift** — apply brand tint to provider rows
4. **BrandLogoView.swift** — no changes needed (already renders logos correctly)

## What stays the same

- Menu bar label (MenuBarLabelView) — out of scope
- BrandLogoView — already works, just used inside new card layout
- All data models and services — purely a view layer change
- Action bar buttons — keep current minimal style
- Error states (ProviderErrorView) — keep current layout, just inherits new card background
- Severity thresholds (15%, 35%) — unchanged
