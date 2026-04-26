import Foundation

// MARK: - GET response DTO

/// One day entry returned by `GET /api/workout-plans`.
///
/// Only `plannedWeekNumber` is used to pre-fill the day selection checkboxes.
/// All other fields are supplemental context and are not submitted in the POST.
struct WorkoutPlanDayResponse: Codable, Identifiable {
    let planId: Int
    let plannedWeekNumber: Int
    let plannedDayOfWeek: String
    let executionCount: Int
    let dayNames: [String]
    let totalExercises: Int
    let totalSets: Int
    let estimatedDurationMinutes: Int

    var id: Int { planId }
}

// MARK: - POST request DTO

/// One day entry in the POST body for `POST /api/workout-plans`.
///
/// Note: `plannedWeekNumber` is serialised as a **String** (e.g. `"1"`, `"7"`),
/// differing from the GET response where it is an Int.
struct WorkoutPlanDayRequest: Codable, Equatable {
    let plannedWeekNumber: String
    let plannedDayOfWeek: String
}
