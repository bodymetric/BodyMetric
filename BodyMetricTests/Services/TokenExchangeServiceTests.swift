import XCTest
@testable import BodyMetric

/// Unit tests for TokenExchangeService.
///
/// Uses MockURLProtocol (from TestHelpers.swift) to simulate backend responses.
///
/// Constitution Principle II: TDD — written before TokenExchangeService.
@MainActor
final class TokenExchangeServiceTests: XCTestCase {

    private var sut: TokenExchangeService!
    private var session: URLSession!

    override func setUp() async throws {
        try await super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        sut = TokenExchangeService(session: session)
    }

    override func tearDown() async throws {
        MockURLProtocol.requestHandler = nil
        sut = nil
        session = nil
        try await super.tearDown()
    }

    // MARK: - 200 success

    func test_exchange_200_returnsBothTokens() async throws {
        MockURLProtocol.requestHandler = { _ in
            let json = """
            {"access_token":"acc-123","refresh_token":"ref-456"}
            """.data(using: .utf8)!
            let resp = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (json, resp)
        }

        let response = try await sut.exchange(googleIdToken: "google-id-token")
        XCTAssertEqual(response.accessToken, "acc-123")
        XCTAssertEqual(response.refreshToken, "ref-456")
    }

    func test_exchange_200_sendsIdTokenInBody() async throws {
        var capturedBody: Data?
        MockURLProtocol.requestHandler = { request in
            capturedBody = request.httpBody
            let json = """
            {"access_token":"a","refresh_token":"r"}
            """.data(using: .utf8)!
            let resp = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (json, resp)
        }

        _ = try await sut.exchange(googleIdToken: "my-google-token")
        let bodyJSON = try JSONDecoder().decode([String: String].self, from: capturedBody!)
        XCTAssertEqual(bodyJSON["id_token"], "my-google-token")
    }

    // MARK: - 401 failure

    func test_exchange_401_throwsTokenExchangeFailed() async {
        MockURLProtocol.requestHandler = { _ in
            let resp = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (Data(), resp)
        }

        do {
            _ = try await sut.exchange(googleIdToken: "bad-token")
            XCTFail("Expected throw")
        } catch AuthError.tokenExchangeFailed {
            // expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    // MARK: - Network failure

    func test_exchange_networkError_throwsTokenExchangeFailed() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await sut.exchange(googleIdToken: "token")
            XCTFail("Expected throw")
        } catch AuthError.tokenExchangeFailed {
            // expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }
}
