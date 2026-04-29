import XCTest
@testable import BodyMetric

/// Unit tests for NewPlanViewModel wizard state machine.
///
/// Constitution Principle II: written before implementation (TDD).
@MainActor
final class NewPlanViewModelTests: XCTestCase {

    private var sut: NewPlanViewModel!
    private var store: WorkoutPlanStore!
    private let testDefaults = UserDefaults(suiteName: "NewPlanViewModelTests")!

    override func setUp() async throws {
        try await super.setUp()
        testDefaults.removePersistentDomain(forName: "NewPlanViewModelTests")
        store = WorkoutPlanStore(defaults: testDefaults)
        sut = NewPlanViewModel()
    }

    override func tearDown() async throws {
        testDefaults.removePersistentDomain(forName: "NewPlanViewModelTests")
        sut = nil
        store = nil
        try await super.tearDown()
    }

    // MARK: - Initial state

    func test_initialStep_isOne() {
        XCTAssertEqual(sut.currentStep, 1)
    }

    func test_totalSteps_defaultsToTwoPlusTwoForDefaultSelection() {
        // Default selection is Mon, Wed, Fri (3 days)
        XCTAssertEqual(sut.totalSteps, 2 + sut.selectedDays.count)
    }

    // MARK: - toggleDay

    func test_toggleDay_addsDay() {
        sut.selectedDays = []
        sut.toggleDay(.monday)
        XCTAssertTrue(sut.selectedDays.contains(.monday))
    }

    func test_toggleDay_removesDayIfAlreadySelected() {
        sut.selectedDays = [.monday]
        sut.toggleDay(.monday)
        XCTAssertFalse(sut.selectedDays.contains(.monday))
    }

    func test_toggleDay_seedsEmptyDayPlanOnSelect() {
        sut.selectedDays = []
        sut.toggleDay(.tuesday)
        XCTAssertNotNil(sut.dayPlans[.tuesday])
    }

    func test_toggleDay_removesDayPlanOnDeselect() {
        sut.selectedDays = [.tuesday]
        sut.dayPlans[.tuesday] = DayPlan(day: .tuesday)
        sut.toggleDay(.tuesday)
        XCTAssertNil(sut.dayPlans[.tuesday])
    }

    // MARK: - totalSteps

    func test_totalSteps_equalsSelectedDaysCountPlusTwo() {
        sut.selectedDays = [.monday, .wednesday]
        XCTAssertEqual(sut.totalSteps, 4)
    }

    func test_totalSteps_isThreeWhenOneDaySelected() {
        sut.selectedDays = [.friday]
        XCTAssertEqual(sut.totalSteps, 3)
    }

    // MARK: - orderedSelectedDays

    func test_orderedSelectedDays_isAlwaysMonToSunSorted() {
        sut.selectedDays = [.sunday, .monday, .friday]
        let ordered = sut.orderedSelectedDays
        XCTAssertEqual(ordered[0], .monday)
        XCTAssertEqual(ordered[1], .friday)
        XCTAssertEqual(ordered[2], .sunday)
    }

    // MARK: - advance

    func test_advance_incrementsStepWhenValid() {
        sut.selectedDays = [.monday]
        sut.dayPlans[.monday] = makeValidDayPlan(for: .monday)
        // Step 1 is valid (at least one day selected)
        XCTAssertEqual(sut.currentStep, 1)
        sut.advance()
        XCTAssertEqual(sut.currentStep, 2)
    }

    func test_advance_isNoOpWhenStepOneAndNoDaysSelected() {
        sut.selectedDays = []
        sut.advance()
        XCTAssertEqual(sut.currentStep, 1)
    }

    func test_advance_doesNotExceedTotalSteps() {
        sut.selectedDays = [.monday]
        sut.dayPlans[.monday] = makeValidDayPlan(for: .monday)
        sut.currentStep = sut.totalSteps
        sut.advance()
        XCTAssertEqual(sut.currentStep, sut.totalSteps)
    }

    // MARK: - retreat

    func test_retreat_decrementsStep() {
        sut.currentStep = 2
        var cancelCalled = false
        sut.retreat(onCancel: { cancelCalled = true })
        XCTAssertEqual(sut.currentStep, 1)
        XCTAssertFalse(cancelCalled)
    }

    func test_retreat_callsOnCancelAtStepOne() {
        sut.currentStep = 1
        var cancelCalled = false
        sut.retreat(onCancel: { cancelCalled = true })
        XCTAssertTrue(cancelCalled)
    }

    // MARK: - isStepValid

    func test_isStepValid_step1_falseWhenNoDaysSelected() {
        sut.selectedDays = []
        XCTAssertFalse(sut.isStepValid(1))
    }

    func test_isStepValid_step1_trueWhenAtLeastOneDaySelected() {
        sut.selectedDays = [.monday]
        XCTAssertTrue(sut.isStepValid(1))
    }

    func test_isStepValid_dayStep_falseWhenDayPlanInvalid() {
        sut.selectedDays = [.monday]
        sut.dayPlans[.monday] = DayPlan(day: .monday) // empty name → invalid
        XCTAssertFalse(sut.isStepValid(2))
    }

    func test_isStepValid_dayStep_trueWhenDayPlanValid() {
        sut.selectedDays = [.monday]
        sut.dayPlans[.monday] = makeValidDayPlan(for: .monday)
        XCTAssertTrue(sut.isStepValid(2))
    }

    func test_isStepValid_reviewStep_falseWhenSomeDaysInvalid() {
        sut.selectedDays = [.monday, .wednesday]
        sut.dayPlans[.monday] = makeValidDayPlan(for: .monday)
        sut.dayPlans[.wednesday] = DayPlan(day: .wednesday) // invalid
        XCTAssertFalse(sut.isStepValid(sut.totalSteps))
    }

    func test_isStepValid_reviewStep_trueWhenAllDaysValid() {
        sut.selectedDays = [.monday]
        sut.dayPlans[.monday] = makeValidDayPlan(for: .monday)
        XCTAssertTrue(sut.isStepValid(sut.totalSteps))
    }

    // MARK: - jumpTo

    func test_jumpTo_allowsJumpToEarlierStep() {
        sut.currentStep = 3
        sut.jumpTo(step: 2)
        XCTAssertEqual(sut.currentStep, 2)
    }

    func test_jumpTo_allowsJumpToCurrentStep() {
        sut.currentStep = 2
        sut.jumpTo(step: 2)
        XCTAssertEqual(sut.currentStep, 2)
    }

    func test_jumpTo_isNoOpForFutureStep() {
        sut.currentStep = 1
        sut.jumpTo(step: 3)
        XCTAssertEqual(sut.currentStep, 1)
    }

    // MARK: - addBlock / removeBlock / updateBlock

    func test_addBlock_appendsBlockToDay() {
        sut.selectedDays = [.monday]
        sut.dayPlans[.monday] = DayPlan(day: .monday)
        let before = sut.dayPlans[.monday]!.blocks.count
        sut.addBlock(for: .monday)
        XCTAssertEqual(sut.dayPlans[.monday]!.blocks.count, before + 1)
    }

    func test_removeBlock_removesBlockById() {
        sut.selectedDays = [.monday]
        var plan = DayPlan(day: .monday)
        let block = ExerciseBlock()
        plan.blocks = [block]
        sut.dayPlans[.monday] = plan

        sut.removeBlock(id: block.id, from: .monday)
        XCTAssertEqual(sut.dayPlans[.monday]!.blocks.count, 0)
    }

    func test_updateBlock_patchesFieldsInPlace() {
        sut.selectedDays = [.monday]
        var plan = DayPlan(day: .monday)
        let block = ExerciseBlock()
        plan.blocks = [block]
        sut.dayPlans[.monday] = plan

        sut.updateBlock(id: block.id, day: .monday) { $0.exerciseId = "squat" }
        XCTAssertEqual(sut.dayPlans[.monday]!.blocks.first?.exerciseId, "squat")
    }

    // MARK: - finish

    func test_finish_setsPresentingSuccessToTrue() {
        sut.selectedDays = [.monday]
        sut.dayPlans[.monday] = makeValidDayPlan(for: .monday)
        sut.finish(store: store)
        XCTAssertTrue(sut.isPresentingSuccess)
    }

    func test_finish_savesWorkoutPlanToStore() {
        sut.selectedDays = [.monday]
        sut.dayPlans[.monday] = makeValidDayPlan(for: .monday)
        sut.finish(store: store)
        XCTAssertNotNil(store.currentPlan)
        XCTAssertEqual(store.currentPlan?.dayPlans.count, 1)
    }

    func test_finish_doesNotSaveWhenNoDaysSelected() {
        sut.selectedDays = []
        sut.finish(store: store)
        XCTAssertFalse(sut.isPresentingSuccess)
        XCTAssertNil(store.currentPlan)
    }

    // MARK: - Helpers

    private func makeValidDayPlan(for day: DayOfWeek) -> DayPlan {
        var plan = DayPlan(day: day)
        plan.sessionName = "Test Session"
        var block = ExerciseBlock()
        block.exerciseId = "bench"
        block.targetReps = 8
        block.targetWeight = 60
        block.restSeconds = 90
        plan.blocks = [block]
        return plan
    }
}

// MARK: - API integration tests (T003 — written before loadDays/saveDays exist)

@MainActor
final class NewPlanViewModelAPITests: XCTestCase {

    private var sut: NewPlanViewModel!
    private var mockService: MockWorkoutPlanService!

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockWorkoutPlanService()
        sut = NewPlanViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        mockService = nil
        try await super.tearDown()
    }

    // MARK: - loadDays: success

    func test_loadDays_success_setsLoadStateLoaded() async {
        mockService.daysToReturn = [
            WorkoutPlanDayResponse(planId: 7, plannedWeekNumber: 7,
                                   plannedDayOfWeek: "sunday", executionCount: 0,
                                   dayNames: [], totalExercises: 0,
                                   totalSets: 0, estimatedDurationMinutes: 0),
        ]
        await sut.loadDays(using: mockService)
        XCTAssertEqual(sut.loadState, .loaded)
    }

    func test_loadDays_success_preFillsSunday() async {
        mockService.daysToReturn = [
            WorkoutPlanDayResponse(planId: 7, plannedWeekNumber: 7,
                                   plannedDayOfWeek: "sunday", executionCount: 0,
                                   dayNames: [], totalExercises: 0,
                                   totalSets: 0, estimatedDurationMinutes: 0),
        ]
        await sut.loadDays(using: mockService)
        XCTAssertEqual(sut.selectedDays, [.sunday])
    }

    func test_loadDays_success_preFillsMondayAndFriday() async {
        mockService.daysToReturn = [
            WorkoutPlanDayResponse(planId: 1, plannedWeekNumber: 1,
                                   plannedDayOfWeek: "monday", executionCount: 0,
                                   dayNames: [], totalExercises: 0,
                                   totalSets: 0, estimatedDurationMinutes: 0),
            WorkoutPlanDayResponse(planId: 5, plannedWeekNumber: 5,
                                   plannedDayOfWeek: "friday", executionCount: 0,
                                   dayNames: [], totalExercises: 0,
                                   totalSets: 0, estimatedDurationMinutes: 0),
        ]
        await sut.loadDays(using: mockService)
        XCTAssertEqual(sut.selectedDays, [.monday, .friday])
    }

    func test_loadDays_invalidWeekNumber_ignoresEntry() async {
        mockService.daysToReturn = [
            WorkoutPlanDayResponse(planId: 99, plannedWeekNumber: 0,
                                   plannedDayOfWeek: "invalid", executionCount: 0,
                                   dayNames: [], totalExercises: 0,
                                   totalSets: 0, estimatedDurationMinutes: 0),
        ]
        await sut.loadDays(using: mockService)
        // loadState is .empty because no valid days parsed, selectedDays stays empty
        XCTAssertEqual(sut.loadState, .empty)
        XCTAssertTrue(sut.selectedDays.isEmpty)
    }

    // MARK: - loadDays: 404 → empty

    func test_loadDays_404_setsLoadStateEmpty() async {
        mockService.errorToThrow = WorkoutPlanError.notFound
        await sut.loadDays(using: mockService)
        XCTAssertEqual(sut.loadState, .empty)
    }

    func test_loadDays_404_selectedDaysEmpty() async {
        mockService.errorToThrow = WorkoutPlanError.notFound
        await sut.loadDays(using: mockService)
        XCTAssertTrue(sut.selectedDays.isEmpty)
    }

    // MARK: - loadDays: network error

    func test_loadDays_networkError_setsLoadStateFailed() async {
        mockService.errorToThrow = WorkoutPlanError.networkError(URLError(.notConnectedToInternet))
        await sut.loadDays(using: mockService)
        if case .failed = sut.loadState { /* ✅ */ } else {
            XCTFail("Expected loadState == .failed, got \(sut.loadState)")
        }
    }

    func test_loadDays_networkError_selectedDaysEmpty() async {
        mockService.errorToThrow = WorkoutPlanError.networkError(URLError(.notConnectedToInternet))
        await sut.loadDays(using: mockService)
        XCTAssertTrue(sut.selectedDays.isEmpty)
    }

    // MARK: - saveDays: success

    func test_saveDays_success_callsOnSuccess() async {
        sut.selectedDays = [.monday]
        sut.dayPlans[.monday] = DayPlan(day: .monday)
        var onSuccessCalled = false
        await sut.saveDays(using: mockService, onSuccess: { onSuccessCalled = true })
        XCTAssertTrue(onSuccessCalled)
    }

    func test_saveDays_success_isSavingFalseAfter() async {
        sut.selectedDays = [.monday]
        await sut.saveDays(using: mockService, onSuccess: {})
        XCTAssertFalse(sut.isSaving)
    }

    func test_saveDays_success_saveErrorMessageNil() async {
        sut.selectedDays = [.monday]
        await sut.saveDays(using: mockService, onSuccess: {})
        XCTAssertNil(sut.saveErrorMessage)
    }

    // MARK: - saveDays: failure

    func test_saveDays_failure_isSavingFalseAfter() async {
        mockService.saveShouldThrow = true
        sut.selectedDays = [.monday]
        await sut.saveDays(using: mockService, onSuccess: {})
        XCTAssertFalse(sut.isSaving)
    }

    func test_saveDays_failure_saveErrorMessageNotNil() async {
        mockService.saveShouldThrow = true
        sut.selectedDays = [.monday]
        await sut.saveDays(using: mockService, onSuccess: {})
        XCTAssertNotNil(sut.saveErrorMessage)
        XCTAssertFalse(sut.saveErrorMessage!.isEmpty)
    }

    func test_saveDays_failure_selectedDaysPreserved() async {
        mockService.saveShouldThrow = true
        sut.selectedDays = [.monday, .friday]
        await sut.saveDays(using: mockService, onSuccess: {})
        XCTAssertEqual(sut.selectedDays, [.monday, .friday])
    }

    func test_saveDays_failure_onSuccessNotCalled() async {
        mockService.saveShouldThrow = true
        sut.selectedDays = [.monday]
        var onSuccessCalled = false
        await sut.saveDays(using: mockService, onSuccess: { onSuccessCalled = true })
        XCTAssertFalse(onSuccessCalled)
    }

    // MARK: - toggleDay clears saveErrorMessage

    func test_toggleDay_clearsSaveErrorMessage() async {
        // Seed an error
        mockService.saveShouldThrow = true
        sut.selectedDays = [.monday]
        await sut.saveDays(using: mockService, onSuccess: {})
        XCTAssertNotNil(sut.saveErrorMessage)

        // Toggle any day → error should clear
        sut.toggleDay(.wednesday)
        XCTAssertNil(sut.saveErrorMessage)
    }
}

// MARK: - MockWorkoutPlanService

@MainActor
final class MockWorkoutPlanService: WorkoutPlanServiceProtocol {
    var daysToReturn: [WorkoutPlanDayResponse] = []
    var errorToThrow: Error?
    var saveShouldThrow = false
    var savedDays: [WorkoutPlanDayRequest]?

    func fetchDays() async throws -> [WorkoutPlanDayResponse] {
        if let error = errorToThrow { throw error }
        return daysToReturn
    }

    // T003: updated to match new return type [WorkoutPlanDayResponse]
    var savedDaysResponse: [WorkoutPlanDayResponse] = []

    func saveDays(_ days: [WorkoutPlanDayRequest]) async throws -> [WorkoutPlanDayResponse] {
        if saveShouldThrow { throw WorkoutPlanError.serverError(500) }
        savedDays = days
        return savedDaysResponse
    }
}

// MARK: - Day config (step 2) tests (T004)

@MainActor
final class NewPlanViewModelDayConfigTests: XCTestCase {

    private var sut: NewPlanViewModel!
    private var mockDayConfigService: MockWorkoutDayPlanService!
    private var mockPlanService: MockWorkoutPlanService!

    override func setUp() async throws {
        try await super.setUp()
        mockDayConfigService = MockWorkoutDayPlanService()
        mockPlanService = MockWorkoutPlanService()
        sut = NewPlanViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        mockDayConfigService = nil
        mockPlanService = nil
        try await super.tearDown()
    }

    // MARK: - saveDays stores workoutPlanIds

    func test_saveDays_storesWorkoutPlanIdsFromResponse() async {
        sut.selectedDays = [.monday, .sunday]
        let mondayResponse = WorkoutPlanDayResponse(planId: 10, plannedWeekNumber: 1,
            plannedDayOfWeek: "monday", executionCount: 0, dayNames: [],
            totalExercises: 0, totalSets: 0, estimatedDurationMinutes: 0)
        let sundayResponse = WorkoutPlanDayResponse(planId: 77, plannedWeekNumber: 7,
            plannedDayOfWeek: "sunday", executionCount: 0, dayNames: [],
            totalExercises: 0, totalSets: 0, estimatedDurationMinutes: 0)
        mockPlanService.savedDaysResponse = [mondayResponse, sundayResponse]

        await sut.saveDays(using: mockPlanService, onSuccess: {})

        XCTAssertEqual(sut.workoutPlanIds[.monday], 10)
        XCTAssertEqual(sut.workoutPlanIds[.sunday], 77)
    }

    // MARK: - saveDayConfig: success

    func test_saveDayConfig_success_callsOnSuccess() async {
        setupDayWithPlanId(day: .monday, planId: 5)
        var called = false
        await sut.saveDayConfig(for: .monday, using: mockDayConfigService, onSuccess: { called = true })
        XCTAssertTrue(called)
    }

    func test_saveDayConfig_success_isDayConfigSavingFalseAfter() async {
        setupDayWithPlanId(day: .monday, planId: 5)
        await sut.saveDayConfig(for: .monday, using: mockDayConfigService, onSuccess: {})
        XCTAssertFalse(sut.isDayConfigSaving)
    }

    func test_saveDayConfig_success_dayConfigSaveErrorNil() async {
        setupDayWithPlanId(day: .monday, planId: 5)
        await sut.saveDayConfig(for: .monday, using: mockDayConfigService, onSuccess: {})
        XCTAssertNil(sut.dayConfigSaveError)
    }

    // MARK: - saveDayConfig: day plan failure

    func test_saveDayConfig_dayPlanFailure_onSuccessNotCalled() async {
        setupDayWithPlanId(day: .monday, planId: 5)
        mockDayConfigService.saveDayPlanShouldThrow = true
        var called = false
        await sut.saveDayConfig(for: .monday, using: mockDayConfigService, onSuccess: { called = true })
        XCTAssertFalse(called)
    }

    func test_saveDayConfig_dayPlanFailure_dayConfigSaveErrorNotNil() async {
        setupDayWithPlanId(day: .monday, planId: 5)
        mockDayConfigService.saveDayPlanShouldThrow = true
        await sut.saveDayConfig(for: .monday, using: mockDayConfigService, onSuccess: {})
        XCTAssertNotNil(sut.dayConfigSaveError)
    }

    func test_saveDayConfig_dayPlanFailure_isDayConfigSavingFalse() async {
        setupDayWithPlanId(day: .monday, planId: 5)
        mockDayConfigService.saveDayPlanShouldThrow = true
        await sut.saveDayConfig(for: .monday, using: mockDayConfigService, onSuccess: {})
        XCTAssertFalse(sut.isDayConfigSaving)
    }

    // MARK: - saveDayConfig: exercise block failure

    func test_saveDayConfig_blockFailure_onSuccessNotCalled() async {
        setupDayWithPlanId(day: .monday, planId: 5)
        mockDayConfigService.saveExerciseBlockShouldThrow = true
        var called = false
        await sut.saveDayConfig(for: .monday, using: mockDayConfigService, onSuccess: { called = true })
        XCTAssertFalse(called)
    }

    func test_saveDayConfig_blockFailure_dayConfigSaveErrorNotNil() async {
        setupDayWithPlanId(day: .monday, planId: 5)
        mockDayConfigService.saveExerciseBlockShouldThrow = true
        await sut.saveDayConfig(for: .monday, using: mockDayConfigService, onSuccess: {})
        XCTAssertNotNil(sut.dayConfigSaveError)
    }

    // MARK: - Duplicate-tap guard

    func test_saveDayConfig_isDayConfigSavingPreventsReeentry() async {
        setupDayWithPlanId(day: .monday, planId: 5)
        // Manually set saving flag to simulate in-progress
        sut.isDayConfigSaving = true
        var called = false
        await sut.saveDayConfig(for: .monday, using: mockDayConfigService, onSuccess: { called = true })
        XCTAssertFalse(called, "Re-entry must be blocked when isDayConfigSaving is true")
    }

    // MARK: - US3: sequential block save — second block fails

    func test_saveDayConfig_secondBlockFails_onSuccessNotCalled() async {
        setupDayWithTwoBlocks(day: .wednesday, planId: 99)
        mockDayConfigService.saveExerciseBlockFailAtCallIndex = 1  // first ok, second fails
        var called = false
        await sut.saveDayConfig(for: .wednesday, using: mockDayConfigService, onSuccess: { called = true })
        XCTAssertFalse(called)
        XCTAssertNotNil(sut.dayConfigSaveError)
    }

    // MARK: - Helpers

    private func setupDayWithPlanId(day: DayOfWeek, planId: Int) {
        sut.selectedDays = [day]
        sut.workoutPlanIds[day] = planId
        var plan = DayPlan(day: day)
        plan.sessionName = "Test Session"
        var block = ExerciseBlock()
        block.exerciseId = "bench"
        block.targetReps = 8
        block.targetWeight = 60
        block.restSeconds = 90
        plan.blocks = [block]
        sut.dayPlans[day] = plan
    }

    private func setupDayWithTwoBlocks(day: DayOfWeek, planId: Int) {
        sut.selectedDays = [day]
        sut.workoutPlanIds[day] = planId
        var plan = DayPlan(day: day)
        plan.sessionName = "Two Block Day"
        var b1 = ExerciseBlock(); b1.exerciseId = "bench"; b1.targetReps = 8; b1.targetWeight = 60; b1.restSeconds = 90
        var b2 = ExerciseBlock(); b2.exerciseId = "squat"; b2.targetReps = 5; b2.targetWeight = 100; b2.restSeconds = 180
        plan.blocks = [b1, b2]
        sut.dayPlans[day] = plan
    }
}

// MARK: - MockWorkoutDayPlanService

@MainActor
final class MockWorkoutDayPlanService: WorkoutDayPlanServiceProtocol {
    var dayPlanResponseId: Int = 42
    var saveDayPlanShouldThrow = false
    var saveExerciseBlockShouldThrow = false
    var saveExerciseBlockFailAtCallIndex: Int? = nil
    private var exerciseBlockCallCount = 0

    func saveDayPlan(workoutPlanId: Int, request: WorkoutDayPlanRequest) async throws -> WorkoutDayPlanResponse {
        if saveDayPlanShouldThrow { throw WorkoutPlanError.serverError(500) }
        return WorkoutDayPlanResponse(workoutDayPlanId: dayPlanResponseId)
    }

    func saveExerciseBlock(workoutDayPlanId: Int, request: ExerciseBlockPlanRequest) async throws {
        defer { exerciseBlockCallCount += 1 }
        if saveExerciseBlockShouldThrow { throw WorkoutPlanError.serverError(500) }
        if let failAt = saveExerciseBlockFailAtCallIndex, exerciseBlockCallCount >= failAt {
            throw WorkoutPlanError.serverError(500)
        }
    }
}
