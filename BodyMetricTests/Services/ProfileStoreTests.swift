import XCTest
@testable import BodyMetric

/// Unit tests for ProfileStore.
///
/// Uses an isolated UserDefaults suite so tests never bleed into real app data.
///
/// Constitution Principle II: TDD — written before the store's callers.
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

    // MARK: - isComplete (updated gate: name + height + weight required)

    func test_isComplete_allRequiredFieldsPresent_returnsTrue() {
        let profile = UserProfile(email: "a@b.com", name: "Alice",
                                  weight: 70, weightUnit: "kg",
                                  height: 175, heightUnit: "cm")
        sut.save(profile)
        XCTAssertTrue(sut.isComplete)
    }

    func test_isComplete_missingName_returnsFalse() {
        let profile = UserProfile(email: "a@b.com", name: nil,
                                  weight: 70, weightUnit: "kg",
                                  height: 175, heightUnit: "cm")
        sut.save(profile)
        XCTAssertFalse(sut.isComplete, "isComplete must be false when name is nil")
    }

    func test_isComplete_emptyName_returnsFalse() {
        let profile = UserProfile(email: "a@b.com", name: "",
                                  weight: 70, weightUnit: "kg",
                                  height: 175, heightUnit: "cm")
        sut.save(profile)
        XCTAssertFalse(sut.isComplete, "isComplete must be false when name is empty")
    }

    func test_isComplete_missingWeight_returnsFalse() {
        let profile = UserProfile(email: "a@b.com", name: "Alice",
                                  weight: nil, weightUnit: nil,
                                  height: 175, heightUnit: "cm")
        sut.save(profile)
        XCTAssertFalse(sut.isComplete)
    }

    func test_isComplete_weightZero_returnsFalse() {
        let profile = UserProfile(email: "a@b.com", name: "Alice",
                                  weight: 0, weightUnit: "kg",
                                  height: 175, heightUnit: "cm")
        sut.save(profile)
        XCTAssertFalse(sut.isComplete, "isComplete must be false when weight is 0")
    }

    func test_isComplete_missingHeight_returnsFalse() {
        let profile = UserProfile(email: "a@b.com", name: "Alice",
                                  weight: 70, weightUnit: "kg",
                                  height: nil, heightUnit: nil)
        sut.save(profile)
        XCTAssertFalse(sut.isComplete)
    }

    func test_isComplete_heightZero_returnsFalse() {
        let profile = UserProfile(email: "a@b.com", name: "Alice",
                                  weight: 70, weightUnit: "kg",
                                  height: 0, heightUnit: "cm")
        sut.save(profile)
        XCTAssertFalse(sut.isComplete, "isComplete must be false when height is 0")
    }

    func test_isComplete_emptyStore_returnsFalse() {
        XCTAssertFalse(sut.isComplete)
    }

    // MARK: - name field round-trip

    func test_save_persistsName() {
        let profile = UserProfile(email: "a@b.com", name: "Alice",
                                  weight: 70, weightUnit: "kg",
                                  height: 175, heightUnit: "cm")
        sut.save(profile)
        XCTAssertEqual(sut.name, "Alice")
    }

    func test_save_nilName_doesNotPersistName() {
        let profile = UserProfile(email: "a@b.com", name: nil,
                                  weight: 70, weightUnit: "kg",
                                  height: 175, heightUnit: "cm")
        sut.save(profile)
        XCTAssertNil(sut.name)
    }

    // MARK: - save(from: AuthUser)

    func test_saveFromAuthUser_persistsAllFields() {
        let user = AuthUser(id: 5, name: "Bob", email: "bob@example.com",
                            height: 180.0, weight: 80.0)
        sut.save(from: user)
        XCTAssertEqual(sut.name, "Bob")
        XCTAssertEqual(sut.email, "bob@example.com")
        XCTAssertEqual(sut.height, 180.0)
        XCTAssertEqual(sut.weight, 80.0)
    }

    func test_saveFromAuthUser_complete_isCompleteTrue() {
        let user = AuthUser(id: 1, name: "Bob", email: "bob@example.com",
                            height: 180.0, weight: 80.0)
        sut.save(from: user)
        XCTAssertTrue(sut.isComplete)
    }

    func test_saveFromAuthUser_nilName_isCompleteFalse() {
        let user = AuthUser(id: 1, name: nil, email: "bob@example.com",
                            height: 180.0, weight: 80.0)
        sut.save(from: user)
        XCTAssertFalse(sut.isComplete)
    }

    // MARK: - Round-trip save / read

    func test_save_roundTrip_allValues() {
        let profile = UserProfile(email: "test@example.com", name: "Tester",
                                  weight: 82.5, weightUnit: "kg",
                                  height: 182.0, heightUnit: "cm")
        sut.save(profile)

        XCTAssertEqual(sut.email, "test@example.com")
        XCTAssertEqual(sut.name, "Tester")
        XCTAssertEqual(sut.weight, 82.5)
        XCTAssertEqual(sut.weightUnit, "kg")
        XCTAssertEqual(sut.height, 182.0)
        XCTAssertEqual(sut.heightUnit, "cm")
    }

    // MARK: - clear

    func test_clear_removesAllValues_includingName() {
        let profile = UserProfile(email: "test@example.com", name: "Tester",
                                  weight: 70, weightUnit: "kg",
                                  height: 175, heightUnit: "cm")
        sut.save(profile)
        sut.clear()

        XCTAssertNil(sut.name)
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

    // MARK: - API response round-trip

    func test_save_afterAPIResponse_valuesReadableImmediately() {
        let apiProfile = UserProfile(email: "user@example.com", name: "User",
                                     weight: 68.0, weightUnit: "kg",
                                     height: 170.0, heightUnit: "cm")
        sut.save(apiProfile)

        XCTAssertEqual(sut.weight, 68.0, "Weight must be readable immediately after save")
        XCTAssertEqual(sut.height, 170.0, "Height must be readable immediately after save")
        XCTAssertTrue(sut.isComplete, "Store must be complete after full API response save")
    }
}
