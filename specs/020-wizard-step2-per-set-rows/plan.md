# Implementation Plan: Home API Response Adaptation

**Branch**: `020-wizard-step2-per-set-rows` | **Date**: 2026-05-28 | **Spec**: [user input]
**Input**: Bug report — `home_data_load_failed | error: Could not read the server response` from `TodayViewModel.swift:49`

## Summary

The `GET /api/home` endpoint returns `exercisesForToday[].sets: []` (an array), but the `TodayExercise` model decodes `numberOfSets: Int` — a key that does not exist in the response. This causes `JSONDecoder` to throw "key not found" on every home screen load. The fix restores `TodayExercise.sets: [HomeExerciseSet]` and derives `numberOfSets` as a computed property. No server change required.

## Technical Context

**Language/Version**: Swift 5.10  
**Primary Dependencies**: URLSession (via `NetworkClient`), `JSONDecoder` (Foundation)  
**Storage**: N/A — home data is server-fetched on every visit  
**Testing**: XCTest  
**Target Platform**: iOS 17+  
**Project Type**: Mobile app  
**Performance Goals**: Home screen decode completes within 300 ms (Principle V)  
**Constraints**: No PII in logs; tokens never in logs (Principles III, VII)  
**Scale/Scope**: 3 files changed, 0 new types added (HomeExerciseSet already existed pre-019)

## Constitution Check

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | Pure Swift model change |
| II. Comprehensive Testing | TDD; ≥ 90% coverage; tests before implementation | ✅ | `HomeServiceTests` already validates `sets` format; `TodayViewModelTests` fixtures updated |
| III. Error Logging | All errors logged; no PII | ✅ | `HomeService` already logs decode failures via `Logger.error` |
| IV. Interaction Tracing | All interactions traced; no PII | ✅ | No new user interactions introduced |
| V. User-Friendly, Simple & Fast | Critical path minimal taps; <300 ms feedback | ✅ | Fix removes a fatal decode error; restores home screen load |
| VI. Grayscale Visual Design | All UI grayscale | ✅ | No UI changes |
| VII. Token Security | Bearer token via Keychain; never in logs | ✅ | No auth layer changes |

## Project Structure

### Source Code

```text
Models/
└── HomeModels.swift          # TodayExercise + HomeExerciseSet — PRIMARY CHANGE

Features/Workout/Views/
└── TodayView.swift           # Preview stubs: numberOfSets: N → sets: []

BodyMetricTests/Features/
└── TodayViewModelTests.swift # Fixtures: numberOfSets: N → sets: []

BodyMetricTests/Services/
└── HomeServiceTests.swift    # Already correct — uses sets array format ✅
```

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
