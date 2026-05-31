import Foundation

/// Contract for loading the exercise catalogue.
///
/// `NetworkClient` handles bearer token injection automatically (Constitution Principle VII).
@MainActor
protocol ExerciseServiceProtocol: AnyObject {

    /// Fetches the complete exercise catalogue grouped by muscle.
    /// - Returns: Array of `ExerciseCatalogGroup`, each containing exercises for one muscle group.
    /// - Throws: `WorkoutPlanError.serverError` on non-200, `.decodingError` on malformed response,
    ///   `.networkError` on transport failure.
    func fetchExerciseCatalog() async throws -> [ExerciseCatalogGroup]
}
