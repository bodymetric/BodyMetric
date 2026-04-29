import Foundation

// MARK: - POST request for /api/workout-plans/{workoutPlanId}/days

/// Request body for creating a named training day within a workout plan.
struct WorkoutDayPlanRequest: Codable {
    let name: String
    let orderIndex: Int
    let isActive: Bool
}

// MARK: - POST response from /api/workout-plans/{workoutPlanId}/days

/// Response from creating a training day.
/// `workoutDayPlanId` is required for the subsequent exercise-block POSTs.
struct WorkoutDayPlanResponse: Decodable, Identifiable {
    let workoutDayPlanId: Int
    var id: Int { workoutDayPlanId }
}

// MARK: - POST request for /api/workout-day-plans/{workoutDayPlanId}/exercise-blocks

/// Request body for saving a single exercise block within a training day.
///
/// ⚠️ Field names are assumed based on existing ExerciseBlock model conventions.
///    Verify against live API and update CodingKeys if needed.
struct ExerciseBlockPlanRequest: Codable {
    let exerciseId: String
    let targetReps: Int
    let targetWeightKg: Double
    let restSeconds: Int

    init(block: ExerciseBlock) {
        self.exerciseId = block.exerciseId
        self.targetReps = block.targetReps
        self.targetWeightKg = block.targetWeight
        self.restSeconds = block.restSeconds
    }

    // ⚠️ Update these keys once confirmed against live API
    private enum CodingKeys: String, CodingKey {
        case exerciseId     = "exerciseId"
        case targetReps     = "targetReps"
        case targetWeightKg = "targetWeightKg"
        case restSeconds    = "restSeconds"
    }
}

// MARK: - DayOfWeek → orderIndex

extension DayOfWeek {
    /// 0-based weekday index used as `orderIndex` in `WorkoutDayPlanRequest`.
    /// Mon=0, Tue=1, … Sun=6  (rawValue is 1-based: Mon=1, Sun=7)
    var orderIndex: Int { rawValue - 1 }
}
