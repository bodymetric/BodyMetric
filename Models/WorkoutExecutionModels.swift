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
struct StartSessionResponse: Decodable, Hashable {
    let id: String
    let planId: Int
    let actualWeekNumber: Int
    let feeling: String
    let exercises: [SessionExercise]
}

/// One exercise entry in the session response.
struct SessionExercise: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let muscle: String
    let restSeconds: Int
    let sets: [SessionSet]
    let pr: SessionPR?
}

/// One target set within a session exercise.
struct SessionSet: Decodable, Hashable {
    let targetReps: Int
    let prevWeight: Double
    let prevReps: Int
}

/// Previous-best record for an exercise, if available.
struct SessionPR: Decodable, Hashable {
    let weight: Double
    let reps: Int
}

// MARK: - StartSessionResponse → WorkoutSession mapping

extension StartSessionResponse {

    /// Maps the API session response to the in-memory `WorkoutSession` used by `ActiveSessionViewModel`.
    func toWorkoutSession() -> WorkoutSession {
        WorkoutSession(
            id: id,
            name: "",
            program: "Week \(actualWeekNumber)",
            dayIndex: actualWeekNumber,
            estimatedMinutes: 0,
            exercises: exercises.map { ex in
                WorkoutExercise(
                    id: ex.id,
                    name: ex.name,
                    muscle: ex.muscle,
                    restSeconds: ex.restSeconds,
                    sets: ex.sets.map { s in
                        WorkoutSet(
                            targetReps: s.targetReps,
                            prevWeight: s.prevWeight,
                            prevReps: s.prevReps
                        )
                    },
                    pr: ex.pr.map { PRRecord(weight: $0.weight, reps: $0.reps) }
                )
            }
        )
    }
}
