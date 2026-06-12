import XCTest
@testable import BodyMetric

/// Unit tests for ReadyToLiftViewModel.
///
/// Constitution Principle II: TDD — covers all LoadState transitions.
@MainActor
final class ReadyToLiftViewModelTests: XCTestCase {

    private var sut: ReadyToLiftViewModel!
    private var mockService: MockWorkoutExecutionService!

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockWorkoutExecutionService()
        sut = ReadyToLiftViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        mockService = nil
        try await super.tearDown()
    }

    // MARK: - Initial state

    func test_initialState_isIdle() {
        XCTAssertEqual(sut.loadState, .idle)
        XCTAssertFalse(sut.isSubmitting)
        XCTAssertNil(sut.sessionResponse)
    }

    // MARK: - beginSession: success

    func test_beginSession_success_setsSessionResponse() async {
        mockService.responseToReturn = makeFixtureResponse()
        await sut.beginSession(planId: 4, actualWeekNumber: 1, feeling: "ok", using: mockService)
        XCTAssertNotNil(sut.sessionResponse)
        XCTAssertEqual(sut.sessionResponse?.workExecutionId, 9)
    }

    func test_beginSession_success_setsLoadStateIdle() async {
        mockService.responseToReturn = makeFixtureResponse()
        await sut.beginSession(planId: 4, actualWeekNumber: 1, feeling: "ok", using: mockService)
        XCTAssertEqual(sut.loadState, .idle)
    }

    func test_beginSession_success_isSubmittingFalseAfter() async {
        mockService.responseToReturn = makeFixtureResponse()
        await sut.beginSession(planId: 4, actualWeekNumber: 1, feeling: "ok", using: mockService)
        XCTAssertFalse(sut.isSubmitting)
    }

    func test_beginSession_uppercasesFeeling() async {
        mockService.responseToReturn = makeFixtureResponse()
        await sut.beginSession(planId: 4, actualWeekNumber: 1, feeling: "ok", using: mockService)
        XCTAssertEqual(mockService.lastRequest?.feeling, "OK")
    }

    func test_beginSession_highFeeling_uppercasedToHIGH() async {
        mockService.responseToReturn = makeFixtureResponse()
        await sut.beginSession(planId: 4, actualWeekNumber: 1, feeling: "high", using: mockService)
        XCTAssertEqual(mockService.lastRequest?.feeling, "HIGH")
    }

    func test_beginSession_passesCorrectPlanIdAndWeekNumber() async {
        mockService.responseToReturn = makeFixtureResponse()
        await sut.beginSession(planId: 7, actualWeekNumber: 3, feeling: "low", using: mockService)
        XCTAssertEqual(mockService.lastRequest?.planId, 7)
        XCTAssertEqual(mockService.lastRequest?.actualWeekNumber, 3)
    }

    // MARK: - beginSession: failure

    func test_beginSession_serverError_setsFailedState() async {
        mockService.errorToThrow = WorkoutPlanError.serverError(500)
        await sut.beginSession(planId: 4, actualWeekNumber: 1, feeling: "ok", using: mockService)
        if case .failed = sut.loadState { /* ✅ */ } else {
            XCTFail("Expected .failed, got \(sut.loadState)")
        }
    }

    func test_beginSession_networkError_setsFailedState() async {
        mockService.errorToThrow = WorkoutPlanError.networkError(URLError(.notConnectedToInternet))
        await sut.beginSession(planId: 4, actualWeekNumber: 1, feeling: "ok", using: mockService)
        if case .failed = sut.loadState { /* ✅ */ } else {
            XCTFail("Expected .failed, got \(sut.loadState)")
        }
    }

    func test_beginSession_failure_isSubmittingFalseAfter() async {
        mockService.errorToThrow = WorkoutPlanError.serverError(400)
        await sut.beginSession(planId: 4, actualWeekNumber: 1, feeling: "ok", using: mockService)
        XCTAssertFalse(sut.isSubmitting)
    }

    func test_beginSession_failure_sessionResponseNil() async {
        mockService.errorToThrow = WorkoutPlanError.serverError(500)
        await sut.beginSession(planId: 4, actualWeekNumber: 1, feeling: "ok", using: mockService)
        XCTAssertNil(sut.sessionResponse)
    }

    func test_beginSession_failure_errorMessageNotEmpty() async {
        mockService.errorToThrow = WorkoutPlanError.serverError(500)
        await sut.beginSession(planId: 4, actualWeekNumber: 1, feeling: "ok", using: mockService)
        if case .failed(let msg) = sut.loadState {
            XCTAssertFalse(msg.isEmpty)
        } else {
            XCTFail("Expected .failed")
        }
    }

    // MARK: - Re-entry guard

    func test_beginSession_reentryGuard_doesNotCallServiceTwice() async {
        sut.loadState = .submitting
        await sut.beginSession(planId: 4, actualWeekNumber: 1, feeling: "ok", using: mockService)
        XCTAssertEqual(mockService.callCount, 0, "Re-entry while submitting must be blocked")
    }

    // MARK: - toWorkoutSession mapping

    func test_fixtureResponse_toWorkoutSession_mapsExercises() {
        let response = makeFixtureResponse()
        let session = response.toWorkoutSession()
        XCTAssertEqual(session.exercises.count, 1)
        XCTAssertEqual(session.exercises[0].name, "Bench Press")
        XCTAssertEqual(session.exercises[0].sets.count, 2)
        XCTAssertEqual(session.exercises[0].restSeconds, 90)
    }

    func test_fixtureResponse_toWorkoutSession_mapsPlanName() {
        let response = makeFixtureResponse()
        let session = response.toWorkoutSession()
        XCTAssertEqual(session.name, "Push Day")
    }

    func test_fixtureResponse_toWorkoutSession_mapsWorkExecutionId() {
        let response = makeFixtureResponse()
        let session = response.toWorkoutSession()
        XCTAssertEqual(session.id, 9)
    }

    func test_fixtureResponse_toWorkoutSession_sortsByOrderIndex() {
        let sets = [
            TargetSet(targetSetId: 2, orderIndex: 2, targetReps: 6, targetWeight: 70),
            TargetSet(targetSetId: 1, orderIndex: 1, targetReps: 8, targetWeight: 60)
        ]
        let block = ExerciseBlockPlan(
            exerciseBlockPlanId: 1, exerciseBlockExecutionId: 301, exerciseId: 113, exerciseName: "Bench Press",
            orderIndex: 1, restSeconds: 90, isOptional: false, numberOfSets: 2, targetSets: sets
        )
        let response = StartWorkoutResponse(
            workExecutionId: 9, workoutPlanId: 188, workoutPlanName: "Push Day",
            totalNumberOfSets: 2, exerciseBlockPlans: [block]
        )
        let session = response.toWorkoutSession()
        XCTAssertEqual(session.exercises[0].sets[0].targetReps, 8, "orderIndex 1 should be first")
        XCTAssertEqual(session.exercises[0].sets[1].targetReps, 6, "orderIndex 2 should be second")
    }

    // MARK: - Helpers

    private func makeFixtureResponse() -> StartWorkoutResponse {
        let sets = [
            TargetSet(targetSetId: 1, orderIndex: 1, targetReps: 8, targetWeight: 80),
            TargetSet(targetSetId: 2, orderIndex: 2, targetReps: 8, targetWeight: 80)
        ]
        let block = ExerciseBlockPlan(
            exerciseBlockPlanId: 72, exerciseBlockExecutionId: 301, exerciseId: 113, exerciseName: "Bench Press",
            orderIndex: 1, restSeconds: 90, isOptional: false, numberOfSets: 2, targetSets: sets
        )
        return StartWorkoutResponse(
            workExecutionId: 9, workoutPlanId: 4, workoutPlanName: "Push Day",
            totalNumberOfSets: 2, exerciseBlockPlans: [block]
        )
    }
}

// MARK: - MockWorkoutExecutionService

@MainActor
final class MockWorkoutExecutionService: WorkoutExecutionServiceProtocol {
    var responseToReturn: StartWorkoutResponse?
    var errorToThrow: Error?
    var lastRequest: StartSessionRequest?
    var callCount = 0

    func startSession(_ request: StartSessionRequest) async throws -> StartWorkoutResponse {
        callCount += 1
        lastRequest = request
        if let error = errorToThrow { throw error }
        return responseToReturn!
    }
}
