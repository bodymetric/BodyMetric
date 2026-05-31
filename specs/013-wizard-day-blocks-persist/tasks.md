# Tasks: Wizard Step 2 — Persist Day Plan with Exercise Blocks

**Input**: Design documents from `/specs/013-wizard-day-blocks-persist/`  
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Scope**: 6 modified files, 0 new files. Replaces the two-step save (feature 011) with a single unified POST per day.

**Tests**: Included — Constitution Principle II (TDD). Update tests first; verify they FAIL before implementing.

---

## Phase 1: Setup

No new directories or files required.

---

## Phase 2: Foundational — Update tests first (blocking all story phases)

**Purpose**: Update existing tests to reflect the new unified request format and removed `saveExerciseBlock`. These tests must FAIL against the current implementation before T003–T006.

- [x] T001 [P] Update `BodyMetricTests/Services/WorkoutDayPlanServiceTests.swift`: replace the `test_saveDayPlan_201_returnsDecodedResponse` test — change mock JSON response to any valid JSON (response body no longer decoded); update `test_saveDayPlan_201_sendsCorrectURL` to remain unchanged; add `test_saveDayPlan_200_doesNotThrow` — status 200 should succeed (currently fails with serverError); update `test_saveDayPlan_201_sendsCorrectPath` — remains valid; remove `test_saveExerciseBlock_*` tests (method no longer exists); update `MockWorkoutDayPlanService` in test helpers — remove `saveExerciseBlockShouldThrow`, `saveExerciseBlockFailAtCallIndex` fields and `saveExerciseBlock` method; add `lastSavedRequest: WorkoutDayPlanRequest?` to capture the full unified request
- [x] T002 [P] Update `BodyMetricTests/Features/NewPlanViewModelTests.swift`: in `MockWorkoutDayPlanService` (defined at the bottom of the file) — remove `saveExerciseBlockShouldThrow`, `saveExerciseBlockFailAtCallIndex`, `exerciseBlockCallCount` fields and `saveExerciseBlock(workoutDayPlanId:request:)` method; add `lastSavedRequest: WorkoutDayPlanRequest?`; change `saveDayPlan` return type to `Void` (remove `return WorkoutDayPlanResponse(workoutDayPlanId: dayPlanResponseId)`); update `test_saveDayConfig_secondBlockFails_onSuccessNotCalled` — this test is now invalid (no more per-block calls); replace it with `test_saveDayConfig_success_requestContainsExerciseBlocks` — set up one valid day plan with one block, call `saveDayConfig`, assert `mockDayConfigService.lastSavedRequest?.exerciseBlocks.count == 1`

**Checkpoint**: T001 and T002 tests FAIL against current code. Ready for implementation.

---

## Phase 3: User Story 1 — Complete configuration for one day and move to the next (Priority: P1) 🎯 MVP

**Goal**: Tapping Continue sends ONE POST with the full day payload (name + exercise blocks + target sets). On 200 or 201, the wizard advances.

**Independent Test**: Run T001 + T002 tests after implementation — all must PASS.

### Implementation for US1

- [x] T003 [US1] Replace content of `Models/WorkoutDayPlanModels.swift`: (1) Keep `WorkoutDayPlanResponse: Decodable, Identifiable { let workoutDayPlanId: Int; var id: Int { workoutDayPlanId } }`; (2) Add `struct TargetSetRequest: Codable { let orderIndex: Int; let targetReps: Int; let targetWeight: Double }`; (3) Add `struct ExerciseBlockRequest: Codable { let exerciseId: Int; let orderIndex: Int; let restSeconds: Int; let isOptional: Bool; let targetSets: [TargetSetRequest]; init(block: ExerciseBlock, orderIndex: Int) { self.exerciseId = Int(block.exerciseId) ?? 0; self.orderIndex = orderIndex; self.restSeconds = block.restSeconds; self.isOptional = false; self.targetSets = [TargetSetRequest(orderIndex: 1, targetReps: block.targetReps, targetWeight: block.targetWeight)] } }`; (4) Replace `WorkoutDayPlanRequest` to include `exerciseBlocks: [ExerciseBlockRequest]` — `struct WorkoutDayPlanRequest: Codable { let name: String; let orderIndex: Int; let isActive: Bool; let exerciseBlocks: [ExerciseBlockRequest] }`; (5) Remove `ExerciseBlockPlanRequest` entirely; (6) Keep `extension DayOfWeek { var orderIndex: Int { rawValue - 1 } }`

- [x] T004 [US1] Update `Services/WorkoutPlan/WorkoutDayPlanServiceProtocol.swift`: change `func saveDayPlan(workoutPlanId: Int, request: WorkoutDayPlanRequest) async throws -> WorkoutDayPlanResponse` to `func saveDayPlan(workoutPlanId: Int, request: WorkoutDayPlanRequest) async throws` (Void return); remove `func saveExerciseBlock(workoutDayPlanId: Int, request: ExerciseBlockPlanRequest) async throws` entirely; update docstring to note response body is not consumed; depends on T003

- [x] T005 [US1] Update `Services/WorkoutPlan/WorkoutDayPlanService.swift`: (1) Update `saveDayPlan` return type to `Void` — remove `let data: Data` capture and the decode block at the end; (2) Change `guard http.statusCode == 201` to `guard [200, 201].contains(http.statusCode)` to accept both success codes; (3) Remove the entire `saveExerciseBlock(workoutDayPlanId:request:) async throws` method; run T001 — all tests must pass; depends on T003, T004

- [x] T006 [US1] Update `Features/NewPlan/ViewModels/NewPlanViewModel.swift` — replace `saveDayConfig(for:using:onSuccess:)` with a simplified single-POST version: `do { let request = WorkoutDayPlanRequest(name: plan.sessionName, orderIndex: day.orderIndex, isActive: true, exerciseBlocks: plan.blocks.enumerated().map { idx, block in ExerciseBlockRequest(block: block, orderIndex: idx + 1) }); try await service.saveDayPlan(workoutPlanId: planId, request: request); Logger.info("wizard_day_plan_saved day:\(day.shortLabel) blockCount:\(plan.blocks.count)"); onSuccess() } catch { Logger.error("wizard_day_config_save_failed", error: error); dayConfigSaveError = "Could not save your workout day. Please try again." }`; remove the two Logger.info lines for separate day/block saves; run T002 — all tests must pass; depends on T003, T004

**Checkpoint**: US1 fully functional. Tap Continue → single POST with embedded blocks → 200/201 → wizard advances.

---

## Phase 4: User Story 2 — Exercise blocks and target sets saved as part of the day (Priority: P2)

**Goal**: Verify the request body correctly includes all exercise blocks with their target sets.

**Independent Test**: Configure a day with two exercise blocks, save, inspect the captured request — both blocks appear in `exerciseBlocks` with correct `orderIndex` and `targetSets`.

- [x] T007 [P] [US2] Add to `BodyMetricTests/Features/NewPlanViewModelTests.swift`: add `test_saveDayConfig_multipleBlocks_assignCorrectOrderIndex` — set up a day plan with two valid blocks, call `saveDayConfig`, assert `lastSavedRequest.exerciseBlocks[0].orderIndex == 1` and `lastSavedRequest.exerciseBlocks[1].orderIndex == 2`; add `test_saveDayConfig_exerciseBlock_hasCorrectTargetSet` — verify `exerciseBlocks[0].targetSets.count == 1` and `targetSets[0].orderIndex == 1`

**Checkpoint**: US1 AND US2 verified.

---

## Phase 5: User Story 3 — Recover gracefully from a save failure (Priority: P3)

**Goal**: When the single POST fails, `dayConfigSaveError` is set and the user stays on the screen.

- [x] T008 [P] [US3] Verify in `BodyMetricTests/Features/NewPlanViewModelTests.swift` that existing tests `test_saveDayConfig_dayPlanFailure_dayConfigSaveErrorNotNil` and `test_saveDayConfig_dayPlanFailure_onSuccessNotCalled` still pass (they should — the failure path is unchanged); if they fail, fix the `MockWorkoutDayPlanService` to match the new `Void` return type

**Checkpoint**: All three user stories functional.

---

## Final Phase: Polish

- [x] T009 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED

---

## Dependencies

```
T001 [P] + T002 [P]   (update tests — fail first)
    ↓
T003 → T004 → T005 → T006   (sequential: models → protocol → service → ViewModel)
    ↓
T007 [P] + T008 [P]   (verify US2 + US3, parallel)
    ↓
T009 (build)
```

---

## Notes

- `ExerciseBlockPlanRequest` is deleted — it was replaced by `ExerciseBlockRequest` which is nested inside `WorkoutDayPlanRequest`
- `MockWorkoutDayPlanService` in test files needs `saveExerciseBlock` removed and `saveDayPlan` return type changed to `Void`
- T003 also removes `ExerciseBlockPlanRequest` — any compile errors from this deletion are intentional and fixed by T006
- Commit convention: `✨ T003: unify WorkoutDayPlanRequest with embedded exerciseBlocks`
