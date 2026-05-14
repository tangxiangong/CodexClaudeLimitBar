import AppKit
import CodexClaudeLimitCore
import SwiftUI

struct LimitPanelView: View {
    @ObservedObject var monitor: LimitMonitor
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            VStack(spacing: 10) {
                ForEach(monitor.statuses) { status in
                    ProviderSectionView(status: status)
                }
            }

            actionBar
        }
        .padding(14)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("限额监控")
                        .font(.headline.weight(.semibold))

                    Text(refreshText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusSummaryView(severity: monitor.overallSeverity)
            }

            HStack(spacing: 10) {
                SummaryMetricView(
                    title: "最低余量",
                    value: minimumRemainingText,
                    tint: monitor.overallSeverity.color
                )

                SummaryMetricView(
                    title: "产品",
                    value: "\(monitor.statuses.count)",
                    tint: .primary
                )
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.separator.opacity(0.35), lineWidth: 1)
        }
    }

    private var refreshText: String {
        guard let lastRefresh = monitor.lastRefresh else {
            return monitor.isRefreshing ? "正在获取最新限额" : "等待首次刷新"
        }

        return "更新于 \(Self.refreshFormatter.string(from: lastRefresh))"
    }

    private var minimumRemainingText: String {
        let remaining = monitor.statuses.compactMap { $0.usage?.lowestRemainingPercent }.min()
        guard let remaining else {
            return "--"
        }

        return "\(Int(remaining.rounded()))%"
    }

    private var actionBar: some View {
        HStack(spacing: 8) {
            Button {
                Task {
                    await monitor.refresh()
                }
            } label: {
                Label("刷新", systemImage: "arrow.clockwise")
            }
            .disabled(monitor.isRefreshing)

            Spacer(minLength: 4)

            Button {
                openURL(URL(string: "https://chatgpt.com/codex/settings/usage")!)
            } label: {
                Label("Codex", systemImage: "safari")
            }

            Button {
                openURL(URL(string: "https://claude.ai/settings/usage")!)
            } label: {
                Label("Claude Code", systemImage: "safari")
            }

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("退出", systemImage: "power")
            }
        }
        .font(.caption)
        .buttonStyle(.borderless)
        .labelStyle(.titleAndIcon)
        .padding(.top, 2)
    }

    private static let refreshFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

private struct StatusSummaryView: View {
    let severity: LimitSeverity

    var body: some View {
        HStack(spacing: 5) {
            if severity == .neutral {
                ProgressView()
                    .controlSize(.small)
            } else {
                Circle()
                    .fill(severity.color)
                    .frame(width: 7, height: 7)
            }

            Text(severity.localizedTitle)
                .font(.caption.weight(.medium))
                .foregroundStyle(severity.color)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(severity.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct SummaryMetricView: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.background.opacity(0.45), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct ProviderSectionView: View {
    let status: ProviderStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.background.opacity(0.72))
                    BrandLogoView(provider: status.provider, size: 28)
                }
                .frame(width: 42, height: 42)

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
                    RemainingBadge(percent: usage.lowestRemainingPercent)
                }
            }

            if let usage = status.usage {
                VStack(spacing: 8) {
                    ForEach(primaryWindows(from: usage)) { window in
                        LimitWindowRow(window: window)
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

                Label(usage.sourceDescription, systemImage: "link")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            } else if status.isRefreshing {
                Text("正在刷新...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(status.errorMessage ?? "暂无数据")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.separator.opacity(0.3), lineWidth: 1)
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

private struct RemainingBadge: View {
    let percent: Double?

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)

            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(color)
                .monospacedDigit()
        }
    }

    private var text: String {
        guard let percent else {
            return "--"
        }

        return "剩余 \(Int(percent.rounded()))%"
    }

    private var color: Color {
        guard let percent else {
            return .secondary
        }

        if percent <= 15 {
            return .red
        }

        if percent <= 35 {
            return .orange
        }

        return .green
    }
}

struct LimitWindowRow: View {
    let window: LimitWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(window.localizedTitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("剩余 \(window.roundedRemaining)%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(severityColor)
                    .monospacedDigit()
            }

            ProgressView(value: window.remainingPercent, total: 100)
                .tint(severityColor)
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
            return "重置时间未知"
        }

        return "\(resetDate.chineseRelativeLimitDescription()) 后重置"
    }
}

private extension LimitWindow {
    var localizedTitle: String {
        switch kind {
        case .fiveHour:
            "5 小时窗口"
        case .weekly:
            "每周窗口"
        case .modelSpecific, .codeReview, .extra:
            title
        }
    }
}

private extension Date {
    func chineseRelativeLimitDescription(now: Date = Date()) -> String {
        let interval = max(0, timeIntervalSince(now))
        let minutes = Int(interval / 60)
        let hours = minutes / 60
        let days = hours / 24

        if days > 0 {
            let remainingHours = hours % 24
            return "\(days)天\(remainingHours)小时"
        }

        if hours > 0 {
            let remainingMinutes = minutes % 60
            return "\(hours)小时\(remainingMinutes)分钟"
        }

        return "\(max(1, minutes))分钟"
    }
}

private extension UsageProviderKind {
    var productDisplayName: String {
        switch self {
        case .codex:
            "Codex"
        case .claude:
            "Claude Code"
        }
    }

    var providerSubtitle: String {
        switch self {
        case .codex:
            "OpenAI Codex"
        case .claude:
            "Anthropic Claude Code"
        }
    }
}

private extension LimitSeverity {
    var localizedTitle: String {
        switch self {
        case .neutral:
            "等待数据"
        case .normal:
            "余量充足"
        case .warning:
            "余量偏低"
        case .danger:
            "需要关注"
        }
    }
}
