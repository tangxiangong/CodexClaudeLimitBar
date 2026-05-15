import CodexClaudeLimitCore
import Foundation
import SwiftUI

@MainActor
final class LimitMonitor: ObservableObject {
    @Published private(set) var statuses: [ProviderStatus]
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastRefresh: Date?

    private let aggregator: UsageAggregator
    private var timer: Timer?
    private var nextRefreshAt: [UsageProviderKind: Date] = [:]

    init(aggregator: UsageAggregator = UsageAggregator()) {
        self.aggregator = aggregator
        self.statuses = UsageProviderKind.allCases.map { ProviderStatus(provider: $0) }
        self.nextRefreshAt = Self.loadRefreshSchedule()
    }

    func start() {
        guard timer == nil else {
            return
        }

        Task {
            await refresh(userInitiated: true)
        }

        timer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }

    func refresh(userInitiated: Bool = false) async {
        guard !isRefreshing else {
            return
        }

        let now = Date()
        let providersToFetch = providersDueForRefresh(now: now, userInitiated: userInitiated)
        guard !providersToFetch.isEmpty else {
            return
        }

        isRefreshing = true
        statuses = statuses.map {
            let isRefreshingProvider = providersToFetch.contains($0.provider)

            return ProviderStatus(
                provider: $0.provider,
                usage: $0.usage,
                errorMessage: $0.errorMessage,
                isRefreshing: isRefreshingProvider
            )
        }

        let fetched = await aggregator.fetch(providers: Set(providersToFetch))
        let fetchedByProvider = Dictionary(uniqueKeysWithValues: fetched.map { ($0.provider, $0) })
        let currentByProvider = Dictionary(uniqueKeysWithValues: statuses.map { ($0.provider, $0) })

        statuses = UsageProviderKind.allCases.map { provider in
            if let fetchedStatus = fetchedByProvider[provider] {
                return fetchedStatus
            }

            var current = currentByProvider[provider] ?? ProviderStatus(provider: provider)
            current.isRefreshing = false
            return current
        }

        for status in fetched {
            setNextRefresh(
                now.addingTimeInterval(refreshInterval(after: status)),
                for: status.provider
            )
        }

        lastRefresh = Date()
        isRefreshing = false
    }

    var menuBarText: String {
        let parts = statuses.compactMap { status -> String? in
            guard let usage = status.usage else {
                return status.errorMessage == nil ? "\(status.provider.menuBarName) --/--" : "\(status.provider.menuBarName) !"
            }

            let five = usage.fiveHour.map { "\($0.roundedRemaining)" } ?? "--"
            let weekly = usage.weekly.map { "\($0.roundedRemaining)" } ?? "--"
            return "\(status.provider.menuBarName) \(five)/\(weekly)"
        }

        return parts.isEmpty ? "限额 --" : parts.joined(separator: " · ")
    }

    var overallSeverity: LimitSeverity {
        let remaining = statuses.compactMap { $0.usage?.lowestRemainingPercent }.min()
        guard let remaining else {
            return statuses.contains(where: { $0.errorMessage != nil }) ? .danger : .neutral
        }

        if remaining <= 15 {
            return .danger
        }

        if remaining <= 35 {
            return .warning
        }

        return .normal
    }

    private func providersDueForRefresh(now: Date, userInitiated: Bool) -> [UsageProviderKind] {
        let currentByProvider = Dictionary(uniqueKeysWithValues: statuses.map { ($0.provider, $0) })

        return UsageProviderKind.allCases.filter { provider in
            if currentByProvider[provider]?.hasNoDataOrError != false {
                return true
            }

            if userInitiated && provider == .codex {
                return true
            }

            guard let nextRefresh = nextRefreshAt[provider] else {
                return true
            }

            return now >= nextRefresh
        }
    }

    private func refreshInterval(after status: ProviderStatus) -> TimeInterval {
        switch status.provider {
        case .codex:
            120
        case .claude:
            if status.errorMessage?.isRateLimitError == true {
                30 * 60
            } else if status.errorMessage != nil {
                5 * 60
            } else {
                10 * 60
            }
        }
    }

    private func setNextRefresh(_ date: Date, for provider: UsageProviderKind) {
        nextRefreshAt[provider] = date
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: provider.refreshScheduleKey)
    }

    private static func loadRefreshSchedule() -> [UsageProviderKind: Date] {
        UsageProviderKind.allCases.reduce(into: [:]) { schedule, provider in
            let timestamp = UserDefaults.standard.double(forKey: provider.refreshScheduleKey)
            guard timestamp > 0 else {
                return
            }

            schedule[provider] = Date(timeIntervalSince1970: timestamp)
        }
    }
}

private extension ProviderStatus {
    var hasNoDataOrError: Bool {
        usage == nil && errorMessage == nil
    }
}

private extension UsageProviderKind {
    var menuBarName: String {
        switch self {
        case .codex:
            "Codex"
        case .claude:
            "Claude"
        }
    }
}

private extension UsageProviderKind {
    var refreshScheduleKey: String {
        "providerRefresh.nextAllowed.\(rawValue)"
    }
}

private extension String {
    var isRateLimitError: Bool {
        contains("HTTP 429")
            || localizedCaseInsensitiveContains("rate_limit_error")
            || localizedCaseInsensitiveContains("rate limited")
    }
}

enum LimitSeverity {
    case neutral
    case normal
    case warning
    case danger

    var color: Color {
        switch self {
        case .neutral:
            .secondary
        case .normal:
            .green
        case .warning:
            .orange
        case .danger:
            .red
        }
    }
}
