# Research: Authenticated API Request Handling

**Feature**: `010-api-auth-session`  
**Date**: 2026-04-28

---

## Gap Analysis: What Exists vs. What the Spec Requires

### ✅ Already implemented (no changes needed)

| Spec Requirement | Existing Implementation | File |
|-----------------|------------------------|------|
| FR-001: Bearer token on all protected requests | `NetworkClient.execute(_:bearerToken:)` sets `Authorization: Bearer` on every request | `NetworkClient.swift` |
| FR-002 (auth paths): `/api/auth/*` exempt | `TokenExchangeService` and `TokenRefreshService` use their own URLSession; they never go through `NetworkClient` | `TokenExchangeService.swift`, `TokenRefreshService.swift` |
| FR-003: Session token stored securely | `TokenStore` holds access token in-memory only; never written to disk | `TokenStore.swift` |
| FR-004: Refresh token in Keychain | `KeychainService.saveRefreshToken` / `loadRefreshToken` / `deleteRefreshToken` | `KeychainService.swift` |
| FR-005: 401 triggers automatic refresh | `NetworkClient.data(for:)` retries after `coordinator.refresh()` on 401 | `NetworkClient.swift` |
| FR-006: New tokens replace old | `tokenStore.store(accessToken:)` + `keychainService.saveRefreshToken` on success | `TokenRefreshCoordinator.swift` |
| FR-007: Original request retried with new token | Second call to `execute(_:bearerToken:)` after coordinator refreshes | `NetworkClient.swift` |
| FR-008: Credentials cleared on refresh failure | `tokenStore.clearAccessToken()` + `keychainService.deleteRefreshToken()` + `forceLogout()` | `TokenRefreshCoordinator.swift` |
| FR-009: Navigate to login on refresh failure | `onForceLogout` → `authService.forceSignOut()` → `isAuthenticated = false` → `BodyMetricApp` shows `LoginView` | `TokenRefreshCoordinator.swift`, `BodyMetricApp.swift` |
| FR-010: Serialised refresh (no refresh storm) | `ongoingRefresh: Task` in `TokenRefreshCoordinator` — all concurrent 401s await the same task | `TokenRefreshCoordinator.swift` |
| Token field names in response | `CodingKeys` maps `"sessionToken"` → `accessToken`, `"refreshToken"` → `refreshToken` | `TokenRefreshResponse.swift`, `TokenExchangeResponse.swift` |

---

## Gap 1: Request body field name bug

**Issue**: `TokenRefreshService.refresh(using:)` encodes the request body as:
```swift
JSONEncoder().encode(["refresh_token": refreshToken])
```
This sends `"refresh_token"` (snake_case). The API spec and all response/exchange payloads use `"refreshToken"` (camelCase). This mismatch means the backend does not receive the refresh token correctly, causing all refresh attempts to fail.

**Decision**: Change the key from `"refresh_token"` to `"refreshToken"`.

**Fix**: Replace the `encode(["refresh_token": ...])` call with a `Encodable` struct or `["refreshToken": ...]` dictionary.

**Rationale**: All other field names in the codebase are camelCase (`sessionToken`, `refreshToken`, `accessToken`). The snake_case here is an inconsistency introduced at a prior commit. Fixing it aligns with the API contract.

**Alternatives considered**:
- Configure JSONEncoder keyEncodingStrategy to `.convertToSnakeCase` — rejected; would change all keys globally and break other uses.
- Use a Codable struct — acceptable but adds boilerplate; a simple dictionary literal `["refreshToken": refreshToken]` is cleaner for a single-field body.

---

## Gap 2: URL-path exemption for /q/* and /version in NetworkClient

**Issue**: `NetworkClient.data(for:)` currently throws `NetworkError.noToken` for any request when no access token is available. If the app ever calls `/q/*` or `/version` through `NetworkClient` before the user is authenticated, the call fails before it reaches the server.

**Decision**: Add a URL-path check to `NetworkClient` that skips token injection (and the `.noToken` guard) for requests matching the exempt path prefixes.

**Exempt path prefixes** (from spec FR-002):
- `/api/auth/` (already handled architecturally — but safe to also add defensively)
- `/q/`
- `/version`

**Implementation approach**: Add a private helper `isExempt(_ request: URLRequest) -> Bool` that checks the request URL path. If exempt, call `execute(_:bearerToken: nil)` — or better, call `session.data(for:)` directly without the Authorization header.

**Rationale**: The app may call public health-check or query endpoints without a user session. Blocking these with `.noToken` is incorrect behavior. The fix is path-based, not credential-based.

**Alternatives considered**:
- Separate `PublicNetworkClient` type — rejected; over-engineering; path check in existing client is cleaner.
- Caller uses raw URLSession for public endpoints — already done for auth endpoints; acceptable but inconsistent.

---

## All NEEDS CLARIFICATION Items

None — both gaps have clear fixes documented above.
