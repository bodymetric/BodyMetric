import Foundation

/// Contract for persisting step-2 wizard data: training day plans and exercise blocks.
///
/// `NetworkClient` handles bearer token injection automatically (Constitution Principle VII).
@MainActor
protocol WorkoutDayPlanServiceProtocol: AnyObject {

    /// Creates a named training day within the user's workout plan.
    /// - Parameters:
    ///   - workoutPlanId: The `planId` from the step-1 `WorkoutPlanDayResponse` for this day.
    ///   - request: Day name, order index, and active flag.
    /// - Returns: The server-assigned `WorkoutDayPlanResponse` containing `workoutDayPlanId`.
    /// - Throws: `WorkoutPlanError.serverError` on non-201; `WorkoutPlanError.networkError` on transport failure.
    func saveDayPlan(workoutPlanId: Int, request: WorkoutDayPlanRequest) async throws -> WorkoutDayPlanResponse

    /// Adds a single exercise block to a training day.
    /// - Parameters:
    ///   - workoutDayPlanId: The `workoutDayPlanId` from the `saveDayPlan` response.
    ///   - request: Exercise details provided by the user.
    /// - Throws: `WorkoutPlanError.serverError` on non-201; `WorkoutPlanError.networkError` on transport failure.
    func saveExerciseBlock(workoutDayPlanId: Int, request: ExerciseBlockPlanRequest) async throws
}
