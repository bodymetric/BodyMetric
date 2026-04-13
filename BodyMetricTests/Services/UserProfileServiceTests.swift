import XCTest
@testable import BodyMetric

/// Unit tests for UserProfileService.
///
/// Uses `MockNetworkClient` (from TestHelpers.swift) so the bearer token
/// injection and 401 retry logic are isolated in NetworkClient tests.
///
/// Constitution Principle II: TDD.
@MainActor
final class UserProfileServiceTests: XCTestCase {

    private var sut: UserProfileService!
    private var mockClient: MockNetworkClient!

    override func setUp() async throws {
        try await super.setUp()
        mockClient = MockNetworkClient()
        sut = UserProfileService(networkClient: mockClient)
    }

    override func tearDown() async throws {
        sut = nil
        mockClient = nil
        try await super.tearDown()
    }

    // MARK: - 200 OK

    func test_fetchProfile_200_returnsDecodedProfile() async throws {
        let json = """
        {"weight":75.5,"weightUnit":"kg","height":180.0,"heightUnit":"cm"}
        """.data(using: .utf8)!
        mockClient.responseData = json
        mockClient.responseStatus = 200

        let profile = try await sut.fetchProfile(email: "user@example.com")

        XCTAssertEqual(profile.email, "user@example.com")
        XCTAssertEqual(profile.weight, 75.5)
        XCTAssertEqual(profile.weightUnit, "kg")
        XCTAssertEqual(profile.height, 180.0)
        XCTAssertEqual(profile.heightUnit, "cm")
    }

    // MARK: - 404

    func test_fetchProfile_404_throwsUserNotFound() async throws {
        mockClient.responseStatus = 404

        do {
            _ = try await sut.fetchProfile(email: "new@example.com")
            XCTFail("Expected userNotFound")
        } catch ProfileFetchError.userNotFound {
            // expected
        }
    }

    // MARK: - Network failure

    func test_fetchProfile_networkFailure_throwsNetworkError() async throws {
        mockClient.errorToThrow = URLError(.notConnectedToInternet)

        do {
            _ = try await sut.fetchProfile(email: "user@example.com")
            XCTFail("Expected networkError or unauthorized")
        } catch ProfileFetchError.unauthorized {
            // NetworkError from client becomes unauthorized
        } catch ProfileFetchError.networkError {
            // raw URLError becomes networkError
        }
    }

    // MARK: - Decode failure

    func test_fetchProfile_malformedJSON_throwsDecodingError() async throws {
        mockClient.responseData = "not json".data(using: .utf8)!
        mockClient.responseStatus = 200

        do {
            _ = try await sut.fetchProfile(email: "user@example.com")
            XCTFail("Expected decodingError")
        } catch ProfileFetchError.decodingError {
            // expected
        }
    }

    // MARK: - URL contains email

    func test_fetchProfile_requestContainsEmail() async throws {
        let json = """
        {"weight":70.0,"weightUnit":"kg","height":175.0,"heightUnit":"cm"}
        """.data(using: .utf8)!
        mockClient.responseData = json
        mockClient.responseStatus = 200

        _ = try await sut.fetchProfile(email: "test@example.com")

        let urlString = mockClient.capturedRequests.first?.url?.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("email="), "URL must include email query parameter")
    }
}
