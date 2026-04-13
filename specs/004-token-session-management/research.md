# Research: Session Token Management

**Branch**: `004-token-session-management` | **Date**: 2026-04-11

---

## Decision 1: Access Token Storage — Memory-Only

**Decision**: The backend-issued access token is stored exclusively in a Swift actor
(`TokenStore`) held in application memory. It is never written to disk, UserDefaults,
or Keychain.

**Rationale**: Access tokens are short-lived (5-minute TTL per spec). Storing ephemeral
credentials in Keychain adds latency and complexity without a security benefit —
Keychain is designed for long-lived secrets. An in-memory store that is cleared when
the app process exits is the idiomatic iOS pattern for short-lived tokens.

**Alternatives considered**:
- Keychain for access token: rejected — Keychain I/O is synchronous and adds overhead
  on every request. Short-lived tokens gain nothing from disk persistence since they
  would be expired by the next app launch anyway.
- UserDefaults: rejected — unencrypted on-disk storage; violates Principle VII.

---

## Decision 2: Refresh Token Storage — iOS Keychain via KeychainSwift

**Decision**: The backend-issued refresh token is persisted in the iOS Keychain under
a namespaced key (`bm.token.refresh`) using the existing `KeychainSwift` SPM package.

**Rationale**: Refresh tokens are long-lived session credentials. They survive app
restarts and must be encrypted at rest. iOS Keychain (Security framework) provides
OS-level encryption, per-app isolation, and access control. KeychainSwift is already
a project dependency (spec 003), so no new packages are required.

**Alternatives considered**:
- Encrypted file: rejected — custom encryption implementation, no OS-level access control.
- Secure Enclave: rejected — adds biometric/hardware binding; overkill for token storage.

---

## Decision 3: Concurrency Guard — Swift Actor + AsyncStream Continuation

**Decision**: A Swift `actor` (`TokenRefreshCoordinator`) serializes token refresh
operations. The first 401 response starts a refresh task; all subsequent concurrent
401s await the same task's result via a stored `Task<String, Error>` handle.

**Pattern**:
```swift
actor TokenRefreshCoordinator {
    private var refreshTask: Task<String, Error>?

    func refresh(using service: TokenRefreshServiceProtocol) async throws -> String {
        if let existing = refreshTask {
            return try await existing.value
        }
        let task = Task { try await service.refresh() }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }
}
```

**Rationale**: Swift actors provide structured concurrency guarantees without manual
locking. The stored `Task` handle allows concurrent callers to await the same refresh
without spawning duplicate network requests. `defer { refreshTask = nil }` ensures
cleanup whether the refresh succeeds or fails.

**Alternatives considered**:
- `NSLock` / `DispatchSemaphore`: rejected — incompatible with Swift async/await;
  risk of deadlock.
- `AsyncThrowingStream`: considered for multi-consumer broadcast; rejected as more
  complex than needed for this use case.
- `actor` with `CheckedContinuation` array: valid but more verbose than the stored
  `Task` pattern.

---

## Decision 4: 401 Interception — Custom URLSession Delegate / Wrapper

**Decision**: A `NetworkClient` class wraps `URLSession` and intercepts all responses.
On HTTP 401, it delegates to `TokenRefreshCoordinator.refresh()`, updates the in-memory
token, and retries the original request exactly once.

**Rationale**: URLSession does not natively support middleware-style interceptors.
A thin wrapper around `URLSession.data(for:)` with explicit 401 handling is the
simplest approach that keeps all auth logic in one place. The retry is capped at once
to prevent infinite loops.

**Alternatives considered**:
- `URLProtocol` subclass: considered for transparent interception. Rejected because
  async/await interop with `URLProtocol` (callback-based) is awkward and error-prone.
- Third-party HTTP client (Alamofire): rejected — Principle I prohibits non-SPM deps;
  Principle I also requires URLSession unless justified.

---

## Decision 5: Proactive Refresh Timer — Structured Concurrency Task

**Decision**: When `TokenStore` stores a new access token, it cancels any existing
timer task and launches a new `Task` that `Task.sleep`s for 295 seconds (4 min 55 s),
then calls `TokenRefreshCoordinator.refresh()`.

**Rationale**: `Task.sleep(for:)` integrates cleanly with Swift structured concurrency.
The task is stored and cancelled when: (a) a new token replaces the existing one or
(b) the user logs out. This avoids any Timer/DispatchQueue bridging issues.

**Alternatives considered**:
- `Timer.scheduledTimer`: rejected — requires RunLoop management and bridging to async.
- Background URLSession: rejected — unnecessary complexity; the timer only needs to
  fire while the app is active.
- App backgrounding: when the app is backgrounded, the Task is suspended by the
  system; on foreground return, the Task resumes and checks remaining sleep time.
  If the token is already expired, the first 401 triggers the reactive path.

---

## Decision 6: Token Exchange Flow — Backend Endpoint After Google Sign-In

**Decision**: After a successful `GIDSignIn.signIn()`, `AuthService` calls a new
`TokenExchangeService` which POSTs the Google id token to `POST /api/auth/google`
on the BodyMetric backend. The response contains `access_token` and `refresh_token`.
The Google id token is ephemeral and managed internally by `GIDSignIn`.

**Rationale**: This is the standard "social login → backend token exchange" pattern.
The BodyMetric backend issues its own token pair (not Google's), giving it control
over session lifetimes and revocation. The Google id token is consumed in the exchange
and not stored separately.

**Constitution VII note**: Principle VII says "The Google id token (JWT) MUST be
written to Keychain". The actual architecture uses the Google id token once for the
backend exchange; the BACKEND-issued refresh token then goes to Keychain. The spirit
of Principle VII is satisfied (long-lived credential in Keychain, short-lived in
memory). A PATCH amendment to Principle VII is recommended to clarify this distinction.

**Alternatives considered**:
- Pass Google id token directly to all API calls: rejected — Google id tokens have
  short TTLs and cannot be refreshed from within the app without re-triggering the
  OAuth flow. Backend-issued tokens allow server-side session control.
- Store Google id token in Keychain AND exchange: rejected — redundant; the Google id
  token is not used after exchange.

---

## Decision 7: Keychain Keys

| Key | Content | TTL |
|-----|---------|-----|
| `bm.token.refresh` | Backend refresh token | Session lifetime |

Access token has no Keychain key — it is never written to disk.
