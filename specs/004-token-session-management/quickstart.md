# Quickstart: Session Token Management

**Branch**: `004-token-session-management` | **Date**: 2026-04-11

Integration scenarios and test guide for the token lifecycle feature.

---

## Happy Path: First Login

```
1. User taps "Sign in with Google"
2. AuthService.signInWithGoogle() is called
3. GIDSignIn presents OAuth sheet → user grants permission
4. AuthService receives GIDSignIn result with idToken
5. TokenExchangeService.exchange(googleIdToken:) is called
   → POST /api/auth/google { id_token: "..." }
   → 200 { access_token: "abc", refresh_token: "xyz" }
6. TokenStore.store(accessToken: "abc") is called
   → access token is held in actor memory
   → 4-minute-55-second proactive timer is started
7. KeychainService.saveRefreshToken("xyz") is called
   → refresh token written to Keychain under key "bm.token.refresh"
8. AuthService.isAuthenticated = true
9. App navigates to HomeView
10. HomeView calls UserProfileService.fetchProfile(email:)
    → NetworkClient builds request
    → Authorization: Bearer abc is added
    → 200 response returns user profile
```

---

## Happy Path: Proactive Token Refresh (4:55 timer)

```
1. 295 seconds have elapsed since access token was stored
2. TokenStore proactive timer fires
3. TokenRefreshCoordinator.refresh() is called
   → reads refresh token from Keychain: "xyz"
   → POST /api/auth/refresh { refresh_token: "xyz" }
   → 200 { access_token: "def", refresh_token: "uvw" }
4. TokenStore.store(accessToken: "def")
   → old access token is replaced
   → new 4:55 timer is started
5. KeychainService.saveRefreshToken("uvw")
   → old refresh token is replaced in Keychain
6. Next API call uses "def" — user uninterrupted
```

---

## Reactive Path: 401 on Protected Endpoint

```
1. NetworkClient sends: GET /api/users?email=... Authorization: Bearer abc
2. Server returns 401 (token expired server-side before 4:55 timer)
3. NetworkClient detects 401
4. TokenRefreshCoordinator.refresh() is called (serialized)
   → POST /api/auth/refresh { refresh_token: "xyz" }
   → 200 { access_token: "def", refresh_token: "uvw" }
5. TokenStore.store(accessToken: "def")
6. KeychainService.saveRefreshToken("uvw")
7. Original request is retried with Authorization: Bearer def
8. 200 response — user sees result; never aware of the refresh
```

---

## Failure Path: Refresh Token Expired

```
1. NetworkClient receives 401 OR proactive timer fires
2. TokenRefreshCoordinator.refresh() is called
   → POST /api/auth/refresh { refresh_token: "xyz" }
   → 401 { error: "invalid_refresh_token" }
3. TokenStore.clearAccessToken() — access token removed from memory
4. KeychainService.deleteRefreshToken() — refresh token deleted from Keychain
5. AuthService.signOut() is called (clears isAuthenticated)
6. App navigates to LoginView
7. User must sign in again
```

---

## Concurrency Path: Multiple Simultaneous 401s

```
1. Two API requests in flight: A and B
2. Both receive 401 simultaneously
3. Request A: TokenRefreshCoordinator.refresh() → starts refresh task
4. Request B: TokenRefreshCoordinator.refresh() → finds existing task, awaits it
5. Refresh completes: new access token "def"
6. Request A retries with "def" → succeeds
7. Request B retries with "def" → succeeds
8. Only ONE POST /api/auth/refresh was sent to the backend
```

---

## Logout Path

```
1. User taps logout in AppHeader
2. AppHeaderViewModel.logout() → authService.signOut()
3. AuthService.signOut():
   a. TokenStore.clearAccessToken() — access token cleared from memory
   b. Proactive timer Task is cancelled
   c. KeychainService.deleteRefreshToken() — refresh token deleted from Keychain
   d. GIDSignIn.sharedInstance.signOut()
   e. isAuthenticated = false
4. App navigates to LoginView
5. No tokens remain anywhere
```

---

## Unit Test Scenarios

### TokenStore Tests
- `test_store_accessToken_setsValue` — stored token is readable
- `test_store_accessToken_startTimer` — timer task is created
- `test_store_newToken_cancelsOldTimer` — replacing token cancels previous timer
- `test_clearAccessToken_setsNil` — cleared token returns nil
- `test_proactiveTimer_callsRefreshCoordinator` — timer fires refresh at 295s

### KeychainService Tests
- `test_saveRefreshToken_canBeLoaded` — round-trip save and load
- `test_deleteRefreshToken_notFoundAfterDelete` — token absent after delete
- `test_loadRefreshToken_throwsWhenAbsent` — throws when no token stored

### TokenRefreshCoordinator Tests
- `test_singleRefreshRequest_onConcurrent401s` — only one refresh call issued
- `test_refresh_success_updatesTokenStore` — access token updated after refresh
- `test_refresh_failure_clearsTokensAndSignsOut` — tokens cleared and sign-out called

### TokenExchangeService Tests
- `test_exchange_200_returnsTokenPair` — decodes access + refresh tokens
- `test_exchange_401_throwsTokenExchangeFailed` — correct error on bad id token
- `test_exchange_networkError_throwsTokenExchangeFailed` — network failure handled

### NetworkClient Tests
- `test_request_includesBearerToken` — Authorization header present
- `test_request_401_triggersRefreshAndRetry` — retry after refresh
- `test_request_401_afterRefreshFails_throwsAuthError` — no infinite retry
- `test_noToken_requestNotSent_redirectsToLogin` — unauthenticated path blocked
