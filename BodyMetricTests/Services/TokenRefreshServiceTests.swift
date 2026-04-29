import XCTest
@testable import BodyMetric

/// Unit tests for TokenRefreshService.
///
/// Uses MockURLProtocol (from TestHelpers.swift) to simulate backend responses.
///
/// Constitution Principle II: TDD — written before TokenRefreshService.
@MainActor
final class TokenRefreshServiceTests: XCTestCase {

    private var sut: TokenRefreshService!
    private var session: URLSession!

    override func setUp() async throws {
        try await super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        sut = TokenRefreshService(session: session)
    }

    override func tearDown() async throws {
        MockURLProtocol.requestHandler = nil
        sut = nil
        session = nil
        try await super.tearDown()
    }

    // MARK: - 200 success

    func test_refresh_200_returnsNewAccessToken() async throws {
        // Mock JSON uses the correct server field names: "sessionToken" and "refreshToken"
        MockURLProtocol.requestHandler = { _ in
            let json = """
            {"sessionToken":"new-acc","refreshToken":"new-ref"}
            """.data(using: .utf8)!
            let resp = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (json, resp)
        }
        let response = try await sut.refresh(using: "old-refresh-token")
        XCTAssertEqual(response.accessToken, "new-acc")
        XCTAssertEqual(response.refreshToken, "new-ref")
    }

    func test_refresh_200_missingRotatedRefresh_returnsNilRefresh() async throws {
        MockURLProtocol.requestHandler = { _ in
            let json = """
            {"sessionToken":"new-acc"}
            """.data(using: .utf8)!
            let resp = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (json, resp)
        }
        let response = try await sut.refresh(using: "token")
        XCTAssertEqual(response.accessToken, "new-acc")
        XCTAssertNil(response.refreshToken, "refreshToken must be nil when backend omits it")
    }

    func test_refresh_sendsRefreshTokenInBody() async throws {
        var capturedBody: Data?
        MockURLProtocol.requestHandler = { req in
            capturedBody = req.httpBody
            let json = """
            {"sessionToken":"a","refreshToken":"r"}
            """.data(using: .utf8)!
            let resp = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (json, resp)
        }
        _ = try await sut.refresh(using: "my-stored-refresh")
        let body = try JSONDecoder().decode([String: String].self, from: capturedBody!)
        // T001: body must use camelCase "refreshToken" per the API contract
        XCTAssertEqual(body["refreshToken"], "my-stored-refresh",
                       "Request body must send camelCase 'refreshToken' key")
        XCTAssertNil(body["refresh_token"],
                     "Request body must NOT send snake_case 'refresh_token' key")
    }

    func test_refresh_doesNotSendAuthorizationHeader() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { req in
            capturedRequest = req
            let json = """
            {"sessionToken":"a","refreshToken":"r"}
            """.data(using: .utf8)!
            let resp = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (json, resp)
        }
        _ = try await sut.refresh(using: "token")
        XCTAssertNil(capturedRequest?.value(forHTTPHeaderField: "Authorization"),
                     "Refresh endpoint must NOT include an Authorization header")
    }

    // MARK: - 401 failure

    func test_refresh_401_throwsTokenExchangeFailed() async {
        MockURLProtocol.requestHandler = { _ in
            let resp = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (Data(), resp)
        }
        do {
            _ = try await sut.refresh(using: "expired-token")
            XCTFail("Expected throw")
        } catch AuthError.tokenExchangeFailed {
            // expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Network failure

    func test_refresh_networkError_throwsTokenExchangeFailed() async {
        MockURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        do {
            _ = try await sut.refresh(using: "token")
            XCTFail("Expected throw")
        } catch AuthError.tokenExchangeFailed {
            // expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
}
