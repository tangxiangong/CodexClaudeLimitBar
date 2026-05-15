import AppKit
import CodexClaudeLimitCore
import SwiftUI

struct LimitPanelView: View {
    @ObservedObject var monitor: LimitMonitor
    @State private var page = LimitPanelPage.usage
    @AppStorage(ProviderVisibilityPreferences.showCodexKey) private var showCodexUsage = true
    @AppStorage(ProviderVisibilityPreferences.showClaudeKey) private var showClaudeUsage = true

    var body: some View {
        Group {
            switch page {
            case .usage:
                usagePage
            case .settings:
                SettingsView {
                    page = .usage
                }
            }
        }
        .padding(14)
    }

    private var usagePage: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            VStack(spacing: 10) {
                ForEach(visibleStatuses) { status in
                    ProviderSectionView(status: status)
                }
            }

            actionBar
        }
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

                StatusSummaryView(severity: visibleOverallSeverity)
            }

            HStack(spacing: 10) {
                SummaryMetricView(
                    title: "最低余量",
                    value: minimumRemainingText,
                    tint: visibleOverallSeverity.color
                )

                SummaryMetricView(
                    title: "产品",
                    value: "\(visibleStatuses.count)",
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
        let remaining = visibleStatuses.compactMap { $0.usage?.lowestRemainingPercent }.min()
        guard let remaining else {
            return "--"
        }

        return "\(Int(remaining.rounded()))%"
    }

    private var actionBar: some View {
        HStack(spacing: 8) {
            Button {
                Task {
                    await monitor.refresh(userInitiated: true)
                }
            } label: {
                Label("刷新", systemImage: "arrow.clockwise")
            }
            .disabled(monitor.isRefreshing)

            Spacer(minLength: 4)

            Button {
                page = .settings
            } label: {
                Label("设置", systemImage: "gearshape")
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

    private var visibleStatuses: [ProviderStatus] {
        ProviderVisibilityPreferences.filter(
            monitor.statuses,
            showCodex: showCodexUsage,
            showClaude: showClaudeUsage
        )
    }

    private var visibleOverallSeverity: LimitSeverity {
        let remaining = visibleStatuses.compactMap { $0.usage?.lowestRemainingPercent }.min()
        guard let remaining else {
            return visibleStatuses.contains(where: { $0.errorMessage != nil }) ? .danger : .neutral
        }

        if remaining <= 15 {
            return .danger
        }

        if remaining <= 35 {
            return .warning
        }

        return .normal
    }

    private static let refreshFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

private enum LimitPanelPage {
    case usage
    case settings
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
                ProviderErrorView(message: status.errorMessage)
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

private struct ProviderErrorView: View {
    let message: String?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(summary.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)

                Text(summary.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var summary: (title: String, detail: String) {
        guard let message, !message.isEmpty else {
            return ("暂无数据", "还没有获取到该服务的用量信息。")
        }

        if message.contains("HTTP 429")
            || message.localizedCaseInsensitiveContains("rate_limit_error")
            || message.localizedCaseInsensitiveContains("rate limited") {
            return ("请求过于频繁", "Claude API 暂时限流，请稍后再刷新。")
        }

        if message.contains("HTTP 401") || message.localizedCaseInsensitiveContains("unauthorized") {
            return ("登录状态失效", "请重新登录后再刷新用量。")
        }

        if message.localizedCaseInsensitiveContains("credentials not found")
            || message.localizedCaseInsensitiveContains("missing credentials") {
            return ("未找到登录信息", "请先完成对应服务的登录。")
        }

        return ("获取失败", sanitizedDetail(from: message))
    }

    private func sanitizedDetail(from message: String) -> String {
        let firstLine = message
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: #" +"#, with: " ", options: .regularExpression)
            .split(separator: "{", maxSplits: 1, omittingEmptySubsequences: true)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let firstLine, !firstLine.isEmpty else {
            return "请稍后重试。"
        }

        if firstLine.count > 120 {
            return "\(firstLine.prefix(120))..."
        }

        return firstLine
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
