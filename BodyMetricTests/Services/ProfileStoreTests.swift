import XCTest
@testable import BodyMetric

/// Unit tests for ProfileStore.
///
/// Uses an isolated UserDefaults suite so tests never bleed into real app data.
///
/// Constitution Principle II: TDD — written before the store's callers in US2.
final class ProfileStoreTests: XCTestCase {

    private var sut: ProfileStore!
    private let suite = "ProfileStoreTests"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        sut = ProfileStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        sut = nil
        defaults = nil
        super.tearDown()
    }

    // MARK: - isComplete

    func test_isComplete_allFieldsPresent_returnsTrue() {
        let profile = UserProfile(email: "a@b.com",
                                  weight: 70, weightUnit: "kg",
                                  height: 175, heightUnit: "cm")
        sut.save(profile)
        XCTAssertTrue(sut.isComplete)
    }

    func test_isComplete_missingWeight_returnsFalse() {
        let profile = UserProfile(email: "a@b.com",
                                  weight: nil, weightUnit: nil,
                                  height: 175, heightUnit: "cm")
        sut.save(profile)
        XCTAssertFalse(sut.isComplete)
    }

    func test_isComplete_missingHeight_returnsFalse() {
        let profile = UserProfile(email: "a@b.com",
                                  weight: 70, weightUnit: "kg",
                                  height: nil, heightUnit: nil)
        sut.save(profile)
        XCTAssertFalse(sut.isComplete)
    }

    func test_isComplete_emptyStore_returnsFalse() {
        XCTAssertFalse(sut.isComplete)
    }

    // MARK: - Round-trip save / read

    func test_save_roundTrip_allValues() {
        let profile = UserProfile(email: "test@example.com",
                                  weight: 82.5, weightUnit: "kg",
                                  height: 182.0, heightUnit: "cm")
        sut.save(profile)

        XCTAssertEqual(sut.email, "test@example.com")
        XCTAssertEqual(sut.weight, 82.5)
        XCTAssertEqual(sut.weightUnit, "kg")
        XCTAssertEqual(sut.height, 182.0)
        XCTAssertEqual(sut.heightUnit, "cm")
    }

    // MARK: - clear

    func test_clear_removesAllValues() {
        let profile = UserProfile(email: "test@example.com",
                                  weight: 70, weightUnit: "kg",
                                  height: 175, heightUnit: "cm")
        sut.save(profile)
        sut.clear()

        XCTAssertNil(sut.email)
        XCTAssertNil(sut.weight)
        XCTAssertNil(sut.weightUnit)
        XCTAssertNil(sut.height)
        XCTAssertNil(sut.heightUnit)
        XCTAssertFalse(sut.isComplete)
    }

    // MARK: - saveEmail

    func test_saveEmail_persistsEmail() {
        sut.saveEmail("only@email.com")
        XCTAssertEqual(sut.email, "only@email.com")
        XCTAssertFalse(sut.isComplete, "Saving only email must not mark store as complete")
    }

    // MARK: - A2 remediation: API → persist → read round-trip

    func test_save_afterAPIResponse_valuesReadableImmediately() {
        // Simulate: mock service returns a profile, HomeViewModel calls save, then reads back.
        let apiProfile = UserProfile(email: "user@example.com",
                                     weight: 68.0, weightUnit: "kg",
                                     height: 170.0, heightUnit: "cm")
        sut.save(apiProfile)

        XCTAssertEqual(sut.weight, 68.0, "Weight must be readable immediately after save")
        XCTAssertEqual(sut.height, 170.0, "Height must be readable immediately after save")
        XCTAssertTrue(sut.isComplete, "Store must be complete after full API response save")
    }
}
