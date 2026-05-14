import Foundation

struct CodexUsagePayload: Decodable {
    let planType: String?
    let rateLimit: CodexRateLimitDetails?
    let additionalRateLimits: [CodexAdditionalRateLimit]?
    let credits: CodexCreditDetails?

    enum CodingKeys: String, CodingKey {
        case planType = "plan_type"
        case rateLimit = "rate_limit"
        case additionalRateLimits = "additional_rate_limits"
        case credits
    }

    func providerUsage(updatedAt: Date) throws -> ProviderUsage {
        var windows: [LimitWindow] = []

        if let primary = rateLimit?.primaryWindow {
            windows.append(primary.limitWindow(id: "codex-5h", title: "5-hour limit", kind: .fiveHour))
        }

        if let secondary = rateLimit?.secondaryWindow {
            windows.append(secondary.limitWindow(id: "codex-weekly", title: "Weekly limit", kind: .weekly))
        }

        for additional in additionalRateLimits ?? [] {
            if let primary = additional.rateLimit?.primaryWindow {
                windows.append(
                    primary.limitWindow(
                        id: "codex-\(additional.meteredFeature ?? additional.limitName ?? "additional")",
                        title: additional.limitName ?? additional.meteredFeature ?? "Additional limit",
                        kind: .modelSpecific
                    )
                )
            }
        }

        guard !windows.isEmpty else {
            throw UsageError.unsupportedResponse("Codex usage response did not contain rate-limit windows.")
        }

        return ProviderUsage(
            provider: .codex,
            planName: planType,
            windows: windows,
            credits: credits?.creditsInfo,
            updatedAt: updatedAt,
            sourceDescription: "chatgpt.com/backend-api usage"
        )
    }
}

struct CodexRateLimitDetails: Decodable {
    let primaryWindow: CodexRateLimitWindow?
    let secondaryWindow: CodexRateLimitWindow?

    enum CodingKeys: String, CodingKey {
        case primaryWindow = "primary_window"
        case secondaryWindow = "secondary_window"
    }
}

struct CodexRateLimitWindow: Decodable {
    let usedPercent: Double?
    let limitWindowSeconds: Int?
    let resetAfterSeconds: Int?
    let resetAt: Int?

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case limitWindowSeconds = "limit_window_seconds"
        case resetAfterSeconds = "reset_after_seconds"
        case resetAt = "reset_at"
    }

    func limitWindow(id: String, title: String, kind: LimitWindowKind) -> LimitWindow {
        LimitWindow(
            id: id,
            title: title,
            kind: kind,
            usedPercent: usedPercent ?? 0,
            resetDate: LimitDateFormatting.parseEpochSeconds(resetAt)
                ?? resetDateFromResetAfterSeconds(),
            windowSeconds: limitWindowSeconds
        )
    }

    private func resetDateFromResetAfterSeconds() -> Date? {
        guard let resetAfterSeconds else {
            return nil
        }

        return Date().addingTimeInterval(TimeInterval(resetAfterSeconds))
    }
}

struct CodexAdditionalRateLimit: Decodable {
    let limitName: String?
    let meteredFeature: String?
    let rateLimit: CodexRateLimitDetails?

    enum CodingKeys: String, CodingKey {
        case limitName = "limit_name"
        case meteredFeature = "metered_feature"
        case rateLimit = "rate_limit"
    }
}

struct CodexCreditDetails: Decodable {
    let hasCredits: Bool?
    let unlimited: Bool?
    let balance: String?

    enum CodingKeys: String, CodingKey {
        case hasCredits = "has_credits"
        case unlimited
        case balance
    }

    var creditsInfo: CreditsInfo {
        CreditsInfo(balance: balance, hasCredits: hasCredits, unlimited: unlimited)
    }
}
