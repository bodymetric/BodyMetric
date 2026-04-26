import Foundation
import Observation

/// UserDefaults-backed store for the user's current workout plan.
///
/// Mirrors the `ProfileStore` pattern: non-sensitive data → UserDefaults + Codable.
/// Tokens and credentials are unrelated to this store.
///
/// Constitution Principle I: pure Swift.
/// Constitution Principle III: no PII in log entries.
@Observable
final class WorkoutPlanStore {

    // MARK: - Keys

    private enum Key {
        static let currentPlan = "bm.workoutPlan.current"
    }

    // MARK: - State

    private(set) var currentPlan: WorkoutPlan?

    // MARK: - Dependencies

    private let defaults: UserDefaults

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    // MARK: - Read

    private func load() {
        guard let data = defaults.data(forKey: Key.currentPlan) else { return }
        do {
            currentPlan = try JSONDecoder().decode(WorkoutPlan.self, from: data)
        } catch {
            Logger.error("WorkoutPlanStore: failed to decode stored plan", error: error)
        }
    }

    // MARK: - Write

    func save(_ plan: WorkoutPlan) {
        do {
            let data = try JSONEncoder().encode(plan)
            defaults.set(data, forKey: Key.currentPlan)
            currentPlan = plan
            Logger.info(
                "workout_plan_saved dayCount:\(plan.dayPlans.count) blockCount:\(plan.dayPlans.flatMap(\.blocks).count)"
            )
        } catch {
            Logger.error("WorkoutPlanStore: failed to encode plan", error: error)
        }
    }

    func clear() {
        defaults.removeObject(forKey: Key.currentPlan)
        currentPlan = nil
    }
}
