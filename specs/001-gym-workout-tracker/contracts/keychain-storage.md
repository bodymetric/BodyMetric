# Keychain Storage Contract

**Branch**: `001-gym-workout-tracker` | **Date**: 2026-04-04

Defines exactly what is stored in the iOS Keychain, with what attributes, and the lifecycle rules governing each item. No other mechanism (UserDefaults, files, SwiftData) MAY be used to store these values.

---

## Stored Items

### Access Token

| Attribute | Value |
|---|---|
| `kSecClass` | `kSecClassGenericPassword` |
| `kSecAttrService` | `"com.bodymetric.app"` |
| `kSecAttrAccount` | `"access_token"` |
| `kSecAttrAccessible` | `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` |
| `kSecAttrSynchronizable` | `false` |
| Value type | UTF-8 encoded `String` (JWT bearer token) |

### Refresh Token

| Attribute | Value |
|---|---|
| `kSecClass` | `kSecClassGenericPassword` |
| `kSecAttrService` | `"com.bodymetric.app"` |
| `kSecAttrAccount` | `"refresh_token"` |
| `kSecAttrAccessible` | `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` |
| `kSecAttrSynchronizable` | `false` |
| Value type | UTF-8 encoded opaque `String` |

---

## Lifecycle Rules

### Write (store)

- Tokens are written immediately after receiving a `200` response from `POST /auth/google`.
- A new `accessToken` is written immediately after a successful `POST /auth/refresh`.
- Write MUST use `kSecItemUpdate` if the item already exists (upsert pattern).
- If the write fails, the error MUST be logged (Principle III) and the auth flow MUST be retried or aborted — a silent failure is not acceptable.

### Read (retrieve)

- `accessToken` is read before every API request to populate the `Authorization` header.
- `refreshToken` is read only by `AuthService.refreshToken()`.
- A missing item on read means the user is unauthenticated; `AuthService` MUST redirect to login.

### Delete (clear)

- Both items MUST be deleted on:
  1. User-initiated logout (`DELETE /auth/session` success).
  2. Failed refresh (`POST /auth/refresh` returns 401).
  3. App receives a `403` on any request where the access token is not the cause.
- Deletion MUST be atomic: delete both items in sequence before navigating away. If deletion of either fails, log the error and attempt deletion of the remaining item.

---

## `KeychainService` Interface Contract

```swift
protocol KeychainServiceProtocol {
    func save(key: KeychainKey, value: String) throws
    func read(key: KeychainKey) throws -> String
    func delete(key: KeychainKey) throws
    func clearAll() throws
}

enum KeychainKey: String {
    case accessToken  = "access_token"
    case refreshToken = "refresh_token"
}

enum KeychainError: Error {
    case itemNotFound
    case writeFailed(OSStatus)
    case readFailed(OSStatus)
    case deleteFailed(OSStatus)
    case unexpectedData
}
```

- All errors thrown by `KeychainService` MUST be caught and logged at the call site (Principle III).
- `KeychainService` MUST be injectable (protocol-based) so tests can use an in-memory mock without touching the real Keychain.
- The real `KeychainService` implementation MUST use `Security.framework` directly (or `KeychainSwift` as a thin wrapper — no other third party).
