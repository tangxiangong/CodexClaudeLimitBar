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
            return "\(provider.accessibilityName) \(status.remainingText)"
        }
        .joined(separator: "，")
    }
}

private enum MenuBarStatusImageRenderer {
    private static let canvasHeight: CGFloat = 18
    private static let iconSize: CGFloat = 14
    private static let iconTextSpacing: CGFloat = 3
    private static let providerSpacing: CGFloat = 8
    private static let textYCorrection: CGFloat = -0.5

    static func image(for statuses: [ProviderStatus], providers: [UsageProviderKind]) -> NSImage {
        let orderedStatuses = providers.map { provider in
            statuses.first { $0.provider == provider } ?? ProviderStatus(provider: provider)
        }
        let segments = orderedStatuses.map { MenuBarStatusSegment(status: $0) }
        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black
        ]
        let widths = segments.map { segment in
            iconSize + iconTextSpacing + segment.textSize(attributes: textAttributes).width
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

                let textSize = segment.textSize(attributes: textAttributes)
                segment.text.draw(
                    at: NSPoint(
                        x: x,
                        y: ((canvasHeight - textSize.height) / 2) + textYCorrection
                    ),
                    withAttributes: textAttributes
                )
                x += textSize.width

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
    let text: NSString
    let opacity: CGFloat

    init(status: ProviderStatus) {
        provider = status.provider
        text = NSString(string: status.remainingText)
        opacity = status.errorMessage == nil ? 1 : 0.55
    }

    func textSize(attributes: [NSAttributedString.Key: Any]) -> NSSize {
        text.size(withAttributes: attributes)
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
        let rootURL = Bundle.module.url(forResource: name, withExtension: "svg")
        let nestedURL = Bundle.module.url(
            forResource: name,
            withExtension: "svg",
            subdirectory: "MenuBarLogos"
        )

        guard let url = rootURL ?? nestedURL else {
            return nil
        }

        return NSImage(contentsOf: url)
    }
}

private extension ProviderStatus {
    var remainingText: String {
        guard let usage else {
            return errorMessage == nil ? "--%" : "!"
        }

        guard let remaining = usage.lowestRemainingPercent else {
            return "--%"
        }

        return "\(Int(remaining.rounded()))%"
    }
}
