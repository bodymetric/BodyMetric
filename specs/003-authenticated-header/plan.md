# Implementation Plan: Authenticated Area Global Header

**Branch**: `003-authenticated-header` | **Date**: 2026-04-10 | **Spec**: [spec.md](./spec.md)
**Input**: "Make a top header with app logo on left and logout icon on right, put margin on both sides"

## Summary

A reusable `AppHeader` SwiftUI view is placed at the top of every authenticated
screen. It shows `AppLogo` on the left with 10 pt leading padding and a
sign-out icon on the right with 10 pt trailing padding. Background is
`GrayscalePalette.primary` (near-black). `BodyMetricApp` wraps all
authenticated screens in a shared container that injects this header.

## Technical Context

**Language/Version**: Swift 5.10
**Primary Dependencies**: SwiftUI (native), GoogleSignIn-iOS via SPM (sign-out call)
**Storage**: None (header is pure UI; sign-out delegates to `AuthService`)
**Testing**: XCTest (unit — ViewModel sign-out path); no UI test required for this feature
**Target Platform**: iOS 17+
**Project Type**: Mobile app
**Performance Goals**: Header renders within one frame (<16 ms); sign-out navigation completes within 2 seconds
**Constraints**: All colors via `GrayscalePalette` tokens only; 10 pt padding on both sides; safe-area aware
**Scale/Scope**: Single reusable view consumed by all current and future authenticated screens

## Constitution Check

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | Pure SwiftUI; no new dependencies |
| II. Comprehensive Testing | TDD; ≥ 90% coverage | ✅ | Sign-out action tested in AppHeaderViewModelTests |
| III. Error Logging | All errors logged with context; no PII | ✅ | Sign-out failure logged in AuthService (already implemented) |
| IV. Interaction Tracing | Meaningful interactions traced; no PII | ✅ | `header_logout_tapped` trace stub in AppHeaderViewModel |
| V. User-Friendly, Simple & Fast | Single primary action; <300 ms feedback | ✅ | One action (logout); header renders synchronously |
| VI. Grayscale Visual Design | All UI colors grayscale only | ✅ | Background = `GrayscalePalette.primary`; logo + icon in grayscale |

## Project Structure

### Documentation (this feature)

```text
specs/003-authenticated-header/
├── plan.md        # This file
├── research.md    # Phase 0 output
└── tasks.md       # Phase 2 output (/speckit-tasks command)
```

### Source Code

```text
# New for this feature
Features/
└── Shared/
    └── Header/
        ├── AppHeader.swift          # Reusable header view
        └── AppHeaderViewModel.swift # @Observable; owns logout action + trace

# Modified
App/
└── BodyMetricApp.swift              # Wrap authenticated content in authenticated container with AppHeader

BodyMetricTests/
└── Features/
    └── AppHeaderViewModelTests.swift  # Sign-out path unit tests
```

**Structure Decision**: `AppHeader` lives under `Features/Shared/Header/` — a shared UI
module pattern consistent with the existing feature-module layout. No new
top-level directories needed.

## Complexity Tracking

> No constitution violations. No complexity exceptions required.
