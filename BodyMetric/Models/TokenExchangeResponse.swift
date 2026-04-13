import Foundation

/// Decoded response from `POST /api/auth/google`.
///
/// Contains the backend-issued access token and refresh token
/// returned after exchanging a Google Sign-In id token.
struct TokenExchangeResponse: Decodable {

    /// Short-lived access token to be held in memory only.
    /// Backend field name: `sessionToken`
    let accessToken: String

    /// Long-lived refresh token to be persisted in Keychain.
    let refreshToken: String

    private enum CodingKeys: String, CodingKey {
        case accessToken  = "sessionToken"
        case refreshToken = "refreshToken"
    }
}
