# Data Model: WorkoutPlanDayResponse Fix

**Date**: 2026-04-30

---

## WorkoutPlanDayResponse — corrected

```swift
struct WorkoutPlanDayResponse: Decodable, Identifiable {
    let id: Int                    // "id" — primary key, used for day-plan POSTs
    let plannedWeekNumber: Int     // 1–7 (Mon–Sun) — maps to DayOfWeek.rawValue
    let plannedDayOfWeek: String   // "MONDAY"–"SUNDAY" — not used in logic
    let createdAt: String?         // ISO timestamp — optional, not used in logic
}
```

**No CodingKeys needed** — all property names match JSON keys exactly. `createdAt` is optional so missing fields don't cause decode failure. `days` and `_links` in the JSON are silently ignored by default Codable behaviour.

---

## Downstream wiring (unchanged except `id`)

```
GET /api/workout-plans
    → [WorkoutPlanDayResponse]
    → NewPlanViewModel.loadDays():
        DayOfWeek(rawValue: response.plannedWeekNumber) → selectedDays
        (unchanged)

POST /api/workout-plans
    → [WorkoutPlanDayResponse]
    → NewPlanViewModel.saveDays():
        workoutPlanIds[day] = response.id   ← was response.planId
        (1 line change)

workoutPlanIds[day]
    → WorkoutDayPlanService.saveDayPlan(workoutPlanId: planId, ...)
    (unchanged — value origin now correct)
```
