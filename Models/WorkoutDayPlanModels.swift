import Foundation

// MARK: - POST /api/workout-plans/{workoutPlanId}/days (unified request — feature 013)

/// One target set within an exercise block.
struct TargetSetRequest: Codable {
    let orderIndex: Int
    let targetReps: Int
    let targetWeight: Double
}

/// One exercise block within a day plan.
///
/// Maps `ExerciseBlock.sets` to a `targetSets` array where each entry is one `SetConfig`.
/// `isOptional` defaults to `false` (v1; UI toggle is future scope).
struct ExerciseBlockRequest: Codable {
    let exerciseId: Int
    let orderIndex: Int
    let restSeconds: Int
    let isOptional: Bool
    let targetSets: [TargetSetRequest]

    init(block: ExerciseBlock, orderIndex: Int) {
        self.exerciseId  = Int(block.exerciseId) ?? 0
        self.orderIndex  = orderIndex
        self.restSeconds = block.restSeconds
        self.isOptional  = false
        self.targetSets  = block.sets.enumerated().map { idx, set in
            TargetSetRequest(
                orderIndex: idx + 1,
                targetReps: set.targetReps,
                targetWeight: set.targetWeight
            )
        }
    }
}

/// Unified request body for `POST /api/workout-plans/{workoutPlanId}/days`.
///
/// Replaces the previous two-step save (separate day + exercise-block POSTs from feature 011).
struct WorkoutDayPlanRequest: Codable {
    let name: String
    let orderIndex: Int
    let isActive: Bool
    let exerciseBlocks: [ExerciseBlockRequest]
}

// MARK: - POST response (kept for forward compatibility; not consumed by client in v1)

struct WorkoutDayPlanResponse: Decodable, Identifiable {
    let workoutDayPlanId: Int
    var id: Int { workoutDayPlanId }
}

// MARK: - DayOfWeek → orderIndex

extension DayOfWeek {
    /// 0-based weekday index used as `orderIndex` in `WorkoutDayPlanRequest`.
    /// Mon=0, Tue=1, … Sun=6  (rawValue is 1-based: Mon=1, Sun=7)
    var orderIndex: Int { rawValue - 1 }
}
