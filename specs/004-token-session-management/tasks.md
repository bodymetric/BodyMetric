# Tasks: Session Token Management

**Input**: Design documents from `/specs/004-token-session-management/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Tests**: TDD required by Constitution Principle II — test tasks are included and MUST be written first (Red-Green-Refactor).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to
- Constitution Principle II: write test → confirm FAIL → implement → confirm PASS

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create new service group directories and file stubs that all phases depend on

- [x] T001 Create directory structure: `BodyMetric/Services/Token/`, `BodyMetric/Services/Keychain/`, `BodyMetric/Services/Network/` (no files yet — directories only, confirmed with `ls`)
- [x] T002 [P] Create `TokenStoreProtocol` in `BodyMetric/Services/Token/TokenStoreProtocol.swift` — `@MainActor protocol` with `accessToken: String? { get async }`, `func store(accessToken: String) async`, `func clearAccessToken() async`
- [x] T003 [P] Create `KeychainServiceProtocol` in `BodyMetric/Services/Keychain/KeychainServiceProtocol.swift` — protocol with `func saveRefreshToken(_ token: String) throws`, `func loadRefreshToken() throws -> String`, `func deleteRefreshToken() throws`
- [x] T004 [P] Create `TokenRefreshServiceProtocol` in `BodyMetric/Services/Token/TokenRefreshServiceProtocol.swift` — `@MainActor protocol` with `func refresh(using refreshToken: String) async throws -> TokenRefreshResponse`
- [x] T005 [P] Create `TokenExchangeServiceProtocol` in `BodyMetric/Services/Token/TokenExchangeServiceProtocol.swift` — `@MainActor protocol` with `func exchange(googleIdToken: String) async throws -> TokenExchangeResponse`
- [x] T006 [P] Create `NetworkClientProtocol` in `BodyMetric/Services/Network/NetworkClientProtocol.swift` — `@MainActor protocol` with `func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)`
- [x] T007 [P] Create `TokenExchangeResponse` model in `BodyMetric/Models/TokenExchangeResponse.swift` — `Decodable` struct with `accessToken: String`, `refreshToken: String` (CodingKeys: `access_token`, `refresh_token`)
- [x] T008 [P] Create `TokenRefreshResponse` model in `BodyMetric/Models/TokenRefreshResponse.swift` — `Decodable` struct with `accessToken: String`, `refreshToken: String?` (CodingKeys: `access_token`, `refresh_token`)
- [x] T009 [P] Create `NetworkError` enum in `BodyMetric/Services/Network/NetworkError.swift` — cases: `.noToken`, `.httpError(Int)`, `.refreshFailed`, `.unauthorized`, `.decodingError`

**Checkpoint**: All protocols and models exist. No logic yet — foundation for all stories.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: `KeychainService` — required by US1, US3, US4, US5. Must exist before any token can be persisted.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T010 Write failing tests for `KeychainService` in `BodyMetric/BodyMetricTests/Services/KeychainServiceTests.swift` — cover: `saveRefreshToken` round-trips correctly, `loadRefreshToken` throws when absent, `deleteRefreshToken` removes token, `save` overwrites previous value (use a real Keychain with a test-only key prefix `bm.test.token.refresh`)
- [x] T011 Implement `KeychainService` conforming to `KeychainServiceProtocol` in `BodyMetric/Services/Keychain/KeychainService.swift` — uses `KeychainSwift`; key: `bm.token.refresh`; all methods throw `AuthError.keychainWriteFailed` on failure; logs presence (`true`/`false`) only, never token value (Principle III)
- [x] T012 Verify T010 tests pass against T011 implementation before proceeding

**Checkpoint**: `KeychainService` is verified. Refresh token can be securely stored and retrieved.

---

## Phase 3: User Story 1 — Token Acquisition After Login (Priority: P1) 🎯 MVP

**Goal**: After Google Sign-In, exchange the id token for backend tokens, store the access token in memory and the refresh token in Keychain.

**Independent Test**: Complete a sign-in flow (mocked via `MockTokenExchangeService`) and verify (a) `TokenStore.accessToken` is non-nil and (b) `KeychainService.loadRefreshToken()` returns the stored refresh token.

### Tests for US1

> **Write these tests FIRST — confirm they FAIL before any implementation**

- [x] T013 [P] [US1] Write failing tests for `TokenStore` (basic storage only, no timer) in `BodyMetric/BodyMetricTests/Services/TokenStoreTests.swift` — cover: `store(accessToken:)` sets `accessToken`, `clearAccessToken()` sets `accessToken` to nil, storing a second token replaces the first
- [x] T014 [P] [US1] Write failing tests for `TokenExchangeService` in `BodyMetric/BodyMetricTests/Services/TokenExchangeServiceTests.swift` — cover: `exchange(googleIdToken:)` on 200 returns `TokenExchangeResponse` with both tokens, on 401 throws `AuthError.tokenExchangeFailed`, on network error throws `AuthError.tokenExchangeFailed` (use `MockURLProtocol`)

### Implementation for US1

- [x] T015 [US1] Implement `TokenStore` actor (storage only — no timer yet) in `BodyMetric/Services/Token/TokenStore.swift` — `actor TokenStore: TokenStoreProtocol`; `private(set) var accessToken: String?`; `func store(accessToken: String) async` sets the value; `func clearAccessToken() async` sets nil
- [x] T016 [US1] Implement `TokenExchangeService` conforming to `TokenExchangeServiceProtocol` in `BodyMetric/Services/Token/TokenExchangeService.swift` — `POST https://api.bodymetric.com.br/api/auth/google` with body `{"id_token": "<googleIdToken>"}`, 10 s timeout; 200 → decode `TokenExchangeResponse`; 401/other → throw `AuthError.tokenExchangeFailed`; accepts injectable `URLSession` for testing (Principle I)
- [x] T017 [US1] Update `AuthService.signInWithGoogle()` in `BodyMetric/Services/Auth/AuthService.swift` — after `GIDSignIn.signIn()` succeeds: (1) extract `idToken.tokenString`, (2) call `tokenExchangeService.exchange(googleIdToken:)`, (3) call `await tokenStore.store(accessToken: response.accessToken)`, (4) call `keychainService.saveRefreshToken(response.refreshToken)`, (5) set `isAuthenticated = true`; on exchange failure: throw `AuthError.tokenExchangeFailed`; inject `tokenExchangeService`, `tokenStore`, `keychainService` via `init`
- [x] T018 [US1] Add trace events to `AuthService` in `BodyMetric/Services/Auth/AuthService.swift` — `token_exchange_started` before exchange call, `token_exchange_succeeded` on success (no token values in payload), `token_exchange_failed` on failure with error category (Principle IV)
- [x] T019 [US1] Verify T013 and T014 tests pass; update `AuthServiceProtocol` in `BodyMetric/Services/Auth/AuthServiceProtocol.swift` to inject `tokenStore`, `keychainService`, `tokenExchangeService` if needed to preserve testability

**Checkpoint**: After sign-in, `TokenStore.accessToken` is set and Keychain has the refresh token. All T013/T014 tests pass.

---

## Phase 4: User Story 2 — Authenticated API Requests (Priority: P1)

**Goal**: Every authenticated API request automatically includes `Authorization: Bearer <access-token>` without any per-call manual wiring.

**Independent Test**: Call `NetworkClient.data(for:)` with a protected request (mocked to return 200) and verify the outgoing request contains `Authorization: Bearer <token>`.

### Tests for US2

> **Write these tests FIRST — confirm they FAIL before any implementation**

- [x] T020 [US2] Write failing tests for `NetworkClient` (bearer injection only — no 401 handling yet) in `BodyMetric/BodyMetricTests/Services/NetworkClientTests.swift` — cover: `data(for:)` with valid token adds `Authorization: Bearer <token>` header to request, `data(for:)` with nil token throws `NetworkError.noToken`, 200 response is returned unchanged (use `MockURLProtocol` + `MockTokenStore`)

### Implementation for US2

- [x] T021 [US2] Implement `NetworkClient` (bearer injection only — no 401 retry yet) in `BodyMetric/Services/Network/NetworkClient.swift` — `@MainActor final class NetworkClient: NetworkClientProtocol`; init receives `tokenStore: TokenStoreProtocol`, `session: URLSession` (injectable); `func data(for request: URLRequest)`: reads `await tokenStore.accessToken`, throws `NetworkError.noToken` if nil, sets `Authorization: Bearer <token>` header, calls `session.data(for:)`, returns `(Data, HTTPURLResponse)`
- [x] T022 [US2] Update `UserProfileService` in `BodyMetric/Services/Profile/UserProfileService.swift` — replace direct `URLSession` usage with `NetworkClient: NetworkClientProtocol` (injectable); update `init` to accept `networkClient: NetworkClientProtocol`; existing `session`-based path removed
- [x] T023 [US2] Update `UserProfileServiceTests` in `BodyMetric/BodyMetricTests/Services/UserProfileServiceTests.swift` — replace `MockURLProtocol`-based session with a `MockNetworkClient` that conforms to `NetworkClientProtocol`; all existing test cases must still pass
- [x] T024 [US2] Verify T020 tests pass against T021 implementation

**Checkpoint**: `NetworkClient` injects bearer tokens. `UserProfileService` uses it. All US2 tests pass.

---

## Phase 5: User Story 5 — Session Cleanup on Logout (Priority: P1)

**Goal**: On logout, all credentials are completely removed — access token from memory, refresh token from Keychain.

**Independent Test**: Call `AuthService.signOut()` (mocked services) and verify `TokenStore.accessToken == nil` and `KeychainService.loadRefreshToken()` throws (token deleted).

### Tests for US5

> **Write these tests FIRST — confirm they FAIL before any implementation**

- [x] T025 [US5] Write failing tests for `AuthService.signOut()` token cleanup in `BodyMetric/BodyMetricTests/Services/AuthServiceTests.swift` (new file or extend existing) — cover: signOut calls `tokenStore.clearAccessToken()`, signOut calls `keychainService.deleteRefreshToken()`, signOut sets `isAuthenticated = false`, `authenticatedEmail` returns nil after signOut (use `MockTokenStore` and `MockKeychainService`)

### Implementation for US5

- [x] T026 [US5] Update `AuthService.signOut()` in `BodyMetric/Services/Auth/AuthService.swift` — (1) `await tokenStore.clearAccessToken()`, (2) `try? keychainService.deleteRefreshToken()` (log error if delete fails, do not throw — sign-out must complete regardless), (3) `GIDSignIn.sharedInstance.signOut()`, (4) `isAuthenticated = false`; resolves `TODO(T012)` in existing code
- [x] T027 [US5] Add trace event `tokens_cleared_on_logout` to `AuthService.signOut()` in `BodyMetric/Services/Auth/AuthService.swift` (Principle IV — no token values in payload)
- [x] T028 [US5] Verify T025 tests pass against T026/T027 implementation

**Checkpoint**: Logout is clean. No credentials remain after sign-out. All P1 user stories (US1, US2, US5) are now complete.

---

## Phase 6: User Story 3 — Proactive Token Refresh (Priority: P2)

**Goal**: 4 minutes and 55 seconds after an access token is stored, the app silently refreshes it — user never sees an interruption.

**Independent Test**: Call `TokenStore.store(accessToken:)` with a mock coordinator; advance time 295 seconds (via injectable clock or fast timer in tests); verify `TokenRefreshCoordinator.refresh()` was called exactly once.

### Tests for US3

> **Write these tests FIRST — confirm they FAIL before any implementation**

- [x] T029 [P] [US3] Write failing tests for `TokenRefreshService` in `BodyMetric/BodyMetricTests/Services/TokenRefreshServiceTests.swift` — cover: `refresh(using:)` on 200 returns `TokenRefreshResponse` with new tokens, on 401 throws `AuthError.tokenExchangeFailed`, on network error throws (use `MockURLProtocol`)
- [x] T030 [P] [US3] Write failing tests for `TokenRefreshCoordinator` in `BodyMetric/BodyMetricTests/Services/TokenRefreshCoordinatorTests.swift` — cover: single refresh call on success updates `tokenStore.accessToken`, single refresh call on failure calls `tokenStore.clearAccessToken()` and `keychainService.deleteRefreshToken()`, concurrent calls result in only one `refreshService.refresh()` invocation (use `MockTokenRefreshService`, `MockTokenStore`, `MockKeychainService`)
- [x] T031 [P] [US3] Write failing tests for `TokenStore` proactive timer in existing `BodyMetric/BodyMetricTests/Services/TokenStoreTests.swift` — cover: `store(accessToken:)` schedules a timer that calls the coordinator after 295 s (use injectable `timerInterval` defaulting to 295.0 for production, set to 0.01 in tests), storing a new token cancels the previous timer task

### Implementation for US3

- [x] T032 [US3] Implement `TokenRefreshService` conforming to `TokenRefreshServiceProtocol` in `BodyMetric/Services/Token/TokenRefreshService.swift` — `POST https://api.bodymetric.com.br/api/auth/refresh` with body `{"refresh_token": "<token>"}`, no `Authorization` header on this call; 200 → decode `TokenRefreshResponse`; 401/other → throw `AuthError.tokenExchangeFailed`; injectable `URLSession`
- [x] T033 [US3] Implement `TokenRefreshCoordinator` actor in `BodyMetric/Services/Token/TokenRefreshCoordinator.swift` — `actor TokenRefreshCoordinator`; holds `private var ongoingRefresh: Task<Void, Error>?`; `func refresh(...)`: if `ongoingRefresh` is non-nil, `try await ongoingRefresh!.value` and return; else create Task that: (1) loads refresh token from Keychain, (2) calls `tokenRefreshService.refresh(using:)`, (3) updates `tokenStore.store(accessToken:)`, (4) if response has new refresh token calls `keychainService.saveRefreshToken()`; `defer { ongoingRefresh = nil }`; on failure calls `tokenStore.clearAccessToken()`, `keychainService.deleteRefreshToken()`, `authService.signOut()`
- [x] T034 [US3] Update `TokenStore` to add proactive timer in `BodyMetric/Services/Token/TokenStore.swift` — add `private var timerTask: Task<Void, Never>?` and `var timerInterval: TimeInterval = 295.0`; in `store(accessToken:)`: cancel existing `timerTask`, start new `Task { try? await Task.sleep(for: .seconds(timerInterval)); guard !Task.isCancelled else { return }; try? await coordinator.refresh(...) }`; update `clearAccessToken()` to also cancel and nil the `timerTask`; inject `coordinator: TokenRefreshCoordinator` into `store(accessToken:coordinator:)`
- [x] T035 [US3] Add trace events to `TokenRefreshCoordinator` in `BodyMetric/Services/Token/TokenRefreshCoordinator.swift` — `token_refresh_started`, `token_refresh_succeeded`, `token_refresh_failed` (include `trigger: "proactive"` or `"reactive"` property — no token values) (Principle IV)
- [x] T036 [US3] Verify T029, T030, T031 tests pass

**Checkpoint**: Proactive refresh fires at 4:55 silently. All US3 tests pass.

---

## Phase 7: User Story 4 — Reactive Token Refresh on 401 (Priority: P2)

**Goal**: When any authenticated request receives a 401, the app refreshes the token and retries the original request once — user never sees an auth error.

**Independent Test**: Call `NetworkClient.data(for:)` with a mock that returns 401 on first call and 200 on retry; verify original request was retried exactly once with the new token.

### Tests for US4

> **Write these tests FIRST — confirm they FAIL before any implementation**

- [x] T037 [US4] Extend `NetworkClientTests` in `BodyMetric/BodyMetricTests/Services/NetworkClientTests.swift` with 401-handling cases — cover: 401 response triggers `coordinator.refresh()`, original request retried once with new token after successful refresh, refresh failure causes `NetworkError.unauthorized` throw (not retry), concurrent 401 responses result in only one `coordinator.refresh()` call (use `MockTokenRefreshCoordinator`, `MockURLProtocol`)

### Implementation for US4

- [x] T038 [US4] Update `NetworkClient.data(for:)` in `BodyMetric/Services/Network/NetworkClient.swift` to handle 401 — after first response: if `http.statusCode == 401`, call `try await coordinator.refresh(...)`, then rebuild request with new `await tokenStore.accessToken`, retry `session.data(for: retryRequest)` exactly once; if coordinator throws (refresh failed), throw `NetworkError.unauthorized`; add `coordinator: TokenRefreshCoordinator` to `NetworkClient.init`
- [x] T039 [US4] Add trace event `token_refresh_on_401` in `NetworkClient` in `BodyMetric/Services/Network/NetworkClient.swift` — fire before calling `coordinator.refresh()` (Principle IV; no URL or token values)
- [x] T040 [US4] Verify T037 tests pass against T038/T039 implementation

**Checkpoint**: 401 responses are handled transparently. Concurrent 401s issue only one refresh. All US4 tests pass.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Wire dependencies in app entry point, validate security constraints, final integration.

- [x] T041 [P] Update `BodyMetricApp` in `BodyMetric/App/BodyMetricApp.swift` — add `@State private var tokenStore = TokenStore()`, `@State private var keychainService = KeychainService()`, `@State private var refreshCoordinator = TokenRefreshCoordinator()`, `@State private var networkClient: NetworkClient`; create `AuthService` with injected deps; create `UserProfileService` with `networkClient`; pass all through `makeHomeViewModel()` and `authenticatedContainer`
- [x] T042 [P] Security audit — grep `Logger` calls in all new files under `BodyMetric/Services/Token/`, `BodyMetric/Services/Keychain/`, `BodyMetric/Services/Network/` and `BodyMetric/Services/Auth/AuthService.swift` to confirm no token string values appear in any log message (only boolean presence is allowed per Principle III/VII)
- [x] T043 [P] Update `AuthServiceProtocol` in `BodyMetric/Services/Auth/AuthServiceProtocol.swift` — add `func restorePreviousSignIn() async -> Bool` to protocol (it exists on `AuthService` but not the protocol); `MockHeaderAuthService` in tests must also get a default implementation
- [x] T044 Session restore path — update `AuthService.restorePreviousSignIn()` in `BodyMetric/Services/Auth/AuthService.swift`: after `GIDSignIn.restorePreviousSignIn()` succeeds, check if refresh token exists in Keychain (`keychainService.loadRefreshToken()`); if present, `isAuthenticated = true`; if absent, sign out immediately (no valid session without a refresh token)
- [ ] T045 [P] Validate all quickstart.md scenarios manually against the running app: happy path login, proactive refresh, reactive 401, concurrent 401, logout cleanup

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — BLOCKS all user stories
- **Phase 3 (US1)**: Depends on Phase 2 — token acquisition
- **Phase 4 (US2)**: Depends on Phase 3 (needs `TokenStore` to inject into `NetworkClient`)
- **Phase 5 (US5)**: Depends on Phase 3 (needs `TokenStore` and `KeychainService` in `AuthService`)
- **Phase 6 (US3)**: Depends on Phase 3 and Phase 5 (needs `TokenStore` actor with timer and coordinator)
- **Phase 7 (US4)**: Depends on Phase 6 (needs `TokenRefreshCoordinator`) and Phase 4 (updates `NetworkClient`)
- **Phase 8 (Polish)**: Depends on all phases complete

### User Story Dependencies

- **US1 (P1)**: Can start after Phase 2 — independent
- **US2 (P1)**: Depends on US1 (`TokenStore` must exist)
- **US5 (P1)**: Depends on US1 (`TokenStore` + `KeychainService` must exist in `AuthService`)
- **US3 (P2)**: Depends on US1 and US5 (needs coordinator + full auth service)
- **US4 (P2)**: Depends on US3 (reuses `TokenRefreshCoordinator`) and US2 (extends `NetworkClient`)

### Parallel Opportunities Within Phases

- Phase 1: T002–T009 all parallel (distinct files)
- Phase 3 tests: T013 and T014 parallel (distinct files)
- Phase 6 tests: T029, T030, T031 all parallel (distinct files)
- Phase 8: T041, T042, T043, T045 parallel

---

## Parallel Example: Phase 3 (US1)

```
Start in parallel:
  Task T013: Write TokenStore tests → BodyMetricTests/Services/TokenStoreTests.swift
  Task T014: Write TokenExchangeService tests → BodyMetricTests/Services/TokenExchangeServiceTests.swift

Then sequentially (depend on tests failing first):
  Task T015: Implement TokenStore
  Task T016: Implement TokenExchangeService
  Task T017: Update AuthService.signInWithGoogle()
  Task T018: Add trace events to AuthService
```

---

## Implementation Strategy

### MVP First (US1 + US2 + US5 — all P1 stories)

1. Complete Phase 1: Setup (protocols + models)
2. Complete Phase 2: Foundational (`KeychainService`)
3. Complete Phase 3: US1 (token acquisition)
4. Complete Phase 4: US2 (bearer injection)
5. Complete Phase 5: US5 (logout cleanup)
6. **STOP and VALIDATE**: All P1 stories working — tokens flow end-to-end, logout is clean
7. App is functionally correct for production use at this point

### Incremental Delivery

1. MVP (above) → P1 complete, app is secure and functional
2. Add Phase 6 (US3, proactive refresh) → no user interruption on 5-minute boundary
3. Add Phase 7 (US4, reactive 401) → graceful handling of server-side invalidation
4. Phase 8 Polish → wiring, audit, validation

---

## Notes

- All test tasks (T010, T013, T014, T020, T025, T029, T030, T031, T037) MUST be written before their corresponding implementation and MUST fail first (Constitution Principle II)
- Tokens MUST NEVER appear in log messages — only `present: true/false` is acceptable (Principle VII)
- `KeychainSwift` is an existing SPM dependency — no package additions required
- `MockURLProtocol`, `MockUserProfileService` patterns already established in existing tests — follow the same pattern for new mocks
- `AuthError.keychainWriteFailed` and `AuthError.tokenExchangeFailed` already defined in `AuthServiceProtocol.swift` — reuse them
- Resolves existing TODOs: `TODO(T014/T015)` in `AuthService.signInWithGoogle()` and `TODO(T012)` in `AuthService.signOut()`
