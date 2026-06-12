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

        XCTAssertEqual(result.workExecutionId, 9)
        XCTAssertEqual(result.workoutPlanId, 188)
        XCTAssertEqual(result.workoutPlanName, "Push Day")
        XCTAssertEqual(result.totalNumberOfSets, 4)
        XCTAssertEqual(result.exerciseBlockPlans.count, 1)
        XCTAssertEqual(result.exerciseBlockPlans[0].targetSets.count, 2)
        XCTAssertEqual(result.exerciseBlockPlans[0].exerciseName, "Inverted Row")
    }

    func test_startSession_201_doesNotThrow() async throws {
        mockClient.responseData = fixtureJSON
        mockClient.responseStatus = 201

        let result = try await sut.startSession(fixtureRequest)
        XCTAssertEqual(result.workExecutionId, 9)
    }

    func test_startSession_decodesTargetSets() async throws {
        mockClient.responseData = fixtureJSON
        mockClient.responseStatus = 200

        let result = try await sut.startSession(fixtureRequest)
        let firstSet = result.exerciseBlockPlans[0].targetSets.first
        XCTAssertEqual(firstSet?.targetReps, 8)
        XCTAssertEqual(firstSet?.targetWeight, 60.0)
    }

    func test_startSession_decodesIsOptional() async throws {
        mockClient.responseData = fixtureJSON
        mockClient.responseStatus = 200

        let result = try await sut.startSession(fixtureRequest)
        XCTAssertFalse(result.exerciseBlockPlans[0].isOptional)
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
        XCTAssertEqual(decoded.planId, 188)
        XCTAssertEqual(decoded.actualWeekNumber, 1)
    }

    // MARK: - Helpers

    private var fixtureRequest: StartSessionRequest {
        StartSessionRequest(planId: 188, actualWeekNumber: 1, feeling: "OK")
    }

    private var fixtureJSON: Data {
        """
        {
          "workExecutionId": 9,
          "workoutPlanId": 188,
          "workoutPlanName": "Push Day",
          "totalNumberOfSets": 4,
          "exerciseBlockPlans": [
            {
              "exerciseBlockPlanId": 72,
              "exerciseBlockExecutionId": 301,
              "exerciseId": 113,
              "exerciseName": "Inverted Row",
              "orderIndex": 1,
              "restSeconds": 90,
              "isOptional": false,
              "numberOfSets": 4,
              "targetSets": [
                {"targetSetId": 109, "orderIndex": 1, "targetReps": 8, "targetWeight": 60.0},
                {"targetSetId": 110, "orderIndex": 2, "targetReps": 8, "targetWeight": 60.0}
              ]
            }
          ]
        }
        """.data(using: .utf8)!
    }
}
