import Foundation
import Observation
import GoogleSignIn

/// Concrete authentication service.
///
/// Sign-in flow:
///   1. Present Google OAuth sheet via `GIDSignIn`.
///   2. Extract `idToken` from the result.
///   3. Exchange `idToken` with the BodyMetric backend (`TokenExchangeService`)
///      for a backend-issued access token + refresh token.
///   4. Store the access token in memory (`TokenStore`).
///   5. Persist the refresh token in Keychain (`KeychainService`).
///
/// Sign-out flow:
///   1. Clear access token from `TokenStore` (and cancel proactive timer).
///   2. Delete refresh token from Keychain.
///   3. Call `GIDSignIn.signOut()`.
///   4. Set `isAuthenticated = false`.
///
/// Constitution Principle III: all errors logged before surfacing; tokens never logged.
/// Constitution Principle IV: key events traced.
/// Constitution Principle VII: access token in memory only; refresh token in Keychain only.
@Observable
@MainActor
final class AuthService: AuthServiceProtocol {

    // MARK: - State

    private(set) var isAuthenticated: Bool = false

    /// `true` when the authenticated user's profile is missing name, height, or weight.
    /// Set by `signInWithGoogle()` after token exchange and by `restorePreviousSignIn()`.
    /// `BodyMetricApp` routes to the profile completion form when this is `true`.
    private(set) var needsProfileSetup: Bool = false

    var authenticatedEmail: String? {
        GIDSignIn.sharedInstance.currentUser?.profile?.email
    }

    // MARK: - Dependencies

    private let tokenExchangeService: TokenExchangeServiceProtocol
    private let tokenStore: any TokenStoreProtocol
    private let keychainService: KeychainServiceProtocol
    private let coordinator: any TokenRefreshCoordinatorProtocol
    private let profileStore: ProfileStore

    // MARK: - Init

    init(
        tokenExchangeService: TokenExchangeServiceProtocol,
        tokenStore: any TokenStoreProtocol,
        keychainService: KeychainServiceProtocol,
        coordinator: any TokenRefreshCoordinatorProtocol,
        profileStore: ProfileStore = ProfileStore()
    ) {
        self.tokenExchangeService = tokenExchangeService
        self.tokenStore = tokenStore
        self.keychainService = keychainService
        self.coordinator = coordinator
        self.profileStore = profileStore
    }

    // MARK: - AuthServiceProtocol

    func signInWithGoogle() async throws {
        Logger.info("Sign-in initiated", category: .auth)
        traceEvent("token_exchange_started")

        guard let windowScene = await UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else {
            Logger.error("Sign-in failed: no active window scene found", category: .auth)
            throw AuthError.googleSignInFailed(
                underlying: NSError(domain: "AuthService", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "No active window"])
            )
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            let user = result.user

            guard let idToken = user.idToken?.tokenString else {
                Logger.warning("Google Sign-In succeeded but idToken is nil", category: .auth)
                throw AuthError.tokenExchangeFailed
            }

            Logger.info("Google Sign-In succeeded. Exchanging id token...", category: .auth)

            let tokenPair = try await tokenExchangeService.exchange(googleIdToken: idToken)

            await tokenStore.store(accessToken: tokenPair.accessToken)
            try keychainService.saveRefreshToken(tokenPair.refreshToken)

            // Always persist the user object so userId is available for subsequent
            // API calls (e.g. PUT /api/users/{id}) even when the profile is incomplete.
            profileStore.save(from: tokenPair.user)
            needsProfileSetup = !tokenPair.user.isComplete
            Logger.info(
                "Profile completeness at login: needsProfileSetup=\(needsProfileSetup)",
                category: .auth
            )

            isAuthenticated = true
            traceEvent("token_exchange_succeeded")
            Logger.info("User is now authenticated (tokens stored)", category: .auth)

        } catch let authErr as AuthError {
            traceEvent("token_exchange_failed")
            Logger.error("Sign-in/exchange failed", category: .auth)
            throw authErr
        } catch {
            if (error as NSError).code == GIDSignInError.canceled.rawValue {
                Logger.info("Sign-in cancelled by user", category: .auth)
                throw AuthError.googleSignInFailed(underlying: error)
            }
            traceEvent("token_exchange_failed")
            Logger.error("Google Sign-In failed", error: error, category: .auth)
            throw AuthError.googleSignInFailed(underlying: error)
        }
    }

    func signOut() async throws {
        Logger.info("Sign-out initiated", category: .auth)

        await tokenStore.clearAccessToken()

        do {
            try keychainService.deleteRefreshToken()
        } catch {
            // Deletion failure is non-fatal for sign-out; log and continue.
            Logger.error("Sign-out: failed to delete refresh token from Keychain",
                         error: error, category: .auth)
        }

        GIDSignIn.sharedInstance.signOut()
        isAuthenticated = false
        traceEvent("tokens_cleared_on_logout")
        Logger.info("User signed out; all tokens cleared", category: .auth)
    }

    // MARK: - Session restoration

    func restorePreviousSignIn() async -> Bool {
        do {
            try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            // Check Keychain for a valid refresh token — if absent, no real session.
            if (try? keychainService.loadRefreshToken()) != nil {
                Logger.info("Previous session restored (refresh token present)", category: .auth)
                // Re-apply profile completeness gate on restore.
                needsProfileSetup = !profileStore.isComplete
                Logger.info(
                    "Session restore: needsProfileSetup=\(needsProfileSetup)",
                    category: .auth
                )
                isAuthenticated = true
                return true
            } else {
                Logger.warning(
                    "Google session restored but no refresh token in Keychain — signing out",
                    category: .auth
                )
                GIDSignIn.sharedInstance.signOut()
                return false
            }
        } catch {
            Logger.debug("No previous session to restore: \(error.localizedDescription)",
                         category: .auth)
            return false
        }
    }

    // MARK: - Profile setup gate

    /// Clears the profile setup gate after a successful profile completion submission.
    func clearNeedsProfileSetup() {
        needsProfileSetup = false
        Logger.info("AuthService: needsProfileSetup cleared", category: .auth)
    }

    // MARK: - Force sign-out (called by TokenRefreshCoordinator on refresh failure)

    /// Non-throwing version of `signOut()` used when the coordinator detects
    /// that the refresh token has expired and must forcibly end the session.
    func forceSignOut() async {
        Logger.warning("AuthService: force sign-out triggered by token refresh failure",
                       category: .auth)
        try? await signOut()
    }

    // MARK: - Tracing stub (Constitution Principle IV)

    private func traceEvent(_ name: String) {
        // TODO(Tracer): replace with Tracer.shared.trace(name)
        Logger.debug("Trace: \(name)", category: .general)
    }
}
