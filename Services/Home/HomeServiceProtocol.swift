import Foundation

/// Contract for loading home screen data.
///
/// `NetworkClient` handles bearer token injection automatically (Constitution Principle VII).
@MainActor
protocol HomeServiceProtocol: AnyObject {

    /// Fetches all data needed to render the home screen.
    /// - Returns: `HomeScreenData` containing the current workout plan summary and today's exercises.
    /// - Throws: `WorkoutPlanError.serverError` on non-200; `.networkError` on transport failure.
    func fetchHomeData() async throws -> HomeScreenData
}
