import XCTest
@testable import BodyMetric

/// Unit tests for PerformedSetService.
///
/// Constitution Principle II: TDD — covers all LoadState transitions.
/// Uses MockNetworkClient — no real network.
@MainActor
final class PerformedSetServiceTests: XCTestCase {

    private var sut: PerformedSetService!
    private var mockClient: MockNetworkClient!

    override func setUp() async throws {
        try await super.setUp()
        mockClient = MockNetworkClient()
        sut = PerformedSetService(networkClient: mockClient)
    }

    override func tearDown() async throws {
        sut = nil
        mockClient = nil
        try await super.tearDown()
    }

    // MARK: - Success

    func test_logPerformedSet_200_doesNotThrow() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 200

        try await sut.logPerformedSet(exerciseBlockExecutionId: 123, weight: 70.0, reps: 8)
    }

    func test_logPerformedSet_201_doesNotThrow() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 201

        try await sut.logPerformedSet(exerciseBlockExecutionId: 123, weight: 70.0, reps: 8)
    }

    // MARK: - Errors

    func test_logPerformedSet_400_throwsServerError() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 400

        do {
            try await sut.logPerformedSet(exerciseBlockExecutionId: 123, weight: 70.0, reps: 8)
            XCTFail("Expected WorkoutPlanError.serverError")
        } catch WorkoutPlanError.serverError(let code) {
            XCTAssertEqual(code, 400)
        }
    }

    func test_logPerformedSet_500_throwsServerError() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 500

        do {
            try await sut.logPerformedSet(exerciseBlockExecutionId: 123, weight: 70.0, reps: 8)
            XCTFail("Expected WorkoutPlanError.serverError")
        } catch WorkoutPlanError.serverError(let code) {
            XCTAssertEqual(code, 500)
        }
    }

    func test_logPerformedSet_networkError_throwsNetworkError() async throws {
        mockClient.errorToThrow = URLError(.notConnectedToInternet)

        do {
            try await sut.logPerformedSet(exerciseBlockExecutionId: 123, weight: 70.0, reps: 8)
            XCTFail("Expected WorkoutPlanError.networkError")
        } catch WorkoutPlanError.networkError {
            // ✅
        }
    }

    // MARK: - Request shape

    func test_logPerformedSet_sendsPOSTToCorrectURL() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 200

        try await sut.logPerformedSet(exerciseBlockExecutionId: 123, weight: 70.0, reps: 8)

        XCTAssertEqual(mockClient.capturedRequests.last?.httpMethod, "POST")
        let url = mockClient.capturedRequests.last?.url?.absoluteString
        XCTAssertTrue(url?.contains("/exercise-block-executions/123/performed-sets") == true)
    }

    func test_logPerformedSet_requestBodyContainsWeightAndReps() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 200

        try await sut.logPerformedSet(exerciseBlockExecutionId: 123, weight: 70.0, reps: 8)

        let bodyData = mockClient.capturedRequests.last?.httpBodyData
        let decoded = try XCTUnwrap(bodyData.flatMap { try? JSONDecoder().decode(LogPerformedSetRequest.self, from: $0) })
        XCTAssertEqual(decoded.weight, 70.0)
        XCTAssertEqual(decoded.reps, 8)
    }
}
