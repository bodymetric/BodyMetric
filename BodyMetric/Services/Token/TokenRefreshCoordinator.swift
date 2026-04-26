import Foundation

// MARK: - Protocol

/// Contract for the token refresh coordinator — enables testable injection
/// into `NetworkClient` and `AuthService` without subclassing the actor.
protocol TokenRefreshCoordinatorProtocol: AnyObject, Sendable {

    /// Refreshes the access token (serialized — at most one refresh in-flight at a time).
    /// On success: updates `tokenStore` with the new access token.
    /// On failure: clears `tokenStore`, deletes Keychain refresh token, calls `onForceLogout`.
    func refresh(tokenStore: any TokenStoreProtocol) async throws
}

// MARK: - Coordinator

/// Serializes concurrent token refresh attempts to ensure only one
/// `POST /api/auth/refresh` call is in-flight at any given time.
///
/// When multiple callers (e.g., several simultaneous 401 responses) attempt
/// to refresh, the first call starts a `Task`; subsequent callers await the
/// same task and reuse its result. This satisfies FR-007.
///
/// Constitution Principle I: pure Swift actor.
/// Constitution Principle III: tokens never logged — only boolean presence.
/// Constitution Principle IV: trace events emitted on start/success/failure.
/// Constitution Principle VII: Keychain refresh token updated or deleted here.
actor TokenRefreshCoordinator: TokenRefreshCoordinatorProtocol {

    // MARK: - Dependencies

    private let refreshService: TokenRefreshServiceProtocol
    private let keychainService: KeychainServiceProtocol
    /// Called when refresh fails — clears app auth state and navigates to login.
    private let onForceLogout: @Sendable () async -> Void

    // MARK: - Concurrency guard

    private var ongoingRefresh: Task<Void, Error>?

    // MARK: - Init

    init(
        refreshService: TokenRefreshServiceProtocol,
        keychainService: KeychainServiceProtocol,
        onForceLogout: @escaping @Sendable () async -> Void
    ) {
        self.refreshService = refreshService
        self.keychainService = keychainService
        self.onForceLogout = onForceLogout
    }

    // MARK: - TokenRefreshCoordinatorProtocol

    func refresh(tokenStore: any TokenStoreProtocol) async throws {
        // If a refresh is already in progress, await its result instead of starting another.
        if let ongoing = ongoingRefresh {
            try await ongoing.value
            return
        }

        traceEvent("token_refresh_started")
        Logger.info("TokenRefreshCoordinator: refresh started", category: .auth)

        let refreshSvc = refreshService
        let keychainSvc = keychainService
        let forceLogout = onForceLogout

        let task = Task<Void, Error> {
            do {
                let refreshToken = try keychainSvc.loadRefreshToken()
                let response = try await refreshSvc.refresh(using: refreshToken)

                await tokenStore.store(accessToken: response.accessToken)

                if let newRefreshToken = response.refreshToken {
                    try keychainSvc.saveRefreshToken(newRefreshToken)
                    Logger.debug(
                        "TokenRefreshCoordinator: refresh token rotated (present: true)",
                        category: .auth
                    )
                }

                Logger.info("TokenRefreshCoordinator: refresh succeeded", category: .auth)
                traceEvent("token_refresh_succeeded")

            } catch {
                Logger.error("TokenRefreshCoordinator: refresh failed — forcing logout",
                             error: error, category: .auth)
                traceEvent("token_refresh_failed")

                await tokenStore.clearAccessToken()
                try? keychainSvc.deleteRefreshToken()
                await forceLogout()
                throw error
            }
        }

        ongoingRefresh = task
        defer { ongoingRefresh = nil }
        try await task.value
    }

    // MARK: - Tracing stub (Constitution Principle IV)

    private func traceEvent(_ name: String) {
        // TODO(Tracer): replace with Tracer.shared.trace(name)
        Logger.debug("Trace: \(name)", category: .general)
    }
}
