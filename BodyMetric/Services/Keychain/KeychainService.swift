import Foundation
import Security

/// Secure refresh token persistence via iOS Keychain.
///
/// Only the refresh token is stored here. The access token is NEVER
/// written to Keychain — it lives in memory only (Constitution Principle VII).
///
/// Log policy: token values MUST NEVER appear in any log entry.
/// Only boolean presence (`present: true/false`) is logged.
///
/// Constitution Principle I: pure Swift, Security framework (no third-party dependency).
/// Constitution Principle III: all errors logged before surfacing; no PII or token values.
/// Constitution Principle VII: sole storage for long-lived session credentials.
final class KeychainService: KeychainServiceProtocol {

    // MARK: - Constants

    private let key: String
    private static let defaultKey = "bm.token.refresh"

    // MARK: - Init

    /// - Parameter key: Keychain key. Defaults to production key `bm.token.refresh`.
    ///   Override in tests with a test-only prefix to avoid polluting production data.
    init(key: String = KeychainService.defaultKey) {
        self.key = key
    }

    // MARK: - KeychainServiceProtocol

    func saveRefreshToken(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw AuthError.keychainWriteFailed
        }

        // Delete any existing entry first (update by delete + add is the simplest path).
        let deleteQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)

        guard status == errSecSuccess else {
            Logger.error("KeychainService: failed to save refresh token (status: \(status))",
                         category: .auth)
            throw AuthError.keychainWriteFailed
        }
        Logger.debug("KeychainService: refresh token saved (present: true)", category: .auth)
    }

    func loadRefreshToken() throws -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            Logger.debug("KeychainService: refresh token not found (present: false)", category: .auth)
            throw AuthError.keychainWriteFailed
        }
        Logger.debug("KeychainService: refresh token loaded (present: true)", category: .auth)
        return token
    }

    func deleteRefreshToken() throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        // errSecItemNotFound is fine — no-op when absent is the desired behaviour.
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            Logger.error("KeychainService: failed to delete refresh token (status: \(status))",
                         category: .auth)
        }
        Logger.debug("KeychainService: refresh token deleted (present: false)", category: .auth)
    }
}
