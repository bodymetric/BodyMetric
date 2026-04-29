# Data Model: Authenticated API Request Handling

**Feature**: `010-api-auth-session`  
**Date**: 2026-04-28

---

## No new entities

This feature contains no new data entities. All models already exist and are correct.

---

## Existing entities (verified against spec)

### TokenRefreshResponse *(existing, no changes needed)*

Maps the `POST /api/auth/refresh` response. Field name mapping is already correct:

| JSON field | Swift property | Notes |
|------------|---------------|-------|
| `sessionToken` | `accessToken` | Mapped via CodingKeys |
| `refreshToken` | `refreshToken` | Direct mapping |

### TokenExchangeResponse *(existing, no changes needed)*

Maps the `POST /api/auth/google` response. Field name mapping is already correct.

---

## Request body: token refresh (BUG FIX)

The refresh request body is a single-field JSON object:

| JSON key | Value | Current (broken) | Correct |
|----------|-------|-----------------|---------|
| `refreshToken` | stored refresh token | `"refresh_token"` | `"refreshToken"` |

**Change**: `TokenRefreshService.refresh(using:)` must encode `["refreshToken": refreshToken]` not `["refresh_token": refreshToken]`.

---

## URL exemption list (NetworkClient)

The following path prefixes MUST NOT receive an `Authorization` header:

| Path prefix | Reason | Currently handled how |
|-------------|--------|-----------------------|
| `/api/auth/` | Auth endpoints don't require auth | Architecture (separate URLSession in auth services) |
| `/q/` | Public query endpoints | NOT currently handled in NetworkClient |
| `/version` | Public version endpoint | NOT currently handled in NetworkClient |

**Change**: `NetworkClient` gains a private `isExemptPath(_ url: URL?) -> Bool` check.

---

## State machine (unchanged)

No state machine changes. The refresh flow is already:

```
Authenticated request → 401
    → TokenRefreshCoordinator.refresh() [serialised]
        → TokenRefreshService.refresh(refreshToken) [BUG FIX: field name]
            → 200: store new tokens, retry original request
            → non-200: clear tokens, call onForceLogout → LoginView
```
