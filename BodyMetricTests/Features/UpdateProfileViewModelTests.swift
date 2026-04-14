import XCTest
@testable import BodyMetric

/// Unit tests for UpdateProfileViewModel.
///
/// Covers: happy path (submit → 201 → success state → redirect),
/// validation (empty name, name > 20, height ≤ 0, weight ≤ 0),
/// error recovery (backend error → button restored, user stays on form),
/// in-flight guard (button disabled during request).
///
/// Constitution Principle II: TDD — written before UpdateProfileViewModel.
@MainActor
final class UpdateProfileViewModelTests: XCTestCase {

    private var mockService: MockUpdateProfileService!
    private var mockProfileStore: ProfileStore!
    private var mockAuthService: MockAuthServiceForProfile!
    private var sut: UpdateProfileViewModel!
    private var testDefaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockUpdateProfileService()
        testDefaults = UserDefaults(suiteName: "UpdateProfileViewModelTests")!
        testDefaults.removePersistentDomain(forName: "UpdateProfileViewModelTests")
        mockProfileStore = ProfileStore(defaults: testDefaults)
        mockAuthService = MockAuthServiceForProfile()

        sut = UpdateProfileViewModel(
            email: "alice@example.com",
            updateService: mockService,
            profileStore: mockProfileStore,
            authService: mockAuthService,
            redirectDelay: 0.05   // fast for tests
        )
    }

    override func tearDown() async throws {
        testDefaults.removePersistentDomain(forName: "UpdateProfileViewModelTests")
        sut = nil
        mockService = nil
        mockProfileStore = nil
        mockAuthService = nil
        testDefaults = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func fillValidFields() {
        sut.name = "Alice"
        sut.heightText = "165.0"
        sut.weightText = "60.0"
    }

    // MARK: - Happy path

    func test_submit_validFields_callsService() async throws {
        fillValidFields()
        mockService.responseToReturn = AuthUser(id: 1, name: "Alice",
                                                email: "alice@example.com",
                                                height: 165.0, weight: 60.0)
        await sut.submit()
        XCTAssertEqual(mockService.callCount, 1, "submit() must call the update service once")
    }

    func test_submit_success_setsIsSuccessTrue() async throws {
        fillValidFields()
        await sut.submit()
        XCTAssertTrue(sut.isSuccess, "isSuccess must be true after successful submission")
    }

    func test_submit_success_isLoadingFalseAfterCompletion() async throws {
        fillValidFields()
        await sut.submit()
        XCTAssertFalse(sut.isLoading, "isLoading must be false after submission completes")
    }

    func test_submit_success_navigatesToHomeAfterDelay() async throws {
        fillValidFields()
        await sut.submit()
        // After redirectDelay (0.05 s), navigationState should be .home
        try await Task.sleep(for: .seconds(0.1))
        XCTAssertEqual(sut.navigationState, .home,
                       "navigationState must be .home after success + redirect delay")
    }

    func test_submit_success_savesProfileToStore() async throws {
        fillValidFields()
        mockService.responseToReturn = AuthUser(id: 1, name: "Alice",
                                                email: "alice@example.com",
                                                height: 165.0, weight: 60.0)
        await sut.submit()
        XCTAssertEqual(mockProfileStore.name, "Alice",
                       "ProfileStore must be saved with name after success")
        XCTAssertEqual(mockProfileStore.height, 165.0)
        XCTAssertEqual(mockProfileStore.weight, 60.0)
    }

    func test_submit_success_clearsNeedsProfileSetup() async throws {
        fillValidFields()
        await sut.submit()
        XCTAssertFalse(mockAuthService.needsProfileSetup,
                       "authService.needsProfileSetup must be false after success")
    }

    // MARK: - Loading state

    func test_submit_duringRequest_isLoadingTrue() async throws {
        fillValidFields()
        mockService.delay = 0.3

        let task = Task { await self.sut.submit() }
        // Give the task a moment to start
        try await Task.sleep(for: .seconds(0.05))
        XCTAssertTrue(sut.isLoading, "isLoading must be true while request is in-flight")
        task.cancel()
    }

    func test_submit_duringRequest_buttonDisabled() async throws {
        fillValidFields()
        mockService.delay = 0.3

        let task = Task { await self.sut.submit() }
        try await Task.sleep(for: .seconds(0.05))
        XCTAssertTrue(sut.isLoading, "Button must be disabled (isLoading=true) during request")
        task.cancel()
    }

    // MARK: - Validation — name

    func test_submit_emptyName_doesNotCallService() async throws {
        sut.name = ""
        sut.heightText = "165.0"
        sut.weightText = "60.0"
        await sut.submit()
        XCTAssertEqual(mockService.callCount, 0, "Empty name must block submission")
        XCTAssertNotNil(sut.errorMessage, "errorMessage must be set for empty name")
    }

    func test_submit_whitespaceName_doesNotCallService() async throws {
        sut.name = "   "
        sut.heightText = "165.0"
        sut.weightText = "60.0"
        await sut.submit()
        XCTAssertEqual(mockService.callCount, 0)
    }

    func test_submit_nameTooLong_doesNotCallService() async throws {
        sut.name = String(repeating: "A", count: 21)   // 21 chars > 20 limit
        sut.heightText = "165.0"
        sut.weightText = "60.0"
        await sut.submit()
        XCTAssertEqual(mockService.callCount, 0, "Name > 20 chars must block submission")
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - Validation — height

    func test_submit_heightNonNumeric_doesNotCallService() async throws {
        sut.name = "Alice"
        sut.heightText = "abc"
        sut.weightText = "60.0"
        await sut.submit()
        XCTAssertEqual(mockService.callCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_submit_heightZero_doesNotCallService() async throws {
        sut.name = "Alice"
        sut.heightText = "0"
        sut.weightText = "60.0"
        await sut.submit()
        XCTAssertEqual(mockService.callCount, 0)
    }

    func test_submit_heightNegative_doesNotCallService() async throws {
        sut.name = "Alice"
        sut.heightText = "-10"
        sut.weightText = "60.0"
        await sut.submit()
        XCTAssertEqual(mockService.callCount, 0)
    }

    // MARK: - Validation — weight

    func test_submit_weightNonNumeric_doesNotCallService() async throws {
        sut.name = "Alice"
        sut.heightText = "165.0"
        sut.weightText = "xyz"
        await sut.submit()
        XCTAssertEqual(mockService.callCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_submit_weightZero_doesNotCallService() async throws {
        sut.name = "Alice"
        sut.heightText = "165.0"
        sut.weightText = "0"
        await sut.submit()
        XCTAssertEqual(mockService.callCount, 0)
    }

    // MARK: - Backend error recovery

    func test_submit_backendError_isLoadingFalseAfter() async throws {
        fillValidFields()
        mockService.shouldThrow = true
        await sut.submit()
        XCTAssertFalse(sut.isLoading, "isLoading must be false after backend error")
    }

    func test_submit_backendError_setsErrorMessage() async throws {
        fillValidFields()
        mockService.shouldThrow = true
        await sut.submit()
        XCTAssertNotNil(sut.errorMessage, "errorMessage must be set on backend error")
    }

    func test_submit_backendError_isSuccessFalse() async throws {
        fillValidFields()
        mockService.shouldThrow = true
        await sut.submit()
        XCTAssertFalse(sut.isSuccess, "isSuccess must remain false after backend error")
    }

    func test_submit_backendError_staysOnForm() async throws {
        fillValidFields()
        mockService.shouldThrow = true
        await sut.submit()
        XCTAssertEqual(sut.navigationState, .form,
                       "navigationState must remain .form after backend error")
    }

    func test_submit_backendError_profileStoreNotSaved() async throws {
        fillValidFields()
        mockService.shouldThrow = true
        await sut.submit()
        XCTAssertFalse(mockProfileStore.isComplete,
                       "ProfileStore must NOT be saved after backend error")
    }

    func test_submit_afterError_canRetry() async throws {
        fillValidFields()
        mockService.shouldThrow = true
        await sut.submit()
        XCTAssertEqual(mockService.callCount, 1)

        // Fix the service and retry
        mockService.shouldThrow = false
        mockService.responseToReturn = AuthUser(id: 1, name: "Alice",
                                                email: "alice@example.com",
                                                height: 165.0, weight: 60.0)
        await sut.submit()
        XCTAssertEqual(mockService.callCount, 2, "Second attempt must be made after fixing error")
        XCTAssertTrue(sut.isSuccess)
    }
}

// MARK: - Mock AuthService for profile tests

@MainActor
final class MockAuthServiceForProfile: AuthServiceProtocol {
    var isAuthenticated: Bool = true
    var authenticatedEmail: String? = "alice@example.com"
    var needsProfileSetup: Bool = true

    func signInWithGoogle() async throws {}
    func signOut() async throws { isAuthenticated = false }
    func restorePreviousSignIn() async -> Bool { false }
}

// Extend MockAuthServiceForProfile so UpdateProfileViewModel can call clearNeedsProfileSetup
// via the AuthService-specific cast. We add a matching method here.
extension MockAuthServiceForProfile {
    func clearNeedsProfileSetup() {
        needsProfileSetup = false
    }
}
