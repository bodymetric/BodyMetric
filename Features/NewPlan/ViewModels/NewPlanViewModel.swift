import Foundation
import Observation

/// State machine for the multi-step New Plan wizard.
///
/// Step mapping:
///   1         → SelectDaysStepView
///   2…N+1     → ConfigureDayStepView for each selected day (Mon→Sun order)
///   N+2       → ReviewStepView
///
/// Constitution Principle II: all mutations are unit-tested via NewPlanViewModelTests.
/// Constitution Principle IV: interaction traces via Logger.info (pending TRACING_BACKEND).
@Observable
@MainActor
final class NewPlanViewModel {

    // MARK: - Day load state (step 1 API)

    enum SelectDaysLoadState: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case failed(String)
    }

    // MARK: - State

    var selectedDays: Set<DayOfWeek> = []
    var dayPlans: [DayOfWeek: DayPlan] = [:]
    var currentStep: Int = 1
    var activePickerBlockId: UUID? = nil
    var isPresentingSuccess: Bool = false

    // MARK: - API state (step 1)

    var loadState: SelectDaysLoadState = .idle
    var isSaving: Bool = false
    var saveErrorMessage: String? = nil

    // MARK: - Derived

    var orderedSelectedDays: [DayOfWeek] {
        DayOfWeek.displayOrder.filter { selectedDays.contains($0) }
    }

    var totalSteps: Int {
        2 + orderedSelectedDays.count
    }

    var allDaysValid: Bool {
        orderedSelectedDays.allSatisfy { dayPlans[$0]?.isValid == true }
    }

    /// The DayOfWeek being configured on the current step (nil if not a day-config step).
    var currentDayOfWeek: DayOfWeek? {
        let dayIndex = currentStep - 2
        guard dayIndex >= 0, dayIndex < orderedSelectedDays.count else { return nil }
        return orderedSelectedDays[dayIndex]
    }

    // MARK: - Day selection

    func toggleDay(_ day: DayOfWeek) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
            dayPlans.removeValue(forKey: day)
        } else {
            selectedDays.insert(day)
            if dayPlans[day] == nil {
                dayPlans[day] = DayPlan(day: day)
            }
        }
        // Clear any prior save error when the user changes their selection (spec FR-013)
        saveErrorMessage = nil
        Logger.info(
            "wizard_day_toggled day:\(day.shortLabel) selected:\(selectedDays.contains(day))"
        )
    }

    // MARK: - Step 1 API actions

    /// Fetches any previously saved training day selections and pre-fills `selectedDays`.
    /// Called on-appear of `SelectDaysStepView` (Constitution Principle IV: traced).
    func loadDays(using service: any WorkoutPlanServiceProtocol) async {
        guard loadState != .loading else { return }
        loadState = .loading
        Logger.info("wizard_days_load_started")

        do {
            let days = try await service.fetchDays()
            // Map plannedWeekNumber (Int) → DayOfWeek; invalid values are silently ignored.
            let mapped = Set(days.compactMap { DayOfWeek(rawValue: $0.plannedWeekNumber) })
            selectedDays = mapped
            loadState = mapped.isEmpty ? .empty : .loaded
            let event = mapped.isEmpty ? "wizard_days_load_empty" : "wizard_days_load_success"
            Logger.info("\(event) count:\(mapped.count)")
        } catch WorkoutPlanError.notFound {
            selectedDays = []
            loadState = .empty
            Logger.info("wizard_days_load_empty (404)")
        } catch {
            Logger.error("wizard_days_load_failed", error: error)
            selectedDays = []
            loadState = .failed(error.localizedDescription)
        }
    }

    /// Saves the current day selection to the server.
    /// On success calls `onSuccess`; on failure sets `saveErrorMessage`.
    func saveDays(
        using service: any WorkoutPlanServiceProtocol,
        onSuccess: @MainActor @Sendable () -> Void
    ) async {
        guard !isSaving else { return }
        isSaving = true
        saveErrorMessage = nil
        Logger.info("wizard_days_save_started dayCount:\(selectedDays.count)")

        let requests = orderedSelectedDays.map(\.toRequest)
        do {
            try await service.saveDays(requests)
            Logger.info("wizard_days_save_success dayCount:\(requests.count)")
            onSuccess()
        } catch {
            Logger.error("wizard_days_save_failed", error: error)
            saveErrorMessage = "Could not save your training days. Please try again."
        }
        isSaving = false
    }

    // MARK: - Navigation

    func advance() {
        guard isStepValid(currentStep), currentStep < totalSteps else { return }
        currentStep += 1
        Logger.info("wizard_step_advanced step:\(currentStep)")
    }

    func retreat(onCancel: () -> Void) {
        if currentStep <= 1 {
            Logger.info("wizard_cancelled")
            onCancel()
        } else {
            currentStep -= 1
        }
    }

    func jumpTo(step: Int) {
        guard step >= 1, step <= currentStep else { return }
        currentStep = step
    }

    // MARK: - Block mutations

    func addBlock(for day: DayOfWeek) {
        guard dayPlans[day] != nil else { return }
        dayPlans[day]?.blocks.append(ExerciseBlock())
    }

    func removeBlock(id: UUID, from day: DayOfWeek) {
        dayPlans[day]?.blocks.removeAll { $0.id == id }
    }

    func updateBlock(id: UUID, day: DayOfWeek, patch: (inout ExerciseBlock) -> Void) {
        guard let idx = dayPlans[day]?.blocks.firstIndex(where: { $0.id == id }) else { return }
        patch(&dayPlans[day]!.blocks[idx])
    }

    // MARK: - Validation

    func isStepValid(_ step: Int) -> Bool {
        if step == 1 {
            return !selectedDays.isEmpty
        }
        if step == totalSteps {
            return allDaysValid
        }
        let dayIndex = step - 2
        guard dayIndex >= 0, dayIndex < orderedSelectedDays.count else { return false }
        let day = orderedSelectedDays[dayIndex]
        return dayPlans[day]?.isValid == true
    }

    // MARK: - Finish

    func finish(store: WorkoutPlanStore) {
        guard allDaysValid, !orderedSelectedDays.isEmpty else { return }
        let plan = WorkoutPlan(dayPlans: orderedSelectedDays.compactMap { dayPlans[$0] })
        store.save(plan)
        isPresentingSuccess = true
        Logger.info(
            "wizard_finished dayCount:\(plan.dayPlans.count) blockCount:\(plan.dayPlans.flatMap(\.blocks).count)"
        )
    }
}
