import Foundation

public enum UsageError: LocalizedError, Sendable {
    case missingCredentials(String)
    case invalidCredentials(String)
    case requestFailed(String)
    case decodeFailed(String)
    case unsupportedResponse(String)

    public var errorDescription: String? {
        switch self {
        case .missingCredentials(let message),
             .invalidCredentials(let message),
             .requestFailed(let message),
             .decodeFailed(let message),
             .unsupportedResponse(let message):
            message
        }
    }
}
