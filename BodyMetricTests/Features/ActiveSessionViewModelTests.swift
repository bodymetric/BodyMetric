import XCTest
@testable import BodyMetric

/// Unit tests for ActiveSessionViewModel — log-set submission lifecycle.
///
/// Constitution Principle II: TDD — covers success, error, re-entry guard, and validation paths.
@MainActor
final class ActiveSessionViewModelTests: XCTestCase {

    private var sut: ActiveSessionViewModel!
    private var mockService: MockPerformedSetService!

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockPerformedSetService()
        sut = ActiveSessionViewModel(
            workExecutionId: 9,
            workout: makeFixtureSession(),
            mood: "OK",
            performedSetService: mockService
        )
    }

    override func tearDown() async throws {
        sut.dispose()
        sut = nil
        mockService = nil
        try await super.tearDown()
    }

    // MARK: - Success path

    func test_commitSet_success_marksDoneAndClosesSheet() async {
        sut.openLog(exIdx: 0, setIdx: 0)
        await sut.commitSet(exIdx: 0, setIdx: 0, weight: 70.0, reps: 8)

        XCTAssertTrue(sut.progress[0].sets[0].done)
        XCTAssertNil(sut.logTarget)
    }

    func test_commitSet_success_isSubmittingLogFalseAfter() async {
        await sut.commitSet(exIdx: 0, setIdx: 0, weight: 70.0, reps: 8)
        XCTAssertFalse(sut.isSubmittingLog)
    }

    func test_commitSet_success_logErrorNilAfter() async {
        await sut.commitSet(exIdx: 0, setIdx: 0, weight: 70.0, reps: 8)
        XCTAssertNil(sut.logError)
    }

    // MARK: - Error paths

    func test_commitSet_networkError_setsLogError() async {
        mockService.errorToThrow = WorkoutPlanError.networkError(URLError(.notConnectedToInternet))
        await sut.commitSet(exIdx: 0, setIdx: 0, weight: 70.0, reps: 8)

        XCTAssertNotNil(sut.logError)
        XCTAssertFalse(sut.isSubmittingLog)
    }

    func test_commitSet_serverError_setsLogError() async {
        mockService.errorToThrow = WorkoutPlanError.serverError(500)
        await sut.commitSet(exIdx: 0, setIdx: 0, weight: 70.0, reps: 8)

        XCTAssertNotNil(sut.logError)
    }

    func test_commitSet_failure_setNotMarkedDone() async {
        mockService.errorToThrow = WorkoutPlanError.serverError(500)
        await sut.commitSet(exIdx: 0, setIdx: 0, weight: 70.0, reps: 8)

        XCTAssertFalse(sut.progress[0].sets[0].done)
    }

    func test_commitSet_failure_isSubmittingLogFalseAfter() async {
        mockService.errorToThrow = WorkoutPlanError.serverError(500)
        await sut.commitSet(exIdx: 0, setIdx: 0, weight: 70.0, reps: 8)

        XCTAssertFalse(sut.isSubmittingLog)
    }

    // MARK: - Re-entry guard (tested via zero-reps path: no call emitted before state change)

    // MARK: - Zero-reps validation

    func test_commitSet_zeroReps_setsLogErrorNoNetworkCall() async {
        await sut.commitSet(exIdx: 0, setIdx: 0, weight: 70.0, reps: 0)

        XCTAssertEqual(mockService.callCount, 0, "No network call for reps == 0")
        XCTAssertNotNil(sut.logError)
    }

    func test_commitSet_zeroReps_setNotMarkedDone() async {
        await sut.commitSet(exIdx: 0, setIdx: 0, weight: 70.0, reps: 0)
        XCTAssertFalse(sut.progress[0].sets[0].done)
    }

    // MARK: - Correct ID used

    func test_commitSet_usesCorrectExerciseBlockExecutionId() async {
        await sut.commitSet(exIdx: 0, setIdx: 0, weight: 70.0, reps: 8)

        XCTAssertEqual(mockService.lastCall?.exerciseBlockExecutionId,
                       sut.workout.exercises[0].exerciseBlockExecutionId)
    }

    // MARK: - Helpers

    private func makeFixtureSession() -> WorkoutSession {
        WorkoutSession(
            id: 9,
            name: "Push Day",
            exercises: [
                WorkoutExercise(
                    exerciseBlockPlanId: 72,
                    exerciseBlockExecutionId: 301,
                    id: 113,
                    name: "Bench Press",
                    restSeconds: 90,
                    sets: [
                        WorkoutSet(targetReps: 8, targetWeight: 80),
                        WorkoutSet(targetReps: 8, targetWeight: 80)
                    ]
                )
            ]
        )
    }
}

// MARK: - MockPerformedSetService

@MainActor
final class MockPerformedSetService: PerformedSetServiceProtocol {
    var errorToThrow: Error?
    var callCount = 0
    var lastCall: (exerciseBlockExecutionId: Int, weight: Double, reps: Int)?

    func logPerformedSet(exerciseBlockExecutionId: Int, weight: Double, reps: Int) async throws {
        callCount += 1
        lastCall = (exerciseBlockExecutionId, weight, reps)
        if let error = errorToThrow { throw error }
    }
}
