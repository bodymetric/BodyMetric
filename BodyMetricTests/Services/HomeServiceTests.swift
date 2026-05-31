import XCTest
@testable import BodyMetric

/// Unit tests for HomeService.
///
/// Constitution Principle II: written before implementation (TDD).
@MainActor
final class HomeServiceTests: XCTestCase {

    private var sut: HomeService!
    private var mockClient: MockNetworkClient!

    override func setUp() async throws {
        try await super.setUp()
        mockClient = MockNetworkClient()
        sut = HomeService(networkClient: mockClient)
    }

    override func tearDown() async throws {
        sut = nil
        mockClient = nil
        try await super.tearDown()
    }

    // MARK: - fetchHomeData: success with plan

    func test_fetchHomeData_200_withPlan_returnsData() async throws {
        let json = """
        {
          "currentWorkoutDayPlan": {
            "id": 7,
            "name": "Peito e Tríceps",
            "dayOfWeek": "SUNDAY",
            "numberOfExercisesTotal": 3,
            "numberSetsTotal": 9,
            "timeEstimateToFinish": 45
          },
          "exercisesForToday": [
            {
              "id": 26, "name": "Bench Press", "orderIndex": 1,
              "sets": [{"orderIndex": 1, "targetReps": 12, "targetWeight": 25.0}]
            },
            {
              "id": 17, "name": "Tricep Extension", "orderIndex": 2,
              "sets": []
            }
          ]
        }
        """.data(using: .utf8)!
        mockClient.responseData = json
        mockClient.responseStatus = 200

        let result = try await sut.fetchHomeData()

        XCTAssertEqual(result.currentWorkoutDayPlan?.id, 7)
        XCTAssertEqual(result.currentWorkoutDayPlan?.name, "Peito e Tríceps")
        XCTAssertEqual(result.currentWorkoutDayPlan?.dayOfWeek, "SUNDAY")
        XCTAssertEqual(result.currentWorkoutDayPlan?.numberOfExercisesTotal, 3)
        XCTAssertEqual(result.currentWorkoutDayPlan?.numberSetsTotal, 9)
        XCTAssertEqual(result.currentWorkoutDayPlan?.timeEstimateToFinish, 45)
        XCTAssertEqual(result.exercisesForToday?.count, 2)
        XCTAssertEqual(result.exercisesForToday?[0].name, "Bench Press")
        XCTAssertEqual(result.exercisesForToday?[0].sets[0].targetReps, 12)
        XCTAssertEqual(result.exercisesForToday?[0].sets[0].targetWeight, 25.0)
    }

    func test_fetchHomeData_200_noPlan_returnsNilPlan() async throws {
        let json = """
        {"exercisesForToday": []}
        """.data(using: .utf8)!
        mockClient.responseData = json
        mockClient.responseStatus = 200

        let result = try await sut.fetchHomeData()

        XCTAssertNil(result.currentWorkoutDayPlan)
    }

    func test_fetchHomeData_200_noExercises_returnsNilExercises() async throws {
        let json = """
        {"currentWorkoutDayPlan": null}
        """.data(using: .utf8)!
        mockClient.responseData = json
        mockClient.responseStatus = 200

        let result = try await sut.fetchHomeData()

        XCTAssertNil(result.exercisesForToday)
    }

    func test_fetchHomeData_sendsGETRequest() async throws {
        mockClient.responseData = "{}".data(using: .utf8)!
        mockClient.responseStatus = 200

        _ = try await sut.fetchHomeData()

        XCTAssertEqual(mockClient.capturedRequests.last?.httpMethod, "GET")
        let url = mockClient.capturedRequests.last?.url?.absoluteString
        XCTAssertTrue(url?.contains("/api/home") == true)
    }

    // MARK: - fetchHomeData: errors

    func test_fetchHomeData_500_throwsServerError() async throws {
        mockClient.responseData = Data()
        mockClient.responseStatus = 500

        do {
            _ = try await sut.fetchHomeData()
            XCTFail("Expected error")
        } catch WorkoutPlanError.serverError(let code) {
            XCTAssertEqual(code, 500)
        }
    }

    func test_fetchHomeData_networkError_throws() async throws {
        mockClient.errorToThrow = URLError(.notConnectedToInternet)

        do {
            _ = try await sut.fetchHomeData()
            XCTFail("Expected error")
        } catch WorkoutPlanError.networkError {
            // ✅
        }
    }
}
