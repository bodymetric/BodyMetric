import Foundation
import Observation

@Observable
@MainActor
final class ActiveSessionViewModel {

    // MARK: - Session data

    let workout: WorkoutSession
    let mood: String

    // MARK: - Progress

    private(set) var progress: [ExerciseProgress]
    var activeExIdx: Int = 0

    var totalSets: Int { progress.reduce(0) { $0 + $1.sets.count } }
    var doneSets: Int  { progress.reduce(0) { $0 + $1.doneCount } }
    var completionFraction: Double { totalSets > 0 ? Double(doneSets) / Double(totalSets) : 0 }

    var totalVolume: Double {
        progress.reduce(0) { $0 + $1.totalVolume }
    }

    // MARK: - Log sheet

    private(set) var logTarget: LogTarget? = nil

    // MARK: - Rest timer

    private(set) var restRemaining: Int? = nil
    private(set) var restTotal: Int = 0

    // MARK: - Session clock

    private(set) var elapsedSeconds: Int = 0

    // MARK: - Completion

    private(set) var completionStats: WorkoutCompletionStats? = nil

    // MARK: - Timers

    private var sessionTimer: Timer?
    private var restTimer: Timer?

    // MARK: - Init

    init(workout: WorkoutSession, mood: String) {
        self.workout = workout
        self.mood = mood
        self.progress = workout.exercises.map { ex in
            ExerciseProgress(
                id: ex.id,
                sets: ex.sets.map { s in
                    SetProgress(
                        done: false,
                        weight: s.prevWeight,
                        reps: s.targetReps,
                        targetReps: s.targetReps,
                        prevWeight: s.prevWeight,
                        prevReps: s.prevReps
                    )
                }
            )
        }
        startSessionClock()
    }
    
    func dispose() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        restTimer?.invalidate()
        restTimer = nil
    }

    deinit {
        
    }

    // MARK: - Log sheet actions

    func openLog(exIdx: Int, setIdx: Int) {
        guard !progress[exIdx].sets[setIdx].done else { return }
        logTarget = LogTarget(exIdx: exIdx, setIdx: setIdx)
    }

    func closeLog() {
        logTarget = nil
    }

    func commitSet(exIdx: Int, setIdx: Int, weight: Double, reps: Int) {
        progress[exIdx].sets[setIdx].done   = true
        progress[exIdx].sets[setIdx].weight = weight
        progress[exIdx].sets[setIdx].reps   = reps
        logTarget = nil

        startRest(seconds: workout.exercises[exIdx].restSeconds)

        // Advance to next exercise if current is fully done
        if progress[exIdx].allDone, exIdx + 1 < progress.count {
            activeExIdx = exIdx + 1
        }

        // Check session complete
        if progress.allSatisfy(\.allDone) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self else { return }
                self.completionStats = WorkoutCompletionStats(
                    totalVolume: self.totalVolume,
                    totalSets: self.totalSets,
                    elapsedSeconds: self.elapsedSeconds
                )
            }
        }
    }

    // MARK: - Rest timer

    func skipRest() {
        restTimer?.invalidate()
        restTimer = nil
        restRemaining = nil
    }

    func addRest(seconds: Int) {
        guard restRemaining != nil else { return }
        restRemaining = (restRemaining ?? 0) + seconds
        restTotal += seconds
    }

    private func startRest(seconds: Int) {
        restTimer?.invalidate()
        restRemaining = seconds
        restTotal = seconds

        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard let r = self.restRemaining, r > 1 else {
                    self.restTimer?.invalidate()
                    self.restRemaining = nil
                    return
                }
                self.restRemaining = r - 1
            }
        }
    }

    // MARK: - Session clock

    private func startSessionClock() {
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedSeconds += 1
            }
        }
    }
}
