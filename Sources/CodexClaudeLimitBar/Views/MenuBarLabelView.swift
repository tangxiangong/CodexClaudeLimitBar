import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var monitor: LimitMonitor

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "gauge.with.dots.needle.33percent")
                .symbolRenderingMode(.hierarchical)
            Text(monitor.menuBarText)
                .monospacedDigit()
                .lineLimit(1)
        }
        .foregroundStyle(monitor.overallSeverity.color)
    }
}
