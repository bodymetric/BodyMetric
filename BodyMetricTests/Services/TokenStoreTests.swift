import XCTest
@testable import BodyMetric

/// Unit tests for TokenStore.
///
/// Timer tests use timerInterval = 0.05 s so the full proactive-refresh path
/// is exercised without waiting 295 seconds.
///
/// Constitution Principle II: TDD — written before TokenStore.
@MainActor
final class TokenStoreTests: XCTestCase {

    private var sut: TokenStore!

    override func setUp() async throws {
        try await super.setUp()
        sut = TokenStore(timerInterval: 0.05)
    }

    override func tearDown() async throws {
        await sut.clearAccessToken()
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Basic storage

    func test_initialAccessToken_isNil() async {
        let token = await sut.accessToken
        XCTAssertNil(token)
    }

    func test_store_setsAccessToken() async {
        await sut.store(accessToken: "token-abc")
        let token = await sut.accessToken
        XCTAssertEqual(token, "token-abc")
    }

    func test_store_newToken_replacesOldToken() async {
        await sut.store(accessToken: "first")
        await sut.store(accessToken: "second")
        let token = await sut.accessToken
        XCTAssertEqual(token, "second")
    }

    func test_clear_setsAccessTokenNil() async {
        await sut.store(accessToken: "token-abc")
        await sut.clearAccessToken()
        let token = await sut.accessToken
        XCTAssertNil(token)
    }

    // MARK: - Proactive timer

    func test_proactiveTimer_callsRefreshAction() async throws {
        var refreshCalled = false
        await sut.setRefreshAction { refreshCalled = true }
        await sut.store(accessToken: "timer-token")
        // Timer is 0.05 s; wait a bit longer to allow it to fire
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertTrue(refreshCalled,
                      "Proactive timer MUST invoke refreshAction after interval")
    }

    func test_storeNewToken_cancelsPreviousTimer() async throws {
        var callCount = 0
        await sut.setRefreshAction { callCount += 1 }

        await sut.store(accessToken: "first")
        // Immediately replace — first timer must be cancelled
        await sut.store(accessToken: "second")

        // Wait beyond what both timers would have needed
        try await Task.sleep(for: .milliseconds(300))

        XCTAssertEqual(callCount, 1,
                       "Only the second timer should fire; first must be cancelled")
    }

    func test_clearAccessToken_cancelsTimer() async throws {
        var refreshCalled = false
        await sut.setRefreshAction { refreshCalled = true }

        await sut.store(accessToken: "token")
        await sut.clearAccessToken()

        try await Task.sleep(for: .milliseconds(200))
        XCTAssertFalse(refreshCalled,
                       "Timer must NOT fire after clearAccessToken()")
    }

    func test_noRefreshAction_timerFires_doesNotCrash() async throws {
        // No action set — timer fires but action is nil; must not crash
        await sut.store(accessToken: "token")
        try await Task.sleep(for: .milliseconds(200))
        // If we get here without a crash or assertion, the test passes
    }
}
