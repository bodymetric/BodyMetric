import XCTest
@testable import BodyMetric

/// Unit tests for WorkoutDayPlanService.
///
/// Constitution Principle II: written before implementation (TDD).
/// Uses MockNetworkClient from TestHelpers — no real network.
@MainActor
final class WorkoutDayPlanServiceTests: XCTestCase {

    private var sut: WorkoutDayPlanService!
    private var mockClient: MockNetworkClient!

    override func setUp() async throws {
        try await super.setUp()
        mockClient = MockNetworkClient()
        sut = WorkoutDayPlanService(networkClient: mockClient)
    }

    override func tearDown() async throws {
        sut = nil
        mockClient = nil
        try await super.tearDown()
    }

    // MARK: - saveDayPlan: success

    func test_saveDayPlan_201_returnsDecodedResponse() async throws {
        let json = """
        {"workoutDayPlanId": 42}
        """.data(using: .utf8)!
        mockClient.responseData = json
        mockClient.responseStatus = 201

        let request = WorkoutDayPlanRequest(name: "Peito e Tríceps", orderIndex: 0, isActive: true)
        let response = try await sut.saveDayPlan(workoutPlanId: 7, request: request)

        XCTAssertEqual(response.workoutDayPlanId, 42)
    }

    func test_saveDayPlan_201_sendsCorrectURL() async throws {
        let json = """{"workoutDayPlanId": 1}""".data(using: .utf8)!
        mockClient.responseData = json
        mockClient.responseStatus = 201

        let request = WorkoutDayPlanRequest(name: "Back", orderIndex: 0, isActive: true)
        _ = try await sut.saveDayPlan(workoutPlanId: 99, request: request)

        let url = mockClient.capturedRequests.last?.url?.absoluteString
        XCTAssertTrue(url?.contains("/api/workout-plans/99/days") == true,
                      "URL must contain correct path with workoutPlanId")
    }

    func test_saveDayPlan_404_throwsServerError() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 404

        let request = WorkoutDayPlanRequest(name: "Test", orderIndex: 0, isActive: true)
        do {
            _ = try await sut.saveDayPlan(workoutPlanId: 1, request: request)
            XCTFail("Expected WorkoutPlanError.serverError")
        } catch WorkoutPlanError.serverError(let code) {
            XCTAssertEqual(code, 404)
        }
    }

    func test_saveDayPlan_500_throwsServerError() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 500

        let request = WorkoutDayPlanRequest(name: "Test", orderIndex: 0, isActive: true)
        do {
            _ = try await sut.saveDayPlan(workoutPlanId: 1, request: request)
            XCTFail("Expected WorkoutPlanError.serverError")
        } catch WorkoutPlanError.serverError(let code) {
            XCTAssertEqual(code, 500)
        }
    }

    func test_saveDayPlan_sendsPostMethod() async throws {
        mockClient.responseData = """{"workoutDayPlanId": 1}""".data(using: .utf8)!
        mockClient.responseStatus = 201

        let request = WorkoutDayPlanRequest(name: "Test", orderIndex: 0, isActive: true)
        _ = try await sut.saveDayPlan(workoutPlanId: 1, request: request)

        XCTAssertEqual(mockClient.capturedRequests.last?.httpMethod, "POST")
    }

    // MARK: - saveExerciseBlock: success

    func test_saveExerciseBlock_201_doesNotThrow() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 201

        var block = ExerciseBlock()
        block.exerciseId = "bench"
        block.targetReps = 8
        block.targetWeight = 80
        block.restSeconds = 90
        let request = ExerciseBlockPlanRequest(block: block)
        try await sut.saveExerciseBlock(workoutDayPlanId: 42, request: request)
    }

    func test_saveExerciseBlock_201_sendsCorrectURL() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 201

        var block = ExerciseBlock()
        block.exerciseId = "squat"
        let request = ExerciseBlockPlanRequest(block: block)
        try await sut.saveExerciseBlock(workoutDayPlanId: 55, request: request)

        let url = mockClient.capturedRequests.last?.url?.absoluteString
        XCTAssertTrue(url?.contains("/api/workout-day-plans/55/exercise-blocks") == true,
                      "URL must contain correct path with workoutDayPlanId")
    }

    func test_saveExerciseBlock_400_throwsServerError() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 400

        var block = ExerciseBlock()
        block.exerciseId = "bench"
        let request = ExerciseBlockPlanRequest(block: block)
        do {
            try await sut.saveExerciseBlock(workoutDayPlanId: 1, request: request)
            XCTFail("Expected WorkoutPlanError.serverError")
        } catch WorkoutPlanError.serverError(let code) {
            XCTAssertEqual(code, 400)
        }
    }
}
