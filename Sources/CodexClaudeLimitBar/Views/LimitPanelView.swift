import AppKit
import CodexClaudeLimitCore
import SwiftUI

struct LimitPanelView: View {
    @ObservedObject var monitor: LimitMonitor
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            ForEach(monitor.statuses) { status in
                ProviderSectionView(status: status)
            }

            Divider()

            HStack(spacing: 10) {
                Button {
                    Task {
                        await monitor.refresh()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(monitor.isRefreshing)

                Spacer()

                Button {
                    openURL(URL(string: "https://chatgpt.com/codex/settings/usage")!)
                } label: {
                    Label("Codex", systemImage: "safari")
                }

                Button {
                    openURL(URL(string: "https://claude.ai/settings/usage")!)
                } label: {
                    Label("Claude", systemImage: "safari")
                }

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
        }
        .padding(16)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Usage Limits")
                    .font(.headline)

                Text(refreshText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if monitor.isRefreshing {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private var refreshText: String {
        guard let lastRefresh = monitor.lastRefresh else {
            return "Waiting for first refresh"
        }

        return "Updated \(lastRefresh.formatted(date: .omitted, time: .shortened))"
    }
}

struct ProviderSectionView: View {
    let status: ProviderStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(status.provider.displayName, systemImage: iconName)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                if let planName = status.usage?.planName, !planName.isEmpty {
                    Text(planName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if let usage = status.usage {
                ForEach(primaryWindows(from: usage)) { window in
                    LimitWindowRow(window: window)
                }

                if let credits = usage.credits?.balance {
                    HStack {
                        Text("Credits")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(credits)
                            .monospacedDigit()
                    }
                    .font(.caption)
                }

                Text(usage.sourceDescription)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            } else if status.isRefreshing {
                Text("Refreshing...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(status.errorMessage ?? "No data yet")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var iconName: String {
        switch status.provider {
        case .codex:
            "chevron.left.forwardslash.chevron.right"
        case .claude:
            "sparkles"
        }
    }

    private func primaryWindows(from usage: ProviderUsage) -> [LimitWindow] {
        [usage.fiveHour, usage.weekly].compactMap { $0 }
    }
}

struct LimitWindowRow: View {
    let window: LimitWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(window.title)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(window.roundedRemaining)% left")
                    .foregroundStyle(severityColor)
                    .monospacedDigit()
            }
            .font(.caption)

            ProgressView(value: window.usedPercent, total: 100)
                .tint(severityColor)

            HStack {
                Text("\(window.roundedUsed)% used")
                Spacer()
                Text(resetText)
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .monospacedDigit()
        }
    }

    private var severityColor: Color {
        if window.remainingPercent <= 15 {
            return .red
        }

        if window.remainingPercent <= 35 {
            return .orange
        }

        return .green
    }

    private var resetText: String {
        guard let resetDate = window.resetDate else {
            return "reset unknown"
        }

        return "resets in \(resetDate.conciseRelativeDescription())"
    }
}
