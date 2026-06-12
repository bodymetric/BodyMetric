# Quickstart: Log Set Performed

**Feature**: `026-log-set-performed`  
**Date**: 2026-06-11

---

## Scenario 1 — Happy path: user logs a set successfully

1. Start a workout session (start-session response includes `exerciseBlockExecutionId: 301` for exercise 0).
2. The active session screen shows the exercise list. Exercise 0 is expanded.
3. User taps the chevron on set 0 of exercise 0 → `LogSetSheet` opens with target weight/reps pre-filled.
4. User adjusts weight to 70 kg, reps to 8.
5. User taps "Log set."
6. Button disables and shows loading indicator.
7. `PerformedSetService` sends `POST /api/exercise-block-executions/301/performed-sets` with `{weight: 70, reps: 8}`.
8. Server responds 200.
9. Sheet dismisses, set row shows checkmark, rest timer starts.

**Test**: `ActiveSessionViewModelTests.test_commitSet_success_marksDoneAndClosesSheet`

---

## Scenario 2 — Network error: user sees error and retries

1. Same setup as scenario 1, step 5 complete.
2. Network is offline. Service throws `WorkoutPlanError.networkError(URLError(.notConnectedToInternet))`.
3. Button re-enables, error label "Failed to log set. Please try again." appears in the sheet.
4. User restores network, taps "Log set" again.
5. Request succeeds. Sheet closes normally.

**Test**: `ActiveSessionViewModelTests.test_commitSet_networkError_setsLogError`

---

## Scenario 3 — Server error (5xx)

1. Same setup as scenario 1, step 5 complete.
2. Server returns 500.
3. Button re-enables, error message shown.
4. `Logger.error` records the failure with status code but no weight/reps (Constitution Principle III).

**Test**: `PerformedSetServiceTests.test_logPerformedSet_500_throwsServerError`

---

## Scenario 4 — Double-tap prevention

1. User taps "Log set."
2. Before the response arrives, user taps "Log set" again.
3. `isSubmittingLog == true` → second tap is blocked (button is disabled).
4. Only one request is sent.

**Test**: `ActiveSessionViewModelTests.test_commitSet_reentryGuard_preventsDuplicateRequest`

---

## Scenario 5 — Zero reps validation

1. User opens `LogSetSheet`, sets reps to 0 using the decrement button.
2. User taps "Log set."
3. No network call is made. `logError = "Reps must be at least 1"` appears in the sheet.
4. User increments reps to 1 and taps "Log set" — request succeeds.

**Test**: `ActiveSessionViewModelTests.test_commitSet_zeroReps_setsLogErrorNoNetworkCall`
