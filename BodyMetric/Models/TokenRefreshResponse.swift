import Foundation

/// Decoded response from `POST /api/auth/refresh`.
///
/// Always contains a new access token. The refresh token is optional —
/// present only if the backend rotates refresh tokens.
struct TokenRefreshResponse: Decodable {

    /// New short-lived access token to replace the current in-memory token.
    let accessToken: String

    /// New refresh token, if the backend rotates refresh tokens.
    /// If `nil`, the existing Keychain refresh token remains valid.
    let refreshToken: String?

    private enum CodingKeys: String, CodingKey {
        case accessToken  = "sessionToken"
        case refreshToken = "refreshToken"
    }
}
