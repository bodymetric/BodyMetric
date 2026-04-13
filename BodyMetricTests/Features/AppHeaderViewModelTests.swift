import XCTest
@testable import BodyMetric

/// Unit tests for AppHeaderViewModel.
///
/// Verifies the logout action delegates correctly to AuthServiceProtocol
/// and handles errors without changing auth state on failure.
///
/// Constitution Principle II: TDD — written before AppHeaderViewModel.
@MainActor
final class AppHeaderViewModelTests: XCTestCase {

    private var mockAuth: MockHeaderAuthService!
    private var sut: AppHeaderViewModel!

    override func setUp() async throws {
        try await super.setUp()
        mockAuth = MockHeaderAuthService()
        sut = AppHeaderViewModel(authService: mockAuth)
    }

    override func tearDown() async throws {
        sut = nil
        mockAuth = nil
        try await super.tearDown()
    }

    // MARK: - Logout success

    func test_logout_callsSignOut() async throws {
        await sut.logout()
        XCTAssertTrue(mockAuth.signOutCalled, "logout() must call authService.signOut()")
    }

    func test_logout_success_clearsErrorMessage() async throws {
        mockAuth.signOutError = nil
        await sut.logout()
        XCTAssertNil(sut.errorMessage, "errorMessage must be nil after successful logout")
    }

    // MARK: - Logout failure

    func test_logout_failure_setsErrorMessage() async throws {
        mockAuth.signOutError = AuthError.googleSignInFailed(
            underlying: NSError(domain: "Test", code: -1)
        )
        await sut.logout()
        XCTAssertNotNil(sut.errorMessage, "errorMessage must be set when signOut fails")
    }

    func test_logout_failure_doesNotChangeAuthState() async throws {
        mockAuth.isAuthenticated = true
        mockAuth.signOutError = AuthError.googleSignInFailed(
            underlying: NSError(domain: "Test", code: -1)
        )
        await sut.logout()
        XCTAssertTrue(mockAuth.isAuthenticated,
                      "Auth state must NOT change when sign-out fails (FR-007)")
    }
}

// MARK: - Mock

@MainActor
final class MockHeaderAuthService: AuthServiceProtocol {
    var isAuthenticated: Bool = false
    var authenticatedEmail: String? = nil
    var signOutCalled = false
    var signOutError: Error? = nil

    func signInWithGoogle() async throws {}

    func signOut() async throws {
        signOutCalled = true
        if let error = signOutError { throw error }
        isAuthenticated = false
    }

    func restorePreviousSignIn() async -> Bool { false }
}
