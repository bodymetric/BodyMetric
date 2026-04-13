import Foundation

/// Contract for secure refresh token persistence via iOS Keychain.
///
/// Only the refresh token is persisted to Keychain (long-lived).
/// The access token is NEVER stored here (Constitution Principle VII).
protocol KeychainServiceProtocol: AnyObject {

    /// Persists the refresh token in the iOS Keychain.
    /// Overwrites any existing value.
    /// - Throws: `AuthError.keychainWriteFailed` on failure.
    func saveRefreshToken(_ token: String) throws

    /// Reads the refresh token from the iOS Keychain.
    /// - Throws: `AuthError.keychainWriteFailed` if the token is absent or unreadable.
    func loadRefreshToken() throws -> String

    /// Deletes the refresh token from the iOS Keychain.
    /// A no-op if the token is already absent.
    /// - Throws: `AuthError.keychainWriteFailed` on unexpected failure.
    func deleteRefreshToken() throws
}
