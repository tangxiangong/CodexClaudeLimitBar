import Foundation

public enum UsageProviderKind: String, CaseIterable, Hashable, Identifiable, Sendable {
    case codex
    case claude

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .codex:
            "Codex"
        case .claude:
            "Claude"
        }
    }

    public var shortName: String {
        switch self {
        case .codex:
            "CX"
        case .claude:
            "CL"
        }
    }
}

public struct CreditsInfo: Equatable, Sendable {
    public let balance: String?
    public let hasCredits: Bool?
    public let unlimited: Bool?

    public init(balance: String? = nil, hasCredits: Bool? = nil, unlimited: Bool? = nil) {
        self.balance = balance
        self.hasCredits = hasCredits
        self.unlimited = unlimited
    }
}

public struct ProviderUsage: Identifiable, Equatable, Sendable {
    public let provider: UsageProviderKind
    public let planName: String?
    public let windows: [LimitWindow]
    public let credits: CreditsInfo?
    public let updatedAt: Date
    public let sourceDescription: String

    public init(
        provider: UsageProviderKind,
        planName: String?,
        windows: [LimitWindow],
        credits: CreditsInfo? = nil,
        updatedAt: Date = Date(),
        sourceDescription: String
    ) {
        self.provider = provider
        self.planName = planName
        self.windows = windows
        self.credits = credits
        self.updatedAt = updatedAt
        self.sourceDescription = sourceDescription
    }

    public var id: UsageProviderKind { provider }

    public var fiveHour: LimitWindow? {
        windows.first { $0.kind == .fiveHour }
    }

    public var weekly: LimitWindow? {
        windows.first { $0.kind == .weekly }
    }

    public var lowestRemainingPercent: Double? {
        let visible = [fiveHour, weekly].compactMap { $0?.remainingPercent }
        return visible.min()
    }
}

public struct ProviderStatus: Identifiable, Equatable, Sendable {
    public let provider: UsageProviderKind
    public var usage: ProviderUsage?
    public var errorMessage: String?
    public var isRefreshing: Bool

    public init(
        provider: UsageProviderKind,
        usage: ProviderUsage? = nil,
        errorMessage: String? = nil,
        isRefreshing: Bool = false
    ) {
        self.provider = provider
        self.usage = usage
        self.errorMessage = errorMessage
        self.isRefreshing = isRefreshing
    }

    public var id: UsageProviderKind { provider }
}
