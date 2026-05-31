# Data Model: Automated Training Week Tracking

**Date**: 2026-05-02

---

## WorkoutPlanDayResponse — updated

```swift
// BEFORE
struct WorkoutPlanDayResponse: Codable, Identifiable {
    let planId: Int
    let plannedWeekNumber: Int    // ← REMOVE
    let plannedDayOfWeek: String
    let executionCount: Int
    let dayNames: [String]
    let totalExercises: Int
    let totalSets: Int
    let estimatedDurationMinutes: Int
    var id: Int { planId }
}

// AFTER
struct WorkoutPlanDayResponse: Codable, Identifiable {
    let planId: Int
    let plannedDayOfWeek: String
    let executionCount: Int
    let dayNames: [String]
    let totalExercises: Int
    let totalSets: Int
    let estimatedDurationMinutes: Int
    let actualWeekNumber: Int?    // ← ADD (optional; server adds when backend ready)
    var id: Int { planId }
}
```

---

## WorkoutPlanDayRequest — updated

```swift
// BEFORE
struct WorkoutPlanDayRequest: Codable, Equatable {
    let plannedWeekNumber: String  // ← REMOVE
    let plannedDayOfWeek: String
}

// AFTER
struct WorkoutPlanDayRequest: Codable, Equatable {
    let plannedDayOfWeek: String
}
```

---

## DayOfWeek.toRequest — updated

```swift
// BEFORE
var toRequest: WorkoutPlanDayRequest {
    WorkoutPlanDayRequest(
        plannedWeekNumber: String(rawValue),
        plannedDayOfWeek: fullLabel.lowercased()
    )
}

// AFTER
var toRequest: WorkoutPlanDayRequest {
    WorkoutPlanDayRequest(
        plannedDayOfWeek: fullLabel.lowercased()
    )
}
```

---

## No other model changes

- `WorkoutPlanDayResponse.planId` — unchanged; still used for `workoutPlanIds` mapping
- `DayOfWeek.init?(fromApiString:)` — unchanged; uses `plannedDayOfWeek`
- All service protocols and implementations — unchanged (field removal is backward-compatible)
