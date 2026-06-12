import Foundation

// MARK: - POST /api/exercise-block-executions/{id}/performed-sets request DTO

/// Request body for logging a performed set on a specific exercise block execution.
struct LogPerformedSetRequest: Codable {
    let weight: Double
    let reps: Int
}
