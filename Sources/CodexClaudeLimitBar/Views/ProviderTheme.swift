import CodexClaudeLimitCore
import SwiftUI

struct ProviderTheme {
    let cardBackground: LinearGradient
    let cardBorder: Color
    let iconGradient: LinearGradient
    let barGradient: LinearGradient
    let barTrack: Color
    let accentText: Color
    let badgeBackground: Color

    static func theme(for provider: UsageProviderKind, colorScheme: ColorScheme) -> ProviderTheme {
        switch (provider, colorScheme) {
        case (.codex, .dark):
            ProviderTheme(
                cardBackground: LinearGradient(
                    colors: [Color(hex: 0x1a1635), Color(hex: 0x151230)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                cardBorder: Color(hex: 0x6366f1).opacity(0.125),
                iconGradient: LinearGradient(
                    colors: [Color(hex: 0x818cf8), Color(hex: 0x6366f1)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                barGradient: LinearGradient(
                    colors: [Color(hex: 0x6366f1), Color(hex: 0xa5b4fc)],
                    startPoint: .leading, endPoint: .trailing
                ),
                barTrack: Color.white.opacity(0.03),
                accentText: Color(hex: 0xa5b4fc),
                badgeBackground: Color(hex: 0x6366f1).opacity(0.094)
            )
        case (.codex, .light):
            ProviderTheme(
                cardBackground: LinearGradient(
                    colors: [Color(hex: 0xeef2ff), Color(hex: 0xe8ecff)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                cardBorder: Color(hex: 0xc7d2fe),
                iconGradient: LinearGradient(
                    colors: [Color(hex: 0x818cf8), Color(hex: 0x6366f1)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                barGradient: LinearGradient(
                    colors: [Color(hex: 0x6366f1), Color(hex: 0xa5b4fc)],
                    startPoint: .leading, endPoint: .trailing
                ),
                barTrack: Color(hex: 0xc7d2fe).opacity(0.375),
                accentText: Color(hex: 0x4f46e5),
                badgeBackground: Color(hex: 0xe0e7ff)
            )
        case (.claude, .dark):
            ProviderTheme(
                cardBackground: LinearGradient(
                    colors: [Color(hex: 0x2e1a13), Color(hex: 0x22130c)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                cardBorder: Color(hex: 0xe8795a).opacity(0.125),
                iconGradient: LinearGradient(
                    colors: [Color(hex: 0xe8795a), Color(hex: 0xcc6044)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                barGradient: LinearGradient(
                    colors: [Color(hex: 0xcc6044), Color(hex: 0xf4a589)],
                    startPoint: .leading, endPoint: .trailing
                ),
                barTrack: Color.white.opacity(0.03),
                accentText: Color(hex: 0xf4a589),
                badgeBackground: Color(hex: 0xe8795a).opacity(0.094)
            )
        case (.claude, .light):
            ProviderTheme(
                cardBackground: LinearGradient(
                    colors: [Color(hex: 0xfef3ee), Color(hex: 0xfdf0ea)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                cardBorder: Color(hex: 0xf9c9b3),
                iconGradient: LinearGradient(
                    colors: [Color(hex: 0xe8795a), Color(hex: 0xcc6044)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                barGradient: LinearGradient(
                    colors: [Color(hex: 0xcc6044), Color(hex: 0xf4a589)],
                    startPoint: .leading, endPoint: .trailing
                ),
                barTrack: Color(hex: 0xf9c9b3).opacity(0.375),
                accentText: Color(hex: 0xc05030),
                badgeBackground: Color(hex: 0xfee4d6)
            )
        @unknown default:
            theme(for: provider, colorScheme: .dark)
        }
    }

    func effectiveBarGradient(remainingPercent: Double) -> LinearGradient {
        if remainingPercent <= 15 {
            return LinearGradient(colors: [.red], startPoint: .leading, endPoint: .trailing)
        }
        if remainingPercent <= 35 {
            return LinearGradient(colors: [.orange], startPoint: .leading, endPoint: .trailing)
        }
        return barGradient
    }

    func effectiveAccentText(remainingPercent: Double) -> Color {
        if remainingPercent <= 15 {
            return .red
        }
        if remainingPercent <= 35 {
            return .orange
        }
        return accentText
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
