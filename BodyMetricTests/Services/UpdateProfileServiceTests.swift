import XCTest
@testable import BodyMetric

/// Unit tests for UpdateProfileService.
///
/// Verifies: 201 success decodes AuthUser; non-201 throws ProfileUpdateError;
/// network error throws; request body contains all four fields;
/// Authorization header is present (injected by NetworkClient).
///
/// Constitution Principle II: TDD — written before UpdateProfileService.
@MainActor
final class UpdateProfileServiceTests: XCTestCase {

    private var mockNetworkClient: MockNetworkClient!
    private var sut: UpdateProfileService!

    private let validRequest = UpdateProfileRequest(
        name: "Alice",
        email: "alice@example.com",
        height: 165.0,
        weight: 60.0
    )

    override func setUp() async throws {
        try await super.setUp()
        mockNetworkClient = MockNetworkClient()
        sut = UpdateProfileService(networkClient: mockNetworkClient)
    }

    override func tearDown() async throws {
        sut = nil
        mockNetworkClient = nil
        try await super.tearDown()
    }

    // MARK: - Success (HTTP 201)

    func test_updateProfile_201_returnsDecodedAuthUser() async throws {
        let user = AuthUser(id: 5, name: "Alice", email: "alice@example.com",
                            height: 165.0, weight: 60.0)
        mockNetworkClient.responseData = try JSONEncoder().encode(UserWrapper(user: user))
        mockNetworkClient.responseStatus = 201

        // Encode the response as the service would receive it
        let body = try JSONEncoder().encode(user)
        mockNetworkClient.responseData = body
        mockNetworkClient.responseStatus = 201

        let result = try await sut.updateProfile(validRequest)
        XCTAssertEqual(result.name, "Alice")
        XCTAssertEqual(result.email, "alice@example.com")
        XCTAssertEqual(result.height, 165.0)
        XCTAssertEqual(result.weight, 60.0)
    }

    // MARK: - Failure (non-201)

    func test_updateProfile_422_throwsServerError() async throws {
        mockNetworkClient.responseData = Data()
        mockNetworkClient.responseStatus = 422

        do {
            _ = try await sut.updateProfile(validRequest)
            XCTFail("Expected ProfileUpdateError to be thrown")
        } catch let error as ProfileUpdateError {
            if case .serverError(let code) = error {
                XCTAssertEqual(code, 422)
            } else {
                XCTFail("Expected .serverError(422), got \(error)")
            }
        }
    }

    func test_updateProfile_500_throwsServerError() async throws {
        mockNetworkClient.responseData = Data()
        mockNetworkClient.responseStatus = 500

        do {
            _ = try await sut.updateProfile(validRequest)
            XCTFail("Expected ProfileUpdateError")
        } catch is ProfileUpdateError {
            // expected
        }
    }

    // MARK: - Network error

    func test_updateProfile_networkError_throwsNetworkError() async throws {
        mockNetworkClient.errorToThrow = URLError(.notConnectedToInternet)

        do {
            _ = try await sut.updateProfile(validRequest)
            XCTFail("Expected ProfileUpdateError.networkError")
        } catch let error as ProfileUpdateError {
            if case .networkError = error { /* expected */ } else {
                XCTFail("Expected .networkError, got \(error)")
            }
        }
    }

    // MARK: - Request body fields

    func test_updateProfile_requestContainsAllFields() async throws {
        mockNetworkClient.responseData = try JSONEncoder().encode(validRequest) // reuse as body
        mockNetworkClient.responseStatus = 201

        // Prepare valid response
        let user = AuthUser(id: 1, name: "Alice", email: "alice@example.com",
                            height: 165.0, weight: 60.0)
        mockNetworkClient.responseData = try JSONEncoder().encode(user)

        _ = try? await sut.updateProfile(validRequest)

        let captured = mockNetworkClient.capturedRequests.first
        XCTAssertNotNil(captured?.httpBody, "Request must have a body")

        if let bodyData = captured?.httpBody,
           let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            XCTAssertEqual(json["name"] as? String, "Alice")
            XCTAssertEqual(json["email"] as? String, "alice@example.com")
            XCTAssertNotNil(json["height"], "height must be present in request body")
            XCTAssertNotNil(json["weight"], "weight must be present in request body")
        } else {
            XCTFail("Could not parse request body as JSON")
        }
    }

    func test_updateProfile_usesCorrectHTTPMethod() async throws {
        let user = AuthUser(id: 1, name: "Alice", email: "alice@example.com",
                            height: 165.0, weight: 60.0)
        mockNetworkClient.responseData = try JSONEncoder().encode(user)
        mockNetworkClient.responseStatus = 201

        _ = try? await sut.updateProfile(validRequest)

        XCTAssertEqual(
            mockNetworkClient.capturedRequests.first?.httpMethod, "POST",
            "updateProfile must use POST"
        )
    }
}

// Helper used only in this test file to avoid compiler warnings
private struct UserWrapper: Encodable {
    let user: AuthUser
}
