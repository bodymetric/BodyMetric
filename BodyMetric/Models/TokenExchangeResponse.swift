import Foundation

/// Decoded response from `POST /api/auth/google`.
///
/// Contains the backend-issued access token, refresh token, and the
/// authenticated user's profile object. The `user` field is used to detect
/// profile incompleteness at login time (feature 005).
struct TokenExchangeResponse: Decodable {

    /// Short-lived access token to be held in memory only.
    /// Backend field name: `sessionToken`
    let accessToken: String

    /// Long-lived refresh token to be persisted in Keychain.
    let refreshToken: String

    /// User profile returned by the backend at login time.
    /// Used to check completeness (name, height, weight) before routing.
    let user: AuthUser

    private enum CodingKeys: String, CodingKey {
        case accessToken  = "sessionToken"
        case refreshToken = "refreshToken"
        case user         = "user"
    }
}
