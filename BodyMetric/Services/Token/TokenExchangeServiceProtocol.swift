import Foundation

/// Contract for the Google id token → backend token exchange call.
///
/// Called once immediately after `GIDSignIn.signIn()` succeeds.
/// Sends the Google id token to `POST /api/auth/google` and receives
/// a backend-issued access token + refresh token.
@MainActor
protocol TokenExchangeServiceProtocol: AnyObject {

    /// Exchanges a Google Sign-In id token for a BodyMetric token pair.
    /// - Parameter googleIdToken: The id token from `GIDSignIn` result.
    /// - Returns: A `TokenExchangeResponse` containing access + refresh tokens.
    /// - Throws: `AuthError.tokenExchangeFailed` on 401 or network failure.
    func exchange(googleIdToken: String) async throws -> TokenExchangeResponse
}
