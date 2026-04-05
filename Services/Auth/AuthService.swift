import Foundation
import Observation
import GoogleSignIn

/// Concrete authentication service (T017).
///
/// Implements the full Google Sign-In OAuth2 flow:
///   1. Present Google's OAuth sheet via `GIDSignIn`.
///   2. Extract the `idToken` from the result.
///   3. (Future – T014/T015) Exchange `idToken` with the BodyMetric backend for
///      an `accessToken` + `refreshToken` and persist them to Keychain.
///
/// For now (no backend yet), a successful Google sign-in sets `isAuthenticated = true`
/// and logs the outcome so the flow is visible end-to-end.
///
/// Constitution Principle III: all errors logged before surfacing.
/// Constitution Principle IV: key events traced (stubs until Tracer is wired).
@Observable
@MainActor
final class AuthService: AuthServiceProtocol {

    // MARK: - State

    /// `true` when the user has a valid Google session.
    private(set) var isAuthenticated: Bool = false

    // MARK: - AuthServiceProtocol

    func signInWithGoogle() async throws {
        let _ = print("🚀 Sign-in initiated")  // temporary test
        Logger.info("Sign-in initiated", category: .auth)

        // Resolve the root view controller required by GoogleSignIn to present its sheet.
        guard let windowScene = await UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            Logger.error("Sign-in failed: no active window scene found", category: .auth)
            throw AuthError.googleSignInFailed(
                underlying: NSError(domain: "AuthService", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "No active window"])
            )
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            let user = result.user

            // Log success without exposing PII (log only token prefix for debugging).
            if let idToken = user.idToken?.tokenString {
                let preview = String(idToken.prefix(12)) + "..."
                Logger.info("✅ Google Sign-In succeeded. idToken preview: \(preview)", category: .auth)
            } else {
                Logger.warning("Google Sign-In succeeded but idToken is nil", category: .auth)
            }

            // TODO(T014/T015): Exchange idToken with backend → store accessToken + refreshToken in Keychain.
            // For now, mark the user as authenticated directly.
            isAuthenticated = true
            Logger.info("User is now authenticated", category: .auth)

        } catch {
            // Check if the user simply cancelled (not a real failure).
            if (error as NSError).code == GIDSignInError.canceled.rawValue {
                Logger.info("Sign-in cancelled by user", category: .auth)
                // Re-throw so LoginViewModel can clear the loading state cleanly.
                throw AuthError.googleSignInFailed(underlying: error)
            }

            Logger.error("❌ Google Sign-In failed", error: error, category: .auth)
            throw AuthError.googleSignInFailed(underlying: error)
        }
    }

    func signOut() async throws {
        GIDSignIn.sharedInstance.signOut()
        isAuthenticated = false
        Logger.info("User signed out", category: .auth)
        // TODO(T014): Call DELETE /auth/session on the backend.
        // TODO(T012): Clear Keychain tokens once KeychainService is implemented.
    }

    // MARK: - Session restoration

    /// Attempt to restore a previous sign-in silently (called during SplashView).
    /// Returns `true` if a prior session was restored without user interaction.
    func restorePreviousSignIn() async -> Bool {
        do {
            try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            Logger.info("✅ Previous Google session restored", category: .auth)
            isAuthenticated = true
            return true
        } catch {
            Logger.debug("No previous session to restore: \(error.localizedDescription)", category: .auth)
            return false
        }
    }
}
