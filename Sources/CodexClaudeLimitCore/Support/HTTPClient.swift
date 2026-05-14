import Foundation

public struct HTTPResponse: Sendable {
    public let data: Data
    public let statusCode: Int
}

public protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> HTTPResponse
}

public struct URLSessionHTTPClient: HTTPClient {
    public init() {}

    public func data(for request: URLRequest) async throws -> HTTPResponse {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UsageError.requestFailed("Response was not HTTP.")
        }

        return HTTPResponse(data: data, statusCode: httpResponse.statusCode)
    }
}

public extension HTTPResponse {
    var bodyPreview: String {
        String(data: data.prefix(1_000), encoding: .utf8) ?? "<non-utf8 response>"
    }

    func requireSuccess(endpointName: String) throws {
        guard (200...299).contains(statusCode) else {
            throw UsageError.requestFailed("\(endpointName) returned HTTP \(statusCode): \(bodyPreview)")
        }
    }
}
