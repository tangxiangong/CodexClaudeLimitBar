import Foundation
import Testing
@testable import CodexClaudeLimitBar

@Suite("LaunchAgent login item fallback")
struct LaunchAgentLoginItemControllerTests {
    @Test("register writes a launch agent plist for the app executable")
    func registerWritesLaunchAgentPlist() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let appURL = temporaryDirectory.appending(path: "CodexClaudeLimitBar.app", directoryHint: .isDirectory)
        let executableURL = appURL.appending(path: "Contents/MacOS/CodexClaudeLimitBar", directoryHint: .notDirectory)
        try FileManager.default.createDirectory(
            at: executableURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data().write(to: executableURL)

        let launchAgentsDirectory = temporaryDirectory.appending(path: "LaunchAgents", directoryHint: .isDirectory)
        let controller = LaunchAgentLoginItemController(
            appBundleURL: appURL,
            launchAgentsDirectory: launchAgentsDirectory
        )

        try controller.register()

        let plistData = try Data(contentsOf: controller.plistURL)
        let plist = try #require(PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any])
        #expect(plist["Label"] as? String == "com.xiaoyu.CodexClaudeLimitBar.launch-at-login")
        #expect(plist["RunAtLoad"] as? Bool == true)
        #expect(plist["KeepAlive"] as? Bool == false)
        #expect(plist["ProgramArguments"] as? [String] == [executableURL.path])
        #expect(controller.isRegistered)
    }

    @Test("unregister removes the launch agent plist")
    func unregisterRemovesLaunchAgentPlist() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let launchAgentsDirectory = temporaryDirectory.appending(path: "LaunchAgents", directoryHint: .isDirectory)
        let controller = LaunchAgentLoginItemController(
            appBundleURL: temporaryDirectory.appending(path: "CodexClaudeLimitBar.app", directoryHint: .isDirectory),
            launchAgentsDirectory: launchAgentsDirectory
        )

        try FileManager.default.createDirectory(at: launchAgentsDirectory, withIntermediateDirectories: true)
        try Data().write(to: controller.plistURL)

        try controller.unregister()

        #expect(!controller.isRegistered)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(
            path: UUID().uuidString,
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
