import XCTest
@testable import BodyMetric

/// Unit tests for HomeViewModel.
///
/// Uses a mock UserProfileService and an in-memory ProfileStore
/// (isolated UserDefaults suite) to verify fetch-or-cache decision logic.
///
/// Constitution Principle II: TDD — written before HomeViewModel.
@MainActor
final class HomeViewModelTests: XCTestCase {

    // MARK: - Helpers

    private var store: ProfileStore!
    private var mockService: MockUserProfileService!
    private var sut: HomeViewModel!

    private let testDefaults = UserDefaults(suiteName: "HomeViewModelTests")!

    override func setUp() async throws {
        try await super.setUp()
        // Isolated UserDefaults so tests don't bleed into real app data.
        testDefaults.removePersistentDomain(forName: "HomeViewModelTests")
        store = ProfileStore(defaults: testDefaults)
        mockService = MockUserProfileService()
    }

    override func tearDown() async throws {
        testDefaults.removePersistentDomain(forName: "HomeViewModelTests")
        sut = nil
        store = nil
        mockService = nil
        try await super.tearDown()
    }

    private func makeSUT(email: String = "test@example.com") -> HomeViewModel {
        HomeViewModel(email: email, profileService: mockService, profileStore: store)
    }

    // MARK: - Cache hit: no fetch

    func test_loadProfile_completeCache_doesNotCallService() async throws {
        var profile = UserProfile(email: "test@example.com",
                                  weight: 70, weightUnit: "kg",
                                  height: 175, heightUnit: "cm")
        store.save(profile)

        sut = makeSUT()
        await sut.loadProfile()

        XCTAssertFalse(mockService.fetchCalled, "Service must NOT be called when cache is complete")
        XCTAssertEqual(sut.weight, 70)
        XCTAssertEqual(sut.height, 175)
    }

    // MARK: - Cache miss: fetch triggered

    func test_loadProfile_incompleteCache_callsService() async throws {
        store.saveEmail("test@example.com") // email present, no weight/height
        let profile = UserProfile(email: "test@example.com",
                                  weight: 80, weightUnit: "kg",
                                  height: 180, heightUnit: "cm")
        mockService.profileToReturn = profile

        sut = makeSUT()
        await sut.loadProfile()

        XCTAssertTrue(mockService.fetchCalled)
        XCTAssertEqual(sut.weight, 80)
        XCTAssertEqual(sut.height, 180)
        XCTAssertEqual(sut.weightUnit, "kg")
        XCTAssertEqual(sut.heightUnit, "cm")
    }

    // MARK: - 200: properties populated

    func test_loadProfile_200_populatesAllProperties() async throws {
        let profile = UserProfile(email: "test@example.com",
                                  weight: 65.5, weightUnit: "kg",
                                  height: 168.0, heightUnit: "cm")
        mockService.profileToReturn = profile

        sut = makeSUT()
        await sut.loadProfile()

        XCTAssertEqual(sut.email, "test@example.com")
        XCTAssertEqual(sut.weight, 65.5)
        XCTAssertEqual(sut.weightUnit, "kg")
        XCTAssertEqual(sut.height, 168.0)
        XCTAssertEqual(sut.heightUnit, "cm")
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.navigationState, .home)
    }

    // MARK: - 404: navigate to createUser

    func test_loadProfile_404_setsNavigationStateToCreateUser() async throws {
        mockService.errorToThrow = ProfileFetchError.userNotFound

        sut = makeSUT()
        await sut.loadProfile()

        XCTAssertEqual(sut.navigationState, .createUser)
    }

    // MARK: - Network error: errorMessage set, email still visible

    func test_loadProfile_networkError_setsErrorMessage() async throws {
        mockService.errorToThrow = ProfileFetchError.networkError(URLError(.notConnectedToInternet))

        sut = makeSUT(email: "test@example.com")
        await sut.loadProfile()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.email, "test@example.com", "Email must remain visible on error")
        XCTAssertEqual(sut.navigationState, .home)
    }

    // MARK: - isLoading clears after fetch

    func test_loadProfile_isLoadingClearsAfterCompletion() async throws {
        let profile = UserProfile(email: "test@example.com",
                                  weight: 70, weightUnit: "kg",
                                  height: 175, heightUnit: "cm")
        mockService.profileToReturn = profile

        sut = makeSUT()
        await sut.loadProfile()

        XCTAssertFalse(sut.isLoading)
    }
}

// MARK: - MockUserProfileService

@MainActor
final class MockUserProfileService: UserProfileServiceProtocol {
    var fetchCalled = false
    var profileToReturn: UserProfile?
    var errorToThrow: Error?

    func fetchProfile(email: String) async throws -> UserProfile {
        fetchCalled = true
        if let error = errorToThrow { throw error }
        guard var profile = profileToReturn else {
            throw ProfileFetchError.userNotFound
        }
        profile.email = email
        return profile
    }
}
