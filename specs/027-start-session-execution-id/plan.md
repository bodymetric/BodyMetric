# Implementation Plan: Start Session Returns Exercise Block Execution ID

**Branch**: `027-start-session-execution-id` | **Date**: 2026-06-21 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/027-start-session-execution-id/spec.md`

## Summary

The server's `POST /api/work-executions/start` response now includes `exerciseBlockExecutionId` for every exercise block. The iOS app must treat this field as required (not optional), propagate it through the session model, and use it when calling `POST /api/exercise-block-executions/{id}/performed-sets`. This is a reversal of the defensive fallback introduced in the 026 bug fix: `Int?` → `Int`, `?? 0` mapping removed, test fixtures restored to include the field. The existing error-handling chain (decode failure → check-in screen error banner) already satisfies the "graceful failure when field is missing" requirement from US3.

## Technical Context

**Language/Version**: Swift 5.10  
**Primary Dependencies**: Foundation (`JSONDecoder`); SwiftUI (`@Observable`); no new SPM packages  
**Storage**: N/A — all data in-memory for the session lifetime  
**Testing**: XCTest (`@MainActor` test classes)  
**Target Platform**: iOS 17+  
**Project Type**: Mobile app (iOS)  
**Performance Goals**: Decode must succeed in < 50 ms (same as before)  
**Constraints**: Must not break existing tests; `guard executionId > 0` in `commitSet` is kept as a last line of defense against a server sending 0  
**Scale/Scope**: 2 production files modified; 3 test files modified; 1 new test added; no new files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | Pure Swift; no new dependencies |
| II. Comprehensive Testing | TDD; ≥ 90% coverage; tests before implementation | ✅ | Existing tests updated; new decode-failure test added for US3 |
| III. Error Logging | All errors logged with timestamp, severity, location, context; no PII | ✅ | Existing decode-failure logging in `WorkoutExecutionService` covers US3 |
| IV. Interaction Tracing | All meaningful interactions traced; no PII in events | ✅ | No new user interactions; session start tracing unchanged |
| V. User-Friendly, Simple & Fast | Single primary action; critical path minimal taps; < 300 ms feedback | ✅ | US3 surfaces error on check-in screen within existing feedback budget |
| VI. Grayscale Visual Design | All UI colors must be grayscale | ✅ | No new UI; existing error banner is grayscale |
| VII. Token Security & Session Management | Bearer token in Authorization header; tokens in Keychain only | ✅ | No auth changes; existing NetworkClient handles token attachment |

## Project Structure

### Documentation (this feature)

```text
specs/027-start-session-execution-id/
├── plan.md              ← This file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── contracts/           ← Phase 1 output
│   └── start-session-api.md
└── tasks.md             ← /speckit-tasks output
```

### Source Code (affected files)

```text
Models/
└── WorkoutExecutionModels.swift        ← exerciseBlockExecutionId: Int? → Int; remove ?? 0

Features/Workout/
└── ViewModels/
    └── ActiveSessionViewModel.swift    ← guard message updated (cosmetic; guard kept)

BodyMetricTests/
├── Features/
│   ├── ReadyToLiftViewModelTests.swift      ← nil → 301 in ExerciseBlockPlan fixtures
│   └── ActiveSessionViewModelTests.swift    ← fixture updated; zero-executionId test kept
└── Services/
    └── WorkoutExecutionServiceTests.swift   ← add "exerciseBlockExecutionId": 301 to JSON; add decode-failure test
```

## Complexity Tracking

No constitution violations. No complexity justifications required.
