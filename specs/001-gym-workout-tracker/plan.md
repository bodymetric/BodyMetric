# Implementation Plan: Gym Workout Tracker with Gamification

**Branch**: `001-gym-workout-tracker` | **Date**: 2026-04-04 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/001-gym-workout-tracker/spec.md`

## Summary

A native iOS app (Swift / SwiftUI) that lets users manage and execute hypertrophy-focused workout programs. Users check in at the gym, log sets and weights per exercise in real time, and review their history. A gamification layer (points, streaks, badges) rewards consistency. Authentication is via Google Sign-In; access and refresh tokens are persisted in the iOS Keychain. All screens use smooth SwiftUI animated transitions and a strict grayscale design palette.

## Technical Context

**Language/Version**: Swift 5.10 / iOS 17+  
**Primary Dependencies**: SwiftUI (UI), URLSession (networking), GoogleSignIn-iOS via SPM (auth), Security framework / KeychainSwift via SPM (secure storage)  
**Storage**: Remote — REST API (managed by backend); Local — iOS Keychain for tokens; SwiftData for offline caching of program and session data  
**Testing**: XCTest (unit + integration), XCUITest (UI flows), Swift Testing (alongside XCTest where applicable)  
**Target Platform**: iOS 17+ (iPhone primary; iPad adaptive layout)  
**Project Type**: Mobile app (iOS, native Swift/SwiftUI)  
**Performance Goals**: App launch-to-ready < 1 s; any visible operation feedback within 300 ms; set logging tap-to-save < 200 ms; screen transitions ≤ 350 ms animated  
**Constraints**: Grayscale-only UI palette; Google Sign-In as sole auth provider (v1); tokens stored exclusively in Keychain (no UserDefaults); SPM-only dependencies  
**Scale/Scope**: 10,000 concurrent users; ~15 screens across 4 feature areas; ~14 API endpoint contracts

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | Swift 5.10, SwiftUI, SPM only. GoogleSignIn-iOS and KeychainSwift via SPM. |
| II. Comprehensive Testing | TDD; ≥ 90% coverage; tests before implementation | ✅ | XCTest + XCUITest mandatory. Red-Green-Refactor enforced per task. |
| III. Error Logging | All errors logged with timestamp, severity, location, context; no PII | ✅ | OSLog (Unified Logging) as default backend per constitution TODO(LOGGING_BACKEND). |
| IV. Interaction Tracing | All meaningful interactions traced; no PII in events | ✅ | Trace events for check-in, set log, session complete, badge unlock, streak update. Backend TBD per TODO(TRACING_BACKEND). |
| V. User-Friendly, Simple & Fast | Single primary action per screen; critical path minimal taps; <1 s launch; <300 ms feedback | ✅ | Animated transitions requested by user; constitution mandates smooth transitions. Animation baseline: spring curve, ~300 ms. |
| VI. Grayscale Visual Design | All UI colors must be grayscale; semantic meaning via shape/icon/text only | ✅ | Enforced for all SwiftUI Color values, asset catalog, SF Symbols, and GoogleSignIn button wrapper. |

## Project Structure

### Documentation (this feature)

```text
specs/001-gym-workout-tracker/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── api-endpoints.md
│   ├── keychain-storage.md
│   └── navigation-transitions.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
BodyMetric/                        # Xcode project root
├── App/
│   ├── BodyMetricApp.swift        # SwiftUI @main entry point
│   └── AppEnvironment.swift       # Root environment / dependency injection
│
├── Core/
│   ├── Logging/
│   │   └── Logger.swift           # OSLog wrapper (Principle III)
│   ├── Tracing/
│   │   └── Tracer.swift           # Interaction trace events (Principle IV)
│   ├── Navigation/
│   │   ├── AppRouter.swift        # Centralised navigation state
│   │   └── Transition.swift       # Reusable animated transition definitions
│   └── Keychain/
│       └── KeychainService.swift  # Secure token read/write via Security framework
│
├── Services/
│   ├── Network/
│   │   ├── APIClient.swift        # URLSession-based HTTP client
│   │   ├── APIError.swift
│   │   └── Endpoints/
│   │       ├── AuthEndpoints.swift
│   │       ├── ProgramEndpoints.swift
│   │       ├── SessionEndpoints.swift
│   │       └── GamificationEndpoints.swift
│   └── Auth/
│       └── AuthService.swift      # Google Sign-In + token lifecycle
│
├── Features/
│   ├── Auth/
│   │   ├── Views/
│   │   │   └── LoginView.swift
│   │   └── ViewModels/
│   │       └── LoginViewModel.swift
│   ├── Program/
│   │   ├── Views/
│   │   │   ├── ProgramView.swift
│   │   │   └── TrainingDayView.swift
│   │   └── ViewModels/
│   │       ├── ProgramViewModel.swift
│   │       └── TrainingDayViewModel.swift
│   ├── Workout/
│   │   ├── Views/
│   │   │   ├── CheckInView.swift
│   │   │   ├── ActiveSessionView.swift
│   │   │   ├── ExerciseLogView.swift
│   │   │   └── SessionCompleteView.swift
│   │   └── ViewModels/
│   │       ├── CheckInViewModel.swift
│   │       ├── ActiveSessionViewModel.swift
│   │       └── ExerciseLogViewModel.swift
│   ├── History/
│   │   ├── Views/
│   │   │   ├── HistoryView.swift
│   │   │   └── ExerciseHistoryView.swift
│   │   └── ViewModels/
│   │       ├── HistoryViewModel.swift
│   │       └── ExerciseHistoryViewModel.swift
│   └── Gamification/
│       ├── Views/
│       │   ├── ProfileView.swift
│       │   └── BadgesView.swift
│       └── ViewModels/
│           ├── ProfileViewModel.swift
│           └── BadgesViewModel.swift
│
├── Models/
│   ├── User.swift
│   ├── WorkoutProgram.swift
│   ├── TrainingDay.swift
│   ├── Exercise.swift
│   ├── PlannedExercise.swift
│   ├── WorkoutSession.swift
│   ├── ExerciseLog.swift
│   ├── ExerciseSet.swift
│   ├── Badge.swift
│   └── Streak.swift
│
└── Resources/
    ├── Assets.xcassets            # Grayscale palette only
    └── Localizable.strings

BodyMetricTests/
├── Unit/
│   ├── Services/
│   │   ├── APIClientTests.swift
│   │   ├── AuthServiceTests.swift
│   │   └── KeychainServiceTests.swift
│   ├── Models/
│   └── ViewModels/
│       ├── CheckInViewModelTests.swift
│       ├── ActiveSessionViewModelTests.swift
│       └── GamificationViewModelTests.swift
└── Integration/
    └── WorkoutFlowTests.swift

BodyMetricUITests/
└── Flows/
    ├── AuthFlowUITests.swift
    ├── WorkoutSessionUITests.swift
    └── GamificationUITests.swift
```

**Structure Decision**: Option 3 variant — single native iOS app with no separate backend (the plan assumes a pre-existing REST API). Feature modules are organised by domain under `Features/`, each owning its Views and ViewModels. Shared infrastructure (logging, tracing, networking, keychain, navigation) lives in `Core/` and `Services/`. This maps directly to the "service layer + vision layer" architecture described by the user.
