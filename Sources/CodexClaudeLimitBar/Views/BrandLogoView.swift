import AppKit
import CodexClaudeLimitCore
import SwiftUI

struct BrandLogoView: View {
    let provider: UsageProviderKind
    var size: CGFloat = 28

    var body: some View {
        Group {
            if let image = BrandLogoImage.image(for: provider, pointSize: size) {
                Image(nsImage: image)
                    .interpolation(.high)
            } else {
                Image(systemName: provider.fallbackSymbolName)
                    .font(.system(size: size * 0.72, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .accessibilityHidden(true)
    }
}

private enum BrandLogoImage {
    static func image(for provider: UsageProviderKind, pointSize: CGFloat) -> NSImage? {
        guard let source = originalImage(for: provider)?.copy() as? NSImage else {
            return nil
        }

        source.size = NSSize(width: pointSize, height: pointSize)
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

    private static let codex = load("codex-color")
    private static let claudeCode = load("claude-code-color")

    private static func load(_ name: String) -> NSImage? {
        let rootURL = Bundle.module.url(forResource: name, withExtension: "png")
        let nestedURL = Bundle.module.url(
            forResource: name,
            withExtension: "png",
            subdirectory: "Logos"
        )

        guard let url = rootURL ?? nestedURL else {
            return nil
        }

        return NSImage(contentsOf: url)
    }
}

private extension UsageProviderKind {
    var fallbackSymbolName: String {
        switch self {
        case .codex:
            "chevron.left.forwardslash.chevron.right"
        case .claude:
            "sparkles"
        }
    }
}
