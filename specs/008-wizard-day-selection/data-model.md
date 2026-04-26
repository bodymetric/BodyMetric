# Data Model: New Plan Wizard — Day Selection API

**Feature**: `008-wizard-day-selection`  
**Date**: 2026-04-26

---

## 1. API Response Model (GET)

### `WorkoutPlanDayResponse`

Represents one day entry returned by `GET /api/workout-plans`.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `planId` | `Int` | yes | Unique identifier for this plan entry |
| `plannedWeekNumber` | `Int` | yes | ISO weekday (1 = Mon … 7 = Sun) |
| `plannedDayOfWeek` | `String` | yes | Lowercase day name (`"monday"` … `"sunday"`) |
| `executionCount` | `Int` | yes | How many times this day has been logged |
| `dayNames` | `[String]` | yes | Session names configured for this day |
| `totalExercises` | `Int` | yes | Number of exercises in the day's template |
| `totalSets` | `Int` | yes | Total sets across all exercises |
| `estimatedDurationMinutes` | `Int` | yes | Estimated session length in minutes |

**Notes**:
- The full response is an array: `[WorkoutPlanDayResponse]`.
- A 404 indicates no plans exist yet for the user (empty state, not an error).
- Only `plannedWeekNumber` is used to populate the checkbox selection. All other fields are supplemental context and are not submitted in the POST.

**Conforms to**: `Codable`, `Identifiable` (via `planId`)

---

## 2. API Request Model (POST)

### `WorkoutPlanDayRequest`

Represents one day entry in the POST body.

| Field | Type | Description |
|-------|------|-------------|
| `plannedWeekNumber` | `String` | ISO weekday as a string (e.g., `"1"` for Monday, `"7"` for Sunday) |
| `plannedDayOfWeek` | `String` | Lowercase day name (e.g., `"monday"`, `"sunday"`) |

**Notes**:
- `plannedWeekNumber` is serialised as a **String** (not Int) in the POST body — confirmed by the API contract.
- The POST body is an array: `[WorkoutPlanDayRequest]`.
- The array contains one entry per selected day.

**Conforms to**: `Codable`

---

## 3. Domain Mapping

### `DayOfWeek` → `WorkoutPlanDayRequest` conversion

The existing `DayOfWeek` enum (from `NewPlanModels.swift`) maps directly to the POST request fields:

| `DayOfWeek` case | `rawValue` | `plannedWeekNumber` | `plannedDayOfWeek` |
|-----------------|-----------|--------------------|--------------------|
| `.monday` | 1 | `"1"` | `"monday"` |
| `.tuesday` | 2 | `"2"` | `"tuesday"` |
| `.wednesday` | 3 | `"3"` | `"wednesday"` |
| `.thursday` | 4 | `"4"` | `"thursday"` |
| `.friday` | 5 | `"5"` | `"friday"` |
| `.saturday` | 6 | `"6"` | `"saturday"` |
| `.sunday` | 7 | `"7"` | `"sunday"` |

The `DayOfWeek` already has `rawValue: Int` and `fullLabel: String` (lowercase). A computed property `toRequest: WorkoutPlanDayRequest` on `DayOfWeek` is the clean conversion point.

---

## 4. Load State

### `SelectDaysLoadState`

Enum tracking the lifecycle of the GET request:

```
enum SelectDaysLoadState {
    case idle
    case loading
    case loaded         // ≥1 day was pre-checked from server
    case empty          // 404: first-time user, no prior data
    case failed(String) // any non-404 GET error; message for logging
}
```

**State transitions**:
```
idle → loading (on-appear)
loading → loaded | empty | failed
failed → loading (on retry / re-appear)
```

---

## 5. Save State

A separate `isSaving: Bool` flag in `NewPlanViewModel` gates the Continue button. A `saveErrorMessage: String?` drives the inline error banner; it is cleared when the user changes the day selection.

```
isSaving = false (default)
─── user taps Continue ──→ isSaving = true, saveErrorMessage = nil
    ─── POST 201 ──→ isSaving = false; advance to step 2
    ─── POST other ──→ isSaving = false; saveErrorMessage = "..." 
```

---

## 6. WorkoutPlanError

Domain error enum for the WorkoutPlanService:

```
enum WorkoutPlanError: LocalizedError {
    case notFound               // 404 on GET
    case serverError(Int)       // non-201/non-200 response
    case decodingError          // JSON decode failure
    case networkError(Error)    // transport failure
}
```
