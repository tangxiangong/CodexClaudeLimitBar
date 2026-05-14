import Foundation

public struct CodexTokenBundle: Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let accountID: String?
}

public actor CodexAuthStore {
    public static let defaultPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".codex/auth.json")

    private let authURL: URL

    public init(authURL: URL = CodexAuthStore.defaultPath) {
        self.authURL = authURL
    }

    public func loadTokens() throws -> CodexTokenBundle {
        guard FileManager.default.fileExists(atPath: authURL.path) else {
            throw UsageError.missingCredentials("Codex auth file not found at \(authURL.path). Run `codex login` first.")
        }

        let data = try Data(contentsOf: authURL)
        let decoded = try JSONDecoder().decode(CodexAuthFile.self, from: data)
        guard let accessToken = decoded.tokens?.accessToken, !accessToken.isEmpty else {
            throw UsageError.invalidCredentials("Codex auth file does not contain tokens.access_token.")
        }

        guard let refreshToken = decoded.tokens?.refreshToken, !refreshToken.isEmpty else {
            throw UsageError.invalidCredentials("Codex auth file does not contain tokens.refresh_token.")
        }

        return CodexTokenBundle(
            accessToken: accessToken,
            refreshToken: refreshToken,
            accountID: decoded.tokens?.accountID
        )
    }

    public func updateTokens(idToken: String?, accessToken: String?, refreshToken: String?) throws {
        let data = try Data(contentsOf: authURL)
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw UsageError.invalidCredentials("Codex auth file is not a JSON object.")
        }

        var tokens = root["tokens"] as? [String: Any] ?? [:]
        if let idToken {
            tokens["id_token"] = idToken
        }
        if let accessToken {
            tokens["access_token"] = accessToken
        }
        if let refreshToken {
            tokens["refresh_token"] = refreshToken
        }

        root["tokens"] = tokens
        root["last_refresh"] = LimitDateFormatting.iso8601String(from: Date())

        let encoded = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
        try encoded.write(to: authURL, options: [.atomic])
    }
}

private struct CodexAuthFile: Decodable {
    let tokens: Tokens?

    struct Tokens: Decodable {
        let accessToken: String?
        let refreshToken: String?
        let accountID: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case accountID = "account_id"
        }
    }
}
