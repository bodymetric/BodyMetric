import Foundation

/// Contract for the token refresh network call.
///
/// Sends the stored refresh token to `POST /api/auth/refresh`
/// and returns a new token pair on success.
@MainActor
protocol TokenRefreshServiceProtocol: AnyObject {

    /// Exchanges the current refresh token for a new access token.
    /// - Parameter refreshToken: The refresh token stored in Keychain.
    /// - Returns: A `TokenRefreshResponse` containing the new access token
    ///   and optionally a new refresh token (if the backend rotates them).
    /// - Throws: `AuthError.tokenExchangeFailed` on 401 or network failure.
    func refresh(using refreshToken: String) async throws -> TokenRefreshResponse
}
