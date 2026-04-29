# Implementation Plan: Home Menu — Sign Out ("Exit")

**Branch**: `009-menu-sign-out` | **Date**: 2026-04-27 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/009-menu-sign-out/spec.md`

## Summary

Add an "Exit" item as the last entry in the home dropdown menu. When tapped, the app calls the existing `AuthService.signOut()` — which already handles Google sign-out, in-memory token clearing, and Keychain refresh-token deletion (Constitution Principle VII). Setting `isAuthenticated = false` in the observable `AuthService` triggers `BodyMetricApp` to route back to the login screen automatically. The feature is pure wiring: 4 modified files, 0 new files, 0 new dependencies.

## Technical Context

**Language/Version**: Swift 5.10 / iOS 17+  
**Primary Dependencies**: SwiftUI (`@Observable`), GoogleSignIn-iOS (already present); no new SPM packages  
**Storage**: No new storage — sign-out deletes Keychain tokens via existing `KeychainService`  
**Testing**: XCTest unit tests (update existing `HomeMenuModelsTests`); no new test files required  
**Target Platform**: iOS 17+ iPhone  
**Project Type**: Mobile app — minor UI addition + existing auth wiring  
**Performance Goals**: Sign-out completes in < 2 s (spec SC-003); menu closes immediately  
**Constraints**: All colors GrayscalePalette; no new dependencies; sign-out must succeed even offline (FR-007)  
**Scale/Scope**: 4 modified files, 0 new files; 1 new `HomeMenuItem` entry; 1 new closure thread through view hierarchy

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | No new packages; pure Swift |
| II. Comprehensive Testing | TDD; ≥ 90% coverage; tests before implementation | ✅ | Existing `HomeMenuModelsTests` must be updated (catalog count 7→8, active count 2→3); `AuthService.signOut` is already tested |
| III. Error Logging | All errors logged with timestamp, severity, location, context; no PII | ✅ | `AuthService.signOut()` already logs; Keychain delete failure is logged and non-fatal |
| IV. Interaction Tracing | All meaningful interactions traced; no PII in events | ✅ | `tokens_cleared_on_logout` trace already in `AuthService.signOut`; add `menu_sign_out_tapped` trace in `HomeMenuView` |
| V. User-Friendly, Simple & Fast | Single primary action per screen; critical path minimal taps; <1 s launch; <300 ms feedback | ✅ | One tap → sign-out; no confirmation dialog; menu closes immediately; sign-out completes async |
| VI. Grayscale Visual Design | All UI colors must be grayscale; semantic meaning via shape/icon/text only | ✅ | "Exit" row uses `GrayscalePalette.secondary` for text (visually subordinate) + SF Symbol icon; a `Divider()` separator provides structural distinction; no non-grayscale colors |
| VII. Token Security & Session Management | Bearer token in Authorization header; tokens in Keychain; delete on logout/expiry | ✅ | `AuthService.signOut()` already: clears access token from memory, deletes refresh token from Keychain, calls `GIDSignIn.sharedInstance.signOut()` |

## Project Structure

### Documentation (this feature)

```text
specs/009-menu-sign-out/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
└── tasks.md             ← Phase 2 output (created by /speckit.tasks)
```

### Source Code

```text
Features/Workout/Models/HomeMenuModels.swift           [MODIFY] add isSignOut field + "exit" catalog entry
Features/Workout/Views/Components/HomeMenuView.swift   [MODIFY] add onSignOut callback; "exit" row styling; Divider separator; trace event
Features/Workout/Views/TodayView.swift                 [MODIFY] add onSignOut parameter; pass to HomeMenuView
Features/Navigation/MainTabView.swift                  [MODIFY] pass onSignOut closure using authService

BodyMetricTests/Features/HomeMenuModelsTests.swift     [MODIFY] update count assertions + add "exit" item tests
```

**Structure Decision**: Feature module `Workout/` owns `HomeMenuModels` and `HomeMenuView`. No new module needed — this is a catalog extension and callback wiring.

## Complexity Tracking

> No Constitution violations requiring justification.
