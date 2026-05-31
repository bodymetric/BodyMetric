# Quickstart: WorkoutPlanDayResponse Fix

**Date**: 2026-04-30

---

## Fix 1 — Models/WorkoutPlanModels.swift

Replace the `WorkoutPlanDayResponse` struct:

```swift
// BEFORE
struct WorkoutPlanDayResponse: Codable, Identifiable {
    let planId: Int
    let plannedWeekNumber: Int
    let plannedDayOfWeek: String
    let executionCount: Int
    let dayNames: [String]
    let totalExercises: Int
    let totalSets: Int
    let estimatedDurationMinutes: Int
    var id: Int { planId }
}

// AFTER
struct WorkoutPlanDayResponse: Decodable, Identifiable {
    let id: Int                   // matches JSON "id"
    let plannedWeekNumber: Int    // unchanged
    let plannedDayOfWeek: String  // unchanged; now UPPERCASE from server
    let createdAt: String?        // optional; not used in logic
    // "days" and "_links" from JSON are silently ignored
}
```

---

## Fix 2 — Features/NewPlan/ViewModels/NewPlanViewModel.swift

One line (line ~134):
```swift
// BEFORE
workoutPlanIds[day] = response.planId

// AFTER
workoutPlanIds[day] = response.id
```

---

## Fix 3 — BodyMetricTests/Services/WorkoutPlanServiceTests.swift

Update all mock JSON strings and assertions. Change:
- `"planId": N` → `"id": N`
- `result[0].planId` → `result[0].id`
- Remove dead fields from mock JSON (`executionCount`, `dayNames`, etc.)

New minimal mock JSON:
```json
[{"id":7,"plannedWeekNumber":7,"plannedDayOfWeek":"SUNDAY","createdAt":"2026-04-30T00:00:00"}]
```

---

## Fix 4 — BodyMetricTests/Features/NewPlanViewModelTests.swift

Replace every `WorkoutPlanDayResponse(planId: X, ...)` with `WorkoutPlanDayResponse(id: X, ...)`. Remove dead constructor parameters.

Minimal constructor:
```swift
WorkoutPlanDayResponse(id: 7, plannedWeekNumber: 7,
                       plannedDayOfWeek: "SUNDAY", createdAt: nil)
```

---

## Verify

After changes:
1. Build succeeds
2. `WorkoutPlanServiceTests` all pass (mock JSON decodes correctly)
3. `NewPlanViewModelAPITests` all pass (workoutPlanIds populated from `id`)
