import Foundation

/// Contract for fetching and saving the user's weekly workout-plan day selections.
///
/// `NetworkClient` handles bearer token injection automatically (Constitution Principle VII).
/// Both methods run on the main actor to be safely callable from SwiftUI `@Observable` ViewModels.
@MainActor
protocol WorkoutPlanServiceProtocol: AnyObject {

    /// Fetches the authenticated user's previously saved training day selections.
    /// - Returns: Array of `WorkoutPlanDayResponse` (may be empty for first-time users).
    /// - Throws: `WorkoutPlanError.notFound` if the user has no saved plan (404),
    ///   `WorkoutPlanError.serverError` for other HTTP errors,
    ///   `WorkoutPlanError.decodingError` for malformed responses,
    ///   `WorkoutPlanError.networkError` for transport failures.
    func fetchDays() async throws -> [WorkoutPlanDayResponse]

    /// Saves (replaces) the user's selected training days on the server.
    ///
    /// The POST is a full replace-all — the server deletes prior records and inserts the
    /// submitted array atomically. The client sends every currently selected day.
    /// - Parameter days: The complete set of days to save.
    /// - Throws: `WorkoutPlanError.serverError` if the server returns non-201,
    ///   `WorkoutPlanError.networkError` for transport failures.
    func saveDays(_ days: [WorkoutPlanDayRequest]) async throws
}
