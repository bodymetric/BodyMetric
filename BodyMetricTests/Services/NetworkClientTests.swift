import XCTest
@testable import BodyMetric

/// Unit tests for NetworkClient.
///
/// Covers: bearer token injection (US2) and 401 reactive refresh + retry (US4).
///
/// Constitution Principle II: TDD — written before NetworkClient.
@MainActor
final class NetworkClientTests: XCTestCase {

    private var sut: NetworkClient!
    private var mockTokenStore: MockTokenStore!
    private var mockCoordinator: MockCoordinator!
    private var session: URLSession!
    private let testURL = URL(string: "https://api.bodymetric.com.br/api/users")!

    override func setUp() async throws {
        try await super.setUp()
        mockTokenStore = MockTokenStore()
        mockCoordinator = MockCoordinator()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        sut = NetworkClient(
            tokenStore: mockTokenStore,
            coordinator: mockCoordinator,
            session: session
        )
    }

    override func tearDown() async throws {
        MockURLProtocol.requestHandler = nil
        sut = nil
        mockTokenStore = nil
        mockCoordinator = nil
        session = nil
        try await super.tearDown()
    }

    // MARK: - US2: Bearer token injection

    func test_data_includesBearerTokenHeader() async throws {
        await mockTokenStore.set(accessToken: "test-token-123")
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { req in
            capturedRequest = req
            let resp = HTTPURLResponse(url: self.testURL, statusCode: 200,
                                       httpVersion: nil, headerFields: nil)!
            return (Data(), resp)
        }
        _ = try await sut.data(for: URLRequest(url: testURL))
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"),
                       "Bearer test-token-123",
                       "Authorization header must contain bearer token")
    }

    // T001: renamed + updated — after fix, noToken path calls coordinator first.
    // When coordinator also fails, throws .unauthorized (not .noToken).
    func test_data_noToken_coordinatorFails_throwsUnauthorized() async throws {
        await mockTokenStore.set(accessToken: nil)
        mockCoordinator.shouldThrow = true
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Request must NOT reach the server when refresh fails")
            let resp = HTTPURLResponse(url: self.testURL, statusCode: 200,
                                       httpVersion: nil, headerFields: nil)!
            return (Data(), resp)
        }
        do {
            _ = try await sut.data(for: URLRequest(url: testURL))
            XCTFail("Expected NetworkError.unauthorized")
        } catch NetworkError.unauthorized {
            // expected — coordinator threw, so unauthorized (not noToken)
        }
    }

    func test_data_200_returnsUnchanged() async throws {
        await mockTokenStore.set(accessToken: "tok")
        let body = "response body".data(using: .utf8)!
        MockURLProtocol.requestHandler = { _ in
            let resp = HTTPURLResponse(url: self.testURL, statusCode: 200,
                                       httpVersion: nil, headerFields: nil)!
            return (body, resp)
        }
        let (data, http) = try await sut.data(for: URLRequest(url: testURL))
        XCTAssertEqual(data, body)
        XCTAssertEqual(http.statusCode, 200)
    }

    // MARK: - noToken proactive refresh (T002 + T003 — fail before fix is applied)

    // T002: no token → coordinator refreshes successfully → request proceeds with new token
    func test_data_noToken_coordinatorRefreshSucceeds_requestProceedsWithNewToken() async throws {
        await mockTokenStore.set(accessToken: nil)
        // Coordinator populates the access token when called
        mockCoordinator.onRefresh = { [weak self] in
            await self?.mockTokenStore.set(accessToken: "refreshed-token")
        }
        var capturedAuth: String?
        MockURLProtocol.requestHandler = { req in
            capturedAuth = req.value(forHTTPHeaderField: "Authorization")
            let resp = HTTPURLResponse(url: self.testURL, statusCode: 200,
                                       httpVersion: nil, headerFields: nil)!
            return (Data(), resp)
        }
        let (_, http) = try await sut.data(for: URLRequest(url: testURL))
        XCTAssertEqual(http.statusCode, 200, "Request must succeed after proactive refresh")
        XCTAssertEqual(capturedAuth, "Bearer refreshed-token",
                       "Request must use the refreshed token in Authorization header")
        XCTAssertTrue(mockCoordinator.refreshCalled,
                      "Coordinator.refresh must be called when accessToken is nil")
    }

    // T003: no token → coordinator throws → throws .unauthorized
    func test_data_noToken_coordinatorThrows_throwsUnauthorized() async throws {
        await mockTokenStore.set(accessToken: nil)
        mockCoordinator.shouldThrow = true
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Request must NOT reach the server when refresh fails")
            return (Data(), HTTPURLResponse(url: self.testURL, statusCode: 200,
                                            httpVersion: nil, headerFields: nil)!)
        }
        do {
            _ = try await sut.data(for: URLRequest(url: testURL))
            XCTFail("Expected NetworkError.unauthorized")
        } catch NetworkError.unauthorized {
            // ✅ expected — refresh failed → unauthorized
        }
    }

    // MARK: - US4: 401 reactive refresh + retry

    func test_data_401_triggersRefreshAndRetry() async throws {
        await mockTokenStore.set(accessToken: "old-token")
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            let status = callCount == 1 ? 401 : 200
            let resp = HTTPURLResponse(url: self.testURL, statusCode: status,
                                       httpVersion: nil, headerFields: nil)!
            return (Data(), resp)
        }
        let (_, http) = try await sut.data(for: URLRequest(url: testURL))
        XCTAssertEqual(http.statusCode, 200, "Retry after refresh must succeed")
        XCTAssertTrue(mockCoordinator.refreshCalled, "Coordinator.refresh must be called on 401")
        XCTAssertEqual(callCount, 2, "Request must be retried exactly once")
    }

    func test_data_401_refreshFailure_throwsUnauthorized() async throws {
        await mockTokenStore.set(accessToken: "tok")
        mockCoordinator.shouldThrow = true
        MockURLProtocol.requestHandler = { _ in
            let resp = HTTPURLResponse(url: self.testURL, statusCode: 401,
                                       httpVersion: nil, headerFields: nil)!
            return (Data(), resp)
        }
        do {
            _ = try await sut.data(for: URLRequest(url: testURL))
            XCTFail("Expected NetworkError.unauthorized")
        } catch NetworkError.unauthorized {
            // expected
        }
    }

    func test_data_401_retryUsesNewToken() async throws {
        await mockTokenStore.set(accessToken: "old-token")
        var capturedRetryAuth: String?
        var callCount = 0
        MockURLProtocol.requestHandler = { req in
            callCount += 1
            if callCount == 1 {
                let resp = HTTPURLResponse(url: self.testURL, statusCode: 401,
                                           httpVersion: nil, headerFields: nil)!
                return (Data(), resp)
            } else {
                capturedRetryAuth = req.value(forHTTPHeaderField: "Authorization")
                await self.mockTokenStore.set(accessToken: "new-token")
                let resp = HTTPURLResponse(url: self.testURL, statusCode: 200,
                                           httpVersion: nil, headerFields: nil)!
                return (Data(), resp)
            }
        }
        // Coordinator updates token store during refresh
        mockCoordinator.onRefresh = { [weak self] in
            await self?.mockTokenStore.set(accessToken: "new-token")
        }
        _ = try await sut.data(for: URLRequest(url: testURL))
        XCTAssertEqual(capturedRetryAuth, "Bearer new-token",
                       "Retry must use the refreshed token")
    }

    // MARK: - FR-002: URL-path exemption (T002 — fails before T004 is implemented)

    func test_data_qPath_doesNotAddAuthorizationHeader() async throws {
        let qURL = URL(string: "https://api.bodymetric.com.br/q/exercises")!
        await mockTokenStore.set(accessToken: "should-not-appear")
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { req in
            capturedRequest = req
            let resp = HTTPURLResponse(url: qURL, statusCode: 200,
                                       httpVersion: nil, headerFields: nil)!
            return (Data(), resp)
        }
        _ = try await sut.data(for: URLRequest(url: qURL))
        XCTAssertNil(capturedRequest?.value(forHTTPHeaderField: "Authorization"),
                     "/q/* requests must NOT include an Authorization header")
    }

    func test_data_versionPath_doesNotAddAuthorizationHeader() async throws {
        let vURL = URL(string: "https://api.bodymetric.com.br/version")!
        await mockTokenStore.set(accessToken: "should-not-appear")
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { req in
            capturedRequest = req
            let resp = HTTPURLResponse(url: vURL, statusCode: 200,
                                       httpVersion: nil, headerFields: nil)!
            return (Data(), resp)
        }
        _ = try await sut.data(for: URLRequest(url: vURL))
        XCTAssertNil(capturedRequest?.value(forHTTPHeaderField: "Authorization"),
                     "/version requests must NOT include an Authorization header")
    }

    func test_data_authPath_doesNotAddAuthorizationHeader() async throws {
        let authURL = URL(string: "https://api.bodymetric.com.br/api/auth/refresh")!
        await mockTokenStore.set(accessToken: "should-not-appear")
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { req in
            capturedRequest = req
            let resp = HTTPURLResponse(url: authURL, statusCode: 200,
                                       httpVersion: nil, headerFields: nil)!
            return (Data(), resp)
        }
        _ = try await sut.data(for: URLRequest(url: authURL))
        XCTAssertNil(capturedRequest?.value(forHTTPHeaderField: "Authorization"),
                     "/api/auth/* requests must NOT include an Authorization header")
    }

    func test_data_exemptPath_worksWithoutToken() async throws {
        // Exempt paths must succeed even when no token is stored — no .noToken error.
        let qURL = URL(string: "https://api.bodymetric.com.br/q/muscle-groups")!
        // Do NOT set an access token — tokenStore is empty.
        MockURLProtocol.requestHandler = { _ in
            let resp = HTTPURLResponse(url: qURL, statusCode: 200,
                                       httpVersion: nil, headerFields: nil)!
            return (Data(), resp)
        }
        // Should NOT throw NetworkError.noToken for an exempt path.
        let (_, http) = try await sut.data(for: URLRequest(url: qURL))
        XCTAssertEqual(http.statusCode, 200)
    }
}

// MARK: - Mocks

actor MockTokenStore: TokenStoreProtocol {
    private(set) var accessToken: String?

    func set(accessToken: String?) {
        self.accessToken = accessToken
    }

    func store(accessToken: String) {
        self.accessToken = accessToken
    }

    func clearAccessToken() {
        accessToken = nil
    }

    func setRefreshAction(_ action: (@Sendable () async -> Void)?) {
        // no-op in mock
    }
}

@MainActor
final class MockCoordinator: TokenRefreshCoordinatorProtocol {
    var refreshCalled = false
    var shouldThrow = false
    var onRefresh: (() async -> Void)?

    func refresh(tokenStore: any TokenStoreProtocol) async throws {
        refreshCalled = true
        await onRefresh?()
        if shouldThrow { throw AuthError.tokenExchangeFailed }
    }
}
