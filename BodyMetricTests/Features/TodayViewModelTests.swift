import XCTest
@testable import BodyMetric

/// Unit tests for TodayViewModel.
///
/// Constitution Principle II: written before implementation (TDD).
@MainActor
final class TodayViewModelTests: XCTestCase {

    private var sut: TodayViewModel!
    private var mockService: MockHomeService!

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockHomeService()
        sut = TodayViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        mockService = nil
        try await super.tearDown()
    }

    // MARK: - loadHomeData: success

    func test_loadHomeData_success_setsLoadedState() async {
        mockService.dataToReturn = makeHomeData(withPlan: true, exercises: 2)
        await sut.loadHomeData(using: mockService)
        if case .loaded = sut.loadState { /* ✅ */ } else {
            XCTFail("Expected .loaded, got \(sut.loadState)")
        }
    }

    func test_loadHomeData_withPlan_hasActivePlanTrue() async {
        mockService.dataToReturn = makeHomeData(withPlan: true, exercises: 0)
        await sut.loadHomeData(using: mockService)
        XCTAssertTrue(sut.hasActivePlan)
    }

    func test_loadHomeData_noPlan_hasActivePlanFalse() async {
        mockService.dataToReturn = makeHomeData(withPlan: false, exercises: 0)
        await sut.loadHomeData(using: mockService)
        XCTAssertFalse(sut.hasActivePlan)
    }

    func test_loadHomeData_withPlan_workoutPlanNotNil() async {
        mockService.dataToReturn = makeHomeData(withPlan: true, exercises: 0)
        await sut.loadHomeData(using: mockService)
        XCTAssertNotNil(sut.workoutPlan)
        XCTAssertEqual(sut.workoutPlan?.name, "Test Plan")
    }

    func test_loadHomeData_withExercises_returnsExercises() async {
        mockService.dataToReturn = makeHomeData(withPlan: false, exercises: 3)
        await sut.loadHomeData(using: mockService)
        XCTAssertEqual(sut.exercisesForToday.count, 3)
    }

    func test_loadHomeData_noExercises_returnsEmpty() async {
        mockService.dataToReturn = makeHomeData(withPlan: false, exercises: 0)
        await sut.loadHomeData(using: mockService)
        XCTAssertTrue(sut.exercisesForToday.isEmpty)
    }

    // MARK: - loadHomeData: failure

    func test_loadHomeData_failure_setsFailedState() async {
        mockService.errorToThrow = WorkoutPlanError.serverError(500)
        await sut.loadHomeData(using: mockService)
        if case .failed = sut.loadState { /* ✅ */ } else {
            XCTFail("Expected .failed, got \(sut.loadState)")
        }
    }

    func test_loadHomeData_failure_hasActivePlanFalse() async {
        mockService.errorToThrow = WorkoutPlanError.serverError(500)
        await sut.loadHomeData(using: mockService)
        XCTAssertFalse(sut.hasActivePlan)
    }

    // MARK: - Re-entry guard

    func test_loadHomeData_calledWhileLoading_doesNotCallServiceTwice() async {
        mockService.dataToReturn = makeHomeData(withPlan: true, exercises: 0)
        // First call sets .loading; simulate re-entry prevention
        sut.loadState = .loading
        await sut.loadHomeData(using: mockService)
        XCTAssertEqual(mockService.fetchCount, 0, "Re-entry while loading must be blocked")
    }

    // MARK: - reload

    func test_reload_setsLoadedStateAfterSuccess() async {
        sut.loadState = .failed("old error")
        mockService.dataToReturn = makeHomeData(withPlan: true, exercises: 1)
        await sut.reload(using: mockService)
        if case .loaded = sut.loadState { /* ✅ */ } else {
            XCTFail("Expected .loaded after reload, got \(sut.loadState)")
        }
    }

    func test_reload_callsFetchService() async {
        mockService.dataToReturn = makeHomeData(withPlan: false, exercises: 0)
        await sut.reload(using: mockService)
        XCTAssertEqual(mockService.fetchCount, 1)
    }

    // MARK: - exercisesForToday ordering

    func test_exercisesForToday_sortedByOrderIndex() async {
        let ex1 = TodayExercise(id: 1, name: "Exercise A", orderIndex: 2, sets: [])
        let ex2 = TodayExercise(id: 2, name: "Exercise B", orderIndex: 1, sets: [])
        mockService.dataToReturn = HomeScreenData(currentWorkoutDayPlan: nil, exercisesForToday: [ex1, ex2])
        await sut.loadHomeData(using: mockService)
        XCTAssertEqual(sut.exercisesForToday[0].orderIndex, 1)
        XCTAssertEqual(sut.exercisesForToday[1].orderIndex, 2)
    }

    // MARK: - Helpers

    private func makeHomeData(withPlan: Bool, exercises: Int) -> HomeScreenData {
        let plan: WorkoutDayPlanSummary? = withPlan
            ? WorkoutDayPlanSummary(id: 1, name: "Test Plan", dayOfWeek: "MONDAY",
                                   numberOfExercisesTotal: 5, numberSetsTotal: 15, timeEstimateToFinish: 60,
                                   actualWeekNumber: 1)
            : nil
        let ex: [TodayExercise]? = exercises > 0
            ? (0..<exercises).map {
                TodayExercise(id: $0, name: "Exercise \($0)", orderIndex: $0, sets: [])
              }
            : []
        return HomeScreenData(currentWorkoutDayPlan: plan, exercisesForToday: ex)
    }
}

// MARK: - MockHomeService

@MainActor
final class MockHomeService: HomeServiceProtocol {
    var dataToReturn: HomeScreenData = HomeScreenData(currentWorkoutDayPlan: nil, exercisesForToday: nil)
    var errorToThrow: Error?
    var fetchCount = 0

    func fetchHomeData() async throws -> HomeScreenData {
        fetchCount += 1
        if let error = errorToThrow { throw error }
        return dataToReturn
    }
}
