import XCTest
@testable import BodyMetric

/// Unit tests for WorkoutDayPlanService.
///
/// Feature 013: saveDayPlan now accepts a unified request with embedded exerciseBlocks.
/// saveExerciseBlock has been removed (exercise blocks are nested in the day request).
/// Accepts both 200 and 201 as success responses.
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

    // MARK: - saveDayPlan: success (Void return)

    func test_saveDayPlan_201_doesNotThrow() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 201

        let request = makeRequest(name: "Peito e Tríceps")
        try await sut.saveDayPlan(workoutPlanId: 7, request: request)
    }

    func test_saveDayPlan_200_doesNotThrow() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 200

        let request = makeRequest(name: "Back Day")
        try await sut.saveDayPlan(workoutPlanId: 7, request: request)
    }

    func test_saveDayPlan_sendsCorrectURL() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 201

        let request = makeRequest(name: "Back")
        try await sut.saveDayPlan(workoutPlanId: 99, request: request)

        let url = mockClient.capturedRequests.last?.url?.absoluteString
        XCTAssertTrue(url?.contains("/api/workout-plans/99/days") == true,
                      "URL must contain correct path with workoutPlanId")
    }

    func test_saveDayPlan_sendsPostMethod() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 201

        let request = makeRequest(name: "Test")
        try await sut.saveDayPlan(workoutPlanId: 1, request: request)

        XCTAssertEqual(mockClient.capturedRequests.last?.httpMethod, "POST")
    }

    func test_saveDayPlan_requestBodyContainsExerciseBlocks() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 201

        var block = ExerciseBlock()
        block.exerciseId = "26"
        block.sets = [SetConfig(targetReps: 12, targetWeight: 80)]
        block.restSeconds = 60
        let blockRequest = ExerciseBlockRequest(block: block, orderIndex: 1)
        let request = WorkoutDayPlanRequest(
            name: "Chest Day",
            orderIndex: 0,
            isActive: true,
            exerciseBlocks: [blockRequest]
        )
        try await sut.saveDayPlan(workoutPlanId: 1, request: request)

        let body = try XCTUnwrap(mockClient.capturedRequests.last?.httpBody)
        let decoded = try JSONDecoder().decode(WorkoutDayPlanRequest.self, from: body)
        XCTAssertEqual(decoded.exerciseBlocks.count, 1)
        XCTAssertEqual(decoded.exerciseBlocks[0].exerciseId, 26)
        XCTAssertEqual(decoded.exerciseBlocks[0].targetSets[0].targetReps, 12)
    }

    // MARK: - saveDayPlan: errors

    func test_saveDayPlan_404_throwsServerError() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 404

        let request = makeRequest(name: "Test")
        do {
            try await sut.saveDayPlan(workoutPlanId: 1, request: request)
            XCTFail("Expected WorkoutPlanError.serverError")
        } catch WorkoutPlanError.serverError(let code) {
            XCTAssertEqual(code, 404)
        }
    }

    func test_saveDayPlan_500_throwsServerError() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 500

        let request = makeRequest(name: "Test")
        do {
            try await sut.saveDayPlan(workoutPlanId: 1, request: request)
            XCTFail("Expected WorkoutPlanError.serverError")
        } catch WorkoutPlanError.serverError(let code) {
            XCTAssertEqual(code, 500)
        }
    }

    // MARK: - Helpers

    private func makeRequest(name: String) -> WorkoutDayPlanRequest {
        WorkoutDayPlanRequest(name: name, orderIndex: 0, isActive: true, exerciseBlocks: [])
    }
}
