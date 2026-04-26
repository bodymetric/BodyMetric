# Data Model: Session Token Management

**Branch**: `004-token-session-management` | **Date**: 2026-04-11

---

## Entities

### AccessToken

Represents the short-lived credential used to authorize API calls.
Held exclusively in memory; never persisted to disk.

| Field | Type | Description |
|-------|------|-------------|
| `value` | `String` | The raw bearer token string |
| `issuedAt` | `Date` | Timestamp when the token was stored in memory |

**Computed**:
- `isExpired: Bool` → `Date.now >= issuedAt + 300s` (5 min TTL)
- `shouldRefreshProactively: Bool` → `Date.now >= issuedAt + 295s` (4 min 55 s)

**Storage**: In-memory only (`TokenStore` actor). Cleared on logout or refresh failure.

---

### RefreshToken

Represents the long-lived credential used to obtain new access tokens.
Persisted exclusively in the iOS Keychain.

| Field | Type | Description |
|-------|------|-------------|
| `value` | `String` | The raw refresh token string |

**Keychain key**: `bm.token.refresh`
**Storage**: iOS Keychain (KeychainSwift). Deleted on logout or refresh failure.

---

### TokenExchangeRequest

Request body sent to the backend after Google Sign-In.

| Field | Type | Description |
|-------|------|-------------|
| `idToken` | `String` | Google-issued id token from `GIDSignIn` result |

**Encoding**: `application/json`, key: `id_token`

---

### TokenExchangeResponse

Backend response to the Google token exchange call.

| Field | Type | Description |
|-------|------|-------------|
| `accessToken` | `String` | Backend-issued access token |
| `refreshToken` | `String` | Backend-issued refresh token |

**Decoding**: `application/json`, snake_case keys: `access_token`, `refresh_token`

---

### TokenRefreshRequest

Request body sent to the backend refresh endpoint.

| Field | Type | Description |
|-------|------|-------------|
| `refreshToken` | `String` | Current refresh token stored in Keychain |

**Encoding**: `application/json`, key: `refresh_token`

---

### TokenRefreshResponse

Backend response to the token refresh call.

| Field | Type | Description |
|-------|------|-------------|
| `accessToken` | `String` | New backend-issued access token |
| `refreshToken` | `String?` | New refresh token (present only if backend rotates) |

**Decoding**: `application/json`, snake_case keys: `access_token`, `refresh_token` (optional)

---

## State Transitions

### TokenStore State Machine

```
[No Token]
    │
    │ signInWithGoogle() + exchange succeed
    ▼
[Token Active]
    │                      │
    │ 4:55 timer fires      │ 401 received
    ▼                      ▼
[Refreshing] ◄─────────────┘
    │                      │
    │ success              │ failure
    ▼                      ▼
[Token Active]         [No Token] → force logout
```

### Session Lifecycle

```
App Launch
    │
    ├─ Refresh token in Keychain? ──No──► Login screen
    │
    ├─ Yes → App considers session potentially active
    │         First authenticated request may get 401 → reactive refresh
    │
User signs in (Google)
    │
    └─ Exchange Google id token → get backend tokens
           │
           ├─ Store access token in memory (TokenStore)
           ├─ Store refresh token in Keychain
           └─ Start proactive 4:55 timer

User logs out
    │
    ├─ Clear access token from TokenStore
    ├─ Cancel proactive timer
    └─ Delete refresh token from Keychain
```

---

## Relationships

```
AuthService
    ├── uses → TokenExchangeService (Google id token → backend tokens)
    └── uses → TokenStore (clear on logout)

TokenStore (actor)
    ├── holds → AccessToken (in memory)
    ├── uses → TokenRefreshCoordinator (on timer fire)
    └── uses → KeychainService (read refresh token for refresh calls)

NetworkClient
    ├── uses → TokenStore (read access token for Authorization header)
    └── uses → TokenRefreshCoordinator (on 401)

TokenRefreshCoordinator (actor)
    ├── uses → TokenRefreshService (network call)
    ├── uses → TokenStore (update access token after refresh)
    └── uses → KeychainService (update/delete refresh token after refresh)

KeychainService
    └── wraps → KeychainSwift (SPM)
```
