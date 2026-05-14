import Foundation

public actor ClaudeUsageProvider: UsageProvider {
    public nonisolated let kind: UsageProviderKind = .claude

    private let credentialStore: ClaudeCredentialStore
    private let httpClient: HTTPClient
    private let decoder: JSONDecoder

    public init(
        credentialStore: ClaudeCredentialStore = ClaudeCredentialStore(),
        httpClient: HTTPClient = URLSessionHTTPClient()
    ) {
        self.credentialStore = credentialStore
        self.httpClient = httpClient
        self.decoder = JSONDecoder()
    }

    public func fetchUsage() async throws -> ProviderUsage {
        let credentials = try await credentialStore.loadCredentials()

        guard let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else {
            throw UsageError.requestFailed("Invalid Claude usage endpoint.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        let response = try await httpClient.data(for: request)
        try response.requireSuccess(endpointName: "Claude usage")

        do {
            let payload = try decoder.decode(ClaudeUsagePayload.self, from: response.data)
            return try payload.providerUsage(
                planName: credentials.subscriptionType ?? credentials.rateLimitTier,
                updatedAt: Date()
            )
        } catch {
            throw UsageError.decodeFailed("Failed to decode Claude usage response: \(error.localizedDescription)")
        }
    }
}
