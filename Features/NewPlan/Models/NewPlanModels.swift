import Foundation

// MARK: - Day of week

/// Ordered training days. Raw value is the ISO weekday number (Mon = 1).
///
/// `displayOrder` guarantees Monday-first rendering in all views.
enum DayOfWeek: Int, CaseIterable, Codable, Identifiable, Hashable {
    case monday    = 1
    case tuesday   = 2
    case wednesday = 3
    case thursday  = 4
    case friday    = 5
    case saturday  = 6
    case sunday    = 7

    var id: Int { rawValue }

    var shortLabel: String {
        switch self {
        case .monday:    return "Mon"
        case .tuesday:   return "Tue"
        case .wednesday: return "Wed"
        case .thursday:  return "Thu"
        case .friday:    return "Fri"
        case .saturday:  return "Sat"
        case .sunday:    return "Sun"
        }
    }

    var fullLabel: String {
        switch self {
        case .monday:    return "Monday"
        case .tuesday:   return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday:  return "Thursday"
        case .friday:    return "Friday"
        case .saturday:  return "Saturday"
        case .sunday:    return "Sunday"
        }
    }

    /// Mon → Sun rendering order for all list / chip views.
    static let displayOrder: [DayOfWeek] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday,
    ]
}

// MARK: - Exercise catalog

/// A read-only exercise definition used in the wizard's block picker.
///
/// The catalog is a compile-time constant; no network fetch required.
struct Exercise: Identifiable {
    let id: String
    let name: String
    let primaryMuscle: String

    /// 18-exercise static catalog across 8 muscle groups.
    static let catalog: [Exercise] = [
        // Chest
        Exercise(id: "bench",        name: "Barbell Bench Press",       primaryMuscle: "Chest"),
        Exercise(id: "incline",      name: "Incline Dumbbell Press",    primaryMuscle: "Chest"),
        Exercise(id: "fly",          name: "Cable Chest Fly",           primaryMuscle: "Chest"),
        // Legs
        Exercise(id: "squat",        name: "Back Squat",                primaryMuscle: "Legs"),
        Exercise(id: "leg-press",    name: "Leg Press",                 primaryMuscle: "Legs"),
        Exercise(id: "lunge",        name: "Walking Lunge",             primaryMuscle: "Legs"),
        // Hamstrings
        Exercise(id: "rdl",          name: "Romanian Deadlift",         primaryMuscle: "Hamstrings"),
        // Back
        Exercise(id: "pullup",       name: "Pull-up",                   primaryMuscle: "Back"),
        Exercise(id: "row",          name: "Barbell Row",               primaryMuscle: "Back"),
        Exercise(id: "lat-pull",     name: "Lat Pulldown",              primaryMuscle: "Back"),
        // Shoulders
        Exercise(id: "ohp",          name: "Overhead Press",            primaryMuscle: "Shoulders"),
        Exercise(id: "lateral",      name: "Dumbbell Lateral Raise",    primaryMuscle: "Shoulders"),
        // Biceps
        Exercise(id: "curl",         name: "Barbell Curl",              primaryMuscle: "Biceps"),
        Exercise(id: "hammer",       name: "Hammer Curl",               primaryMuscle: "Biceps"),
        // Triceps
        Exercise(id: "tri-ext",      name: "Triceps Cable Extension",   primaryMuscle: "Triceps"),
        Exercise(id: "skull",        name: "Skullcrusher",              primaryMuscle: "Triceps"),
        // Core
        Exercise(id: "plank",        name: "Plank",                     primaryMuscle: "Core"),
        Exercise(id: "cable-crunch", name: "Cable Crunch",              primaryMuscle: "Core"),
    ]
}

// MARK: - Exercise block

/// A single exercise slot within a day plan.
///
/// `isValid` gates the Continue button in `ConfigureDayStepView`.
struct ExerciseBlock: Identifiable, Codable {
    var id: UUID           = UUID()
    var exerciseId: String = ""
    var targetReps: Int    = 8
    var targetWeight: Double = 60.0
    var restSeconds: Int   = 90

    var isValid: Bool {
        !exerciseId.isEmpty && targetReps >= 1 && targetWeight >= 0 && restSeconds >= 0
    }
}

// MARK: - Day plan

/// Configuration for a single training day: one named session + ordered exercise blocks.
struct DayPlan: Codable {
    var day: DayOfWeek
    var sessionName: String    = ""
    var blocks: [ExerciseBlock] = [ExerciseBlock()]

    var isValid: Bool {
        !sessionName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !blocks.isEmpty &&
        blocks.allSatisfy(\.isValid)
    }
}

// MARK: - Workout plan (root persisted model)

/// The complete weekly plan produced by the wizard.
///
/// Persisted to UserDefaults via `WorkoutPlanStore`. `Codable` conformance
/// allows round-trip JSON serialisation without any schema migration for v1.
struct WorkoutPlan: Identifiable, Codable {
    var id: UUID          = UUID()
    var createdAt: Date   = Date()
    var dayPlans: [DayPlan]

    var isValid: Bool {
        !dayPlans.isEmpty && dayPlans.allSatisfy(\.isValid)
    }
}

// MARK: - API mapping (T009)

extension DayOfWeek {
    /// Converts this day to the POST request format for `WorkoutPlanService.saveDays(_:)`.
    ///
    /// `plannedWeekNumber` is a String per the API contract (differs from GET response Int).
    var toRequest: WorkoutPlanDayRequest {
        WorkoutPlanDayRequest(
            plannedWeekNumber: String(rawValue),
            plannedDayOfWeek: fullLabel.lowercased()
        )
    }
}
