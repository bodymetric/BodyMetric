import Foundation

/// Errors produced by `NetworkClient`.
///
/// Distinct from `ProfileFetchError` (domain-specific) and `AuthError` (auth flow).
/// These represent transport-level and token-related failures.
enum NetworkError: LocalizedError {

    /// No access token is in memory; the user is not authenticated.
    case noToken

    /// The server returned an HTTP error status (non-401, non-2xx).
    case httpError(Int)

    /// Token refresh failed; the user has been signed out.
    case refreshFailed

    /// Received a 401 and token refresh also failed or was rejected.
    case unauthorized

    /// Response body could not be decoded.
    case decodingError

    var errorDescription: String? {
        switch self {
        case .noToken:         return "No active session. Please sign in."
        case .httpError(let c): return "Server error (\(c)). Please try again."
        case .refreshFailed:   return "Session expired. Please sign in again."
        case .unauthorized:    return "Authorization failed. Please sign in again."
        case .decodingError:   return "Could not read server response."
        }
    }
}
