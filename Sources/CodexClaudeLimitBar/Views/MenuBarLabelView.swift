import AppKit
import CodexClaudeLimitCore
import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var monitor: LimitMonitor
    @AppStorage(ProviderVisibilityPreferences.showCodexKey) private var showCodexUsage = true
    @AppStorage(ProviderVisibilityPreferences.showClaudeKey) private var showClaudeUsage = true

    var body: some View {
        let visibleProviders = ProviderVisibilityPreferences.visibleProviders(
            showCodex: showCodexUsage,
            showClaude: showClaudeUsage
        )
        let image = MenuBarStatusImageRenderer.image(
            for: monitor.statuses,
            providers: visibleProviders
        )

        Image(nsImage: image)
            .renderingMode(.template)
            .interpolation(.high)
            .frame(width: image.size.width, height: image.size.height)
            .accessibilityLabel(accessibilityText(for: visibleProviders))
    }

    private func accessibilityText(for providers: [UsageProviderKind]) -> String {
        providers.map { provider in
            let status = monitor.statuses.first { $0.provider == provider } ?? ProviderStatus(provider: provider)
            return "\(provider.accessibilityName) \(status.accessibilityRemainingText)"
        }
        .joined(separator: "，")
    }
}

private enum MenuBarStatusImageRenderer {
    private static let canvasHeight: CGFloat = 26
    private static let iconSize: CGFloat = 18
    private static let iconTextSpacing: CGFloat = 3
    private static let columnSpacing: CGFloat = 5
    private static let providerSpacing: CGFloat = 8
    private static let lineSpacing: CGFloat = -2

    static func image(for statuses: [ProviderStatus], providers: [UsageProviderKind]) -> NSImage {
        let orderedStatuses = providers.map { provider in
            statuses.first { $0.provider == provider } ?? ProviderStatus(provider: provider)
        }
        let segments = orderedStatuses.map { MenuBarStatusSegment(status: $0) }
        let labelFont = NSFont.systemFont(ofSize: 10.5, weight: .semibold)
        let valueFont = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .bold)
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: NSColor.black
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: valueFont,
            .foregroundColor: NSColor.black
        ]
        let widths = segments.map { segment in
            iconSize + iconTextSpacing + segment.blockSize(
                labelAttributes: labelAttributes,
                valueAttributes: valueAttributes,
                columnSpacing: columnSpacing,
                lineSpacing: lineSpacing
            ).width
        }
        let totalWidth = widths.reduce(0, +) + providerSpacing * CGFloat(max(segments.count - 1, 0))
        let canvasSize = NSSize(width: ceil(totalWidth), height: canvasHeight)

        let image = NSImage(size: canvasSize, flipped: false) { _ in
            NSColor.black.set()

            var x: CGFloat = 0
            for (index, segment) in segments.enumerated() {
                if let icon = MenuBarIconImage.image(for: segment.provider, pointSize: iconSize) {
                    icon.draw(
                        in: NSRect(
                            x: x,
                            y: (canvasHeight - iconSize) / 2,
                            width: iconSize,
                            height: iconSize
                        ),
                        from: .zero,
                        operation: .sourceOver,
                        fraction: segment.opacity
                    )
                }

                x += iconSize + iconTextSpacing

                let blockSize = segment.blockSize(
                    labelAttributes: labelAttributes,
                    valueAttributes: valueAttributes,
                    columnSpacing: columnSpacing,
                    lineSpacing: lineSpacing
                )

                var columnX = x
                for column in segment.columns {
                    let columnSize = column.size(
                        labelAttributes: labelAttributes,
                        valueAttributes: valueAttributes,
                        lineSpacing: lineSpacing
                    )
                    let labelSize = column.labelSize(attributes: labelAttributes)
                    let valueSize = column.valueSize(attributes: valueAttributes)
                    let textBaseY = (canvasHeight - blockSize.height) / 2

                    column.labelText.draw(
                        at: NSPoint(
                            x: columnX + ((columnSize.width - labelSize.width) / 2),
                            y: textBaseY + valueSize.height + lineSpacing
                        ),
                        withAttributes: labelAttributes
                    )
                    column.valueText.draw(
                        at: NSPoint(
                            x: columnX + ((columnSize.width - valueSize.width) / 2),
                            y: textBaseY
                        ),
                        withAttributes: valueAttributes
                    )

                    columnX += columnSize.width + columnSpacing
                }

                x += blockSize.width

                if index < segments.count - 1 {
                    x += providerSpacing
                }
            }

            return true
        }

        image.isTemplate = true
        return image
    }
}

private extension UsageProviderKind {
    var accessibilityName: String {
        switch self {
        case .codex:
            "Codex"
        case .claude:
            "Claude Code"
        }
    }
}

private struct MenuBarStatusSegment {
    let provider: UsageProviderKind
    let columns: [MenuBarStatusColumn]
    let opacity: CGFloat

    init(status: ProviderStatus) {
        provider = status.provider
        columns = status.menuBarColumns.map {
            MenuBarStatusColumn(label: $0.label, value: $0.value)
        }
        opacity = status.errorMessage == nil ? 1 : 0.55
    }

    func blockSize(
        labelAttributes: [NSAttributedString.Key: Any],
        valueAttributes: [NSAttributedString.Key: Any],
        columnSpacing: CGFloat,
        lineSpacing: CGFloat
    ) -> NSSize {
        let columnSizes = columns.map {
            $0.size(
                labelAttributes: labelAttributes,
                valueAttributes: valueAttributes,
                lineSpacing: lineSpacing
            )
        }
        let columnGapWidth = columnSpacing * CGFloat(max(columnSizes.count - 1, 0))

        return NSSize(
            width: columnSizes.reduce(0) { $0 + $1.width } + columnGapWidth,
            height: columnSizes.map(\.height).max() ?? 0
        )
    }
}

private struct MenuBarStatusColumn {
    let labelText: NSString
    let valueText: NSString

    init(label: String, value: String) {
        labelText = NSString(string: label)
        valueText = NSString(string: value)
    }

    func labelSize(attributes: [NSAttributedString.Key: Any]) -> NSSize {
        labelText.size(withAttributes: attributes)
    }

    func valueSize(attributes: [NSAttributedString.Key: Any]) -> NSSize {
        valueText.size(withAttributes: attributes)
    }

    func size(
        labelAttributes: [NSAttributedString.Key: Any],
        valueAttributes: [NSAttributedString.Key: Any],
        lineSpacing: CGFloat
    ) -> NSSize {
        let labelSize = labelSize(attributes: labelAttributes)
        let valueSize = valueSize(attributes: valueAttributes)
        return NSSize(
            width: max(labelSize.width, valueSize.width),
            height: labelSize.height + lineSpacing + valueSize.height
        )
    }
}

private enum MenuBarIconImage {
    static func image(for provider: UsageProviderKind, pointSize: CGFloat) -> NSImage? {
        guard let source = originalImage(for: provider)?.copy() as? NSImage else {
            return nil
        }

        source.size = NSSize(width: pointSize, height: pointSize)
        source.isTemplate = true
        return source
    }

    private static func originalImage(for provider: UsageProviderKind) -> NSImage? {
        switch provider {
        case .codex:
            codex
        case .claude:
            claudeCode
        }
    }

    private static let codex = load("codex-menu")
    private static let claudeCode = load("claude-code-menu")

    private static func load(_ name: String) -> NSImage? {
        guard let url = AppResourceLocator.url(
            forResource: name,
            withExtension: "svg",
            subdirectory: "MenuBarLogos"
        ) else {
            return nil
        }

        return NSImage(contentsOf: url)
    }
}

private extension ProviderStatus {
    var menuBarColumns: [(label: String, value: String)] {
        guard let usage else {
            let value = errorMessage == nil ? "--%" : "!"
            return [
                ("5h", value),
                ("week", value)
            ]
        }

        return usage.menuBarColumns
    }

    var accessibilityRemainingText: String {
        guard let usage else {
            return errorMessage == nil ? "暂无用量" : "获取失败"
        }

        return usage.accessibilityRemainingText
    }
}

private extension ProviderUsage {
    var menuBarColumns: [(label: String, value: String)] {
        [
            ("5h", percentText(for: fiveHour)),
            ("week", percentText(for: weekly))
        ]
    }

    var accessibilityRemainingText: String {
        "5 小时 \(percentText(for: fiveHour))，每周 \(percentText(for: weekly))"
    }

    private func percentText(for window: LimitWindow?) -> String {
        guard let window else {
            return "--%"
        }

        return "\(window.roundedRemaining)%"
    }
}
