# Implementation Plan: User Profile Fetch & Display

**Branch**: `002-user-profile-fetch` | **Date**: 2026-04-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-user-profile-fetch/spec.md`

## Summary

After a successful Google Sign-In, the app extracts the user's email from the
Google session and calls `GET https://api.bodymetric.com.br/api/users?email=<email>`.
A 200 response triggers weight + height extraction and local persistence; a 404
redirects the user to a "Create Account" screen. On subsequent launches with a
restored session, the app checks local storage and re-fetches if weight or
height is absent. The home screen always displays the authenticated user's
email, weight, and height.

## Technical Context

**Language/Version**: Swift 5.10
**Primary Dependencies**: SwiftUI (UI), URLSession (networking), GoogleSignIn-iOS via SPM (auth), KeychainSwift via SPM (secure email storage), UserDefaults (weight/height cache)
**Storage**: UserDefaults for weight/height (non-sensitive); Keychain (KeychainSwift) for email (already used by auth layer)
**Testing**: XCTest (unit + integration); XCUITest (UI)
**Target Platform**: iOS 17+
**Project Type**: Mobile app
**Performance Goals**: Profile data appears within 3 seconds of sign-in on a standard mobile connection; local cache hit renders within 500 ms
**Constraints**: No PII in logs; all UI must be grayscale; API response must be decoded without crashing on missing/null fields
**Scale/Scope**: Single-user device; no multi-account support

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Swift-Native Code | All product code in Swift; SPM for dependencies | ✅ | URLSession + KeychainSwift via SPM; no Objective-C |
| II. Comprehensive Testing | TDD; ≥ 90% coverage; tests before implementation | ✅ | UserProfileServiceTests, ProfileStoreTests, HomeViewModelTests required |
| III. Error Logging | All errors logged with timestamp, severity, location, context; no PII | ✅ | API errors and storage errors logged; email redacted in logs |
| IV. Interaction Tracing | All meaningful interactions traced; no PII in events | ✅ | Trace: profile_fetch_started, profile_fetch_succeeded, profile_fetch_404, profile_cached_hit |
| V. User-Friendly, Simple & Fast | Single primary action per screen; <1 s launch; <300 ms feedback | ✅ | Home screen is read-only display; loading state shown within 300 ms |
| VI. Grayscale Visual Design | All UI colors must be grayscale; semantic meaning via shape/icon/text | ✅ | HomeView and CreateUserView use GrayscalePalette tokens only |

## Project Structure

### Documentation (this feature)

```text
specs/002-user-profile-fetch/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── contracts/
│   └── users-endpoint.md  # API contract
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code

```text
# Existing (unchanged unless noted)
App/
└── BodyMetricApp.swift              # Updated: wire ProfileCoordinator post-auth

Core/
├── Design/GrayscalePalette.swift
├── Logging/Logger.swift
└── Navigation/Transition.swift

Features/
├── Auth/
│   ├── ViewModels/LoginViewModel.swift
│   └── Views/LoginView.swift
└── Splash/
    └── SplashView.swift

Services/
├── Auth/
│   ├── AuthService.swift
│   └── AuthServiceProtocol.swift

# New for this feature
Models/
└── UserProfile.swift                # Decodable struct: email, weight, height, units

Services/
├── Profile/
│   ├── UserProfileServiceProtocol.swift   # Protocol for testability
│   └── UserProfileService.swift           # URLSession GET /api/users?email=
└── Storage/
    └── ProfileStore.swift                 # UserDefaults read/write for weight/height/email

Features/
├── Home/
│   ├── ViewModels/HomeViewModel.swift     # @Observable; triggers fetch if cache incomplete
│   └── Views/HomeView.swift               # Displays email, weight, height
└── CreateUser/
    └── Views/CreateUserView.swift         # Shown on 404; placeholder for user creation

Tests/
├── Unit/
│   ├── UserProfileServiceTests.swift
│   ├── ProfileStoreTests.swift
│   └── HomeViewModelTests.swift
└── Integration/
    └── ProfileFetchIntegrationTests.swift
```

**Structure Decision**: Single-project mobile app. New code follows the existing
feature-module layout (Features/, Services/, Models/) already established in
feature 001. No new top-level directories introduced.

## Complexity Tracking

> No constitution violations to justify.

---

## Phase 0: Research

### Research Questions

| # | Unknown | Resolution |
|---|---------|------------|
| R1 | Does `GET /api/users?email=` require an Authorization header? | Assumed public for now (no token in spec); confirm with API owner before T-implementation. If auth required, add bearer token from Google idToken. |
| R2 | What is the exact JSON shape of a 200 response? | See contracts/users-endpoint.md. Assumed `{ "weight": Double, "height": Double, "weightUnit": String, "heightUnit": String }`. Confirm and update decoder. |
| R3 | What should "Create User" screen do — just a placeholder or a full form? | For this feature: placeholder only (shows a message + "Contact support"). Full user creation is a future feature. |
| R4 | Which storage layer for email? | Email already held in `GIDSignIn.sharedInstance.currentUser` while session is active. Persist to UserDefaults (non-sensitive display value) alongside weight/height. Keychain reserved for tokens. |
| R5 | How does re-fetch trigger on restored session? | `HomeViewModel.onAppear` checks `ProfileStore.isComplete`; if false, calls `UserProfileService.fetchProfile(email:)`. |

### Decisions

**D1 — API auth**: No auth header assumed. If the API returns 401, `UserProfileService` logs the error and surfaces `.unauthorized` case; revisit with API owner.

**D2 — JSON contract**: See `contracts/users-endpoint.md`. `UserProfile` is decoded with `@DecodingFailure`-safe optionals so a missing field never crashes.

**D3 — CreateUser scope**: `CreateUserView` is a static placeholder for this feature. It receives no data and shows an informational message. Full creation form is out of scope.

**D4 — Email storage**: Stored in `UserDefaults` under a namespaced key (`bm.profile.email`). Not sensitive enough for Keychain; Keychain is reserved for auth tokens.

**D5 — Fetch trigger**: `HomeViewModel` is the single orchestration point. It is initialized by `BodyMetricApp` after authentication is confirmed (either new sign-in or restored session). `ProfileStore.isComplete` guards against redundant API calls.

