import XCTest
@testable import BodyMetric

/// Unit tests for TokenRefreshCoordinator.
///
/// Verifies: success path updates tokenStore, failure path clears credentials and calls
/// force-logout, concurrent calls result in only one network request.
///
/// Constitution Principle II: TDD — written alongside TokenRefreshCoordinator.
@MainActor
final class TokenRefreshCoordinatorTests: XCTestCase {

    private var mockTokenStore: CoordTokenStore!
    private var mockRefreshService: CoordRefreshService!
    private var mockKeychain: CoordKeychain!
    private var forceLogoutCalled: Bool!
    private var sut: TokenRefreshCoordinator!

    override func setUp() async throws {
        try await super.setUp()
        mockTokenStore = CoordTokenStore()
        mockRefreshService = CoordRefreshService()
        mockKeychain = CoordKeychain()
        forceLogoutCalled = false

        sut = TokenRefreshCoordinator(
            refreshService: mockRefreshService,
            keychainService: mockKeychain,
            onForceLogout: { [weak self] in self?.forceLogoutCalled = true }
        )
        // Pre-populate a refresh token in the mock keychain
        try mockKeychain.saveRefreshToken("stored-refresh-token")
    }

    override func tearDown() async throws {
        sut = nil
        mockTokenStore = nil
        mockRefreshService = nil
        mockKeychain = nil
        try await super.tearDown()
    }

    // MARK: - Success path

    func test_refresh_success_updatesTokenStore() async throws {
        mockRefreshService.responseToReturn = TokenRefreshResponse(
            accessToken: "new-access",
            refreshToken: nil
        )
        try await sut.refresh(tokenStore: mockTokenStore)
        let token = await mockTokenStore.accessToken
        XCTAssertEqual(token, "new-access",
                       "tokenStore must be updated with new access token on success")
    }

    func test_refresh_success_rotatesRefreshTokenInKeychain() async throws {
        mockRefreshService.responseToReturn = TokenRefreshResponse(
            accessToken: "new-access",
            refreshToken: "new-refresh"
        )
        try await sut.refresh(tokenStore: mockTokenStore)
        XCTAssertEqual(mockKeychain.savedRefreshToken, "new-refresh",
                       "Keychain refresh token must be rotated when backend returns one")
    }

    func test_refresh_success_noRotation_keepsExistingKeychain() async throws {
        mockRefreshService.responseToReturn = TokenRefreshResponse(
            accessToken: "new-access",
            refreshToken: nil
        )
        try await sut.refresh(tokenStore: mockTokenStore)
        XCTAssertEqual(mockKeychain.savedRefreshToken, "stored-refresh-token",
                       "Existing refresh token must be kept when backend does not rotate")
    }

    func test_refresh_success_doesNotCallForceLogout() async throws {
        mockRefreshService.responseToReturn = TokenRefreshResponse(
            accessToken: "new-access",
            refreshToken: nil
        )
        try await sut.refresh(tokenStore: mockTokenStore)
        XCTAssertFalse(forceLogoutCalled, "forceLogout must NOT be called on success")
    }

    // MARK: - Failure path

    func test_refresh_failure_clearsAccessToken() async throws {
        mockRefreshService.shouldThrow = true
        try? await sut.refresh(tokenStore: mockTokenStore)
        let token = await mockTokenStore.accessToken
        XCTAssertNil(token, "Access token must be cleared when refresh fails")
        XCTAssertTrue(mockTokenStore.clearAccessTokenCalled)
    }

    func test_refresh_failure_deletesRefreshTokenFromKeychain() async throws {
        mockRefreshService.shouldThrow = true
        try? await sut.refresh(tokenStore: mockTokenStore)
        XCTAssertTrue(mockKeychain.deleteRefreshTokenCalled,
                      "Refresh token must be deleted from Keychain on failure")
    }

    func test_refresh_failure_callsForceLogout() async throws {
        mockRefreshService.shouldThrow = true
        try? await sut.refresh(tokenStore: mockTokenStore)
        XCTAssertTrue(forceLogoutCalled, "forceLogout must be called when refresh fails")
    }

    // MARK: - Concurrency guard

    func test_concurrentRefreshCalls_onlyOneNetworkRequest() async throws {
        // Use a slow refresh service so we can overlap calls
        mockRefreshService.delay = 0.1
        mockRefreshService.responseToReturn = TokenRefreshResponse(
            accessToken: "new-access",
            refreshToken: nil
        )

        // Fire two concurrent refresh calls
        async let first: Void = sut.refresh(tokenStore: mockTokenStore)
        async let second: Void = sut.refresh(tokenStore: mockTokenStore)
        _ = try await (first, second)

        XCTAssertEqual(mockRefreshService.callCount, 1,
                       "Only one network request must be issued for concurrent refresh calls")
    }
}

// MARK: - Mocks

actor CoordTokenStore: TokenStoreProtocol {
    private(set) var accessToken: String? = "old-access-token"
    var clearAccessTokenCalled = false

    func store(accessToken: String) { self.accessToken = accessToken }
    func clearAccessToken() {
        clearAccessTokenCalled = true
        accessToken = nil
    }
    func setRefreshAction(_ action: (@Sendable () async -> Void)?) {}
}

@MainActor
final class CoordRefreshService: TokenRefreshServiceProtocol {
    var responseToReturn = TokenRefreshResponse(accessToken: "acc", refreshToken: nil)
    var shouldThrow = false
    var callCount = 0
    var delay: TimeInterval = 0

    func refresh(using refreshToken: String) async throws -> TokenRefreshResponse {
        callCount += 1
        if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
        if shouldThrow { throw AuthError.tokenExchangeFailed }
        return responseToReturn
    }
}

final class CoordKeychain: KeychainServiceProtocol {
    var savedRefreshToken: String? = nil
    var deleteRefreshTokenCalled = false

    func saveRefreshToken(_ token: String) throws { savedRefreshToken = token }
    func loadRefreshToken() throws -> String {
        guard let t = savedRefreshToken else { throw AuthError.keychainWriteFailed }
        return t
    }
    func deleteRefreshToken() throws {
        deleteRefreshTokenCalled = true
        savedRefreshToken = nil
    }
}
