import Foundation

/// Minimal authentication contract consumed by ViewModels.
///
/// The protocol boundary allows ViewModels, previews, and tests to compile
/// independently of the concrete `AuthService` implementation.
@MainActor
protocol AuthServiceProtocol: AnyObject {

    /// `true` when the user has a valid session (tokens stored and authenticated).
    var isAuthenticated: Bool { get }

    /// The authenticated user's email address, or `nil` if no session is active.
    /// Sourced from `GIDSignIn.sharedInstance.currentUser?.profile?.email`.
    var authenticatedEmail: String? { get }

    /// Initiates the Google Sign-In OAuth2 flow, exchanges the resulting id token
    /// for a BodyMetric session token pair, and persists them appropriately.
    ///
    /// - Throws: `AuthError` on failure.
    func signInWithGoogle() async throws

    /// Clears in-memory and Keychain tokens, signs out from Google, and
    /// sets `isAuthenticated = false`.
    func signOut() async throws

    /// Attempts to restore a previous sign-in silently (called during SplashView).
    /// Returns `true` if a prior session was restored without user interaction.
    func restorePreviousSignIn() async -> Bool
}

// MARK: - Auth errors

enum AuthError: LocalizedError {
    case googleSignInFailed(underlying: Error)
    case tokenExchangeFailed
    case keychainWriteFailed

    var errorDescription: String? {
        switch self {
        case .googleSignInFailed:  return "Google Sign-In was cancelled or failed."
        case .tokenExchangeFailed: return "Could not authenticate with the server. Please try again."
        case .keychainWriteFailed: return "Could not securely save your session. Please try again."
        }
    }
}
