import XCTest
@testable import BodyMetric

/// Unit tests for KeychainService.
///
/// Uses a test-only key prefix to avoid polluting production Keychain data.
/// Each test cleans up after itself via tearDown.
///
/// Constitution Principle II: TDD — written before KeychainService.
final class KeychainServiceTests: XCTestCase {

    private var sut: KeychainService!

    override func setUp() {
        super.setUp()
        // Use test key prefix so we never touch production "bm.token.refresh"
        sut = KeychainService(key: "bm.test.token.refresh")
        try? sut.deleteRefreshToken() // clean slate
    }

    override func tearDown() {
        try? sut.deleteRefreshToken()
        sut = nil
        super.tearDown()
    }

    // MARK: - saveRefreshToken / loadRefreshToken

    func test_saveAndLoad_roundTrip() throws {
        try sut.saveRefreshToken("my-refresh-token")
        let loaded = try sut.loadRefreshToken()
        XCTAssertEqual(loaded, "my-refresh-token")
    }

    func test_save_overwritesPreviousValue() throws {
        try sut.saveRefreshToken("first-token")
        try sut.saveRefreshToken("second-token")
        let loaded = try sut.loadRefreshToken()
        XCTAssertEqual(loaded, "second-token", "Second save must overwrite the first")
    }

    // MARK: - loadRefreshToken when absent

    func test_load_throwsWhenAbsent() {
        XCTAssertThrowsError(try sut.loadRefreshToken(),
                             "load must throw when no token is stored")
    }

    // MARK: - deleteRefreshToken

    func test_delete_removesToken() throws {
        try sut.saveRefreshToken("token-to-delete")
        try sut.deleteRefreshToken()
        XCTAssertThrowsError(try sut.loadRefreshToken(),
                             "load must throw after delete")
    }

    func test_delete_isNoOpWhenAbsent() {
        // Deleting when nothing is stored must not throw
        XCTAssertNoThrow(try sut.deleteRefreshToken())
    }
}
