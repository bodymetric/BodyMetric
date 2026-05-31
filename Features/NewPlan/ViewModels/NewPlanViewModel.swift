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

    // MARK: - Edit plan load state (feature 017)

    enum EditPlanLoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: - State

    var selectedDays: Set<DayOfWeek> = []
    var dayPlans: [DayOfWeek: DayPlan] = [:]
    var currentStep: Int = 1
    var activePickerBlockId: UUID? = nil
    var isPresentingSuccess: Bool = false

    // MARK: - Edit mode state (feature 017)

    /// Server-assigned plan ID; non-nil when the wizard is in edit mode.
    var planId: Int? = nil
    var editPlanLoadState: EditPlanLoadState = .idle

    var isEditMode: Bool { planId != nil }

    // MARK: - API state (step 1)

    var loadState: SelectDaysLoadState = .idle
    var isSaving: Bool = false
    var saveErrorMessage: String? = nil

    // MARK: - API state (step 2)

    /// planId per DayOfWeek, populated from step-1 saveDays response (feature 011).
    var workoutPlanIds: [DayOfWeek: Int] = [:]
    var isDayConfigSaving: Bool = false
    var dayConfigSaveError: String? = nil

    // MARK: - Exercise catalog (feature 012)

    /// Loaded once when step 2 first appears; shared across all exercise pickers.
    var exerciseGroups: [ExerciseCatalogGroup] = []
    var exerciseCatalogLoadState: ExerciseCatalogLoadState = .idle

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
        dayConfigSaveError = nil
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
            // Map plannedDayOfWeek string → DayOfWeek; invalid values are silently ignored.
            // (plannedWeekNumber is the ISO week of the year, not the day of week)
            let mapped = Set(days.compactMap { DayOfWeek(fromApiString: $0.plannedDayOfWeek) })
            selectedDays = mapped
            // Seed dayPlans for every pre-filled day — mirrors what toggleDay() does.
            // Without this, addBlock() and isStepValid() silently fail on step 2
            // because they guard on dayPlans[day] != nil.
            for day in mapped where dayPlans[day] == nil {
                dayPlans[day] = DayPlan(day: day)
            }
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
            var savedDays = try await service.saveDays(requests)
            // If the POST response body didn't include the plans (empty), fall back to GET
            // to retrieve the planIds needed for step-2 day-plan POSTs.
            if savedDays.isEmpty {
                savedDays = (try? await service.fetchDays()) ?? []
            }
            for response in savedDays {
                if let day = DayOfWeek(fromApiString: response.plannedDayOfWeek) {
                    workoutPlanIds[day] = response.planId
                }
            }
            Logger.info("wizard_days_save_success dayCount:\(requests.count)")
            onSuccess()
        } catch {
            Logger.error("wizard_days_save_failed", error: error)
            saveErrorMessage = "Could not save your training days. Please try again."
        }
        isSaving = false
    }

    /// Saves the current day's configuration (day plan + all exercise blocks) to the server.
    ///
    /// Sequential: day plan first, then each exercise block using the returned workoutDayPlanId.
    /// Advances the wizard only when all saves succeed (spec FR-009).
    func saveDayConfig(
        for day: DayOfWeek,
        using service: any WorkoutDayPlanServiceProtocol,
        onSuccess: @MainActor @Sendable () -> Void
    ) async {
        guard !isDayConfigSaving,
              let plan = dayPlans[day],
              let planId = workoutPlanIds[day] else { return }

        isDayConfigSaving = true
        dayConfigSaveError = nil
        Logger.info("wizard_day_config_save_started day:\(day.shortLabel)")

        do {
            // Unified single POST: day + all exercise blocks in one request (feature 013)
            let request = WorkoutDayPlanRequest(
                name: plan.sessionName,
                orderIndex: day.orderIndex,
                isActive: true,
                exerciseBlocks: plan.blocks.enumerated().map { idx, block in
                    ExerciseBlockRequest(block: block, orderIndex: idx + 1)
                }
            )
            try await service.saveDayPlan(workoutPlanId: planId, request: request)
            Logger.info("wizard_day_plan_saved day:\(day.shortLabel) blockCount:\(plan.blocks.count)")

            onSuccess()
        } catch {
            Logger.error("wizard_day_config_save_failed", error: error)
            dayConfigSaveError = "Could not save your workout day. Please try again."
        }
        isDayConfigSaving = false
    }

    // MARK: - Exercise catalog (feature 012)

    /// Loads the exercise catalogue once per wizard session.
    /// Subsequent calls are no-ops if `exerciseGroups` is already populated (single-load guard).
    func loadExerciseCatalog(using service: any ExerciseServiceProtocol) async {
        guard exerciseGroups.isEmpty else { return }
        exerciseCatalogLoadState = .loading
        Logger.info("exercise_catalog_load_started")
        do {
            exerciseGroups = try await service.fetchExerciseCatalog()
            exerciseCatalogLoadState = .loaded
            Logger.info("exercise_catalog_load_success groupCount:\(exerciseGroups.count)")
        } catch {
            Logger.error("exercise_catalog_load_failed", error: error)
            exerciseCatalogLoadState = .failed("Could not load exercises. Please try again.")
        }
    }

    /// Forces a re-fetch of the catalogue (e.g., after the user taps Retry).
    func reloadExerciseCatalog(using service: any ExerciseServiceProtocol) async {
        exerciseGroups = []
        await loadExerciseCatalog(using: service)
    }

    /// Returns the display name for a given `exerciseId` string (e.g., "26") from the loaded catalog.
    func exerciseName(for exerciseId: String) -> String? {
        guard let id = Int(exerciseId) else { return nil }
        return exerciseGroups.flatMap(\.exercises).first { $0.id == id }?.name
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

    // MARK: - Edit mode actions (feature 017)

    /// Pre-fills all wizard state from the server's current active plan.
    /// Called on wizard appear when `editPlanId` is non-nil.
    func loadCurrentPlan(using service: any WorkoutPlanServiceProtocol) async {
        guard editPlanLoadState != .loading else { return }
        editPlanLoadState = .loading
        Logger.info("edit_plan_load_started")

        do {
            let plan = try await service.fetchCurrentPlan()
            planId = plan.id
            let days = Set(plan.days.compactMap { DayOfWeek(fromApiString: $0.plannedDayOfWeek) })
            selectedDays = days

            for apiDay in plan.days {
                guard let day = DayOfWeek(fromApiString: apiDay.plannedDayOfWeek) else { continue }
                workoutPlanIds[day] = apiDay.id
                let blocks = apiDay.exerciseBlocks
                    .sorted { $0.orderIndex < $1.orderIndex }
                    .map { block -> ExerciseBlock in
                        var b = ExerciseBlock()
                        b.exerciseId  = String(block.exerciseId)
                        b.restSeconds = block.restSeconds
                        b.sets = block.targetSets
                            .sorted { $0.orderIndex < $1.orderIndex }
                            .map { SetConfig(targetReps: $0.targetReps, targetWeight: $0.targetWeight) }
                        if b.sets.isEmpty { b.sets = [SetConfig()] }
                        return b
                    }
                dayPlans[day] = DayPlan(day: day, sessionName: apiDay.name, blocks: blocks)
            }
            editPlanLoadState = .loaded
            Logger.info("edit_plan_load_success planId:\(plan.id) dayCount:\(plan.days.count)")
        } catch WorkoutPlanError.notFound {
            editPlanLoadState = .failed("No active plan found.")
            Logger.info("edit_plan_load_not_found")
        } catch {
            Logger.error("edit_plan_load_failed", error: error)
            editPlanLoadState = .failed("Could not load your plan. Please try again.")
        }
    }

    /// Sends a unified PUT to update the existing plan. Used at wizard completion in edit mode.
    func updatePlan(
        using service: any WorkoutPlanServiceProtocol,
        onSuccess: @MainActor @Sendable () -> Void
    ) async {
        guard let id = planId, !isSaving else { return }
        isSaving = true
        saveErrorMessage = nil
        Logger.info("edit_plan_update_started planId:\(id)")

        let dayRequests = orderedSelectedDays.compactMap { day -> UpdateWorkoutPlanDayRequest? in
            guard let plan = dayPlans[day] else { return nil }
            return UpdateWorkoutPlanDayRequest(
                plannedDayOfWeek: day.fullLabel.lowercased(),
                name: plan.sessionName,
                orderIndex: day.orderIndex,
                isActive: true,
                exerciseBlocks: plan.blocks.enumerated().map { idx, block in
                    ExerciseBlockRequest(block: block, orderIndex: idx + 1)
                }
            )
        }

        do {
            try await service.updatePlan(id: id, request: UpdateWorkoutPlanRequest(days: dayRequests))
            Logger.info("edit_plan_update_success planId:\(id)")
            onSuccess()
        } catch {
            Logger.error("edit_plan_update_failed", error: error)
            saveErrorMessage = "Could not update your plan. Please try again."
        }
        isSaving = false
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
