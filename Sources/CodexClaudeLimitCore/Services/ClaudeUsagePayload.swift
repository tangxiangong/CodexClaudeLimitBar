import Foundation

struct ClaudeUsagePayload: Decodable {
    let fiveHour: ClaudeLimitBucket?
    let sevenDay: ClaudeLimitBucket?
    let sevenDaySonnet: ClaudeLimitBucket?
    let sevenDayOpus: ClaudeLimitBucket?
    let extraUsage: ClaudeExtraUsage?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDaySonnet = "seven_day_sonnet"
        case sevenDayOpus = "seven_day_opus"
        case extraUsage = "extra_usage"
    }

    func providerUsage(planName: String?, updatedAt: Date) throws -> ProviderUsage {
        var windows: [LimitWindow] = []

        if let fiveHour {
            windows.append(fiveHour.limitWindow(id: "claude-5h", title: "5-hour limit", kind: .fiveHour))
        }

        if let sevenDay {
            windows.append(sevenDay.limitWindow(id: "claude-weekly", title: "Weekly limit", kind: .weekly))
        }

        if let sevenDaySonnet {
            windows.append(sevenDaySonnet.limitWindow(id: "claude-sonnet", title: "Sonnet weekly", kind: .modelSpecific))
        }

        if let sevenDayOpus {
            windows.append(sevenDayOpus.limitWindow(id: "claude-opus", title: "Opus weekly", kind: .modelSpecific))
        }

        guard !windows.isEmpty else {
            throw UsageError.unsupportedResponse("Claude usage response did not contain rate-limit windows.")
        }

        let credits: CreditsInfo?
        if let extraUsage {
            credits = CreditsInfo(
                balance: extraUsage.usedCredits.map { String(format: "%.2f / %.2f", $0, extraUsage.monthlyLimit ?? 0) },
                hasCredits: extraUsage.isEnabled,
                unlimited: nil
            )
        } else {
            credits = nil
        }

        return ProviderUsage(
            provider: .claude,
            planName: planName,
            windows: windows,
            credits: credits,
            updatedAt: updatedAt,
            sourceDescription: "api.anthropic.com/api/oauth/usage"
        )
    }
}

struct ClaudeLimitBucket: Decodable {
    let utilization: Double?
    let resetsAt: String?
    let usedPercentage: Double?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
        case usedPercentage = "used_percentage"
    }

    func limitWindow(id: String, title: String, kind: LimitWindowKind) -> LimitWindow {
        LimitWindow(
            id: id,
            title: title,
            kind: kind,
            usedPercent: utilization ?? usedPercentage ?? 0,
            resetDate: LimitDateFormatting.parseDate(resetsAt),
            windowSeconds: nil
        )
    }
}

struct ClaudeExtraUsage: Decodable {
    let isEnabled: Bool?
    let monthlyLimit: Double?
    let usedCredits: Double?
    let utilization: Double?

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case monthlyLimit = "monthly_limit"
        case usedCredits = "used_credits"
        case utilization
    }
}
