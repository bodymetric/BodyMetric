import XCTest
@testable import BodyMetric

/// Unit tests for WorkoutExecutionService.
///
/// Constitution Principle II: written alongside implementation (TDD).
/// Uses MockNetworkClient — no real network.
@MainActor
final class WorkoutExecutionServiceTests: XCTestCase {

    private var sut: WorkoutExecutionService!
    private var mockClient: MockNetworkClient!

    override func setUp() async throws {
        try await super.setUp()
        mockClient = MockNetworkClient()
        sut = WorkoutExecutionService(networkClient: mockClient)
    }

    override func tearDown() async throws {
        sut = nil
        mockClient = nil
        try await super.tearDown()
    }

    // MARK: - startSession: success

    func test_startSession_200_decodesResponse() async throws {
        mockClient.responseData = fixtureJSON
        mockClient.responseStatus = 200

        let result = try await sut.startSession(fixtureRequest)

        XCTAssertEqual(result.id, "exec-1")
        XCTAssertEqual(result.planId, 4)
        XCTAssertEqual(result.actualWeekNumber, 1)
        XCTAssertEqual(result.feeling, "OK")
        XCTAssertEqual(result.exercises.count, 1)
        XCTAssertEqual(result.exercises[0].sets.count, 2)
        XCTAssertEqual(result.exercises[0].name, "Bench Press")
    }

    func test_startSession_201_doesNotThrow() async throws {
        mockClient.responseData = fixtureJSON
        mockClient.responseStatus = 201

        let result = try await sut.startSession(fixtureRequest)
        XCTAssertEqual(result.id, "exec-1")
    }

    func test_startSession_decodesExercisePR() async throws {
        let json = """
        {
          "id": "exec-2", "planId": 4, "actualWeekNumber": 1, "feeling": "HIGH",
          "exercises": [{
            "id": "ex-1", "name": "Bench Press", "muscle": "Chest", "restSeconds": 120,
            "sets": [{"targetReps": 8, "prevWeight": 80.0, "prevReps": 8}],
            "pr": {"weight": 82.5, "reps": 6}
          }]
        }
        """.data(using: .utf8)!
        mockClient.responseData = json
        mockClient.responseStatus = 200

        let result = try await sut.startSession(fixtureRequest)
        XCTAssertEqual(result.exercises[0].pr?.weight, 82.5)
        XCTAssertEqual(result.exercises[0].pr?.reps, 6)
    }

    // MARK: - startSession: errors

    func test_startSession_400_throwsServerError() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 400

        do {
            _ = try await sut.startSession(fixtureRequest)
            XCTFail("Expected WorkoutPlanError.serverError")
        } catch WorkoutPlanError.serverError(let code) {
            XCTAssertEqual(code, 400)
        }
    }

    func test_startSession_500_throwsServerError() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 500

        do {
            _ = try await sut.startSession(fixtureRequest)
            XCTFail("Expected WorkoutPlanError.serverError")
        } catch WorkoutPlanError.serverError(let code) {
            XCTAssertEqual(code, 500)
        }
    }

    func test_startSession_networkError_throwsNetworkError() async throws {
        mockClient.errorToThrow = URLError(.notConnectedToInternet)

        do {
            _ = try await sut.startSession(fixtureRequest)
            XCTFail("Expected WorkoutPlanError.networkError")
        } catch WorkoutPlanError.networkError {
            // ✅
        }
    }

    func test_startSession_malformedJSON_throwsDecodingError() async throws {
        mockClient.responseData = "not-json".data(using: .utf8)!
        mockClient.responseStatus = 200

        do {
            _ = try await sut.startSession(fixtureRequest)
            XCTFail("Expected WorkoutPlanError.decodingError")
        } catch WorkoutPlanError.decodingError {
            // ✅
        }
    }

    // MARK: - startSession: request shape

    func test_startSession_sendsPOSTToCorrectURL() async throws {
        mockClient.responseData = fixtureJSON
        mockClient.responseStatus = 200

        _ = try await sut.startSession(fixtureRequest)

        XCTAssertEqual(mockClient.capturedRequests.last?.httpMethod, "POST")
        let url = mockClient.capturedRequests.last?.url?.absoluteString
        XCTAssertTrue(url?.contains("/work-executions/start") == true)
    }

    func test_startSession_requestBodyContainsFeelingAndPlanId() async throws {
        mockClient.responseData = fixtureJSON
        mockClient.responseStatus = 200

        _ = try await sut.startSession(fixtureRequest)

        let bodyData = mockClient.capturedRequests.last?.httpBodyData
        let decoded = try XCTUnwrap(bodyData.flatMap { try? JSONDecoder().decode(StartSessionRequest.self, from: $0) })
        XCTAssertEqual(decoded.feeling, "OK")
        XCTAssertEqual(decoded.planId, 4)
        XCTAssertEqual(decoded.actualWeekNumber, 1)
    }

    // MARK: - Helpers

    private var fixtureRequest: StartSessionRequest {
        StartSessionRequest(planId: 4, actualWeekNumber: 1, feeling: "OK")
    }

    private var fixtureJSON: Data {
        """
        {
          "id": "exec-1",
          "planId": 4,
          "actualWeekNumber": 1,
          "feeling": "OK",
          "exercises": [
            {
              "id": "ex-1",
              "name": "Bench Press",
              "muscle": "Chest",
              "restSeconds": 90,
              "sets": [
                {"targetReps": 8, "prevWeight": 80.0, "prevReps": 8},
                {"targetReps": 8, "prevWeight": 80.0, "prevReps": 7}
              ],
              "pr": null
            }
          ]
        }
        """.data(using: .utf8)!
    }
}
