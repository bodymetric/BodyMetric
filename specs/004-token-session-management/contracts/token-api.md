# Contract: Token API Endpoints

**Branch**: `004-token-session-management` | **Date**: 2026-04-11

These contracts define the expected request/response shapes that the iOS app will
produce and consume. Backend must conform to these contracts.

---

## POST /api/auth/google — Google Token Exchange

Exchanges a Google Sign-In id token for a BodyMetric session token pair.
Called once immediately after `GIDSignIn.signIn()` succeeds.

### Request

```
POST https://api.bodymetric.com.br/api/auth/google
Content-Type: application/json

{
  "id_token": "<google-id-token-string>"
}
```

### Response — 200 OK

```json
{
  "access_token": "<backend-access-token>",
  "refresh_token": "<backend-refresh-token>"
}
```

### Response — 401 Unauthorized

```json
{
  "error": "invalid_token",
  "message": "Google id token is invalid or expired"
}
```

### Response — 500 Internal Server Error

```json
{
  "error": "server_error",
  "message": "Token exchange failed"
}
```

### App Behavior

| Response | Action |
|----------|--------|
| 200 | Store `access_token` in memory; store `refresh_token` in Keychain; start 4:55 timer |
| 401 | Throw `AuthError.tokenExchangeFailed`; show error to user; remain on login screen |
| 5xx | Throw `AuthError.tokenExchangeFailed`; show error to user; remain on login screen |
| Network error | Throw `AuthError.tokenExchangeFailed`; show error to user |

---

## POST /api/auth/refresh — Token Refresh

Exchanges the stored refresh token for a new access token.
Triggered proactively (4:55 timer) or reactively (401 on any authenticated request).

### Request

```
POST https://api.bodymetric.com.br/api/auth/refresh
Content-Type: application/json

{
  "refresh_token": "<stored-refresh-token>"
}
```

> Note: This endpoint does NOT require an `Authorization` header — the refresh token
> itself is the credential.

### Response — 200 OK

```json
{
  "access_token": "<new-access-token>",
  "refresh_token": "<new-refresh-token>"
}
```

> `refresh_token` in the response is optional. If the backend does not rotate refresh
> tokens, it may be omitted. The app will keep the existing Keychain refresh token.

### Response — 401 Unauthorized (refresh token expired or revoked)

```json
{
  "error": "invalid_refresh_token",
  "message": "Refresh token is expired or revoked"
}
```

### Response — 500 Internal Server Error

```json
{
  "error": "server_error",
  "message": "Token refresh failed"
}
```

### App Behavior

| Response | Action |
|----------|--------|
| 200 | Replace in-memory access token; replace Keychain refresh token if present in response; reset 4:55 timer |
| 401 | Delete access token from memory; delete refresh token from Keychain; force user to login screen |
| 5xx | Delete access token from memory; delete refresh token from Keychain; force user to login screen |
| Network error | Delete access token from memory; delete refresh token from Keychain; force user to login screen |

---

## Authenticated Request Convention

All requests to protected endpoints MUST include:

```
Authorization: Bearer <access-token>
```

### Example

```
GET https://api.bodymetric.com.br/api/users?email=user@example.com
Authorization: Bearer eyJhbGciOiJSUzI1NiJ9...
```

### On 401 from any protected endpoint

The app will:
1. Serialize via `TokenRefreshCoordinator` (only one refresh at a time)
2. Call `POST /api/auth/refresh`
3. On success: retry the original request once with the new token
4. On failure: sign out and redirect to login screen

---

## Internal Service Interfaces (Swift Contracts)

### TokenStoreProtocol

```swift
protocol TokenStoreProtocol: AnyObject {
    var accessToken: String? { get async }
    func store(accessToken: String) async
    func clearAccessToken() async
}
```

### KeychainServiceProtocol

```swift
protocol KeychainServiceProtocol: AnyObject {
    func saveRefreshToken(_ token: String) throws
    func loadRefreshToken() throws -> String
    func deleteRefreshToken() throws
}
```

### TokenRefreshServiceProtocol

```swift
@MainActor
protocol TokenRefreshServiceProtocol: AnyObject {
    func refresh(using refreshToken: String) async throws -> TokenRefreshResponse
}
```

### TokenExchangeServiceProtocol

```swift
@MainActor
protocol TokenExchangeServiceProtocol: AnyObject {
    func exchange(googleIdToken: String) async throws -> TokenExchangeResponse
}
```

### NetworkClientProtocol

```swift
@MainActor
protocol NetworkClientProtocol: AnyObject {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}
```
