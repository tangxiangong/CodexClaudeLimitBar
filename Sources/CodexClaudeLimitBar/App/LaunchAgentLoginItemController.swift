import Foundation

struct LaunchAgentLoginItemController {
    private static let label = "com.xiaoyu.CodexClaudeLimitBar.launch-at-login"

    let appBundleURL: URL
    let launchAgentsDirectory: URL

    init(
        appBundleURL: URL = Bundle.main.bundleURL,
        launchAgentsDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Library/LaunchAgents", directoryHint: .isDirectory)
    ) {
        self.appBundleURL = appBundleURL
        self.launchAgentsDirectory = launchAgentsDirectory
    }

    var plistURL: URL {
        launchAgentsDirectory.appending(path: "\(Self.label).plist", directoryHint: .notDirectory)
    }

    var isAvailable: Bool {
        appBundleURL.pathExtension == "app"
            && FileManager.default.fileExists(atPath: executableURL.path)
    }

    var isRegistered: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    func register() throws {
        guard isAvailable else {
            throw LaunchAgentLoginItemError.unsupportedBundle(appBundleURL.path)
        }

        try FileManager.default.createDirectory(
            at: launchAgentsDirectory,
            withIntermediateDirectories: true
        )

        let plist = LaunchAgentPlist(
            label: Self.label,
            programArguments: [executableURL.path],
            runAtLoad: true,
            keepAlive: false
        )
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let data = try encoder.encode(plist)
        try data.write(to: plistURL, options: .atomic)
    }

    func unregister() throws {
        guard isRegistered else {
            return
        }

        try FileManager.default.removeItem(at: plistURL)
    }

    private var executableURL: URL {
        appBundleURL.appending(path: "Contents/MacOS/CodexClaudeLimitBar", directoryHint: .notDirectory)
    }
}

private struct LaunchAgentPlist: Encodable {
    let label: String
    let programArguments: [String]
    let runAtLoad: Bool
    let keepAlive: Bool

    enum CodingKeys: String, CodingKey {
        case label = "Label"
        case programArguments = "ProgramArguments"
        case runAtLoad = "RunAtLoad"
        case keepAlive = "KeepAlive"
    }
}

private enum LaunchAgentLoginItemError: LocalizedError {
    case unsupportedBundle(String)

    var errorDescription: String? {
        switch self {
        case let .unsupportedBundle(path):
            "当前运行路径不是可注册的 app bundle：\(path)"
        }
    }
}
