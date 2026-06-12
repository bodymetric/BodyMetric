# BodyMetric Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-06-11

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
- Swift 5.10 / iOS 17+ + SwiftUI (`@Observable`), GoogleSignIn-iOS (already present); no new SPM packages (009-menu-sign-out)
- No new storage — sign-out deletes Keychain tokens via existing `KeychainService` (009-menu-sign-out)
- Swift 5.10 / iOS 17+ + URLSession (native), KeychainSwift SPM package; no new dependencies (010-api-auth-session)
- Keychain (refresh token — existing); in-memory actor (access token — existing) (010-api-auth-session)
- Swift 5.10 / iOS 17+ + SwiftUI (`@Observable`), URLSession via existing `NetworkClient`; no new SPM packages (011-wizard-day-persist)
- No local persistence; all data saved to server (011-wizard-day-persist)
- Swift 5.10 / iOS 17+ + Existing `TokenRefreshCoordinator`, `KeychainService`, `TokenStore`; no new SPM packages (011-wizard-day-persist)
- iOS Keychain (refresh token); in-memory actor (access token) (011-wizard-day-persist)
- Swift 5.10 / iOS 17+ + Swift `Codable`; no new packages (011-wizard-day-persist)
- No persistence; catalog is in-memory for the wizard session (012-wizard-exercise-catalog)
- Swift 5.10 / iOS 17+ + Swift `Codable`; no new SPM packages (014-workout-week-tracking)
- No local persistence changes (014-workout-week-tracking)
- No local persistence; home data is fetched on every screen visi (015-home-screen-data)
- Swift 5.10 + SwiftUI (`@Observable`), URLSession via `NetworkClient` (existing) (019-home-api-numberofsets)
- N/A — home data is server-fetched on every visit; no local persistence change (019-home-api-numberofsets)
- Swift 5.10 + SwiftUI (`@Observable`), `@Bindable` — no new SPM packages (020-wizard-step2-per-set-rows)
- In-memory during wizard; no new UserDefaults or server persistence changes (020-wizard-step2-per-set-rows)
- Swift 5.10 + URLSession (via `NetworkClient`), `JSONDecoder` (Foundation) (020-wizard-step2-per-set-rows)
- Swift 5.10 + URLSession via `NetworkClient` (existing); no new SPM packages (021-wizard-day-save)
- N/A — all data is sent to the server; no local persistence changes (021-wizard-day-save)
- Swift 5.10 / iOS 17+ + SwiftUI (`@Observable`, `.fullScreenCover`, `.onChange`), URLSession via `NetworkClient` (existing) (022-home-refresh-post-workout)
- Swift 5.10 / iOS 17+ + SwiftUI (`@Bindable`) — no new dependencies (023-wizard-review-exercise-names)
- N/A — display-only fix; no persistence change (023-wizard-review-exercise-names)
- Swift 5.10 / iOS 17+ + SwiftUI (`@Bindable`, `View`) — no new dependencies (024-remove-plan-another-week)
- N/A — display-only change; no persistence (024-remove-plan-another-week)
- Swift 5.10 / iOS 17+ + SwiftUI (`@Observable`, `NavigationStack`, `NavigationPath`), URLSession via `NetworkClient` (existing); no new SPM packages (025-start-workout-execution)
- N/A — all data in-memory for the session lifetime; no persistence changes (025-start-workout-execution)
- Swift 5.10 / iOS 17+ + SwiftUI (`@Observable`, `@Bindable`), URLSession via existing `NetworkClient`; no new SPM packages (026-log-set-performed)
- N/A — all data sent to server; no local persistence changes (026-log-set-performed)

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
- 026-log-set-performed: Added Swift 5.10 / iOS 17+ + SwiftUI (`@Observable`, `@Bindable`), URLSession via existing `NetworkClient`; no new SPM packages
- 025-start-workout-execution: Added Swift 5.10 / iOS 17+ + SwiftUI (`@Observable`, `NavigationStack`, `NavigationPath`), URLSession via `NetworkClient` (existing); no new SPM packages
- 024-remove-plan-another-week: Added Swift 5.10 / iOS 17+ + SwiftUI (`@Bindable`, `View`) — no new dependencies


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
