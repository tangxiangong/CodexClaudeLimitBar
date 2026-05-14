import Foundation

public enum LimitWindowKind: String, Codable, Sendable {
    case fiveHour
    case weekly
    case modelSpecific
    case codeReview
    case extra
}

public struct LimitWindow: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let kind: LimitWindowKind
    public let usedPercent: Double
    public let resetDate: Date?
    public let windowSeconds: Int?

    public init(
        id: String,
        title: String,
        kind: LimitWindowKind,
        usedPercent: Double,
        resetDate: Date?,
        windowSeconds: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.usedPercent = usedPercent.clamped(to: 0...100)
        self.resetDate = resetDate
        self.windowSeconds = windowSeconds
    }

    public var remainingPercent: Double {
        (100 - usedPercent).clamped(to: 0...100)
    }

    public var roundedRemaining: Int {
        Int(remainingPercent.rounded())
    }

    public var roundedUsed: Int {
        Int(usedPercent.rounded())
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
