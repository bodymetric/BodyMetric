import XCTest
@testable import BodyMetric

/// Unit tests for AuthService — covers US5 (logout cleanup).
///
/// Constitution Principle II: TDD.
@MainActor
final class AuthServiceTests: XCTestCase {

    private var sut: AuthService!
    private var mockTokenStore: MockSignOutTokenStore!
    private var mockKeychainService: MockSignOutKeychainService!

    override func setUp() async throws {
        try await super.setUp()
        mockTokenStore = MockSignOutTokenStore()
        mockKeychainService = MockSignOutKeychainService()
        sut = AuthService(
            tokenExchangeService: MockTokenExchangeService(),
            tokenStore: mockTokenStore,
            keychainService: mockKeychainService,
            coordinator: MockProtocolCoordinator()
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockTokenStore = nil
        mockKeychainService = nil
        try await super.tearDown()
    }

    // MARK: - US5: Logout cleanup

    func test_signOut_clearsAccessToken() async throws {
        try await sut.signOut()
        XCTAssertTrue(mockTokenStore.clearAccessTokenCalled,
                      "signOut must call tokenStore.clearAccessToken()")
    }

    func test_signOut_deletesRefreshTokenFromKeychain() async throws {
        try await sut.signOut()
        XCTAssertTrue(mockKeychainService.deleteRefreshTokenCalled,
                      "signOut must call keychainService.deleteRefreshToken()")
    }

    func test_signOut_setsIsAuthenticatedFalse() async throws {
        try await sut.signOut()
        XCTAssertFalse(sut.isAuthenticated,
                       "isAuthenticated must be false after signOut")
    }

    func test_signOut_deletionFailure_stillCompletesSignOut() async throws {
        mockKeychainService.shouldThrowOnDelete = true
        // Must not propagate the Keychain error — signOut always completes
        try await sut.signOut()
        XCTAssertFalse(sut.isAuthenticated, "signOut must complete even if Keychain delete fails")
        XCTAssertTrue(mockTokenStore.clearAccessTokenCalled, "Access token must be cleared")
    }
}

// MARK: - Mocks

actor MockSignOutTokenStore: TokenStoreProtocol {
    private(set) var accessToken: String? = "existing-token"
    var clearAccessTokenCalled = false

    func store(accessToken: String) { self.accessToken = accessToken }
    func clearAccessToken() {
        clearAccessTokenCalled = true
        accessToken = nil
    }
    func setRefreshAction(_ action: (@Sendable () async -> Void)?) {}
}

final class MockSignOutKeychainService: KeychainServiceProtocol {
    var deleteRefreshTokenCalled = false
    var shouldThrowOnDelete = false

    func saveRefreshToken(_ token: String) throws {}
    func loadRefreshToken() throws -> String { "stored-token" }
    func deleteRefreshToken() throws {
        deleteRefreshTokenCalled = true
        if shouldThrowOnDelete { throw AuthError.keychainWriteFailed }
    }
}

@MainActor
final class MockTokenExchangeService: TokenExchangeServiceProtocol {
    func exchange(googleIdToken: String) async throws -> TokenExchangeResponse {
        TokenExchangeResponse(accessToken: "acc", refreshToken: "ref")
    }
}

/// Stub coordinator conforming to the protocol (not subclassing the actor).
final class MockProtocolCoordinator: TokenRefreshCoordinatorProtocol {
    func refresh(tokenStore: any TokenStoreProtocol) async throws {}
}
