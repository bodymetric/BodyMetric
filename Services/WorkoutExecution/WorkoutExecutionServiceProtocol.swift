import Foundation

/// Contract for starting a workout execution session.
///
/// `NetworkClient` handles Bearer token injection automatically (Constitution Principle VII).
/// Throws `WorkoutPlanError.serverError` for non-200/201 responses,
/// `.decodingError` for malformed responses, `.networkError` for transport failures.
@MainActor
protocol WorkoutExecutionServiceProtocol: AnyObject {

    /// Starts a new workout execution session for the authenticated user.
    ///
    /// - Parameter request: Session parameters — planId, actualWeekNumber, and uppercase feeling.
    /// - Returns: Session response containing the generated exercise blocks.
    func startSession(_ request: StartSessionRequest) async throws -> StartSessionResponse
}
