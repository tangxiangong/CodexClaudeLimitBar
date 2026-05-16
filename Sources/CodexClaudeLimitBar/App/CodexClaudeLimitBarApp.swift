import AppKit
import CodexClaudeLimitCore
import SwiftUI

@main
struct CodexClaudeLimitBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var monitor = LimitMonitor()

    var body: some Scene {
        MenuBarExtra {
            LimitPanelView(monitor: monitor)
                .frame(width: 380)
                .task {
                    monitor.start()
                }
        } label: {
            MenuBarLabelView(monitor: monitor)
                .onAppear {
                    monitor.start()
                }
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        ProcessInfo.processInfo.disableAutomaticTermination("CodexClaudeLimitBar runs as a menu bar agent.")
        NSApp.setActivationPolicy(.accessory)
    }
}
