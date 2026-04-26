# BodyMetric Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-04-26

## Active Technologies
- Swift 5.10 + SwiftUI (UI), URLSession (networking), GoogleSignIn-iOS via SPM (auth), KeychainSwift via SPM (secure email storage), UserDefaults (weight/height cache) (002-user-profile-fetch)
- UserDefaults for weight/height (non-sensitive); Keychain (KeychainSwift) for email (already used by auth layer) (002-user-profile-fetch)
- Swift 5.10 + SwiftUI (native), GoogleSignIn-iOS via SPM (sign-out call) (003-authenticated-header)
- None (header is pure UI; sign-out delegates to `AuthService`) (003-authenticated-header)
- Swift 5.10 + iOS 17+ + GoogleSignIn-iOS (SPM, existing), KeychainSwift (SPM, existing) (004-token-session-management)
- iOS Keychain (refresh token only); in-memory actor (access token) (004-token-session-management)
- Swift 5.10 + iOS 17+ + SwiftUI (`@Observable`), URLSession (via `NetworkClient`), GoogleSignIn-iOS (SPM, existing) (005-profile-completion-form)
- `ProfileStore` (UserDefaults-backed, non-sensitive fields); Keychain for tokens (existing) (005-profile-completion-form)
- Swift 5.10 / iOS 17+ + SwiftUI (`@Observable`, `NavigationStack`, ZStack overlays), no new SPM packages required (006-home-menu-dropdown)
- UserDefaults (via existing `ProfileStore` pattern) for saving the resulting `WorkoutPlan`; in-memory during wizard flow (006-home-menu-dropdown)
- Swift 5.10 / iOS 17+ + SwiftUI (`@Observable`), URLSession (via existing `NetworkClient`); no new SPM packages (008-wizard-day-selection)
- No local persistence for this feature (day selections live on the server); existing `WorkoutPlanStore` (UserDefaults) is unaffected (008-wizard-day-selection)

- Swift 5.10 / iOS 17+ + SwiftUI (UI), URLSession (networking), GoogleSignIn-iOS via SPM (auth), Security framework / KeychainSwift via SPM (secure storage) (001-gym-workout-tracker)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Swift 5.10 / iOS 17+

## Code Style

Swift 5.10 / iOS 17+: Follow standard conventions

## Recent Changes
- 008-wizard-day-selection: Added Swift 5.10 / iOS 17+ + SwiftUI (`@Observable`), URLSession (via existing `NetworkClient`); no new SPM packages
- 006-home-menu-dropdown: Added Swift 5.10 / iOS 17+ + SwiftUI (`@Observable`, `NavigationStack`, ZStack overlays), no new SPM packages required
- 005-profile-completion-form: Added Swift 5.10 + iOS 17+ + SwiftUI (`@Observable`), URLSession (via `NetworkClient`), GoogleSignIn-iOS (SPM, existing)


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
