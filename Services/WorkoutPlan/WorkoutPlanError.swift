import Foundation

/// Errors produced by `WorkoutPlanService`.
///
/// Constitution Principle III: `errorDescription` must never contain tokens,
/// credentials, or raw server messages that could include PII.
enum WorkoutPlanError: LocalizedError, Equatable {

    /// 404 response — no prior data for this user; treated as an empty state, not an error.
    case notFound

    /// Non-2xx / non-201 HTTP status returned by the server.
    case serverError(Int)

    /// Response body could not be decoded into the expected shape.
    case decodingError

    /// Transport-level failure (e.g. no network, timeout).
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "No existing plan found."
        case .serverError(let code):
            return "Server error (\(code)). Please try again."
        case .decodingError:
            return "Could not read the server response."
        case .networkError:
            return "Network unavailable. Check your connection and try again."
        }
    }

    static func == (lhs: WorkoutPlanError, rhs: WorkoutPlanError) -> Bool {
        switch (lhs, rhs) {
        case (.notFound, .notFound):         return true
        case (.decodingError, .decodingError): return true
        case (.serverError(let a), .serverError(let b)): return a == b
        case (.networkError, .networkError): return true
        default: return false
        }
    }
}
