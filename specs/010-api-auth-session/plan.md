# Implementation Plan: Authenticated API Request Handling

**Branch**: `010-api-auth-session` | **Date**: 2026-04-28 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/010-api-auth-session/spec.md`

## Summary

Gap analysis reveals the existing auth infrastructure (NetworkClient, TokenRefreshCoordinator, TokenRefreshService, KeychainService) already implements ~90% of this spec. Two concrete gaps remain:

1. **Request body field name bug** (`TokenRefreshService`): sends `"refresh_token"` (snake_case) in the POST body, but the API contract requires `"refreshToken"` (camelCase). This is likely causing refresh failures.
2. **Missing URL-path exemption** (`NetworkClient`): `/q/*` and `/version` paths are not currently exempt from token injection. Auth endpoints (`/api/auth/*`) are already exempt by architecture — they use their own URLSession instances.

All other requirements (FR-001, FR-003–FR-010) are fully implemented and tested.

## Technical Context

**Language/Version**: Swift 5.10 / iOS 17+  
**Primary Dependencies**: URLSession (native), KeychainSwift SPM package; no new dependencies  
**Storage**: Keychain (refresh token — existing); in-memory actor (access token — existing)  
**Testing**: XCTest; existing `TokenRefreshServiceTests` and `NetworkClientTests` need additions  
**Target Platform**: iOS 17+ iPhone  
**Project Type**: Mobile app — bug fix + minor NetworkClient extension  
**Performance Goals**: Token refresh transparent (spec SC-003); no user-visible delay  
**Constraints**: Tokens never logged; no new SPM dependencies; ≥ 90% coverage  
**Scale/Scope**: 2 modified files, test additions only

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | Pure Swift; no new packages |
| II. Comprehensive Testing | TDD; ≥ 90% coverage; tests before implementation | ✅ | Existing test files updated; failing tests written before fixing the field name bug |
| III. Error Logging | All errors logged; no PII/tokens in logs | ✅ | Existing Logger calls remain compliant; no new logging needed |
| IV. Interaction Tracing | All meaningful interactions traced; no PII | ✅ | `token_refresh_started/succeeded/failed` already in `TokenRefreshCoordinator`; no new trace events needed |
| V. User-Friendly, Simple & Fast | Token refresh transparent to user; <300 ms feedback | ✅ | Refresh is fully invisible; field name fix ensures it actually succeeds |
| VI. Grayscale Visual Design | All UI colors grayscale | ✅ | No UI changes |
| VII. Token Security & Session Management | Bearer token in header; Keychain storage; delete on logout/expiry | ✅ | Already implemented; field name fix ensures refresh actually works end-to-end |

## Project Structure

### Documentation (this feature)

```text
specs/010-api-auth-session/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
└── tasks.md             ← Phase 2 output (created by /speckit.tasks)
```

### Source Code (changed files only)

```text
BodyMetric/Services/Token/TokenRefreshService.swift         [MODIFY] fix body: "refresh_token" → "refreshToken"
BodyMetric/Services/Network/NetworkClient.swift             [MODIFY] add URL-path exemption for /q/* and /version

BodyMetricTests/Services/TokenRefreshServiceTests.swift     [MODIFY] update + add request body field name tests
BodyMetricTests/Services/NetworkClientTests.swift           [MODIFY] add tests for path-exempt requests (no token header)
```

**Structure Decision**: All changes are to existing files. No new files, no new directories, no new SPM packages required.

## Complexity Tracking

> No Constitution violations requiring justification.
