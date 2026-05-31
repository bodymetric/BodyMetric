# Tasks: Wizard Step 2 — Per-Set Row Configuration

**Input**: Design documents from `/specs/020-wizard-step2-per-set-rows/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Scope**: 6 modified files + 1 new type (`SetConfig`). No new files, no new directories, no new SPM packages.
**Tests**: Constitution Principle II — tests updated alongside each implementation task.

---

## Phase 1: Setup

No new directories, packages, or project files required. All changes are in existing files.

---

## Phase 2: Foundational — Add SetConfig and Update ExerciseBlock (blocking all phases)

**Purpose**: Introduce the `SetConfig` type and replace the flat scalar fields on `ExerciseBlock`. All downstream tasks (UI, API request builder, ViewModel, tests) depend on this new shape compiling.

- [X] T001 Add `struct SetConfig: Identifiable, Codable` to `Features/NewPlan/Models/NewPlanModels.swift`: fields `var id: UUID = UUID()`, `var targetReps: Int = 8`, `var targetWeight: Double = 60.0`; place above `ExerciseBlock`

- [X] T002 Update `ExerciseBlock` in `Features/NewPlan/Models/NewPlanModels.swift`: remove `var numberOfSets: Int = 4`, `var targetReps: Int = 8`, `var targetWeight: Double = 60.0`; add `var sets: [SetConfig] = (0..<4).map { _ in SetConfig() }`; update `isValid` to `!exerciseId.isEmpty && !sets.isEmpty && sets.allSatisfy { $0.targetReps >= 1 && $0.targetWeight >= 0 } && restSeconds >= 0`; depends on T001

**Checkpoint**: `SetConfig` and updated `ExerciseBlock` compile. Compiler now flags every downstream reference to `block.numberOfSets`, `block.targetReps`, `block.targetWeight` — T003–T008 address each site.

---

## Phase 3: User Story 1 — Per-Set Row Table UI (Priority: P1) 🎯 MVP

**Goal**: `ExerciseBlockRowView` renders a table of individual set rows (SET | REPS | WEIGHT columns) with numbered badges, per-row steppers, and × remove buttons. Default 4 rows, each showing 8 reps / 60 kg. REST stepper remains as a single block-level control below the table.

**Independent Test**: Open step 2 of the wizard with one empty block. Verify 4 set rows appear, each with REPS = 8 and WEIGHT = 60 kg. Change row 2's reps to 10 and confirm rows 1, 3, 4 are unchanged.

### Implementation for US1

- [X] T003 [US1] Replace `stepperGrid` in `Features/NewPlan/Views/Components/ExerciseBlockRowView.swift` with a `setRowsTable`: (1) add column header `HStack` with "SET", "REPS", "WEIGHT" labels (`font .system(size: 9, design: .monospaced)`, `foregroundStyle GrayscalePalette.secondary`, `tracking 1.2`); (2) `ForEach(Array(block.sets.enumerated()), id: \.element.id)` rendering a `setRow(index:set:)` view for each set; (3) `setRow` shows: numbered badge (1-based `index+1`, same style as block number badge), a `BMStepperView(label: "Reps", unit: "", value: Double(set.targetReps), step: 1, min: 1, max: 50)` with `onChange` that does `var updated = block; updated.sets[index].targetReps = Int(newValue); onChange(updated)`, a `BMStepperView(label: "Weight", unit: "kg", value: set.targetWeight, step: 2.5, min: 0, max: 500)` with `onChange` that does `var updated = block; updated.sets[index].targetWeight = newValue; onChange(updated)`, and an × button that calls `var updated = block; updated.sets.remove(at: index); onChange(updated)` — × is `.opacity(block.sets.count > 1 ? 1 : 0)` with `.disabled(block.sets.count <= 1)`; depends on T001, T002

- [X] T004 [US1] Add separate `restStepper` view below `setRowsTable` in `Features/NewPlan/Views/Components/ExerciseBlockRowView.swift`: `BMStepperView(label: "Rest", unit: "s", value: Double(block.restSeconds), step: 15, min: 0, max: 600)` with `onChange` updating `block.restSeconds`; add `.padding(.top, 8)` between table and REST stepper; depends on T003

- [X] T005 [P] [US1] Update `BodyMetricTests/Features/NewPlanModelsTests.swift`: replace all references to `block.targetReps`, `block.targetWeight`, `block.numberOfSets` with `block.sets[0].targetReps`, `block.sets[0].targetWeight`, `block.sets.count`; update `isValid` tests to match new `isValid` rule (empty `sets` → invalid; `sets[0].targetReps == 0` → invalid; `sets[0].targetWeight == 0` → valid); add `test_setConfig_defaultValues` asserting `SetConfig().targetReps == 8` and `SetConfig().targetWeight == 60.0`; add `test_exerciseBlock_defaultSetsCount` asserting `ExerciseBlock().sets.count == 4`; depends on T002

**Checkpoint**: US1 complete. Wizard step 2 renders set rows table. REST stepper visible below table. Model tests pass.

---

## Phase 4: User Story 2 — Add and Remove Sets (Priority: P2)

**Goal**: "+ Add set" button appends a new row copying the last row's values. × removes the row and renumbers automatically. Minimum 1 set enforced by hiding × at count = 1.

**Independent Test**: Start with 4 rows. Tap "+ Add set" → 5 rows, row 5 copies row 4's values. Tap × on row 3 → 4 rows remain, renumbered 1–4.

### Implementation for US2

- [X] T006 [US2] Add `addSetButton` view to `ExerciseBlockRowView` in `Features/NewPlan/Views/Components/ExerciseBlockRowView.swift` (below the set rows, inside the table container): button with label `HStack { Image(systemName: "plus"); Text("Add set") }`, `font .system(size: 13, design: .rounded).weight(.semibold)`, `foregroundStyle GrayscalePalette.secondary`; action: `var updated = block; let last = updated.sets.last ?? SetConfig(); updated.sets.append(SetConfig(targetReps: last.targetReps, targetWeight: last.targetWeight)); onChange(updated)`; depends on T003

**Checkpoint**: US1 + US2 complete. Full add/remove set interaction works. × button auto-hides at 1 set (already wired in T003).

---

## Phase 5: User Story 3 — REST Stepper Per Block (Priority: P3)

**Goal**: REST time is configurable at the exercise block level as a single stepper (seconds), positioned below the set rows table, independent of individual set rows.

**Independent Test**: Adjust REST on block 1 to 120s. Add block 2. Verify block 2's REST is 90s (default). Verify block 1's REST is still 120s.

### Implementation for US3

- [X] T007 [US3] Verify `ExerciseBlockRowView` in `Features/NewPlan/Views/Components/ExerciseBlockRowView.swift`: confirm `restStepper` (added in T004) is correctly isolated from `setRowsTable`; confirm changing REST via `onChange` only modifies `block.restSeconds` and no set in `block.sets`; no additional code change needed if T004 is complete — mark done after verification; depends on T004

**Checkpoint**: All 3 user stories complete. Set rows, add/remove, and REST stepper all work independently.

---

## Phase 6: API and ViewModel Wiring (Polish — cross-cutting)

**Purpose**: Update the API request builder and edit-mode loader to use the new `block.sets` shape. Update service tests.

- [X] T008 Update `ExerciseBlockRequest.init(block:orderIndex:)` in `Models/WorkoutDayPlanModels.swift`: replace `self.targetSets = (1...block.numberOfSets).map { idx in TargetSetRequest(orderIndex: idx, targetReps: block.targetReps, targetWeight: block.targetWeight) }` with `self.targetSets = block.sets.enumerated().map { idx, set in TargetSetRequest(orderIndex: idx + 1, targetReps: set.targetReps, targetWeight: set.targetWeight) }`; also remove the stale comment "Wraps the single `ExerciseBlock` target prescription into a one-element `targetSets` array"; depends on T002

- [X] T009 Update edit-mode block loader in `Features/NewPlan/ViewModels/NewPlanViewModel.swift` (lines ~320–328): replace `let firstSet = block.targetSets.min(by: { $0.orderIndex < $1.orderIndex }); b.targetReps = firstSet?.targetReps ?? 8; b.targetWeight = firstSet?.targetWeight ?? 0` with `b.sets = block.targetSets.sorted { $0.orderIndex < $1.orderIndex }.map { SetConfig(targetReps: $0.targetReps, targetWeight: $0.targetWeight) }; if b.sets.isEmpty { b.sets = [SetConfig()] }`; depends on T002, T008

- [X] T010 [P] Update `BodyMetricTests/Services/WorkoutDayPlanServiceTests.swift`: in `test_saveDayConfig_sendsCorrectRequestBody`, replace setup that uses `block.targetReps = 12; block.targetWeight = 80` with `block.sets = [SetConfig(targetReps: 12, targetWeight: 80)]`; assert `decoded.exerciseBlocks[0].targetSets[0].targetReps == 12` and `decoded.exerciseBlocks[0].targetSets[0].targetWeight == 80.0` (assertions unchanged — only fixture setup changes); depends on T002, T008

- [X] T011 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED with zero errors mentioning `numberOfSets`, `targetReps`, or `targetWeight` on `ExerciseBlock`

---

## Dependencies

```
T001 (SetConfig struct)
    ↓
T002 (ExerciseBlock updated — blocks all downstream)
    ↓
T003 [US1] (setRowsTable in ExerciseBlockRowView)
    ↓
T004 [US1] (restStepper below table)
    ↓
T006 [US2] (addSetButton)
    ↓
T007 [US3] (REST isolation verify)

T002 → T005 [P] (NewPlanModelsTests — parallel with T003/T004)
T002 → T008 (WorkoutDayPlanModels request builder)
T008 → T009 (NewPlanViewModel edit-mode loader)
T008 → T010 [P] (WorkoutDayPlanServiceTests)
T002..T010 → T011 (build)
```

T005 and T003 are [P] after T002 — different files.  
T010 and T009 are [P] after T008 — different files.

---

## Notes

- `BMStepperView` is a private struct in `ExerciseBlockRowView.swift` — no changes to its signature needed.
- `ConfigureDayStepView.swift` is **not** modified — it passes blocks to `ExerciseBlockRowView` via `onChange(updated)` which is unchanged.
- `NewPlanWizardView.swift` is **not** modified — Continue/Finish gates use `block.isValid` which is updated in T002.
- Constitution VII: no auth layer changes; NetworkClient bearer token injection is unaffected.
- The `ExerciseBlockRowView` external interface (parameters) is **unchanged** — only its internal body changes.

---

## Amendment: Home API Response Adaptation

**Trigger**: Runtime error `home_data_load_failed | error: Could not read the server response` from `TodayViewModel.swift:49`.
**Root cause**: `TodayExercise.numberOfSets: Int` cannot decode `"sets": []` (array) from the server. See `research.md` amendment section and `contracts/home-api.md`.

**Scope**: 3 files + 1 build verification. No new files, no new services, no API changes.

---

### Phase: Foundational — Restore HomeExerciseSet and fix TodayExercise decoder

**Purpose**: `TodayExercise` currently expects `numberOfSets: Int` but the server sends `sets: [...]`. This blocks all downstream steps.

- [X] T012 In `Models/HomeModels.swift`: (1) add `struct HomeExerciseSet: Decodable, Equatable` with fields `let orderIndex: Int`, `let targetReps: Int`, `let targetWeight: Double`; (2) on `TodayExercise`, replace `let numberOfSets: Int` with `let sets: [HomeExerciseSet]`; (3) add computed property `var numberOfSets: Int { sets.count }`; place `HomeExerciseSet` above `TodayExercise` in the file

**Checkpoint**: `TodayExercise` now decodes `"sets": []` from JSON. Compiler flags any call site that passes `numberOfSets:` as an initializer argument — T013 and T014 address those.

---

### Phase: Fix Call Sites (parallel after T012)

- [X] T013 [P] [US1] In `Features/Workout/Views/TodayView.swift`: find all preview stubs that construct `TodayExercise(id:, name:, orderIndex:, numberOfSets: N)` and change the last argument from `numberOfSets: N` to `sets: []`; there are two stubs in the `#Preview` block at the bottom of the file; depends on T012

- [X] T014 [P] [US1] In `BodyMetricTests/Features/TodayViewModelTests.swift`: find all fixture lines that construct `TodayExercise(id:, name:, orderIndex:, numberOfSets: N)` and change `numberOfSets: N` to `sets: []`; depends on T012

---

### Phase: Polish — Build verification

- [X] T015 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED with zero errors referencing `numberOfSets` as a stored property on `TodayExercise`; depends on T012, T013, T014

---

## Amendment Dependencies

```
T012 (HomeExerciseSet + TodayExercise model fix)
    ↓
T013 [P] (TodayView preview stubs)
T014 [P] (TodayViewModelTests fixtures)
    ↓
T015 (build)
```

T013 and T014 are parallel — different files, both depend only on T012.

---

## Amendment Notes

- `BodyMetricTests/Services/HomeServiceTests.swift` already uses `sets` array format in JSON fixtures and asserts `sets[0].targetReps` — **no changes needed** ✅
- `HomeService.swift` decoding logic is unchanged — `JSONDecoder` handles the rest once the model is correct
- `TodayView.swift` production code (`Text("\(ex.numberOfSets) sets")`) remains valid — `numberOfSets` is now a computed property returning `sets.count`
- `WorkoutDayPlanSummary` is unchanged — all its fields already match the server response
