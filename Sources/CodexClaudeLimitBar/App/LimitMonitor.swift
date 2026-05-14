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

    init(aggregator: UsageAggregator = UsageAggregator()) {
        self.aggregator = aggregator
        self.statuses = UsageProviderKind.allCases.map { ProviderStatus(provider: $0) }
    }

    func start() {
        guard timer == nil else {
            return
        }

        Task {
            await refresh()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }

    func refresh() async {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true
        statuses = statuses.map {
            ProviderStatus(
                provider: $0.provider,
                usage: $0.usage,
                errorMessage: $0.errorMessage,
                isRefreshing: true
            )
        }

        let fetched = await aggregator.fetchAll()
        statuses = UsageProviderKind.allCases.map { provider in
            fetched.first { $0.provider == provider } ?? ProviderStatus(provider: provider)
        }
        lastRefresh = Date()
        isRefreshing = false
    }

    var menuBarText: String {
        let parts = statuses.compactMap { status -> String? in
            guard let usage = status.usage else {
                return status.errorMessage == nil ? "\(status.provider.shortName) --/--" : "\(status.provider.shortName) !"
            }

            let five = usage.fiveHour.map { "\($0.roundedRemaining)" } ?? "--"
            let weekly = usage.weekly.map { "\($0.roundedRemaining)" } ?? "--"
            return "\(status.provider.shortName) \(five)/\(weekly)"
        }

        return parts.isEmpty ? "Limits --" : parts.joined(separator: " · ")
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
