# Quickstart: Automated Training Week Tracking

**Date**: 2026-05-02

---

## Production code changes (2 files)

### Models/WorkoutPlanModels.swift

1. Remove `let plannedWeekNumber: Int` from `WorkoutPlanDayResponse`
2. Add `let actualWeekNumber: Int?` to `WorkoutPlanDayResponse`
3. Remove `let plannedWeekNumber: String` from `WorkoutPlanDayRequest`
4. Remove the comment "Note: `plannedWeekNumber` is serialised as a **String**..."

### Features/NewPlan/Models/NewPlanModels.swift

5. In `DayOfWeek.toRequest`, remove `plannedWeekNumber: String(rawValue)` from the `WorkoutPlanDayRequest` init
6. Update the doc comment on `toRequest` (remove reference to plannedWeekNumber)

---

## Test fixture changes (2 test files)

### BodyMetricTests/Services/WorkoutPlanServiceTests.swift

For every mock JSON string that contains `"plannedWeekNumber":N,`:
- Remove the `"plannedWeekNumber":N,` fragment
- Add `"actualWeekNumber": null` OR just omit it (it's optional)

For every `WorkoutPlanDayRequest(plannedWeekNumber: "N", plannedDayOfWeek: "DAY")`:
- Change to `WorkoutPlanDayRequest(plannedDayOfWeek: "DAY")`

For every assertion like `XCTAssertEqual(result[0].plannedWeekNumber, 7)`:
- Remove or replace with an assertion that doesn't reference `plannedWeekNumber`

For decoded body assertion `XCTAssertEqual(decoded[0].plannedWeekNumber, "3")`:
- Remove this assertion

### BodyMetricTests/Features/NewPlanViewModelTests.swift

For every `WorkoutPlanDayResponse(planId: X, plannedWeekNumber: Y, plannedDayOfWeek: "DAY", ...)`:
- Remove `plannedWeekNumber: Y` from the constructor call

---

## Verify build passes

```bash
xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'
```
