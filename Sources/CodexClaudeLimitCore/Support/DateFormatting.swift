import Foundation

public enum LimitDateFormatting {
    private static func iso8601WithFractions() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    private static func iso8601() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }

    public static func parseDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else {
            return nil
        }

        if let numeric = Double(value) {
            let seconds = numeric > 10_000_000_000 ? numeric / 1000 : numeric
            return Date(timeIntervalSince1970: seconds)
        }

        return iso8601WithFractions().date(from: value) ?? iso8601().date(from: value)
    }

    public static func parseEpochSeconds(_ value: Int?) -> Date? {
        guard let value else {
            return nil
        }

        return Date(timeIntervalSince1970: TimeInterval(value))
    }
}

public extension LimitDateFormatting {
    static func iso8601String(from date: Date) -> String {
        iso8601().string(from: date)
    }
}

public extension Date {
    func conciseRelativeDescription(now: Date = Date()) -> String {
        let interval = max(0, timeIntervalSince(now))
        let minutes = Int(interval / 60)
        let hours = minutes / 60
        let days = hours / 24

        if days > 0 {
            let remainingHours = hours % 24
            return "\(days)d \(remainingHours)h"
        }

        if hours > 0 {
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }

        return "\(max(1, minutes))m"
    }
}
