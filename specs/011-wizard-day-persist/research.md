# Research: WorkoutPlanDayResponse Model Fix

**Date**: 2026-04-30

---

## 1. Root cause

`WorkoutPlanDayResponse` was defined against an assumed schema:
```swift
struct WorkoutPlanDayResponse: Codable, Identifiable {
    let planId: Int          // ← actual key is "id"
    let executionCount: Int  // ← not in real response
    let dayNames: [String]   // ← not in real response
    ...
}
```

The real `GET /api/workout-plans` response:
```json
{
    "id": 47,
    "plannedWeekNumber": 1,
    "plannedDayOfWeek": "MONDAY",
    "createdAt": "2026-04-30T00:42:35.745334770",
    "days": [],
    "_links": { ... }
}
```

Result: `JSONDecoder` fails silently (Codable ignores unknown keys but throws on missing required keys). `planId` is a required `let` property; if the JSON has `"id"` but not `"planId"`, decoding fails → `WorkoutPlanError.decodingError` → the app cannot pre-fill day selections.

---

## 2. Field-by-field analysis

| JSON key | Old struct | New struct | Used in logic? |
|----------|-----------|------------|----------------|
| `"id"` | missing (struct had `"planId"`) | `id: Int` | Yes — `workoutPlanIds[day] = response.id` |
| `"plannedWeekNumber"` | `plannedWeekNumber: Int` | unchanged | Yes — `DayOfWeek(rawValue:)` mapping |
| `"plannedDayOfWeek"` | `plannedDayOfWeek: String` | unchanged | No (only `plannedWeekNumber` used) |
| `"createdAt"` | absent | `createdAt: String?` (optional) | No |
| `"days"` | absent | ignored | No |
| `"_links"` | absent | ignored | No |
| `"executionCount"` | `executionCount: Int` | removed | No |
| `"dayNames"` | `dayNames: [String]` | removed | No |
| `"totalExercises"` | `totalExercises: Int` | removed | No |
| `"totalSets"` | `totalSets: Int` | removed | No |
| `"estimatedDurationMinutes"` | `estimatedDurationMinutes: Int` | removed | No |

`days` and `_links` are present in the response but not needed. Swift `Codable` ignores undeclared JSON keys by default, so they don't need to be modelled.

---

## 3. Downstream impact of `planId` → `id`

One call site in production code:
```swift
// NewPlanViewModel.swift:134
workoutPlanIds[day] = response.planId  →  workoutPlanIds[day] = response.id
```

`workoutPlanIds[day]` feeds the step-2 `WorkoutDayPlanService.saveDayPlan(workoutPlanId:)` call. No further changes needed downstream.

---

## 4. `plannedDayOfWeek` uppercase change

Values changed from `"monday"` to `"MONDAY"`. This field is NOT used anywhere in logic — we only use `plannedWeekNumber: Int` for day identification. No code change needed for this.

---

## 5. Test mock updates needed

| File | What to update |
|------|---------------|
| `WorkoutPlanServiceTests.swift` | Replace `"planId"` with `"id"` in all mock JSON strings; replace `result[0].planId` with `result[0].id`; remove dead fields from mock JSON |
| `NewPlanViewModelTests.swift` | Replace `WorkoutPlanDayResponse(planId: X, ...)` with `WorkoutPlanDayResponse(id: X, ...)`; remove dead constructor params |
