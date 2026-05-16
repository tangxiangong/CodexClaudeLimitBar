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
            VStack(spacing: 10) {
                ForEach(visibleStatuses) { status in
                    ProviderSectionView(status: status)
                }
            }

            actionBar
        }
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
}

private enum LimitPanelPage {
    case usage
    case settings
}

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
