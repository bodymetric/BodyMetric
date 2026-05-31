import Foundation
import Observation

/// Load state machine for the home screen.
///
/// Owns the `GET /api/home` fetch lifecycle and exposes derived properties
/// for the workout card, exercises card, and menu state.
///
/// Constitution Principle II: all state is unit-tested via TodayViewModelTests.
/// Constitution Principle IV: interaction traces via Logger.info.
@Observable
@MainActor
final class TodayViewModel {

    // MARK: - State

    var loadState: HomeLoadState = .idle

    // MARK: - Derived

    var hasActivePlan: Bool {
        guard case .loaded(let d) = loadState else { return false }
        return d.currentWorkoutDayPlan != nil
    }

    var workoutPlan: WorkoutDayPlanSummary? {
        guard case .loaded(let d) = loadState else { return nil }
        return d.currentWorkoutDayPlan
    }

    var exercisesForToday: [TodayExercise] {
        guard case .loaded(let d) = loadState else { return [] }
        return (d.exercisesForToday ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }

    // MARK: - Load

    /// Fetches home screen data once. Re-entry while loading is blocked.
    func loadHomeData(using service: any HomeServiceProtocol) async {
        guard loadState != .loading else { return }
        loadState = .loading
        Logger.info("home_data_load_started")

        do {
            let data = try await service.fetchHomeData()
            loadState = .loaded(data)
            Logger.info("home_data_load_success hasActivePlan:\(hasActivePlan)")
        } catch {
            Logger.error("home_data_load_failed", error: error)
            loadState = .failed("Could not load home data. Please try again.")
        }
    }

    /// Resets state and re-fetches.
    func reload(using service: any HomeServiceProtocol) async {
        loadState = .idle
        await loadHomeData(using: service)
    }
}
