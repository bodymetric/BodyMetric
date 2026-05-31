# Tasks: WorkoutPlanDayResponse Model Fix

**Input**: Design documents from `/specs/011-wizard-day-persist/`  
**Prerequisites**: plan.md ✅ research.md ✅ data-model.md ✅ quickstart.md ✅

**Scope**: 4 files changed; 0 new files; build must pass after all tasks complete.

**Organization**: T001 (struct fix) blocks T002–T004. T002, T003, T004 are parallel.

---

## Phase 1: Setup

No new directories, files, or dependencies required.

---

## Phase 2: Foundational (Blocking)

**Purpose**: Rewrite the `WorkoutPlanDayResponse` struct so it matches the live API. All downstream consumer fixes (T002–T004) depend on this compiling first.

- [x] T001 Rewrite `WorkoutPlanDayResponse` in `Models/WorkoutPlanModels.swift`: replace the entire struct with the following — `struct WorkoutPlanDayResponse: Decodable, Identifiable { let id: Int; let plannedWeekNumber: Int; let plannedDayOfWeek: String; let createdAt: String? }` — remove the fields `planId`, `executionCount`, `dayNames`, `totalExercises`, `totalSets`, `estimatedDurationMinutes`; remove the computed `var id: Int { planId }` (the stored `id: Int` satisfies `Identifiable` directly); change `Codable` to `Decodable` (response-only type); add a doc comment: `// "days" and "_links" from JSON are silently ignored by default Codable behaviour`

**Checkpoint**: Struct compiles. T002, T003, T004 can now begin in parallel.

---

## Phase 3: Consumer fixes (all parallel after T001)

- [x] T002 [P] Update `Features/NewPlan/ViewModels/NewPlanViewModel.swift`: find the line `workoutPlanIds[day] = response.planId` (line ~134) and change `response.planId` to `response.id`; also update the comment on the line above from "Store planId per DayOfWeek" to "Store id per DayOfWeek" or "Store workoutPlanId per DayOfWeek"; depends on T001

- [x] T003 [P] Update `BodyMetricTests/Services/WorkoutPlanServiceTests.swift`: make the following changes (all depend on T001):
  1. Lines ~32–40 (multi-line mock JSON in `test_fetchDays_200_returnsDecodedArray`): replace with minimal valid JSON `{"id":7,"plannedWeekNumber":7,"plannedDayOfWeek":"SUNDAY","createdAt":"2026-04-30T00:00:00"}` inside the array; remove `"executionCount"`, `"dayNames"`, `"totalExercises"`, `"totalSets"`, `"estimatedDurationMinutes"` fields
  2. Line ~49 (`XCTAssertEqual(result[0].planId, 7)`): change `.planId` to `.id`
  3. Line ~123 (inline JSON string `[{"planId":1,...}]`): replace `"planId":1` with `"id":1`; remove dead fields, keep `"plannedWeekNumber":1,"plannedDayOfWeek":"MONDAY"`; add `"createdAt":"2026-04-30T00:00:00"`
  4. Lines ~138–148 (inline JSON + assertion): replace `"planId":7` with `"id":7`; remove dead fields; change `result[0].planId` to `result[0].id`
  5. Line ~153 (inline JSON `[{"planId":3,...}]`): replace `"planId":3` with `"id":3`; remove dead fields

- [x] T004 [P] Update `BodyMetricTests/Features/NewPlanViewModelTests.swift`: replace every `WorkoutPlanDayResponse(planId: X, ...)` call with `WorkoutPlanDayResponse(id: X, plannedWeekNumber: Y, plannedDayOfWeek: "WEEKDAY", createdAt: nil)` — remove the dead parameters `executionCount:`, `dayNames:`, `totalExercises:`, `totalSets:`, `estimatedDurationMinutes:`. The affected lines are approximately: 282, 293, 304, 308, 319, 480, 483. For each call, keep only `id:`, `plannedWeekNumber:`, `plannedDayOfWeek:`, and add `createdAt: nil`; depends on T001

---

## Final Phase: Polish

- [x] T005 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED with no new errors

---

## Dependencies

- T001 must complete before T002, T003, T004
- T002, T003, T004 are fully parallel (different files)
- T005 depends on T001–T004

```
T001 (struct) → T002 (ViewModel) ┐
               → T003 (ServiceTests) ├→ T005 (build)
               → T004 (VMTests)    ┘
```

---

## Notes

- Only `id`, `plannedWeekNumber`, `plannedDayOfWeek`, `createdAt` fields are in the new struct
- `plannedDayOfWeek` is not used in any logic; only `plannedWeekNumber` drives `DayOfWeek` mapping
- `createdAt: String?` is optional so missing/null values decode cleanly
- `"days"` and `"_links"` in the real JSON are silently ignored by Decodable
