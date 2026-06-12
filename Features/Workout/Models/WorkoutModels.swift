import Foundation

// MARK: - Workout session

struct WorkoutSession {
    let id: Int
    let name: String
    let exercises: [WorkoutExercise]

    var totalSets: Int { exercises.reduce(0) { $0 + $1.sets.count } }
}

struct WorkoutExercise {
    let exerciseBlockPlanId: Int
    let exerciseBlockExecutionId: Int
    let id: Int
    let name: String
    let restSeconds: Int
    let sets: [WorkoutSet]
}

struct WorkoutSet {
    let targetReps: Int
    let targetWeight: Double
}

// MARK: - Session progress

struct SetProgress {
    var done: Bool
    var weight: Double
    var reps: Int
    let targetReps: Int
    let targetWeight: Double
}

struct ExerciseProgress {
    let id: Int
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
        id: 0,
        name: "Push Day · Chest & Triceps",
        exercises: [
            WorkoutExercise(
                exerciseBlockPlanId: 0,
                exerciseBlockExecutionId: 0,
                id: 1, name: "Barbell Bench Press",
                restSeconds: 120,
                sets: [
                    WorkoutSet(targetReps: 8, targetWeight: 80),
                    WorkoutSet(targetReps: 8, targetWeight: 80),
                    WorkoutSet(targetReps: 6, targetWeight: 80),
                    WorkoutSet(targetReps: 6, targetWeight: 80),
                ]
            ),
            WorkoutExercise(
                exerciseBlockPlanId: 0,
                exerciseBlockExecutionId: 0,
                id: 2, name: "Incline Dumbbell Press",
                restSeconds: 90,
                sets: [
                    WorkoutSet(targetReps: 10, targetWeight: 28),
                    WorkoutSet(targetReps: 10, targetWeight: 28),
                    WorkoutSet(targetReps: 8,  targetWeight: 28),
                ]
            ),
            WorkoutExercise(
                exerciseBlockPlanId: 0,
                exerciseBlockExecutionId: 0,
                id: 3, name: "Cable Chest Fly",
                restSeconds: 75,
                sets: [
                    WorkoutSet(targetReps: 12, targetWeight: 16),
                    WorkoutSet(targetReps: 12, targetWeight: 16),
                    WorkoutSet(targetReps: 12, targetWeight: 16),
                ]
            ),
            WorkoutExercise(
                exerciseBlockPlanId: 0,
                exerciseBlockExecutionId: 0,
                id: 4, name: "Overhead Tricep Extension",
                restSeconds: 60,
                sets: [
                    WorkoutSet(targetReps: 12, targetWeight: 22.5),
                    WorkoutSet(targetReps: 12, targetWeight: 22.5),
                    WorkoutSet(targetReps: 10, targetWeight: 22.5),
                ]
            ),
            WorkoutExercise(
                exerciseBlockPlanId: 0,
                exerciseBlockExecutionId: 0,
                id: 5, name: "Tricep Pushdown",
                restSeconds: 60,
                sets: [
                    WorkoutSet(targetReps: 15, targetWeight: 30),
                    WorkoutSet(targetReps: 12, targetWeight: 30),
                    WorkoutSet(targetReps: 10, targetWeight: 30),
                ]
            ),
        ]
    )
}
