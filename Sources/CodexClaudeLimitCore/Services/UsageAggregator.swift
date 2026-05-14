import Foundation

public struct UsageAggregator: Sendable {
    private let providers: [any UsageProvider]

    public init(providers: [any UsageProvider] = [
        CodexUsageProvider(),
        ClaudeUsageProvider()
    ]) {
        self.providers = providers
    }

    public func fetchAll() async -> [ProviderStatus] {
        await withTaskGroup(of: ProviderStatus.self) { group in
            for provider in providers {
                group.addTask {
                    do {
                        let usage = try await provider.fetchUsage()
                        return ProviderStatus(provider: provider.kind, usage: usage)
                    } catch {
                        return ProviderStatus(
                            provider: provider.kind,
                            errorMessage: error.localizedDescription
                        )
                    }
                }
            }

            var statuses: [ProviderStatus] = []
            for await status in group {
                statuses.append(status)
            }

            return statuses.sorted { $0.provider.rawValue < $1.provider.rawValue }
        }
    }
}
