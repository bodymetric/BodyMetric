# Tasks: Gym Workout Tracker with Gamification

**Input**: Design documents from `/specs/001-gym-workout-tracker/`  
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Tech Stack**: Swift 5.10 / iOS 17+, SwiftUI, URLSession, GoogleSignIn-iOS (SPM), KeychainSwift (SPM), SwiftData  
**Architecture**: MVVM — `@Observable` ViewModels · Service Layer · Vision (SwiftUI) Layer  
**Tests**: XCTest unit tests required per Constitution Principle II (TDD — write failing test first, implement, confirm pass)  
**Additional context**: SplashView with centered logo (`logo/funny_health_apple_logo.svg`) on white background

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)

---

## Phase 1: Setup

**Purpose**: Xcode project scaffolding, SPM dependencies, and asset preparation

- [ ] T001 Create Xcode project `BodyMetric` with targets: `BodyMetric` (app), `BodyMetricTests` (unit/integration), `BodyMetricUITests` — bundle ID `com.bodymetric.app`, minimum deployment iOS 17
- [ ] T002 [P] Add `GoogleSignIn-iOS` package (`https://github.com/google/GoogleSignIn-iOS`, `≥ 7.1.0`) via SPM, linking `GoogleSignIn` and `GoogleSignInSwift` targets to the `BodyMetric` app target
- [ ] T003 [P] Add `KeychainSwift` package (`https://github.com/evgenyneu/keychain-swift`, `≥ 20.0`) via SPM, linking to the `BodyMetric` app target
- [x] T004 Add `logo/funny_health_apple_logo.svg` to `BodyMetric/Resources/Assets.xcassets` as an image set named `AppLogo` with Preserve Vector Data enabled (single scale, universal)
- [ ] T005 Add `Config.xcconfig` (gitignored) with `API_BASE_URL = https://api-dev.bodymetric.app`; reference `$(API_BASE_URL)` in `BodyMetric-Info.plist` as `APIBaseURL`; add `Config.xcconfig` to `.gitignore`
- [ ] T006 [P] Configure Google Sign-In reversed client ID URL scheme in `BodyMetric-Info.plist` under `CFBundleURLSchemes` (placeholder value documented in `quickstart.md` step 3)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure every user story depends on — Logging, Tracing, Design, Navigation, Keychain, Networking, Auth, Splash

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Core Infrastructure

- [x] T007 Create `BodyMetric/Core/Logging/Logger.swift` — `OSLog`-backed `Logger` struct with static methods: `debug(_:file:function:line:)`, `info(_:file:function:line:)`, `warning(_:file:function:line:)`, `error(_:error:file:function:line:)`, `fault(_:file:function:line:)`. Each call emits timestamp, severity, source location, and message. No PII in any log output. (Principle III)
- [ ] T008 [P] Create `BodyMetric/Core/Tracing/Tracer.swift` — `Tracer` struct with `static func track(event: TraceEvent)`. Define `TraceEvent` as a struct with `name: String` (snake_case), `timestamp: Date`, and `properties: [String: String]`. Stub the backend call with `Logger.debug` until TODO(TRACING_BACKEND) is resolved. (Principle IV)
- [x] T009 [P] Create `BodyMetric/Core/Design/GrayscalePalette.swift` — `enum GrayscalePalette` with static `Color` constants: `background`, `surface`, `primary`, `secondary`, `disabled`, `separator` using light/dark adaptive grayscale values per research.md. No non-grayscale values. (Principle VI)
- [x] T010 [P] Create `BodyMetric/Core/Navigation/Transition.swift` — `Animation` extensions `.bmSpring` (spring, response 0.35, damping 0.82) and `.bmFade` (easeInOut, 0.25 s); `AnyTransition` extensions `.bmSlide` (asymmetric move + opacity) and `.bmScaleUp` (asymmetric scale + opacity). These are the ONLY animation values used across the app. (Principle V)

### Navigation

- [ ] T011 Create `BodyMetric/Core/Navigation/AppRouter.swift` — `@Observable final class AppRouter` with `NavigationPath` per tab: `workoutPath`, `programPath`, `historyPath`, `profilePath`; `var presentedSheet: SheetDestination?`; `enum SheetDestination`; `enum WorkoutDestination`, `ProgramDestination`, `HistoryDestination`, `ProfileDestination` matching the screen inventory in `contracts/navigation-transitions.md`

### Security

> **TDD**: Write T077 first — confirm it fails — then implement T012.

- [ ] T077 [P] Write `BodyMetricTests/Unit/Services/KeychainServiceTests.swift` — XCTest unit tests for `KeychainServiceProtocol`: `test_save_and_read_accessToken()`, `test_save_and_read_refreshToken()`, `test_read_missingKey_throwsItemNotFound()`, `test_delete_removesItem()`, `test_clearAll_removesBothTokens()`, `test_save_overwritesExistingValue()`. Use a real `KeychainService` instance; clean up all test keys in `tearDown`. **Must FAIL before T012 is implemented.**
- [ ] T012 Create `BodyMetric/Core/Keychain/KeychainService.swift` — `protocol KeychainServiceProtocol` with `save(key:value:)`, `read(key:)`, `delete(key:)`, `clearAll()` throwing `KeychainError`; `enum KeychainKey` (`.accessToken`, `.refreshToken`); `enum KeychainError`; `struct KeychainService: KeychainServiceProtocol` implementation using `KeychainSwift` with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` and `synchronizable = false` per `contracts/keychain-storage.md`

### Networking

> **TDD**: Write T078 first — confirm it fails — then implement T015.

- [ ] T078 [P] Write `BodyMetricTests/Unit/Services/APIClientTests.swift` — XCTest unit tests for `APIClient` using `MockURLProtocol` or `MockAPIClient`: `test_send_successfulResponse_decodesModel()`, `test_send_401_triggersTokenRefresh()`, `test_send_secondConsecutive401_postsSessionExpiredNotification()`, `test_send_networkError_throwsNetworkUnavailable()`, `test_send_decodingFailure_throwsDecodingFailed()`, `test_send_404_throwsNotFound()`. **Must FAIL before T015 is implemented.**
- [ ] T013 [P] Create `BodyMetric/Services/Network/APIError.swift` — `enum APIError: Error` covering `.unauthorized`, `.forbidden`, `.notFound`, `.conflict`, `.serverError(message: String)`, `.decodingFailed`, `.networkUnavailable`. Map HTTP status codes per error contract in `contracts/api-endpoints.md`.
- [ ] T014 Create `BodyMetric/Services/Network/Endpoints/AuthEndpoints.swift` — typed `URLRequest` builders for: `POST /auth/google` (body: idToken), `POST /auth/refresh` (body: refreshToken), `DELETE /auth/session`. Base URL read from `Bundle.main.infoDictionary["APIBaseURL"]`. All requests set `Content-Type: application/json`.
- [ ] T015 Create `BodyMetric/Services/Network/APIClient.swift` — `protocol APIClientProtocol { func send<T: Decodable>(_ request: URLRequest) async throws -> T }`; `actor APIClient: APIClientProtocol` using `URLSession.shared`; 401 handling: call `AuthService.refreshToken()` → retry once → on second 401 post `Notification` `.userSessionExpired`; all errors logged via `Logger.error` before throwing (Principle III); `struct MockAPIClient: APIClientProtocol` for tests

### Authentication

> **TDD**: Write T079 first — confirm it fails — then implement T017.

- [ ] T079 [P] Write `BodyMetricTests/Unit/Services/AuthServiceTests.swift` — XCTest unit tests for `AuthService` using `MockAPIClient` and `MockKeychainService`: `test_signIn_success_setsIsAuthenticatedTrue()`, `test_signIn_success_writesTokensToKeychain()`, `test_signIn_apiFailure_throwsAndLogsError()`, `test_refreshToken_success_updatesAccessTokenInKeychain()`, `test_refreshToken_401_callsSignOut()`, `test_signOut_clearsKeychain()`, `test_signOut_setsIsAuthenticatedFalse()`, `test_sessionExpiredNotification_setsIsAuthenticatedFalse()`. **Must FAIL before T017 is implemented.**
- [ ] T016 [P] Create `BodyMetric/Models/User.swift` — `struct User: Codable, Identifiable` with fields from data-model.md: `id`, `email`, `displayName`, `avatarURL`, `weightUnit` (`enum WeightUnit: String, Codable` with `kg`, `lbs`), `activeProgramId`, `totalPoints`, `createdAt`
- [x] T017 Create `BodyMetric/Services/Auth/AuthService.swift` — `@Observable final class AuthService` with `var isAuthenticated: Bool`; `func signInWithGoogle(presenting:) async throws` (calls `GIDSignIn`, exchanges `idToken` via `POST /auth/google`, writes tokens to `KeychainService`); `func refreshToken() async throws` (calls `POST /auth/refresh`, updates access token in Keychain); `func signOut() async throws` (calls `DELETE /auth/session`, calls `KeychainService.clearAll()`); on `Notification.userSessionExpired` set `isAuthenticated = false`; log all errors (Principle III); trace `sign_in_success`, `sign_out`, `token_refreshed` events (Principle IV)

### Splash & Auth Views

- [x] T018 Create `BodyMetric/Features/Splash/SplashView.swift` — SwiftUI `View` with `.background(Color.white)` (explicit white — this is the one screen that uses white before `GrayscalePalette` is set up), centered `Image("AppLogo")` using `.resizable().scaledToFit()` with a fixed frame (e.g., 120×120), no text, no animation required. Used as the initial view during auth state resolution.
- [x] T019 Create `BodyMetric/Features/Auth/ViewModels/LoginViewModel.swift` — `@Observable final class LoginViewModel` with `var isLoading: Bool`, `var errorMessage: String?`; `func signIn(presenting:) async` calling `AuthService.signInWithGoogle`; all errors caught, logged, and surfaced as `errorMessage`; trace `login_tapped` event
- [x] T020 Create `BodyMetric/Features/Auth/Views/LoginView.swift` — SwiftUI `View` with `GrayscalePalette.background` background; centered layout: `Image("AppLogo")` (120×120), app name text, custom `GrayscaleGoogleSignInButton` (wraps `GoogleSignInButton` with `GrayscalePalette.surface` background and `GrayscalePalette.primary` foreground); loading indicator when `viewModel.isLoading`; error message text when non-nil

### App Entry Point

- [ ] T021 Create `BodyMetric/App/AppEnvironment.swift` — `@Observable final class AppEnvironment` holding injected service instances: `authService: AuthService`, `apiClient: APIClientProtocol`, `keychainService: KeychainServiceProtocol`, `router: AppRouter`; `static func live() -> AppEnvironment` constructing real implementations; reads `APIBaseURL` from `Bundle.main`
- [x] T022 Create `BodyMetric/App/BodyMetricApp.swift` — `@main struct BodyMetricApp: App`; instantiate `AppEnvironment.live()` as `@State`; `.environment(appEnvironment)`; show `SplashView` until `authService.isAuthenticated` is resolved (brief async check for stored token via `GIDSignIn.restorePreviousSignIn`); transition to `LoginView` (unauthenticated) or `MainTabView` (authenticated) using `.bmFade` animation; `.onOpenURL` handler for `GIDSignIn.sharedInstance.handle(url)`

**Checkpoint**: SplashView → LoginView flow works. Google Sign-In sheet opens, tokens are written to Keychain. App persists auth state across restarts.

---

## Phase 3: User Story 1 — Gym Check-In and Workout Session Tracking (Priority: P1) 🎯 MVP

**Goal**: Users can check in at the gym, log sets with weight and reps for each exercise, and complete the session — persisted to workout history.

**Independent Test**: Launch the app, authenticate, tap Check In on a training day, log 3 sets on 2 exercises with varying weights, tap "Finish Workout" — session appears in history list.

### Models

- [ ] T023 [P] [US1] Create `BodyMetric/Models/WorkoutSession.swift` — `struct WorkoutSession: Codable, Identifiable` with all fields from data-model.md: `id`, `userId`, `trainingDayId`, `status` (`enum SessionStatus: String, Codable` with `inProgress`, `completed`, `abandoned`), `startedAt`, `completedAt`, `exerciseLogs`, `pointsAwarded`
- [ ] T024 [P] [US1] Create `BodyMetric/Models/ExerciseLog.swift` — `struct ExerciseLog: Codable, Identifiable` with `id`, `sessionId`, `plannedExerciseId`, `exerciseId`, `skipped`, `sets: [ExerciseSet]`
- [ ] T025 [P] [US1] Create `BodyMetric/Models/ExerciseSet.swift` — `struct ExerciseSet: Codable, Identifiable` with `id`, `exerciseLogId`, `setNumber`, `reps` (validated: ≥ 1), `weight` (≥ 0), `weightUnit: WeightUnit`, `completedAt`

### Service Layer

> **TDD**: Write T080 first — confirm it fails — then implement T027.

- [ ] T080 [P] [US1] Write `BodyMetricTests/Unit/Services/WorkoutSessionServiceTests.swift` — XCTest unit tests using `MockAPIClient`: `test_checkIn_success_returnsInProgressSession()`, `test_checkIn_409_throwsConflict()`, `test_logExercise_success_returnsExerciseLog()`, `test_logExercise_networkError_throwsAndLogsError()`, `test_completeSession_success_returnsCompletedSessionWithPoints()`, `test_completeSession_returnsNewBadgesInResponse()`, `test_abandonSession_success_callsAbandonedStatus()`. **Must FAIL before T027 is implemented.**
- [ ] T026 [P] [US1] Create `BodyMetric/Services/Network/Endpoints/SessionEndpoints.swift` — typed `URLRequest` builders for: `POST /sessions` (body: trainingDayId), `PATCH /sessions/{id}` (body: status), `POST /sessions/{id}/exercise-logs` (body: plannedExerciseId, skipped, sets array) per `contracts/api-endpoints.md`
- [ ] T027 [US1] Create `BodyMetric/Services/WorkoutSessionService.swift` — `protocol WorkoutSessionServiceProtocol`; `actor WorkoutSessionService: WorkoutSessionServiceProtocol` with: `func checkIn(trainingDayId:) async throws -> WorkoutSession`; `func logExercise(sessionId:log:) async throws -> ExerciseLog`; `func completeSession(sessionId:) async throws -> (WorkoutSession, Streak, [Badge])`; `func abandonSession(sessionId:) async throws`; all errors logged (Principle III); trace `checkin_started`, `set_logged`, `session_completed`, `session_abandoned` (Principle IV)

### ViewModels

- [ ] T028 [P] [US1] Create `BodyMetric/Features/Workout/ViewModels/CheckInViewModel.swift` — `@Observable final class CheckInViewModel` with today's `TrainingDay` (loaded from `ProgramService` or passed in), `isCheckedIn: Bool`, `func checkIn() async`; on success pushes `.activeSession(sessionId)` via `AppRouter`; errors surfaced as `errorMessage`
- [ ] T029 [P] [US1] Create `BodyMetric/Features/Workout/ViewModels/ActiveSessionViewModel.swift` — `@Observable final class ActiveSessionViewModel` with `session: WorkoutSession`, `exerciseLogs: [ExerciseLog]`, `func skipExercise(plannedExerciseId:) async`, `func finishWorkout() async`; on finish navigates to `.sessionComplete(sessionId)`; surfaces `newBadges: [Badge]` from response
- [ ] T030 [P] [US1] Create `BodyMetric/Features/Workout/ViewModels/ExerciseLogViewModel.swift` — `@Observable final class ExerciseLogViewModel` with `sets: [ExerciseSet]`, `func addSet(reps:weight:) async`; validate reps ≥ 1; warn (not block) if weight > 500 kg / 1100 lbs with `showsWeightWarning: Bool`; log all errors

### Views

- [ ] T031 [P] [US1] Create `BodyMetric/Features/Workout/Views/CheckInView.swift` — SwiftUI `View` showing today's training day card (label, muscle groups, exercise count); single primary action "Check In" button (`GrayscalePalette.primary` fill); uses `matchedGeometryEffect(id: "workoutCard", in: namespace)` for hero transition to `ActiveSessionView`; all colors from `GrayscalePalette`
- [ ] T032 [P] [US1] Create `BodyMetric/Features/Workout/Views/ActiveSessionView.swift` — SwiftUI `View` matched to hero namespace from `CheckInView`; `List` of planned exercises with inline set counter and "Log Set" button per row; "Skip" button (visually subordinate, `GrayscalePalette.secondary`); "Finish Workout" primary button at bottom; enter via `.bmScaleUp` transition
- [ ] T033 [P] [US1] Create `BodyMetric/Features/Workout/Views/ExerciseLogView.swift` — SwiftUI `View` presented as `.sheet` with `.presentationDetents([.medium, .large])`; `Stepper` for reps, numeric field for weight, weight unit label; "Add Set" button; list of already-logged sets with set number, reps, weight; weight-too-high warning `Alert` when `viewModel.showsWeightWarning`
- [ ] T034 [US1] Create `BodyMetric/Features/Workout/Views/SessionCompleteView.swift` — SwiftUI `View` presented as `.sheet(.large)`; checkmark SF Symbol (grayscale, bold); "Workout Complete" headline; points awarded (`+N pts`); new badges earned (icon + name, if any); "Done" button dismisses sheet and pops navigation to home root

### Integration

- [ ] T035 [US1] Create `BodyMetric/Features/Main/MainTabView.swift` — `TabView` with 4 tabs: Home (CheckInView), Program (placeholder `Text`), History (placeholder `Text`), Profile (placeholder `Text`); each tab wraps a `NavigationStack` bound to `AppRouter` path; register `navigationDestination` for all `WorkoutDestination` cases; apply `.bmFade` on tab switch
- [ ] T036 [US1] Wire `WorkoutSessionService` into `AppEnvironment.live()` and inject into `CheckInViewModel`, `ActiveSessionViewModel`, `ExerciseLogViewModel` via `@Environment(AppEnvironment.self)`

**Checkpoint**: Full check-in → log sets → finish workout flow is functional end-to-end. US1 is independently testable.

---

## Phase 4: User Story 2 — Workout Program Management (Priority: P2)

**Goal**: Users can view their assigned weekly program, browse training days, and inspect planned exercises with target sets and rep ranges.

**Independent Test**: Navigate to the Program tab — weekly schedule is visible. Tap a training day — planned exercises with targets are listed. With no program assigned, a prompt to set up a program appears.

### Models

- [ ] T037 [P] [US2] Create `BodyMetric/Models/Exercise.swift` — `struct Exercise: Codable, Identifiable` with `id`, `name`, `primaryMuscle`, `secondaryMuscles`, `instructions`, `videoURL`
- [ ] T038 [P] [US2] Create `BodyMetric/Models/PlannedExercise.swift` — `struct PlannedExercise: Codable, Identifiable` with `id`, `trainingDayId`, `exerciseId`, `exercise: Exercise`, `order`, `targetSets`, `targetRepsMin`, `targetRepsMax`, `restSeconds`, `notes`
- [ ] T039 [P] [US2] Create `BodyMetric/Models/TrainingDay.swift` — `struct TrainingDay: Codable, Identifiable` with `id`, `programId`, `dayOfWeek` (`enum DayOfWeek: String, Codable, CaseIterable`), `label`, `muscleGroups`, `plannedExercises`, `isRestDay`
- [ ] T040 [P] [US2] Create `BodyMetric/Models/WorkoutProgram.swift` — `struct WorkoutProgram: Codable, Identifiable` with `id`, `name`, `description`, `weekCount`, `trainingDays`, `createdAt`

### Service Layer

> **TDD**: Write T081 first — confirm it fails — then implement T042.

- [ ] T081 [P] [US2] Write `BodyMetricTests/Unit/Services/ProgramServiceTests.swift` — XCTest unit tests using `MockAPIClient`: `test_fetchProgram_success_returnsWorkoutProgram()`, `test_fetchProgram_404_throwsNotFound()`, `test_fetchTodaysTrainingDay_matchingDay_returnsTrainingDay()`, `test_fetchTodaysTrainingDay_noMatchingDay_returnsNil()`, `test_fetchTodaysTrainingDay_isRestDay_returnsRestDay()`, `test_fetchProgram_cachesResult_usesCache_onSecondCall()`. **Must FAIL before T042 is implemented.**
- [ ] T041 [P] [US2] Create `BodyMetric/Services/Network/Endpoints/ProgramEndpoints.swift` — typed `URLRequest` builders for: `GET /programs/{id}`, `GET /programs/{id}/training-days`, `GET /training-days/{id}` per `contracts/api-endpoints.md`
- [ ] T042 [US2] Create `BodyMetric/Services/ProgramService.swift` — `protocol ProgramServiceProtocol`; `actor ProgramService: ProgramServiceProtocol` with: `func fetchProgram(id:) async throws -> WorkoutProgram`; `func fetchTodaysTrainingDay(programId:) async throws -> TrainingDay?`; SwiftData cache read-before-network for program data (stale-while-revalidate); log errors (Principle III); trace `program_viewed`, `training_day_viewed` (Principle IV)

### ViewModels

- [ ] T043 [P] [US2] Create `BodyMetric/Features/Program/ViewModels/ProgramViewModel.swift` — `@Observable final class ProgramViewModel` with `program: WorkoutProgram?`, `isLoading: Bool`, `errorMessage: String?`, `func load() async`; if `user.activeProgramId == nil` set `showsNoProgramPrompt = true`
- [ ] T044 [P] [US2] Create `BodyMetric/Features/Program/ViewModels/TrainingDayViewModel.swift` — `@Observable final class TrainingDayViewModel` with `trainingDay: TrainingDay`, `plannedExercises: [PlannedExercise]`

### Views

- [ ] T045 [P] [US2] Create `BodyMetric/Features/Program/Views/ProgramView.swift` — SwiftUI `View` showing week grid (Mon–Sun) with day labels and muscle group chips; rest days shown as "Rest" with empty-circle SF Symbol; tap a training day → `NavigationLink(value: ProgramDestination.trainingDay(id))` with `.bmSlide` push; "Set Up Program" prompt overlay when `viewModel.showsNoProgramPrompt`
- [ ] T046 [US2] Create `BodyMetric/Features/Program/Views/TrainingDayView.swift` — SwiftUI `View` listing `PlannedExercise` rows: exercise name, `targetSets × targetRepsMin–targetRepsMax`, optional rest interval, notes in secondary text (`GrayscalePalette.secondary`); navigation title = day label

### Integration

- [ ] T047 [US2] Replace Program tab placeholder in `MainTabView.swift` with `ProgramView`; register `navigationDestination` for `ProgramDestination` cases; wire `ProgramService` into `AppEnvironment.live()` and inject into `ProgramViewModel` and `TrainingDayViewModel`
- [ ] T048 [US2] Update `CheckInViewModel` to use `ProgramService.fetchTodaysTrainingDay` to load today's training day instead of a hardcoded stub

**Checkpoint**: Program tab shows weekly schedule. Tapping a day shows its exercises. No-program state prompts setup. US2 independently testable alongside US1.

---

## Phase 5: User Story 3 — Exercise History and Progress Review (Priority: P3)

**Goal**: Users can view the chronological log of sets, reps, and weights for any exercise across all past sessions.

**Independent Test**: Tap any exercise name in a completed session → `ExerciseHistoryView` shows at least 2 past sessions with dates, sets, and weight per set in descending order.

### Service Layer

> **TDD**: Write T082 first — confirm it fails — then implement T050.

- [ ] T082 [P] [US3] Write `BodyMetricTests/Unit/Services/HistoryServiceTests.swift` — XCTest unit tests using `MockAPIClient`: `test_fetchHistory_success_returnsLogsInDescendingOrder()`, `test_fetchHistory_withNextBefore_paginatesCorrectly()`, `test_fetchHistory_emptyResponse_returnsEmptyPage()`, `test_fetchHistory_networkError_throwsAndLogsError()`, `test_fetchHistory_cachesResult_returnsCache_onSubsequentCall()`, `test_fetchHistory_expiredCache_refetchesFromNetwork()`. **Must FAIL before T050 is implemented.**
- [ ] T049 [P] [US3] Create `BodyMetric/Services/Network/Endpoints/HistoryEndpoints.swift` — typed `URLRequest` builder for `GET /exercises/{exerciseId}/history` with optional `limit` and `before` query params per `contracts/api-endpoints.md`
- [ ] T050 [US3] Create `BodyMetric/Services/HistoryService.swift` — `protocol HistoryServiceProtocol`; `actor HistoryService: HistoryServiceProtocol` with `func fetchHistory(exerciseId:limit:before:) async throws -> ExerciseHistoryPage`; define `struct ExerciseHistoryPage: Decodable` with `logs: [SessionExerciseSummary]` and `nextBefore: Date?`; SwiftData cache for last 30 sessions per exercise; log errors (Principle III); trace `exercise_history_viewed` (Principle IV)

### ViewModels

- [ ] T051 [P] [US3] Create `BodyMetric/Features/History/ViewModels/HistoryViewModel.swift` — `@Observable final class HistoryViewModel` with `sessions: [WorkoutSession]`, `isLoading: Bool`, `func load() async` fetching recent sessions; grouped by week for display
- [ ] T052 [P] [US3] Create `BodyMetric/Features/History/ViewModels/ExerciseHistoryViewModel.swift` — `@Observable final class ExerciseHistoryViewModel` with `exerciseName: String`, `logs: [SessionExerciseSummary]`, `hasMore: Bool`, `func load() async`, `func loadMore() async` (pagination via `nextBefore`); log errors (Principle III)

### Views

- [ ] T053 [P] [US3] Create `BodyMetric/Features/History/Views/HistoryView.swift` — SwiftUI `View` listing completed `WorkoutSession` rows: date, training day label, total sets logged, points awarded; grouped by week with section headers; tap session row → detail not required for US3 (tap exercise within ActiveSession/SessionComplete instead)
- [ ] T054 [US3] Create `BodyMetric/Features/History/Views/ExerciseHistoryView.swift` — SwiftUI `View` showing exercise name as navigation title; `List` of session entries each with date, ordered sets (set N: Xkg × Y reps); progressive overload visible by scanning top to bottom; "Load More" button when `viewModel.hasMore`; all colors `GrayscalePalette`

### Integration

- [ ] T055 [US3] Replace History tab placeholder in `MainTabView.swift` with `HistoryView`; register `navigationDestination` for `HistoryDestination.exerciseHistory(exerciseId)`; wire `HistoryService` into `AppEnvironment.live()`
- [ ] T056 [US3] Add `NavigationLink(value: HistoryDestination.exerciseHistory(exerciseId))` to each exercise row in `SessionCompleteView` and `ActiveSessionView` so users can tap into history from a completed session

**Checkpoint**: History tab shows session list. Tapping an exercise navigates to its chronological set/weight history. US3 independently testable.

---

## Phase 6: User Story 4 — Gamification and Consistency Rewards (Priority: P4)

**Goal**: Users earn points, build streaks, and unlock badges by completing workouts; all visible in the Profile tab.

**Independent Test**: Complete 3 workouts on separate days → Profile tab shows streak count 3, correct total points, and at least "First Workout" badge earned with its date.

### Models

- [ ] T057 [P] [US4] Create `BodyMetric/Models/Badge.swift` — `struct Badge: Codable, Identifiable` with `id`, `name`, `description`, `iconName`; `enum BadgeCondition: Codable` discriminated union: `.sessionCount(count: Int)`, `.streakDays(days: Int)`, `.totalPoints(points: Int)`, `.exercisePR(exerciseId: String)` with custom `Codable` keyed on `"type"`
- [ ] T058 [P] [US4] Create `BodyMetric/Models/UserBadge.swift` — `struct UserBadge: Codable, Identifiable` with `id`, `userId`, `badgeId`, `badge: Badge`, `earnedAt: Date`
- [ ] T059 [P] [US4] Create `BodyMetric/Models/Streak.swift` — `struct Streak: Codable, Identifiable` with `id`, `userId`, `currentCount`, `longestCount`, `lastCompletedDate: Date?`

### Service Layer

> **TDD**: Write T083 first — confirm it fails — then implement T061.

- [ ] T083 [P] [US4] Write `BodyMetricTests/Unit/Services/GamificationServiceTests.swift` — XCTest unit tests using `MockAPIClient`: `test_fetchStreak_success_returnsStreakWithCurrentCount()`, `test_fetchStreak_networkError_throwsAndLogsError()`, `test_fetchBadgeCatalogue_success_returnsEarnedAndLockedBadges()`, `test_fetchBadgeCatalogue_earnedBadge_hasEarnedAtDate()`, `test_fetchBadgeCatalogue_lockedBadge_hasNilEarnedAt()`, `test_fetchBadgeCatalogue_networkError_throwsAndLogsError()`. **Must FAIL before T061 is implemented.**
- [ ] T060 [P] [US4] Create `BodyMetric/Services/Network/Endpoints/GamificationEndpoints.swift` — typed `URLRequest` builders for `GET /users/me/streak` and `GET /badges` per `contracts/api-endpoints.md`
- [ ] T061 [US4] Create `BodyMetric/Services/GamificationService.swift` — `protocol GamificationServiceProtocol`; `actor GamificationService: GamificationServiceProtocol` with: `func fetchStreak() async throws -> Streak`; `func fetchBadgeCatalogue() async throws -> [BadgeEntry]` (define `struct BadgeEntry: Decodable` with `badge`, `earned: Bool`, `earnedAt: Date?`); log errors (Principle III); trace `profile_viewed`, `badges_viewed` (Principle IV)

### ViewModels

- [ ] T062 [P] [US4] Create `BodyMetric/Features/Gamification/ViewModels/ProfileViewModel.swift` — `@Observable final class ProfileViewModel` with `user: User?`, `streak: Streak?`, `recentBadges: [UserBadge]`, `func load() async`; surfaces `newBadges: [Badge]` passed from `WorkoutSessionService` completion response
- [ ] T063 [P] [US4] Create `BodyMetric/Features/Gamification/ViewModels/BadgesViewModel.swift` — `@Observable final class BadgesViewModel` with `entries: [BadgeEntry]`, `earnedCount: Int`, `func load() async`; separates earned (with date) from locked (with criteria description)

### Views

- [ ] T064 [P] [US4] Create `BodyMetric/Features/Gamification/Views/ProfileView.swift` — SwiftUI `View` with: display name (from `User.displayName`); streak widget — current streak count as large numeral, filled-circle SF Symbol chain, longest streak secondary; total points numeral; row of recently earned badge icons (up to 5, tappable → `BadgesView`); "View All Badges" `NavigationLink`; all semantic meaning via text/icons not color (Principle VI)
- [ ] T065 [US4] Create `BodyMetric/Features/Gamification/Views/BadgesView.swift` — SwiftUI `View` with two sections: "Earned" (badge icon filled + name + earned date) and "Locked" (badge icon outlined + name + unlock criteria as plain text); badge icon rendered from `Badge.iconName` as SF Symbol in `.monochrome` rendering; no color used for earned/locked distinction — use fill vs outline SF Symbol variant

### Integration

- [ ] T066 [US4] Replace Profile tab placeholder in `MainTabView.swift` with `ProfileView`; register `navigationDestination` for `ProfileDestination.badges`; wire `GamificationService` into `AppEnvironment.live()` and inject into `ProfileViewModel` and `BadgesViewModel`
- [ ] T067 [US4] Update `SessionCompleteView` and `ActiveSessionViewModel` to display `newBadges` returned from `WorkoutSessionService.completeSession` — show each badge as icon + name in the completion sheet; trace `badge_earned` for each new badge (Principle IV)
- [ ] T068 [US4] Add `GET /users/me` endpoint builder to `AuthEndpoints.swift`; load `User` profile in `AppEnvironment` post-login and expose as `appEnvironment.currentUser: User?`; `ProfileViewModel` reads from `appEnvironment.currentUser` (no extra network call on every profile view)

**Checkpoint**: Profile tab shows streak, points, badges. Completing a workout updates all three. US4 independently testable alongside US1–US3.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Hardening, caching, token lifecycle, and constitution compliance sweep

- [ ] T069 [P] Add SwiftData cache schema in `BodyMetric/Cache/ProgramCache.swift` — `@Model class CachedProgram` and `@Model class CachedTrainingDay` and `@Model class CachedPlannedExercise`; 7-day TTL eviction; write on first fetch, read before network in `ProgramService`
- [ ] T070 [P] Add SwiftData in-progress session cache in `BodyMetric/Cache/SessionCache.swift` — `@Model class CachedSession` with all `ExerciseLog` and `ExerciseSet` data; write on every `logExercise` call in `WorkoutSessionService`; on app cold start check for in-progress cached session and resume `ActiveSessionView` (crash recovery for US1)
- [ ] T071 [P] Add SwiftData exercise history cache in `BodyMetric/Cache/HistoryCache.swift` — `@Model class CachedExerciseLog` per exercise per session; 7-day TTL; read-before-network in `HistoryService.fetchHistory`
- [ ] T072 Wire 401 token refresh retry in `APIClient.swift` — on `APIError.unauthorized`: call `authService.refreshToken()` → update `Authorization` header → retry original request once; on second failure call `authService.signOut()` and post `Notification.userSessionExpired` (already stubbed in T015); add integration test in `BodyMetricTests/Integration/TokenRefreshTests.swift`
- [ ] T073 [P] Grayscale audit — search all `*.swift` files under `BodyMetric/Features/` and `BodyMetric/Core/Design/` for raw `Color(` or `.red`, `.green`, `.blue`, `.yellow`, `.orange`, `.purple`, `.cyan`, `.indigo`, `.mint`, `.teal` usages; replace every instance with the appropriate `GrayscalePalette` constant; verify `.multicolor` SF Symbol rendering is absent (Principle VI)
- [ ] T074 [P] Tracing audit — verify every ViewModel method that triggers a state-modifying user action emits a `Tracer.track(event:)` call; add missing trace events for any screen view or data mutation not covered in T017–T067 (Principle IV)
- [ ] T075 [P] Logging audit — verify every `catch` block across `Services/` and `ViewModels/` calls `Logger.error` before handling or rethrowing; add missing calls; confirm no PII (email, displayName) appears in any log output (Principle III)
- [ ] T076 Run `quickstart.md` validation — follow steps 1–9 verbatim on a clean simulator; confirm: SplashView appears on launch, Google Sign-In sheet works, all 4 tabs navigate correctly, animated transitions match spring baseline, grayscale-only visuals pass visual inspection

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Requires Phase 1 complete — **BLOCKS all user stories**
- **US1 (Phase 3)**: Requires Phase 2 complete
- **US2 (Phase 4)**: Requires Phase 2 complete; US1 not required but `CheckInView` integrates with `ProgramService` (T048)
- **US3 (Phase 5)**: Requires Phase 2 complete; US1 provides the session data US3 displays
- **US4 (Phase 6)**: Requires Phase 2 complete; integrates with US1 completion response (T067)
- **Polish (Phase 7)**: Requires all desired user stories complete

### Within Each User Story

- Models → Endpoints → Service → ViewModels → Views → Integration
- Models marked `[P]` within a phase can be created simultaneously
- Endpoints marked `[P]` within a phase can be created simultaneously
- ViewModels and Views marked `[P]` within a phase can be created simultaneously
- Integration tasks are always sequential (last in each phase)

---

## Parallel Execution Examples

### Phase 2 (Foundational) — launch together

```
T007 Logger.swift
T008 Tracer.swift
T009 GrayscalePalette.swift
T010 Transition.swift
```
Then: T011 AppRouter → T012 KeychainService → T013+T014 APIError+AuthEndpoints (parallel) → T015 APIClient → T016 User model → T017 AuthService → T018+T019+T020 (Splash+LoginViewModel+LoginView, parallel) → T021 AppEnvironment → T022 BodyMetricApp

### Phase 3 (US1) — launch models together

```
T023 WorkoutSession.swift
T024 ExerciseLog.swift
T025 ExerciseSet.swift
T026 SessionEndpoints.swift
```
Then: T027 WorkoutSessionService → ViewModels (T028+T029+T030, parallel) → Views (T031+T032+T033, parallel) → T034 → T035+T036

### Phase 4 (US2) — launch models together

```
T037 Exercise.swift
T038 PlannedExercise.swift
T039 TrainingDay.swift
T040 WorkoutProgram.swift
T041 ProgramEndpoints.swift
```
Then: T042 ProgramService → T043+T044 (parallel) → T045+T046 (parallel) → T047+T048

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. Complete Phase 1 (Setup)
2. Complete Phase 2 (Foundational) — SplashView, Auth, API, Keychain
3. Complete Phase 3 (US1) — Check-In, Session Tracking
4. **STOP and VALIDATE**: Check in, log sets, complete workout end-to-end
5. Demo-ready MVP

### Incremental Delivery

1. Setup + Foundational → Auth + Splash works
2. US1 → Gym check-in and workout logging works (MVP)
3. US2 → Program browsing works alongside US1
4. US3 → History and progress review works
5. US4 → Gamification layer completes the experience
6. Polish → Production-hardened with caching, token refresh, compliance sweep

### Parallel Team Strategy

After Phase 2 is complete:
- Developer A: US1 (check-in, session tracking)
- Developer B: US2 (program management)
- Developer C: US3 + US4 (history + gamification) — US4 needs US1 response model, coordinate on T067

---

## Notes

- `[P]` = different files, no incomplete task dependencies — safe to run in parallel
- `[Story]` label maps each task to a user story for traceability
- Constitution gates apply to every task: Principle II (TDD — test must fail before implementation), III (logging), IV (tracing), VI (grayscale) — check per PR
- **TDD order**: For each service, write the `Tests.swift` file (T077–T083) FIRST, run it to confirm all tests fail, THEN implement the service to make them pass
- Commit message format: `T012: implement KeychainService` (imperative, task ID prefix)
- Stop at each `**Checkpoint**` to validate the story independently before proceeding
- `GrayscalePalette` usage is mandatory — never use raw `Color` literals in Views
