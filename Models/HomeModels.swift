import Foundation

// MARK: - GET /api/home response DTOs

/// Complete home screen data from `GET /api/home`.
struct HomeScreenData: Decodable, Equatable {
    let currentWorkoutDayPlan: WorkoutDayPlanSummary?
    let exercisesForToday: [TodayExercise]?
}

/// Summary of the current training day plan shown on the home screen.
struct WorkoutDayPlanSummary: Decodable, Equatable {
    let id: Int
    let name: String
    let dayOfWeek: String             // e.g., "SUNDAY" — displayed on the workout card
    let numberOfExercisesTotal: Int
    let numberSetsTotal: Int
    let timeEstimateToFinish: Int     // minutes (corrected from timeEstimateToFinishes)
    let actualWeekNumber: Int?        // server-tracked training week; nil until server ships the field
}

/// One set entry within a `TodayExercise`, decoded from `GET /api/home`.
struct HomeExerciseSet: Decodable, Equatable {
    let orderIndex: Int
    let targetReps: Int
    let targetWeight: Double
}

/// A single exercise entry in today's list.
struct TodayExercise: Decodable, Identifiable, Equatable {
    let id: Int
    let name: String
    let orderIndex: Int               // used to sort exercises in display order
    let sets: [HomeExerciseSet]       // server sends "sets" array (may be empty)
    var numberOfSets: Int { sets.count }
}

// MARK: - Load state

/// Loading lifecycle for the home screen data.
enum HomeLoadState: Equatable {
    case idle
    case loading
    case loaded(HomeScreenData)
    case failed(String)
}
