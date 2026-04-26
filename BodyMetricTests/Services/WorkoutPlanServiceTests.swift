import XCTest
@testable import BodyMetric

/// Unit tests for WorkoutPlanService.
///
/// Constitution Principle II: written before implementation (TDD).
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
        [{
            "planId": 7,
            "plannedWeekNumber": 7,
            "plannedDayOfWeek": "sunday",
            "executionCount": 0,
            "dayNames": ["Costa e bíceps"],
            "totalExercises": 0,
            "totalSets": 0,
            "estimatedDurationMinutes": 0
        }]
        """.data(using: .utf8)!
        mockClient.responseData = json
        mockClient.responseStatus = 200

        let result = try await sut.fetchDays()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].planId, 7)
        XCTAssertEqual(result[0].plannedWeekNumber, 7)
        XCTAssertEqual(result[0].plannedDayOfWeek, "sunday")
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
        mockClient.responseData = Data()
        mockClient.responseStatus = 201

        let days = [
            WorkoutPlanDayRequest(plannedWeekNumber: "1", plannedDayOfWeek: "monday"),
            WorkoutPlanDayRequest(plannedWeekNumber: "7", plannedDayOfWeek: "sunday"),
        ]
        // Should not throw
        try await sut.saveDays(days)
    }

    func test_saveDays_201_sendsCorrectJSONBody() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 201

        let days = [WorkoutPlanDayRequest(plannedWeekNumber: "3", plannedDayOfWeek: "wednesday")]
        try await sut.saveDays(days)

        let capturedRequest = try XCTUnwrap(mockClient.capturedRequests.last)
        XCTAssertEqual(capturedRequest.httpMethod, "POST")
        let body = try XCTUnwrap(capturedRequest.httpBodyData)
        let decoded = try JSONDecoder().decode([WorkoutPlanDayRequest].self, from: body)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].plannedWeekNumber, "3")
        XCTAssertEqual(decoded[0].plannedDayOfWeek, "wednesday")
    }

    // MARK: - saveDays: server error

    func test_saveDays_400_throwsServerError() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 400

        let days = [WorkoutPlanDayRequest(plannedWeekNumber: "1", plannedDayOfWeek: "monday")]

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

        let days = [WorkoutPlanDayRequest(plannedWeekNumber: "1", plannedDayOfWeek: "monday")]

        do {
            try await sut.saveDays(days)
            XCTFail("Expected WorkoutPlanError.serverError")
        } catch WorkoutPlanError.serverError(let code) {
            XCTAssertEqual(code, 500)
        }
    }
}

// MARK: - URLRequest body helper

private extension URLRequest {
    var httpBodyData: Data? {
        // For tests, the body may be in httpBodyStream
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
