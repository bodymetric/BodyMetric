import Foundation

/// Minimal authentication contract consumed by ViewModels.
///
/// Full implementation lives in `AuthService.swift` (task T017) once the
/// GoogleSignIn-iOS SPM package is added (task T002).
/// The protocol boundary allows ViewModels and previews to compile independently.
@MainActor
protocol AuthServiceProtocol: AnyObject {

    /// `true` when the user has a valid session (access token present in Keychain).
    var isAuthenticated: Bool { get }

    /// The authenticated user's email address, or `nil` if no session is active.
    /// Sourced from `GIDSignIn.sharedInstance.currentUser?.profile?.email`.
    var authenticatedEmail: String? { get }

    /// Initiates the Google Sign-In OAuth2 flow and exchanges the resulting
    /// `idToken` for a BodyMetric session token pair, persisting both to Keychain.
    ///
    /// - Throws: `AuthError` on failure.
    func signInWithGoogle() async throws

    /// Invalidates the current session on the server and clears both tokens from Keychain.
    func signOut() async throws
}

// MARK: - Auth errors

enum AuthError: LocalizedError {
    case googleSignInFailed(underlying: Error)
    case tokenExchangeFailed
    case keychainWriteFailed

    var errorDescription: String? {
        switch self {
        case .googleSignInFailed: return "Google Sign-In was cancelled or failed."
        case .tokenExchangeFailed: return "Could not authenticate with the server. Please try again."
        case .keychainWriteFailed: return "Could not securely save your session. Please try again."
        }
    }
}
