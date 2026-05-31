import Foundation

/// Contract for persisting step-2 wizard data: unified day plan with embedded exercise blocks.
///
/// Feature 013: replaces the two-step save (separate day + exercise-block POSTs)
/// with a single `saveDayPlan` call whose request body includes all exercise blocks.
///
/// `NetworkClient` handles bearer token injection automatically (Constitution Principle VII).
@MainActor
protocol WorkoutDayPlanServiceProtocol: AnyObject {

    /// Saves a training day with all its exercise blocks in one request.
    ///
    /// Accepts both 200 and 201 as success responses.
    /// The response body is not consumed by the client in v1.
    /// - Parameters:
    ///   - workoutPlanId: The `planId` from the step-1 `WorkoutPlanDayResponse` for this day.
    ///   - request: Day name, order index, active flag, and embedded exercise blocks.
    /// - Throws: `WorkoutPlanError.serverError` on non-200/201;
    ///   `WorkoutPlanError.networkError` on transport failure.
    func saveDayPlan(workoutPlanId: Int, request: WorkoutDayPlanRequest) async throws
}
