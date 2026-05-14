import Foundation

public actor CodexUsageProvider: UsageProvider {
    public nonisolated let kind: UsageProviderKind = .codex

    private let authStore: CodexAuthStore
    private let httpClient: HTTPClient
    private let decoder: JSONDecoder

    public init(
        authStore: CodexAuthStore = CodexAuthStore(),
        httpClient: HTTPClient = URLSessionHTTPClient()
    ) {
        self.authStore = authStore
        self.httpClient = httpClient
        self.decoder = JSONDecoder()
    }

    public func fetchUsage() async throws -> ProviderUsage {
        let tokens = try await authStore.loadTokens()

        do {
            return try await fetchUsage(accessToken: tokens.accessToken, accountID: tokens.accountID)
        } catch let error as UsageError {
            guard case .requestFailed(let message) = error, message.contains("HTTP 401") else {
                throw error
            }

            let refreshed = try await refreshTokens(refreshToken: tokens.refreshToken)
            try await authStore.updateTokens(
                idToken: refreshed.idToken,
                accessToken: refreshed.accessToken,
                refreshToken: refreshed.refreshToken
            )

            let updatedTokens = try await authStore.loadTokens()
            return try await fetchUsage(accessToken: updatedTokens.accessToken, accountID: updatedTokens.accountID)
        }
    }

    private func fetchUsage(accessToken: String, accountID: String?) async throws -> ProviderUsage {
        let endpoints = [
            "https://chatgpt.com/backend-api/wham/usage",
            "https://chatgpt.com/backend-api/codex/usage"
        ]

        var lastError: Error?
        for endpoint in endpoints {
            do {
                return try await fetchUsage(endpoint: endpoint, accessToken: accessToken, accountID: accountID)
            } catch {
                lastError = error
            }
        }

        throw lastError ?? UsageError.requestFailed("Codex usage request failed.")
    }

    private func fetchUsage(endpoint: String, accessToken: String, accountID: String?) async throws -> ProviderUsage {
        guard let url = URL(string: endpoint) else {
            throw UsageError.requestFailed("Invalid Codex usage endpoint.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("codex-cli", forHTTPHeaderField: "User-Agent")
        if let accountID, !accountID.isEmpty {
            request.setValue(accountID, forHTTPHeaderField: "ChatGPT-Account-Id")
        }

        let response = try await httpClient.data(for: request)
        try response.requireSuccess(endpointName: "Codex usage")

        do {
            let payload = try decoder.decode(CodexUsagePayload.self, from: response.data)
            return try payload.providerUsage(updatedAt: Date())
        } catch {
            throw UsageError.decodeFailed("Failed to decode Codex usage response: \(error.localizedDescription)")
        }
    }

    private func refreshTokens(refreshToken: String) async throws -> CodexRefreshResponse {
        guard let url = URL(string: "https://auth.openai.com/oauth/token") else {
            throw UsageError.requestFailed("Invalid Codex refresh endpoint.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("codex-cli", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONEncoder().encode(CodexRefreshRequest(refreshToken: refreshToken))

        let response = try await httpClient.data(for: request)
        try response.requireSuccess(endpointName: "Codex token refresh")

        do {
            return try decoder.decode(CodexRefreshResponse.self, from: response.data)
        } catch {
            throw UsageError.decodeFailed("Failed to decode Codex token refresh response.")
        }
    }
}

private struct CodexRefreshRequest: Encodable {
    let clientID = "app_EMoamEEZ73f0CkXaXp7hrann"
    let grantType = "refresh_token"
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case grantType = "grant_type"
        case refreshToken = "refresh_token"
    }
}

private struct CodexRefreshResponse: Decodable {
    let idToken: String?
    let accessToken: String?
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}
