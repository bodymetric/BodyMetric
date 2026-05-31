import Foundation

// MARK: - GET response DTO

/// One day entry returned by `GET /api/workout-plans` and created by `POST /api/workout-plans`.
///
/// `plannedDayOfWeek` ("MONDAY"–"SUNDAY") drives checkbox pre-fill in the wizard.
/// `planId` is the primary key used for step-2 day-plan POSTs.
/// `actualWeekNumber` is the server-tracked training cycle counter (1, 2, 3 …); optional
/// so the app decodes cleanly before and after the server ships this field.
/// `_links` is present in the JSON but silently ignored by Decodable.
struct WorkoutPlanDayResponse: Codable, Identifiable {
    let planId: Int
    let plannedDayOfWeek: String  // "MONDAY"–"SUNDAY" — used for checkbox pre-fill
    let executionCount: Int
    let dayNames: [String]
    let totalExercises: Int
    let totalSets: Int
    let estimatedDurationMinutes: Int
    let actualWeekNumber: Int?    // server-managed training week counter; nil until server ships

    var id: Int { planId }
}

// MARK: - POST request DTO

/// One day entry in the POST body for `POST /api/workout-plans`.
///
/// Day identity is communicated via `plannedDayOfWeek` alone; the server
/// manages `actualWeekNumber` automatically (feature 014).
struct WorkoutPlanDayRequest: Codable, Equatable {
    let plannedDayOfWeek: String
}

// MARK: - GET /api/workout-plans/current response DTOs

/// Full current plan returned by `GET /api/workout-plans/current`.
struct CurrentWorkoutPlan: Decodable {
    let id: Int
    let days: [CurrentWorkoutPlanDay]
}

/// One training day within the current active plan.
struct CurrentWorkoutPlanDay: Decodable {
    let id: Int
    let plannedDayOfWeek: String
    let name: String
    let orderIndex: Int
    let exerciseBlocks: [CurrentExerciseBlock]
}

/// One exercise block within a training day of the current plan.
struct CurrentExerciseBlock: Decodable {
    let exerciseId: Int
    let orderIndex: Int
    let restSeconds: Int
    let targetSets: [CurrentTargetSet]
}

/// One target set within an exercise block of the current plan.
struct CurrentTargetSet: Decodable {
    let orderIndex: Int
    let targetReps: Int
    let targetWeight: Double
}

// MARK: - PUT /api/workout-plans/{id} request DTOs

/// Full update payload for `PUT /api/workout-plans/{id}`.
struct UpdateWorkoutPlanRequest: Codable {
    let days: [UpdateWorkoutPlanDayRequest]
}

/// One training day in the update payload.
struct UpdateWorkoutPlanDayRequest: Codable {
    let plannedDayOfWeek: String
    let name: String
    let orderIndex: Int
    let isActive: Bool
    let exerciseBlocks: [ExerciseBlockRequest]
}
