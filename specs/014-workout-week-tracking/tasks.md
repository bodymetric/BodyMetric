# Tasks: Automated Training Week Tracking

**Input**: Design documents from `/specs/014-workout-week-tracking/`  
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ quickstart.md ✅

**Scope**: 4 modified files; 0 new files. Remove `plannedWeekNumber` from all payloads; add `actualWeekNumber: Int?` to response model.

**Tests**: Fixture updates only (existing test logic unchanged; structs change shape).

---

## Phase 1: Setup

No new directories or files required.

---

## Phase 2: Foundational — Production model changes (blocking)

**Purpose**: Update the two production model files. T002–T004 all depend on T001 compiling.

- [x] T001 Update `Models/WorkoutPlanModels.swift`: (1) In `WorkoutPlanDayResponse` remove `let plannedWeekNumber: Int` and add `let actualWeekNumber: Int?` (optional so existing decoders work before server ships); (2) In `WorkoutPlanDayRequest` remove `let plannedWeekNumber: String`; (3) Remove the comment above `WorkoutPlanDayRequest` that says "Note: `plannedWeekNumber` is serialised as a **String**..."

- [x] T002 [P] Update `Features/NewPlan/Models/NewPlanModels.swift`: (1) In the `DayOfWeek.toRequest` computed property, change `WorkoutPlanDayRequest(plannedWeekNumber: String(rawValue), plannedDayOfWeek: fullLabel.lowercased())` to `WorkoutPlanDayRequest(plannedDayOfWeek: fullLabel.lowercased())`; (2) Update the doc comment on `toRequest` — remove the line that mentions `plannedWeekNumber`; depends on T001

**Checkpoint**: Production code compiles. Test fixture updates can now proceed in parallel.

---

## Phase 3: User Story 1 — Training week advances automatically (Priority: P1)

**Goal**: Mobile app stops sending `plannedWeekNumber` in step-1 requests and stops decoding it from responses. The server manages week progression without any app participation.

**Independent Test**: Build succeeds; `WorkoutPlanDayRequest` no longer has a `plannedWeekNumber` field; `WorkoutPlanDayResponse` no longer has a `plannedWeekNumber` field.

- [x] T003 [P] [US1] Update `BodyMetricTests/Services/WorkoutPlanServiceTests.swift`: (1) In every mock JSON string that contains `"plannedWeekNumber":N,` — remove that fragment from the JSON (e.g., change `{"planId":7,"plannedWeekNumber":7,"plannedDayOfWeek":"SUNDAY",...}` to `{"planId":7,"plannedDayOfWeek":"SUNDAY",...}`); (2) In every `WorkoutPlanDayRequest(plannedWeekNumber: "N", plannedDayOfWeek: "DAY")` call — remove the `plannedWeekNumber: "N"` argument; (3) Remove assertions `XCTAssertEqual(result[0].plannedWeekNumber, 7)` and `XCTAssertEqual(decoded[0].plannedWeekNumber, "3")`; (4) Remove `decoded[0].plannedWeekNumber` reference; depends on T001

- [x] T004 [P] [US1] Update `BodyMetricTests/Features/NewPlanViewModelTests.swift`: in every `WorkoutPlanDayResponse(planId: X, plannedWeekNumber: Y, plannedDayOfWeek: "DAY", ...)` constructor call, remove `plannedWeekNumber: Y`; the affected lines are approximately 282, 290, 298, 299, 307, 465, 466; depends on T001

**Checkpoint**: US1 complete. All `plannedWeekNumber` references removed from production and test code.

---

## Phase 4: User Story 2 — Current training week visible (Priority: P2)

**Goal**: App model is ready to receive and store `actualWeekNumber` from server responses.

- [x] T005 [P] [US2] Verify `Models/WorkoutPlanModels.swift` has `let actualWeekNumber: Int?` on `WorkoutPlanDayResponse` (done in T001); confirm `actualWeekNumber` decodes without crashing on both `null` and integer JSON values by checking it is `Int?` (optional)

**Checkpoint**: Model ready. App will display `actualWeekNumber` when UI task is added in a future feature.

---

## Phase 5: User Story 3 — New plan resets training week (Priority: P3)

**Goal**: When the server resets `actualWeekNumber` to 1 on a new plan creation, the app correctly reads it.

- [x] T006 [P] [US3] Confirm no client-side logic sets or increments `actualWeekNumber` — search for `actualWeekNumber` in all Swift production files excluding tests and specs, confirm it only appears in the model declaration in `Models/WorkoutPlanModels.swift`

**Checkpoint**: All three user stories functional from the mobile app's perspective.

---

## Final Phase: Polish

- [x] T007 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED with no new errors

---

## Dependencies

```
T001 (models)
    ↓
T002 [P] + T003 [P] + T004 [P]   (parallel — different files)
    ↓
T005 [P] + T006 [P]   (parallel verifications)
    ↓
T007 (build)
```

---

## Notes

- `plannedWeekNumber` in `WorkoutPlanDayResponse` was already not used in any logic since feature 008 (day identification switched to `fromApiString(plannedDayOfWeek:)`). Removal is safe.
- `actualWeekNumber: Int?` is optional so the app decodes cleanly with or without the server field.
- No UI changes in this feature — `actualWeekNumber` display is deferred to a future slice.
- Commit convention: `✨ T001: remove plannedWeekNumber; add optional actualWeekNumber`
