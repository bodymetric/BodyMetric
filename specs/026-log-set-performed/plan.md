# Implementation Plan: Fix Begin Session Decode Failure (026 Bug Fix)

**Branch**: `026-log-set-performed` | **Date**: 2026-06-13 | **Spec**: [spec.md](spec.md)  
**Input**: Bug report — `POST /api/work-executions/start` response is missing `exerciseBlockExecutionId`; app fails to decode and shows "Could not read the server response."

## Summary

Feature 026 added `let exerciseBlockExecutionId: Int` (non-optional) to `ExerciseBlockPlan`. The backend's start-session response does not include this field, so `JSONDecoder` throws `DecodingError.keyNotFound`, which propagates as a decode failure and prevents the session from starting. The fix makes the field optional at the decode boundary (`ExerciseBlockPlan`), maps it with a `?? 0` fallback into `WorkoutExercise`, and adds a guard in `commitSet` that prevents calling the log-set API when the execution ID is unavailable.

## Technical Context

**Language/Version**: Swift 5.10  
**Primary Dependencies**: Foundation (`JSONDecoder`, `URLSession`); SwiftUI (`@Observable`); no new SPM packages  
**Storage**: N/A — fix is purely in-memory model and networking layer  
**Testing**: XCTest (`@MainActor` test classes)  
**Target Platform**: iOS 17+  
**Project Type**: Mobile app (iOS)  
**Performance Goals**: Decode must succeed in < 50 ms (same as before)  
**Constraints**: Must not break existing 026 tests; must not introduce new non-optional fields without server support  
**Scale/Scope**: 3 files modified; 2 test files updated; no new files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | Pure Swift fix; no new dependencies |
| II. Comprehensive Testing | TDD; ≥ 90% coverage; tests before implementation | ✅ | Existing tests updated; guard path covered by new test case |
| III. Error Logging | All errors logged with timestamp, severity, location, context; no PII | ✅ | `commitSet` guard logs executionId absence; no PII in logs |
| IV. Interaction Tracing | All meaningful interactions traced; no PII in events | ✅ | No new interactions introduced; fix is transparent to user |
| V. User-Friendly, Simple & Fast | Single primary action per screen; critical path minimal taps; < 1 s launch; < 300 ms feedback | ✅ | Session start now succeeds; fallback error message is clear and actionable |
| VI. Grayscale Visual Design | All UI colors must be grayscale; semantic meaning via shape/icon/text only | ✅ | No new UI; existing error label (grayscale) reused |
| VII. Token Security & Session Management | Bearer token in Authorization header; tokens in Keychain only; deleted on logout/expiry | ✅ | No auth changes; existing NetworkClient handles token attachment |

## Project Structure

### Documentation (this feature)

```text
specs/026-log-set-performed/
├── plan.md              ← This file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── contracts/           ← Phase 1 output
│   └── start-session-api.md
└── tasks.md             ← Phase 2 output (/speckit-tasks)
```

### Source Code (affected files)

```text
Models/
└── WorkoutExecutionModels.swift       ← ExerciseBlockPlan: Int → Int?

Features/Workout/
├── Models/
│   └── WorkoutModels.swift            ← WorkoutExercise: exerciseBlockExecutionId stays Int (mapped with ?? 0)
└── ViewModels/
    └── ActiveSessionViewModel.swift   ← commitSet: guard executionId > 0

BodyMetricTests/
├── Features/
│   ├── ReadyToLiftViewModelTests.swift       ← fixture: exerciseBlockExecutionId removed or set to nil
│   └── ActiveSessionViewModelTests.swift     ← new test: guard fires when executionId == 0
└── Services/
    └── WorkoutExecutionServiceTests.swift    ← JSON fixture: remove exerciseBlockExecutionId key
```

## Complexity Tracking

No constitution violations. No complexity justifications required.
