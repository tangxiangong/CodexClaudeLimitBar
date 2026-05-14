public protocol UsageProvider: Sendable {
    var kind: UsageProviderKind { get }
    func fetchUsage() async throws -> ProviderUsage
}
