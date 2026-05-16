import CodexClaudeLimitCore
import SwiftUI

struct SettingsView: View {
    let onBack: () -> Void

    @StateObject private var launchAtLogin = LaunchAtLoginController()
    @AppStorage(ProviderVisibilityPreferences.showCodexKey) private var showCodexUsage = true
    @AppStorage(ProviderVisibilityPreferences.showClaudeKey) private var showClaudeUsage = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Button(action: onBack) {
                    Label("返回", systemImage: "chevron.left")
                }
                .buttonStyle(.borderless)
                .labelStyle(.titleAndIcon)

                Spacer()

                Text("显示设置")
                    .font(.headline.weight(.semibold))
            }

            VStack(spacing: 0) {
                ProviderVisibilityRow(
                    provider: .codex,
                    isOn: providerBinding(.codex),
                    isDisabled: isLastVisible(.codex)
                )

                Divider()
                    .padding(.leading, 52)

                ProviderVisibilityRow(
                    provider: .claude,
                    isOn: providerBinding(.claude),
                    isDisabled: isLastVisible(.claude)
                )
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.separator.opacity(0.35), lineWidth: 1)
            }

            VStack(spacing: 0) {
                LaunchAtLoginRow(controller: launchAtLogin)
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.separator.opacity(0.35), lineWidth: 1)
            }
        }
        .onAppear {
            normalizeVisibility()
            launchAtLogin.refresh()
        }
    }

    private func providerBinding(_ provider: UsageProviderKind) -> Binding<Bool> {
        Binding {
            ProviderVisibilityPreferences.isVisible(
                provider,
                showCodex: showCodexUsage,
                showClaude: showClaudeUsage
            )
        } set: { isVisible in
            guard isVisible || !isLastVisible(provider) else {
                return
            }

            switch provider {
            case .codex:
                showCodexUsage = isVisible
            case .claude:
                showClaudeUsage = isVisible
            }
        }
    }

    private func isLastVisible(_ provider: UsageProviderKind) -> Bool {
        let visible = ProviderVisibilityPreferences.visibleProviders(
            showCodex: showCodexUsage,
            showClaude: showClaudeUsage
        )

        return visible.count == 1 && visible.first == provider
    }

    private func normalizeVisibility() {
        if !showCodexUsage && !showClaudeUsage {
            showCodexUsage = true
            showClaudeUsage = true
        }
    }
}

private struct LaunchAtLoginRow: View {
    @ObservedObject var controller: LaunchAtLoginController

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "power.circle")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("开机自启动")
                    .font(.body.weight(.medium))

                Text(controller.detailText)
                    .font(.caption)
                    .foregroundStyle(controller.errorMessage == nil ? Color.secondary : Color.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle(
                "",
                isOn: Binding {
                    controller.isEnabled
                } set: { isEnabled in
                    controller.setEnabled(isEnabled)
                }
            )
            .labelsHidden()
            .toggleStyle(.switch)
            .disabled(!controller.isAvailable)
        }
        .padding(.vertical, 10)
    }
}

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

private extension UsageProviderKind {
    var settingsTitle: String {
        switch self {
        case .codex:
            "Codex"
        case .claude:
            "Claude Code"
        }
    }

    var settingsSubtitle: String {
        switch self {
        case .codex:
            "OpenAI Codex"
        case .claude:
            "Anthropic Claude Code"
        }
    }
}
