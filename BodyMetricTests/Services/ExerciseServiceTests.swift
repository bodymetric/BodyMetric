import XCTest
@testable import BodyMetric

/// Unit tests for ExerciseService.
///
/// Constitution Principle II: written before implementation (TDD).
/// Uses MockNetworkClient from TestHelpers — no real network.
@MainActor
final class ExerciseServiceTests: XCTestCase {

    private var sut: ExerciseService!
    private var mockClient: MockNetworkClient!

    override func setUp() async throws {
        try await super.setUp()
        mockClient = MockNetworkClient()
        sut = ExerciseService(networkClient: mockClient)
    }

    override func tearDown() async throws {
        sut = nil
        mockClient = nil
        try await super.tearDown()
    }

    // MARK: - fetchExerciseCatalog: success

    func test_fetchExerciseCatalog_200_returnsDecodedGroups() async throws {
        let json = """
        [{"group":"back","exercises":[{"id":26,"name":"Back Extension"},{"id":17,"name":"Barbell Row"}]},
         {"group":"biceps","exercises":[{"id":56,"name":"Barbell Curl"}]}]
        """.data(using: .utf8)!
        mockClient.responseData = json
        mockClient.responseStatus = 200

        let result = try await sut.fetchExerciseCatalog()

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].group, "back")
        XCTAssertEqual(result[0].exercises.count, 2)
        XCTAssertEqual(result[0].exercises[0].id, 26)
        XCTAssertEqual(result[0].exercises[0].name, "Back Extension")
        XCTAssertEqual(result[1].group, "biceps")
        XCTAssertEqual(result[1].exercises[0].id, 56)
    }

    func test_fetchExerciseCatalog_200_emptyArray_returnsEmpty() async throws {
        mockClient.responseData = "[]".data(using: .utf8)!
        mockClient.responseStatus = 200

        let result = try await sut.fetchExerciseCatalog()
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - fetchExerciseCatalog: error

    func test_fetchExerciseCatalog_500_throwsServerError() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 500

        do {
            _ = try await sut.fetchExerciseCatalog()
            XCTFail("Expected WorkoutPlanError.serverError")
        } catch WorkoutPlanError.serverError(let code) {
            XCTAssertEqual(code, 500)
        }
    }

    func test_fetchExerciseCatalog_404_throwsServerError() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 404

        do {
            _ = try await sut.fetchExerciseCatalog()
            XCTFail("Expected WorkoutPlanError.serverError")
        } catch WorkoutPlanError.serverError(let code) {
            XCTAssertEqual(code, 404)
        }
    }

    func test_fetchExerciseCatalog_networkError_throws() async throws {
        mockClient.errorToThrow = URLError(.notConnectedToInternet)

        do {
            _ = try await sut.fetchExerciseCatalog()
            XCTFail("Expected error")
        } catch WorkoutPlanError.networkError {
            // ✅ expected
        }
    }

    func test_fetchExerciseCatalog_malformedJSON_throwsDecodingError() async throws {
        mockClient.responseData = "not-json".data(using: .utf8)!
        mockClient.responseStatus = 200

        do {
            _ = try await sut.fetchExerciseCatalog()
            XCTFail("Expected WorkoutPlanError.decodingError")
        } catch WorkoutPlanError.decodingError {
            // ✅ expected
        }
    }

    func test_fetchExerciseCatalog_sendsGETRequest() async throws {
        mockClient.responseData = "[]".data(using: .utf8)!
        mockClient.responseStatus = 200

        _ = try await sut.fetchExerciseCatalog()

        XCTAssertEqual(mockClient.capturedRequests.last?.httpMethod, "GET")
        let url = mockClient.capturedRequests.last?.url?.absoluteString
        XCTAssertTrue(url?.contains("/api/exercises") == true)
    }
}
