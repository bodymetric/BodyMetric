import Foundation
import XCTest
@testable import BodyMetric

// MARK: - MockURLProtocol

/// Intercepts URLSession requests in tests without hitting the network.
///
/// Handler returns `(Data, HTTPURLResponse)` matching the signature of
/// `URLSession.data(for:)` to keep call sites intuitive.
final class MockURLProtocol: URLProtocol {

    /// Set this before each test; clear it in `tearDown`.
    static var requestHandler: ((URLRequest) async throws -> (Data, HTTPURLResponse))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        let req = request
        let client = self.client
        Task {
            do {
                let (data, response) = try await handler(req)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }

    override func stopLoading() {}
}

// MARK: - MockNetworkClient

/// In-memory stub for `NetworkClientProtocol`.
/// Returns preset responses without touching URLSession.
@MainActor
final class MockNetworkClient: NetworkClientProtocol {

    var responseData: Data = Data()
    var responseStatus: Int = 200
    var errorToThrow: Error?
    var capturedRequests: [URLRequest] = []

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        capturedRequests.append(request)
        if let error = errorToThrow { throw error }
        let resp = HTTPURLResponse(
            url: request.url!,
            statusCode: responseStatus,
            httpVersion: nil,
            headerFields: nil
        )!
        return (responseData, resp)
    }
}

// MARK: - MockUserProfileService

@MainActor
final class MockUserProfileService: UserProfileServiceProtocol {
    var profileToReturn: UserProfile?
    var errorToThrow: Error?

    func fetchProfile(email: String) async throws -> UserProfile {
        if let error = errorToThrow { throw error }
        return profileToReturn!
    }
}

// MARK: - MockUpdateProfileService

/// In-memory stub for `UpdateProfileServiceProtocol`.
@MainActor
final class MockUpdateProfileService: UpdateProfileServiceProtocol {

    var responseToReturn = AuthUser(
        id: 1, name: "Default", email: "default@example.com",
        height: 170.0, weight: 70.0
    )
    var shouldThrow = false
    var callCount = 0
    var delay: TimeInterval = 0

    func updateProfile(_ request: UpdateProfileRequest) async throws -> AuthUser {
        callCount += 1
        if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
        if shouldThrow { throw ProfileUpdateError.serverError(422) }
        return responseToReturn
    }
}
