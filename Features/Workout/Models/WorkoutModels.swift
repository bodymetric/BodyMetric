import Foundation

// MARK: - Workout session

struct WorkoutSession {
    let id: String
    let name: String
    let program: String
    let dayIndex: Int
    let estimatedMinutes: Int
    let exercises: [WorkoutExercise]

    var totalSets: Int { exercises.reduce(0) { $0 + $1.sets.count } }
}

struct WorkoutExercise {
    let id: String
    let name: String
    let muscle: String
    let restSeconds: Int
    let sets: [WorkoutSet]
    let pr: PRRecord?
}

struct WorkoutSet {
    let targetReps: Int
    let prevWeight: Double
    let prevReps: Int
}

struct PRRecord {
    let weight: Double
    let reps: Int
}

// MARK: - Session progress

struct SetProgress {
    var done: Bool
    var weight: Double
    var reps: Int
    let targetReps: Int
    let prevWeight: Double
    let prevReps: Int
}

struct ExerciseProgress {
    let id: String
    var sets: [SetProgress]

    var allDone: Bool { sets.allSatisfy(\.done) }
    var doneCount: Int { sets.filter(\.done).count }
    var totalVolume: Double {
        sets.filter(\.done).reduce(0) { $0 + $1.weight * Double($1.reps) }
    }
}

// MARK: - Completion

struct WorkoutCompletionStats {
    let totalVolume: Double
    let totalSets: Int
    let elapsedSeconds: Int
}

// MARK: - Streak

struct WorkoutStreak {
    let days: Int
    let weekDone: [Bool]
    static let mockStreak = WorkoutStreak(
        days: 12,
        weekDone: [true, true, false, true, true, false, false]
    )// Mon–Sun, 7 elements
}

// MARK: - Log target

struct LogTarget: Equatable {
    let exIdx: Int
    let setIdx: Int
}

// MARK: - Mock data

extension WorkoutSession {
    static let mockToday = WorkoutSession(
        id: "w-push-1",
        name: "Push Day · Chest & Triceps",
        program: "PPL · Week 5",
        dayIndex: 28,
        estimatedMinutes: 52,
        exercises: [
            WorkoutExercise(
                id: "e1", name: "Barbell Bench Press", muscle: "Chest",
                restSeconds: 120,
                sets: [
                    WorkoutSet(targetReps: 8, prevWeight: 80, prevReps: 8),
                    WorkoutSet(targetReps: 8, prevWeight: 80, prevReps: 8),
                    WorkoutSet(targetReps: 6, prevWeight: 80, prevReps: 7),
                    WorkoutSet(targetReps: 6, prevWeight: 80, prevReps: 6),
                ],
                pr: PRRecord(weight: 82.5, reps: 6)
            ),
            WorkoutExercise(
                id: "e2", name: "Incline Dumbbell Press", muscle: "Upper Chest",
                restSeconds: 90,
                sets: [
                    WorkoutSet(targetReps: 10, prevWeight: 28, prevReps: 10),
                    WorkoutSet(targetReps: 10, prevWeight: 28, prevReps: 10),
                    WorkoutSet(targetReps: 8,  prevWeight: 28, prevReps: 9),
                ],
                pr: nil
            ),
            WorkoutExercise(
                id: "e3", name: "Cable Chest Fly", muscle: "Chest",
                restSeconds: 75,
                sets: [
                    WorkoutSet(targetReps: 12, prevWeight: 16, prevReps: 12),
                    WorkoutSet(targetReps: 12, prevWeight: 16, prevReps: 12),
                    WorkoutSet(targetReps: 12, prevWeight: 16, prevReps: 12),
                ],
                pr: nil
            ),
            WorkoutExercise(
                id: "e4", name: "Overhead Tricep Extension", muscle: "Triceps",
                restSeconds: 60,
                sets: [
                    WorkoutSet(targetReps: 12, prevWeight: 22.5, prevReps: 12),
                    WorkoutSet(targetReps: 12, prevWeight: 22.5, prevReps: 12),
                    WorkoutSet(targetReps: 10, prevWeight: 22.5, prevReps: 10),
                ],
                pr: nil
            ),
            WorkoutExercise(
                id: "e5", name: "Tricep Pushdown", muscle: "Triceps",
                restSeconds: 60,
                sets: [
                    WorkoutSet(targetReps: 15, prevWeight: 30, prevReps: 15),
                    WorkoutSet(targetReps: 12, prevWeight: 30, prevReps: 13),
                    WorkoutSet(targetReps: 10, prevWeight: 30, prevReps: 12),
                ],
                pr: nil
            ),
        ]
    )

    
}
