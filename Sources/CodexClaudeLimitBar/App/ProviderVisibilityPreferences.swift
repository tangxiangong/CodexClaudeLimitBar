import CodexClaudeLimitCore

enum ProviderVisibilityPreferences {
    static let showCodexKey = "providerVisibility.showCodex"
    static let showClaudeKey = "providerVisibility.showClaude"

    static func visibleProviders(showCodex: Bool, showClaude: Bool) -> [UsageProviderKind] {
        let visibility = normalized(showCodex: showCodex, showClaude: showClaude)

        return UsageProviderKind.allCases.filter { provider in
            switch provider {
            case .codex:
                visibility.showCodex
            case .claude:
                visibility.showClaude
            }
        }
    }

    static func isVisible(
        _ provider: UsageProviderKind,
        showCodex: Bool,
        showClaude: Bool
    ) -> Bool {
        visibleProviders(showCodex: showCodex, showClaude: showClaude).contains(provider)
    }

    static func filter(
        _ statuses: [ProviderStatus],
        showCodex: Bool,
        showClaude: Bool
    ) -> [ProviderStatus] {
        let visible = Set(visibleProviders(showCodex: showCodex, showClaude: showClaude))
        return statuses.filter { visible.contains($0.provider) }
    }

    private static func normalized(showCodex: Bool, showClaude: Bool) -> (showCodex: Bool, showClaude: Bool) {
        if !showCodex && !showClaude {
            return (true, true)
        }

        return (showCodex, showClaude)
    }
}
