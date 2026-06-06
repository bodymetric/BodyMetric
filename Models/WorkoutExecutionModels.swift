import Foundation

// MARK: - POST /api/work-executions/start request DTO

/// Request body for starting a new workout execution session.
///
/// `feeling` MUST be uppercase before transmission (enforced by `ReadyToLiftViewModel`).
struct StartSessionRequest: Codable {
    let planId: Int
    let actualWeekNumber: Int
    let feeling: String
}

// MARK: - POST /api/work-executions/start response DTOs

/// Top-level response from a successful session-start call.
struct StartWorkoutResponse: Decodable, Hashable {
    let workExecutionId: Int
    let workoutPlanId: Int
    let workoutPlanName: String
    let totalNumberOfSets: Int
    let exerciseBlockPlans: [ExerciseBlockPlan]
}

/// One exercise block in the session response.
struct ExerciseBlockPlan: Decodable, Hashable {
    let exerciseBlockPlanId: Int
    let exerciseId: Int
    let exerciseName: String
    let orderIndex: Int
    let restSeconds: Int
    let isOptional: Bool
    let numberOfSets: Int
    let targetSets: [TargetSet]
}

/// One target set within an exercise block.
struct TargetSet: Decodable, Hashable {
    let targetSetId: Int
    let orderIndex: Int
    let targetReps: Int
    let targetWeight: Double
}

// MARK: - StartWorkoutResponse → WorkoutSession mapping

extension StartWorkoutResponse {

    /// Maps the API session response to the in-memory `WorkoutSession` used by `ActiveSessionViewModel`.
    func toWorkoutSession() -> WorkoutSession {
        WorkoutSession(
            id: workExecutionId,
            name: workoutPlanName,
            exercises: exerciseBlockPlans
                .sorted { $0.orderIndex < $1.orderIndex }
                .map { block in
                    WorkoutExercise(
                        exerciseBlockPlanId: block.exerciseBlockPlanId,
                        id: block.exerciseId,
                        name: block.exerciseName,
                        restSeconds: block.restSeconds,
                        sets: block.targetSets
                            .sorted { $0.orderIndex < $1.orderIndex }
                            .map { WorkoutSet(targetReps: $0.targetReps, targetWeight: $0.targetWeight) }
                    )
                }
        )
    }
}
