import Foundation
import Observation

/// View model for `LoginView`.
///
/// Owns the sign-in action and surfaces loading / error state to the view.
/// Depends on `AuthServiceProtocol` — injected at construction for testability.
@Observable
@MainActor
final class LoginViewModel {

    // MARK: - Published state

    /// `true` while the sign-in network call is in flight.
    var isLoading: Bool = false

    /// Non-nil when sign-in failed; cleared on the next sign-in attempt.
    var errorMessage: String?

    // MARK: - Private

    private let authService: AuthServiceProtocol

    // MARK: - Init

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    // MARK: - Actions

    /// Initiates the Google Sign-In flow.
    /// Clears any previous error, sets `isLoading`, and delegates to `AuthService`.
    func signIn() async {
        
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        // TODO(Principle IV): Tracer.track(event: TraceEvent(name: "login_tapped"))

        do {
            
           
            try await authService.signInWithGoogle()
        } catch {
            // TODO(Principle III): Logger.error("Sign-in failed", error: error)
            let _ = print("HEEETY")
            
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Sign-in failed. Please try again."
        }
    }
}
