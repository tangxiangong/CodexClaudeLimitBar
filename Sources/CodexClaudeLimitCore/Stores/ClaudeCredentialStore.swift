import Foundation

public struct ClaudeCredentials: Equatable, Sendable {
    public let accessToken: String
    public let subscriptionType: String?
    public let rateLimitTier: String?
    public let expiresAt: Date?

    public var isExpired: Bool {
        guard let expiresAt else { return false }
        return Date() >= expiresAt
    }
}

public actor ClaudeCredentialStore {
    public static let defaultPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/.credentials.json")

    private let credentialsURL: URL
    private let keychainService: String

    public init(
        credentialsURL: URL = ClaudeCredentialStore.defaultPath,
        keychainService: String = "Claude Code-credentials"
    ) {
        self.credentialsURL = credentialsURL
        self.keychainService = keychainService
    }

    public func loadCredentials() throws -> ClaudeCredentials {
        if FileManager.default.fileExists(atPath: credentialsURL.path) {
            let data = try Data(contentsOf: credentialsURL)
            return try decodeCredentials(data: data)
        }

        if let keychainData = try readKeychainCredentials() {
            return try decodeCredentials(data: keychainData)
        }

        throw UsageError.missingCredentials("Claude credentials not found. Run `claude /login` first.")
    }

    public func refreshCredentials() async throws -> ClaudeCredentials {
        let claudePath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/bin/claude").path

        guard FileManager.default.fileExists(atPath: claudePath) else {
            throw UsageError.invalidCredentials("Claude CLI not found. Please reinstall Claude Code.")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: claudePath)
        process.arguments = ["auth", "status"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        return try loadCredentials()
    }

    private func decodeCredentials(data: Data) throws -> ClaudeCredentials {
        let decoded = try JSONDecoder().decode(ClaudeCredentialsFile.self, from: data)
        guard let token = decoded.claudeAiOauth?.accessToken, !token.isEmpty else {
            throw UsageError.invalidCredentials("Claude credentials do not contain claudeAiOauth.accessToken.")
        }

        let expiresAt: Date? = decoded.claudeAiOauth?.expiresAt.map {
            Date(timeIntervalSince1970: Double($0) / 1000)
        }

        return ClaudeCredentials(
            accessToken: token,
            subscriptionType: decoded.claudeAiOauth?.subscriptionType,
            rateLimitTier: decoded.claudeAiOauth?.rateLimitTier,
            expiresAt: expiresAt
        )
    }

    private func readKeychainCredentials() throws -> Data? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", keychainService, "-w"]

        let output = Pipe()
        let errors = Pipe()
        process.standardOutput = output
        process.standardError = errors

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else {
            return nil
        }

        let data = output.fileHandleForReading.readDataToEndOfFile()
        return data.isEmpty ? nil : data
    }
}

private struct ClaudeCredentialsFile: Decodable {
    let claudeAiOauth: OAuth?

    struct OAuth: Decodable {
        let accessToken: String?
        let subscriptionType: String?
        let rateLimitTier: String?
        let expiresAt: Int64?
    }
}
