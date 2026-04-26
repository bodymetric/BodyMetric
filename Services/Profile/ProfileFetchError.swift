import Foundation

/// Typed errors produced by `UserProfileService`.
///
/// Every case maps to one or more HTTP outcomes or transport failures.
/// Callers (HomeViewModel) switch on this enum to drive navigation and
/// user-facing messages.
///
/// Constitution Principle III: error context surfaced without PII.
enum ProfileFetchError: LocalizedError {

    /// The API returned 404 — no user record exists for the given email.
    case userNotFound

    /// The API returned 401 — caller must re-authenticate.
    case unauthorized

    /// The API returned a 5xx status code.
    case serverError(Int)

    /// A transport-level failure (no connectivity, timeout, DNS, etc.).
    case networkError(Error)

    /// The response body could not be decoded into `UserProfile`.
    case decodingError

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "Your profile was not found. Please create an account."
        case .unauthorized:
            return "Authentication required. Please sign in again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .networkError:
            return "No connection. Please check your network and try again."
        case .decodingError:
            return "Unexpected response from server. Please try again."
        }
    }
}
