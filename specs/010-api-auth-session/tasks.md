# Tasks: Authenticated API Request Handling

**Input**: Design documents from `/specs/010-api-auth-session/`  
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ quickstart.md ✅

**Tests**: Included — required by Constitution Principle II (TDD). Tests must FAIL before implementation.

**Scope summary**: Only 2 files change in production code. Everything else is already implemented correctly.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[Story]**: US1 / US2

---

## Phase 1: Setup

No new directories, files, or dependencies required. Proceed directly to foundational tests.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Write all failing tests first (TDD). Both user stories need these tests to verify the fixes.

### Tests (write first — must FAIL before T003 and T005)

- [x] T001 [P] In `BodyMetricTests/Services/TokenRefreshServiceTests.swift`: change the existing assertion at the line `XCTAssertEqual(body["refresh_token"], "my-stored-refresh")` to `XCTAssertEqual(body["refreshToken"], "my-stored-refresh")`; also add a new assertion immediately after: `XCTAssertNil(body["refresh_token"], "Must not send snake_case key")` — this test must now FAIL against the current implementation (which sends `"refresh_token"`)
- [x] T002 [P] In `BodyMetricTests/Services/NetworkClientTests.swift`: add two new test methods after the existing token-injection tests:
  `test_data_qPath_doesNotAddAuthorizationHeader` — creates a URLRequest to `https://api.bodymetric.com.br/q/exercises`, sets `MockURLProtocol.requestHandler` to capture the request and return a 200 empty response, calls `sut.data(for:)`, asserts `capturedRequest.value(forHTTPHeaderField: "Authorization") == nil`;
  `test_data_versionPath_doesNotAddAuthorizationHeader` — same pattern for `https://api.bodymetric.com.br/version` — both tests must FAIL against the current implementation (which adds a token to every request or throws `.noToken`)

**Checkpoint**: T001 and T002 fail. Ready for implementation.

---

## Phase 3: User Story 1 — Seamless session continuation when token expires (Priority: P1) 🎯 MVP

**Goal**: When a session token expires, the app automatically refreshes it using the stored refresh token, and retries the original request — transparently, with no user disruption.

**Root cause**: The refresh request body sends `"refresh_token"` (snake_case) but the backend expects `"refreshToken"` (camelCase). This makes every refresh attempt fail, causing unnecessary logouts.

**Independent Test**: Run T001 against a fixed `TokenRefreshService` — test must PASS.

### Implementation for US1

- [x] T003 [US1] In `BodyMetric/Services/Token/TokenRefreshService.swift`: find the line `request.httpBody = try JSONEncoder().encode(["refresh_token": refreshToken])` and change it to `request.httpBody = try JSONEncoder().encode(["refreshToken": refreshToken])`; run T001 — test must now PASS

**Checkpoint**: US1 fully functional. Token refresh requests now reach the backend with the correct field name, enabling automatic session continuation.

---

## Phase 4: User Story 2 — Session persists across app restarts (Priority: P2)

**Goal**: Tokens are stored securely on the device. After an app restart, the user is still authenticated. Additionally, public endpoints (`/q/*`, `/version`) can be called without a session credential.

**Independent Test**: Run T002 against a fixed `NetworkClient` — tests must PASS.

### Implementation for US2

- [x] T004 [US2] In `BodyMetric/Services/Network/NetworkClient.swift`: add the following private static constant and helper method to the `NetworkClient` class:

  ```swift
  private static let exemptPathPrefixes = ["/api/auth/", "/q/", "/version"]
  
  private func isExemptPath(_ request: URLRequest) -> Bool {
      guard let path = request.url?.path else { return false }
      return Self.exemptPathPrefixes.contains { path.hasPrefix($0) }
  }
  ```

  Then modify `data(for request: URLRequest)` to check exempt paths at the top of the method, before the `guard let token` line:

  ```swift
  if isExemptPath(request) {
      let (data, response) = try await session.data(for: request)
      guard let http = response as? HTTPURLResponse else {
          throw NetworkError.httpError(-1)
      }
      return (data, http)
  }
  ```

  (Note: exempt-path requests skip token injection entirely and are sent directly via `session.data(for:)`, without any Authorization header or 401 retry logic.)

  Run T002 — both tests must now PASS.

**Checkpoint**: US1 AND US2 both functional. Token refresh works; public endpoints accessible without credentials.

---

## Phase 5: User Story 3 — Graceful forced logout when session cannot be renewed (Priority: P3)

**Goal**: If the refresh itself fails, credentials are cleared and the user is sent to the login screen.

**Implementation status**: Already fully implemented in `TokenRefreshCoordinator.swift`. No code changes needed.

- [x] T005 [US3] Run the existing test suite for `BodyMetricTests/Services/TokenRefreshCoordinatorTests.swift` to confirm all tests still pass after changes from T003 and T004; if any fail, investigate and fix before proceeding

**Checkpoint**: All three user stories independently functional and verified.

---

## Final Phase: Polish & Cross-Cutting Concerns

- [x] T006 [P] Audit `TokenRefreshServiceTests.swift`: verify the mock response JSON uses `"sessionToken"` (not `"access_token"`) to match the CodingKey mapping in `TokenRefreshResponse.swift`; if the test at `response.refreshToken == "new-ref"` uses `"refresh_token"` in the mock JSON but the CodingKey expects `"refreshToken"`, correct the mock JSON to `{"sessionToken":"new-acc","refreshToken":"new-ref"}` so the test validates actual decoding
- [x] T007 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED with no new errors or warnings

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 2**: T001 and T002 are parallel (different test files) — both must FAIL before T003/T004
- **Phase 3 (US1)**: T003 depends on T001 failing first
- **Phase 4 (US2)**: T004 depends on T002 failing first; T004 can run in parallel with T003
- **Phase 5 (US3)**: T005 runs after T003 and T004 (verification task)
- **Final**: T006 + T007 run after all story phases; T006 can run alongside T007

---

## Parallel Opportunities

```
Phase 2 (write failing tests simultaneously):
  T001 (TokenRefreshServiceTests) ‖ T002 (NetworkClientTests)

Phase 3+4 (implement simultaneously — different files):
  T003 (TokenRefreshService.swift) ‖ T004 (NetworkClient.swift)

Final:
  T006 (mock JSON audit) ‖ T007 (build)
```

---

## Implementation Strategy

### MVP (User Story 1 only — 3 tasks)

1. T001: write failing test for body field name
2. T003: fix `"refresh_token"` → `"refreshToken"` in TokenRefreshService.swift
3. T007: build passes

**STOP and VALIDATE**: verify that a real 401 triggers a refresh that now reaches the backend correctly.

### Full Delivery (all stories — 7 tasks)

Same as MVP + T002 → T004 (URL exemption) + T005 (coordinator verification) + T006 (mock JSON audit).

---

## Notes

- Only 2 production files change: `TokenRefreshService.swift` (1-line fix) and `NetworkClient.swift` (~10 lines added)
- Everything else — coordinator, Keychain, forced logout, retry logic — is already correct
- TDD: T001 must FAIL before T003; T002 must FAIL before T004
- Commit convention: `🐛 T003: fix refresh request body key refresh_token → refreshToken`
