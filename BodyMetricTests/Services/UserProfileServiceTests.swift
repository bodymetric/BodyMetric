import XCTest
@testable import BodyMetric

/// Unit tests for UserProfileService.
///
/// Uses a URLProtocol stub to intercept URLSession requests without hitting
/// the real network. Tests cover all four outcomes: 200, 404, network failure,
/// and decode failure.
///
/// Constitution Principle II: TDD — these tests are written before the service.
@MainActor
final class UserProfileServiceTests: XCTestCase {

    // MARK: - Subject under test

    private var sut: UserProfileService!
    private var session: URLSession!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        sut = UserProfileService(session: session)
    }

    override func tearDown() async throws {
        MockURLProtocol.requestHandler = nil
        sut = nil
        session = nil
        try await super.tearDown()
    }

    // MARK: - 200 OK

    func test_fetchProfile_200_returnsDecodedProfile() async throws {
        let json = """
        {"weight":75.5,"weightUnit":"kg","height":180.0,"heightUnit":"cm"}
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: nil)!
            return (response, json)
        }

        let profile = try await sut.fetchProfile(email: "user@example.com")

        XCTAssertEqual(profile.email, "user@example.com")
        XCTAssertEqual(profile.weight, 75.5)
        XCTAssertEqual(profile.weightUnit, "kg")
        XCTAssertEqual(profile.height, 180.0)
        XCTAssertEqual(profile.heightUnit, "cm")
    }

    // MARK: - 404

    func test_fetchProfile_404_throwsUserNotFound() async throws {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                           statusCode: 404,
                                           httpVersion: nil,
                                           headerFields: nil)!
            return (response, Data())
        }

        do {
            _ = try await sut.fetchProfile(email: "new@example.com")
            XCTFail("Expected userNotFound to be thrown")
        } catch ProfileFetchError.userNotFound {
            // expected
        }
    }

    // MARK: - Network failure

    func test_fetchProfile_networkFailure_throwsNetworkError() async throws {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await sut.fetchProfile(email: "user@example.com")
            XCTFail("Expected networkError to be thrown")
        } catch ProfileFetchError.networkError {
            // expected
        }
    }

    // MARK: - Decode failure

    func test_fetchProfile_malformedJSON_throwsDecodingError() async throws {
        let badJSON = "not json at all".data(using: .utf8)!

        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: nil)!
            return (response, badJSON)
        }

        do {
            _ = try await sut.fetchProfile(email: "user@example.com")
            XCTFail("Expected decodingError to be thrown")
        } catch ProfileFetchError.decodingError {
            // expected
        }
    }

    // MARK: - URL contains email

    func test_fetchProfile_requestContainsEmail() async throws {
        var capturedRequest: URLRequest?
        let json = """
        {"weight":70.0,"weightUnit":"kg","height":175.0,"heightUnit":"cm"}
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: nil)!
            return (response, json)
        }

        _ = try await sut.fetchProfile(email: "test@example.com")

        let urlString = capturedRequest?.url?.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("email="), "URL must contain email query parameter")
        XCTAssertFalse(urlString.contains("test@example.com"),
                       "Email must be URL-encoded in the request")
    }
}

// MARK: - MockURLProtocol

/// Intercepts URLSession requests in tests without hitting the network.
final class MockURLProtocol: URLProtocol {

    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
