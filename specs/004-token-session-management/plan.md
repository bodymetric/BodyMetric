# Implementation Plan: Session Token Management

**Branch**: `004-token-session-management` | **Date**: 2026-04-11 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/004-token-session-management/spec.md`

## Summary

After a successful Google Sign-In, `AuthService` exchanges the Google id token with the
BodyMetric backend (`POST /api/auth/google`) to receive a backend-issued access token and
refresh token. The access token is held exclusively in memory by a Swift actor (`TokenStore`);
the refresh token is persisted in the iOS Keychain. A `NetworkClient` injects the bearer
token into every authenticated request and handles 401 responses by serializing token
refresh via `TokenRefreshCoordinator` and retrying the original request once. A proactive
295-second (4 min 55 s) timer in `TokenStore` triggers a silent background refresh before
the access token expires.

## Technical Context

**Language/Version**: Swift 5.10 + iOS 17+
**Primary Dependencies**: GoogleSignIn-iOS (SPM, existing), KeychainSwift (SPM, existing)
**Storage**: iOS Keychain (refresh token only); in-memory actor (access token)
**Testing**: XCTest with MockURLProtocol and protocol-based dependency injection
**Target Platform**: iOS 17+
**Project Type**: Mobile app
**Performance Goals**: Token refresh must complete in <2 s; no user-visible delay
**Constraints**: Access token MUST NOT touch disk; tokens MUST NOT appear in logs
**Scale/Scope**: Single authenticated user per device session

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | Pure Swift actors, protocols, URLSession. KeychainSwift via SPM (existing). No new non-SPM deps. |
| II. Comprehensive Testing | TDD; ≥ 90% coverage; tests before implementation | ✅ | Full test suites for TokenStore, KeychainService, TokenRefreshCoordinator, TokenExchangeService, NetworkClient. Tests written before implementation. |
| III. Error Logging | All errors logged; no PII; tokens never in logs | ✅ | All catch sites logged. Tokens never logged — only boolean presence (e.g., `refreshToken: present=true`). |
| IV. Interaction Tracing | All meaningful interactions traced; no PII/tokens in events | ✅ | Events: `token_exchange_succeeded`, `token_refresh_started`, `token_refresh_succeeded`, `token_refresh_failed`, `user_forced_logout_on_refresh_failure`. |
| V. User-Friendly, Simple & Fast | Token operations are invisible to user; no extra taps | ✅ | All token operations are background; user never sees a refresh prompt. |
| VI. Grayscale Visual Design | No new color UI introduced | ✅ | No new UI screens. Existing logout path on refresh failure uses existing LoginView. |
| VII. Token Security & Session Management | Bearer token on all authenticated requests; Keychain for long-lived credentials; deletion on logout/expiry | ✅ (with note) | Access token in memory (short-lived, acceptable). Refresh token in Keychain. Bearer header on all requests. Deletion on logout and refresh failure. **Note**: Constitution VII specifies storing the Google id token in Keychain; this feature clarifies the architecture — the Google id token is consumed in the exchange and not stored; only the backend-issued refresh token goes to Keychain. A PATCH amendment to Principle VII is recommended after this feature ships. |

## Complexity Tracking

| Item | Why Needed | Simpler Alternative Rejected Because |
|------|------------|--------------------------------------|
| `TokenRefreshCoordinator` actor | Serializes concurrent 401-triggered refreshes (FR-007) | A simple boolean flag is not concurrency-safe in Swift async/await; actor guarantees exclusive access |
| `NetworkClient` wrapper | Centralizes bearer injection + 401 interception | Per-service manual header injection would scatter auth logic across all service files and require updates whenever a new service is added |

## Project Structure

### Documentation (this feature)

```text
specs/004-token-session-management/
├── plan.md              # This file
├── research.md          # Phase 0 output ✅
├── data-model.md        # Phase 1 output ✅
├── quickstart.md        # Phase 1 output ✅
├── contracts/
│   └── token-api.md    # Phase 1 output ✅
└── tasks.md             # Phase 2 output (via /speckit-tasks)
```

### Source Code

```text
BodyMetric/
├── Services/
│   ├── Auth/
│   │   ├── AuthService.swift              (UPDATE — add token exchange after sign-in; token cleanup on sign-out)
│   │   ├── AuthServiceProtocol.swift      (no change)
│   │   └── TokenExchangeService.swift     (NEW — POST /api/auth/google)
│   ├── Token/
│   │   ├── TokenStore.swift               (NEW — in-memory access token + 4:55 proactive timer)
│   │   ├── TokenStoreProtocol.swift       (NEW)
│   │   ├── TokenRefreshCoordinator.swift  (NEW — actor, serializes refresh, await dedup)
│   │   ├── TokenRefreshService.swift      (NEW — POST /api/auth/refresh)
│   │   └── TokenRefreshServiceProtocol.swift (NEW)
│   ├── Keychain/
│   │   ├── KeychainService.swift          (NEW — save/load/delete refresh token via KeychainSwift)
│   │   └── KeychainServiceProtocol.swift  (NEW)
│   └── Network/
│       ├── NetworkClient.swift            (NEW — URLSession wrapper, bearer injection, 401 retry)
│       ├── NetworkClientProtocol.swift    (NEW)
│       └── NetworkError.swift             (NEW — network-layer error enum)
│
├── Models/
│   ├── TokenExchangeResponse.swift        (NEW — Decodable: access_token, refresh_token)
│   └── TokenRefreshResponse.swift         (NEW — Decodable: access_token, refresh_token?)

BodyMetricTests/
├── Services/
│   ├── TokenStoreTests.swift              (NEW)
│   ├── KeychainServiceTests.swift         (NEW)
│   ├── TokenRefreshCoordinatorTests.swift (NEW)
│   ├── TokenExchangeServiceTests.swift    (NEW)
│   └── NetworkClientTests.swift          (NEW)
```

**Structure Decision**: Mobile app layout. New `Token/` and `Keychain/` groups under `Services/`
to clearly separate concerns. `Network/` houses the authenticated networking layer that
replaces direct `URLSession` usage in feature services (starting with `UserProfileService`
which will be updated to use `NetworkClient`).

## Architecture: Key Design Decisions

### 1. TokenStore (actor)

```swift
actor TokenStore: TokenStoreProtocol {
    private(set) var accessToken: String?
    private var timerTask: Task<Void, Never>?

    func store(accessToken: String, coordinator: TokenRefreshCoordinator) {
        self.accessToken = accessToken
        timerTask?.cancel()
        timerTask = Task {
            try? await Task.sleep(for: .seconds(295))
            guard !Task.isCancelled else { return }
            try? await coordinator.refresh()
        }
    }

    func clearAccessToken() {
        accessToken = nil
        timerTask?.cancel()
        timerTask = nil
    }
}
```

### 2. TokenRefreshCoordinator (actor)

```swift
actor TokenRefreshCoordinator {
    private var ongoingRefresh: Task<Void, Error>?

    func refresh(
        refreshService: TokenRefreshServiceProtocol,
        tokenStore: TokenStoreProtocol,
        keychainService: KeychainServiceProtocol,
        authService: AuthServiceProtocol
    ) async throws {
        if let existing = ongoingRefresh {
            return try await existing.value
        }
        let task = Task<Void, Error> {
            let refreshToken = try keychainService.loadRefreshToken()
            let response = try await refreshService.refresh(using: refreshToken)
            await tokenStore.store(accessToken: response.accessToken, coordinator: self)
            if let newRefresh = response.refreshToken {
                try keychainService.saveRefreshToken(newRefresh)
            }
        }
        ongoingRefresh = task
        defer { ongoingRefresh = nil }
        try await task.value
    }
}
```

### 3. NetworkClient — Bearer Injection + 401 Retry

```swift
final class NetworkClient: NetworkClientProtocol {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var req = request
        if let token = await tokenStore.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, resp) = try await session.data(for: req)
        let http = resp as! HTTPURLResponse
        guard http.statusCode == 401 else { return (data, http) }
        // Refresh + retry once
        try await coordinator.refresh(...)
        var retryReq = request
        if let newToken = await tokenStore.accessToken {
            retryReq.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
        }
        return try await session.data(for: retryReq) as! (Data, HTTPURLResponse)
    }
}
```

### 4. AuthService — Updated signInWithGoogle

```swift
// After GIDSignIn.signIn() succeeds:
let response = try await tokenExchangeService.exchange(googleIdToken: idToken)
await tokenStore.store(accessToken: response.accessToken, coordinator: coordinator)
try keychainService.saveRefreshToken(response.refreshToken)
isAuthenticated = true
```

### 5. AuthService — Updated signOut

```swift
func signOut() async throws {
    await tokenStore.clearAccessToken()        // clear in-memory token
    try? keychainService.deleteRefreshToken()  // delete Keychain token
    GIDSignIn.sharedInstance.signOut()
    isAuthenticated = false
}
```

## Dependency Wiring

All services are injected through `BodyMetricApp`:

```swift
@State private var tokenStore = TokenStore()
@State private var keychainService = KeychainService()
@State private var coordinator = TokenRefreshCoordinator()
@State private var networkClient: NetworkClient  // receives above deps in init

// AuthService receives tokenStore + keychainService + coordinator
// UserProfileService updated to use networkClient instead of raw URLSession
```

## Migration Notes

- `UserProfileService` currently uses raw `URLSession` — it must be updated to use
  `NetworkClient` so bearer token injection and 401 handling are automatic.
- `AuthService.signOut()` currently has `TODO(T012): Clear Keychain tokens` — this
  feature implements that TODO.
- `AuthService.signInWithGoogle()` currently has `TODO(T014/T015): Exchange idToken with backend`
  — this feature implements that TODO via `TokenExchangeService`.
