# Implementation Plan: Start Workout Flow

**Branch**: `018-start-workout-flow` | **Date**: 2026-05-18 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/018-start-workout-flow/spec.md`

## Summary

When the user taps "Start Workout" on the home screen, the app navigates to the existing `CheckInView` ("Ready to Lift") with plan context. The user selects their feeling (Low/Good/Strong), then taps "Begin session" which calls `POST /api/work-executions/start` with the plan ID, current week number, and uppercase feeling. On success, the app navigates to the existing `ActiveSessionView` pre-populated with exercise blocks from the API response. On failure, an error is shown and the button re-enables.

## Technical Context

**Language/Version**: Swift 5.10 / iOS 17+
**Primary Dependencies**: SwiftUI (`@Observable`), URLSession via existing `NetworkClient`; no new SPM packages
**Storage**: No local persistence; session data is in-memory for the duration of the workout
**Testing**: XCTest (`@MainActor` unit tests following existing patterns)
**Target Platform**: iOS 17+ Simulator + device
**Performance Goals**: Session start API call completes and navigates in < 3 s; "Begin session" loading indicator appears in < 300 ms
**Constraints**: Bearer token injected by `NetworkClient`; feeling always uppercase; re-entry guard on submit button
**Scale/Scope**: 3 new files, 3 modified files; reuses existing `CheckInView`, `ActiveSessionView`, `ActiveSessionViewModel`

## Constitution Check

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | No new packages; pure Swift |
| II. Comprehensive Testing | TDD; ≥ 90% coverage; tests before implementation | ✅ | Tests for service methods and VM actions |
| III. Error Logging | All errors logged at ERROR; no PII or tokens | ✅ | All catch sites log via `Logger.error`; feeling value is not PII |
| IV. Interaction Tracing | All meaningful interactions traced | ✅ | `session_begin_started/success/failed` traces |
| V. User-Friendly, Simple & Fast | Single CTA; loading indicator < 300 ms | ✅ | "Begin session" is the only CTA; loading state immediate |
| VI. Grayscale Visual Design | All UI colors grayscale | ✅ | `CheckInView` already uses `GrayscalePalette` exclusively |
| VII. Token Security & Session Management | Bearer token via `NetworkClient`; no tokens in logs | ✅ | New service uses `networkClient.data(for:)` — token injection automatic |

## Project Structure

### Documentation (this feature)

```text
specs/018-start-workout-flow/
├── plan.md           ✅
├── spec.md           ✅
├── research.md       ✅
├── data-model.md     ✅
├── quickstart.md     ✅
├── contracts/
│   └── api.md        ✅
└── checklists/
    └── requirements.md ✅
```

### Source Code

```text
Models/
├── HomeModels.swift                          # MODIFY: add actualWeekNumber to WorkoutDayPlanSummary
└── WorkoutExecutionModels.swift              # NEW: request/response DTOs + WorkoutSession mapping

Services/WorkoutExecution/                    # NEW directory
├── WorkoutExecutionServiceProtocol.swift     # NEW
└── WorkoutExecutionService.swift             # NEW

Features/Workout/
├── ViewModels/
│   └── ReadyToLiftViewModel.swift            # NEW: @Observable ViewModel for CheckInView API state
└── Views/
    ├── CheckInView.swift                     # MODIFY: replace WorkoutSession param with plan context; add ViewModel + API wiring; error/loading state
    └── TodayView.swift                       # MODIFY: wire "Start Workout" button + fullScreenCover for CheckInView

BodyMetricTests/
├── Services/
│   └── WorkoutExecutionServiceTests.swift    # NEW
└── Features/
    └── ReadyToLiftViewModelTests.swift       # NEW
```

## Complexity Tracking

> No constitution violations.

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]  
**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]  
**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]  
**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]  
**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]
**Project Type**: [e.g., library/cli/web-service/mobile-app/compiler/desktop-app or NEEDS CLARIFICATION]  
**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]  
**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]  
**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ☐ | |
| II. Comprehensive Testing | TDD; ≥ 90% coverage; tests before implementation | ☐ | |
| III. Error Logging | All errors logged with timestamp, severity, location, context; no PII | ☐ | |
| IV. Interaction Tracing | All meaningful interactions traced; no PII in events | ☐ | |
| V. User-Friendly, Simple & Fast | Single primary action per screen; critical path minimal taps; <1 s launch; <300 ms feedback | ☐ | |
| VI. Grayscale Visual Design | All UI colors must be grayscale; semantic meaning via shape/icon/text only | ☐ | |

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
