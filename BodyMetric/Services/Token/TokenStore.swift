import Foundation

/// In-memory access token store with proactive 4-minute-55-second refresh timer.
///
/// The access token is held EXCLUSIVELY in memory — it is NEVER written
/// to disk, UserDefaults, or Keychain (Constitution Principle VII).
///
/// ## Circular dependency break
/// `TokenStore` and `TokenRefreshCoordinator` mutually depend on each other
/// (store fires the coordinator; coordinator updates the store). To avoid a
/// circular init dependency, `setRefreshAction(_:)` wires the timer action
/// after both objects are created.
///
/// Constitution Principle I: pure Swift actor.
/// Constitution Principle VII: access token never touches persistent storage.
actor TokenStore: TokenStoreProtocol {

    // MARK: - State

    private(set) var accessToken: String?
    private var timerTask: Task<Void, Never>?
    private var refreshAction: (@Sendable () async -> Void)?

    // MARK: - Configuration

    /// Seconds before the token expires to trigger a proactive refresh.
    /// Default is 295 (4 min 55 s). Override in tests for fast execution.
    let timerInterval: TimeInterval

    // MARK: - Init

    init(timerInterval: TimeInterval = 295) {
        self.timerInterval = timerInterval
    }

    // MARK: - TokenStoreProtocol

    func store(accessToken: String) {
        self.accessToken = accessToken
        timerTask?.cancel()
        let interval = timerInterval
        let action = refreshAction
        timerTask = Task { [action] in
            try? await Task.sleep(for: .seconds(interval))
            guard !Task.isCancelled else { return }
            await action?()
        }
        Logger.debug("TokenStore: access token stored, timer started (\(Int(timerInterval)) s)",
                     category: .auth)
    }

    func clearAccessToken() {
        accessToken = nil
        timerTask?.cancel()
        timerTask = nil
        Logger.debug("TokenStore: access token cleared, timer cancelled", category: .auth)
    }

    func setRefreshAction(_ action: (@Sendable () async -> Void)?) {
        self.refreshAction = action
    }
}
