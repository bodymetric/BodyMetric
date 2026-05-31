import XCTest
@testable import BodyMetric

/// Unit tests for WorkoutPlanService.
///
/// Feature 014: `plannedWeekNumber` removed from all payloads.
/// Uses MockNetworkClient from TestHelpers — no real network.
@MainActor
final class WorkoutPlanServiceTests: XCTestCase {

    private var sut: WorkoutPlanService!
    private var mockClient: MockNetworkClient!

    private let planURL = URL(string: "https://api.bodymetric.com.br/api/workout-plans")!

    override func setUp() async throws {
        try await super.setUp()
        mockClient = MockNetworkClient()
        sut = WorkoutPlanService(networkClient: mockClient)
    }

    override func tearDown() async throws {
        sut = nil
        mockClient = nil
        try await super.tearDown()
    }

    // MARK: - fetchDays: success

    func test_fetchDays_200_returnsDecodedArray() async throws {
        let json = """
        [{"planId":7,"plannedDayOfWeek":"SUNDAY","executionCount":0,"dayNames":[],"totalExercises":0,"totalSets":0,"estimatedDurationMinutes":0}]
        """.data(using: .utf8)!
        mockClient.responseData = json
        mockClient.responseStatus = 200

        let result = try await sut.fetchDays()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].planId, 7)
        XCTAssertEqual(result[0].plannedDayOfWeek, "SUNDAY")
    }

    func test_fetchDays_200_withActualWeekNumber_decodesCorrectly() async throws {
        let json = """
        [{"planId":7,"plannedDayOfWeek":"SUNDAY","executionCount":0,"dayNames":[],"totalExercises":0,"totalSets":0,"estimatedDurationMinutes":0,"actualWeekNumber":3}]
        """.data(using: .utf8)!
        mockClient.responseData = json
        mockClient.responseStatus = 200

        let result = try await sut.fetchDays()

        XCTAssertEqual(result[0].actualWeekNumber, 3)
    }

    func test_fetchDays_200_missingActualWeekNumber_decodesAsNil() async throws {
        let json = """
        [{"planId":7,"plannedDayOfWeek":"SUNDAY","executionCount":0,"dayNames":[],"totalExercises":0,"totalSets":0,"estimatedDurationMinutes":0}]
        """.data(using: .utf8)!
        mockClient.responseData = json
        mockClient.responseStatus = 200

        let result = try await sut.fetchDays()

        XCTAssertNil(result[0].actualWeekNumber)
    }

    func test_fetchDays_200_emptyArray_returnsEmpty() async throws {
        mockClient.responseData = "[]".data(using: .utf8)!
        mockClient.responseStatus = 200

        let result = try await sut.fetchDays()
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - fetchDays: 404 → notFound

    func test_fetchDays_404_throwsNotFound() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 404

        do {
            _ = try await sut.fetchDays()
            XCTFail("Expected WorkoutPlanError.notFound")
        } catch WorkoutPlanError.notFound {
            // ✅ expected
        }
    }

    // MARK: - fetchDays: server error

    func test_fetchDays_500_throwsServerError() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 500

        do {
            _ = try await sut.fetchDays()
            XCTFail("Expected WorkoutPlanError.serverError")
        } catch WorkoutPlanError.serverError(let code) {
            XCTAssertEqual(code, 500)
        }
    }

    // MARK: - fetchDays: decode error

    func test_fetchDays_200_malformedJSON_throwsDecodingError() async throws {
        mockClient.responseData = "not-json".data(using: .utf8)!
        mockClient.responseStatus = 200

        do {
            _ = try await sut.fetchDays()
            XCTFail("Expected WorkoutPlanError.decodingError")
        } catch WorkoutPlanError.decodingError {
            // ✅ expected
        }
    }

    // MARK: - fetchDays: network error

    func test_fetchDays_networkError_throwsNetworkError() async throws {
        mockClient.errorToThrow = URLError(.notConnectedToInternet)

        do {
            _ = try await sut.fetchDays()
            XCTFail("Expected WorkoutPlanError.networkError")
        } catch WorkoutPlanError.networkError {
            // ✅ expected
        }
    }

    // MARK: - saveDays: success

    func test_saveDays_201_doesNotThrow() async throws {
        let json = """
        [{"planId":1,"plannedDayOfWeek":"MONDAY","executionCount":0,"dayNames":[],"totalExercises":0,"totalSets":0,"estimatedDurationMinutes":0}]
        """.data(using: .utf8)!
        mockClient.responseData = json
        mockClient.responseStatus = 201

        let days = [
            WorkoutPlanDayRequest(plannedDayOfWeek: "monday"),
            WorkoutPlanDayRequest(plannedDayOfWeek: "sunday"),
        ]
        let result = try await sut.saveDays(days)
        XCTAssertFalse(result.isEmpty, "saveDays must return decoded [WorkoutPlanDayResponse]")
    }

    func test_saveDays_201_returnsDecodedDayResponses() async throws {
        let json = """
        [{"planId":7,"plannedDayOfWeek":"SUNDAY","executionCount":0,"dayNames":[],"totalExercises":0,"totalSets":0,"estimatedDurationMinutes":0}]
        """.data(using: .utf8)!
        mockClient.responseData = json
        mockClient.responseStatus = 201

        let days = [WorkoutPlanDayRequest(plannedDayOfWeek: "sunday")]
        let result = try await sut.saveDays(days)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].planId, 7)
    }

    func test_saveDays_201_sendsCorrectJSONBody() async throws {
        let json = """
        [{"planId":3,"plannedDayOfWeek":"WEDNESDAY","executionCount":0,"dayNames":[],"totalExercises":0,"totalSets":0,"estimatedDurationMinutes":0}]
        """.data(using: .utf8)!
        mockClient.responseData = json
        mockClient.responseStatus = 201

        let days = [WorkoutPlanDayRequest(plannedDayOfWeek: "wednesday")]
        _ = try await sut.saveDays(days)

        let capturedRequest = try XCTUnwrap(mockClient.capturedRequests.last)
        XCTAssertEqual(capturedRequest.httpMethod, "POST")
        let body = try XCTUnwrap(capturedRequest.httpBodyData)
        let decoded = try JSONDecoder().decode([WorkoutPlanDayRequest].self, from: body)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].plannedDayOfWeek, "wednesday")
    }

    // MARK: - saveDays: server error

    func test_saveDays_400_throwsServerError() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 400

        let days = [WorkoutPlanDayRequest(plannedDayOfWeek: "monday")]

        do {
            try await sut.saveDays(days)
            XCTFail("Expected WorkoutPlanError.serverError")
        } catch WorkoutPlanError.serverError(let code) {
            XCTAssertEqual(code, 400)
        }
    }

    func test_saveDays_500_throwsServerError() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 500

        let days = [WorkoutPlanDayRequest(plannedDayOfWeek: "monday")]

        do {
            try await sut.saveDays(days)
            XCTFail("Expected WorkoutPlanError.serverError")
        } catch WorkoutPlanError.serverError(let code) {
            XCTAssertEqual(code, 500)
        }
    }

    // MARK: - fetchCurrentPlan: success

    func test_fetchCurrentPlan_200_decodesCorrectly() async throws {
        let json = """
        {
          "id": 123,
          "days": [
            {
              "id": 456,
              "plannedDayOfWeek": "MONDAY",
              "name": "Chest Day",
              "orderIndex": 0,
              "exerciseBlocks": [
                {
                  "exerciseId": 26,
                  "orderIndex": 1,
                  "restSeconds": 90,
                  "targetSets": [{"orderIndex": 1, "targetReps": 10, "targetWeight": 60.0}]
                }
              ]
            }
          ]
        }
        """.data(using: .utf8)!
        mockClient.responseData = json
        mockClient.responseStatus = 200

        let result = try await sut.fetchCurrentPlan()

        XCTAssertEqual(result.id, 123)
        XCTAssertEqual(result.days.count, 1)
        XCTAssertEqual(result.days[0].id, 456)
        XCTAssertEqual(result.days[0].plannedDayOfWeek, "MONDAY")
        XCTAssertEqual(result.days[0].name, "Chest Day")
        XCTAssertEqual(result.days[0].exerciseBlocks[0].exerciseId, 26)
        XCTAssertEqual(result.days[0].exerciseBlocks[0].targetSets[0].targetReps, 10)
        XCTAssertEqual(result.days[0].exerciseBlocks[0].targetSets[0].targetWeight, 60.0)
    }

    func test_fetchCurrentPlan_404_throwsNotFound() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 404

        do {
            _ = try await sut.fetchCurrentPlan()
            XCTFail("Expected WorkoutPlanError.notFound")
        } catch WorkoutPlanError.notFound {
            // ✅
        }
    }

    func test_fetchCurrentPlan_500_throwsServerError() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 500

        do {
            _ = try await sut.fetchCurrentPlan()
            XCTFail("Expected WorkoutPlanError.serverError")
        } catch WorkoutPlanError.serverError(let code) {
            XCTAssertEqual(code, 500)
        }
    }

    func test_fetchCurrentPlan_sendsGETRequestToCurrentEndpoint() async throws {
        let json = """
        {"id": 1, "days": []}
        """.data(using: .utf8)!
        mockClient.responseData = json
        mockClient.responseStatus = 200

        _ = try await sut.fetchCurrentPlan()

        XCTAssertEqual(mockClient.capturedRequests.last?.httpMethod, "GET")
        let url = mockClient.capturedRequests.last?.url?.absoluteString
        XCTAssertTrue(url?.contains("/workout-plans/current") == true)
    }

    func test_fetchCurrentPlan_networkError_throwsNetworkError() async throws {
        mockClient.errorToThrow = URLError(.notConnectedToInternet)

        do {
            _ = try await sut.fetchCurrentPlan()
            XCTFail("Expected WorkoutPlanError.networkError")
        } catch WorkoutPlanError.networkError {
            // ✅
        }
    }

    // MARK: - updatePlan: success

    func test_updatePlan_200_doesNotThrow() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 200

        let request = UpdateWorkoutPlanRequest(days: [])
        try await sut.updatePlan(id: 123, request: request)
        // no throw = pass
    }

    func test_updatePlan_204_doesNotThrow() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 204

        let request = UpdateWorkoutPlanRequest(days: [])
        try await sut.updatePlan(id: 123, request: request)
    }

    func test_updatePlan_400_throwsServerError() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 400

        let request = UpdateWorkoutPlanRequest(days: [])
        do {
            try await sut.updatePlan(id: 123, request: request)
            XCTFail("Expected WorkoutPlanError.serverError")
        } catch WorkoutPlanError.serverError(let code) {
            XCTAssertEqual(code, 400)
        }
    }

    func test_updatePlan_sendsPUTRequestWithCorrectPlanId() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 200

        let request = UpdateWorkoutPlanRequest(days: [])
        try await sut.updatePlan(id: 123, request: request)

        XCTAssertEqual(mockClient.capturedRequests.last?.httpMethod, "PUT")
        let url = mockClient.capturedRequests.last?.url?.absoluteString
        XCTAssertTrue(url?.contains("/workout-plans/123") == true)
    }

    func test_updatePlan_networkError_throwsNetworkError() async throws {
        mockClient.errorToThrow = URLError(.notConnectedToInternet)

        let request = UpdateWorkoutPlanRequest(days: [])
        do {
            try await sut.updatePlan(id: 123, request: request)
            XCTFail("Expected WorkoutPlanError.networkError")
        } catch WorkoutPlanError.networkError {
            // ✅
        }
    }
}

// MARK: - URLRequest body helper

private extension URLRequest {
    var httpBodyData: Data? {
        if let data = httpBody { return data }
        guard let stream = httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: bufferSize)
            if count > 0 { data.append(contentsOf: buffer[0..<count]) }
        }
        return data
    }
}
