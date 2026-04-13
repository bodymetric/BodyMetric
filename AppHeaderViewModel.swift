import Foundation
import Observation

/// ViewModel for AppHeader.
///
/// Owns the logout action and delegates to `AuthServiceProtocol`.
/// On failure the error is logged and surfaced via `errorMessage`;
/// the user remains authenticated (FR-007).
///
/// Constitution Principle III: sign-out errors logged with context; no PII.
/// Constitution Principle IV: `header_logout_tapped` trace stub present.
@Observable
@MainActor
final class AppHeaderViewModel {

    // MARK: - State

    private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol

    // MARK: - Init

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    // MARK: - Actions

    func logout() async {
        traceEvent("header_logout_tapped")
        Logger.info("Logout tapped from header", category: .auth)
        do {
            try await authService.signOut()
            errorMessage = nil
            Logger.info("Logout successful", category: .auth)
        } catch {
            Logger.error("Logout failed — user remains authenticated", error: error, category: .auth)
            errorMessage = "Sign-out failed. Please try again."
        }
    }

    // MARK: - Tracing stub (Constitution Principle IV)

    private func traceEvent(_ name: String) {
        // TODO(Tracer): replace with Tracer.shared.trace(name)
        Logger.debug("Trace: \(name)", category: .general)
    }
}
