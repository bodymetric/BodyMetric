# Tasks: Wizard Step 2 — Save Day Config on Continue

**Input**: Design documents from `/specs/021-wizard-day-save/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Scope**: 0 new files. All 11 functional requirements are already implemented (features 011, 013, 020).
See `research.md` for the full requirement-to-code traceability audit.

**Tests**: All relevant tests already exist in `NewPlanViewModelTests.swift` and `WorkoutDayPlanServiceTests.swift`.

---

## Phase 1: Setup

No new directories, packages, or project files required. All required code already exists.

---

## Phase 2: Verification — Confirm spec 021 is satisfied by existing implementation

**Purpose**: Confirm that each requirement from spec 021 matches the live code, and that the build passes with no regressions.

**Independent Test**: Run `xcodebuild build` — must exit `BUILD SUCCEEDED`. Grep for `saveDayConfig` call in `NewPlanWizardView.swift` — must exist.

### User Story 1 — Save Workout Day on Continue

- [X] T001 [US1] Verify in `Features/NewPlan/Views/NewPlanWizardView.swift` (line ~197–206) that the Continue button action in non-edit mode calls `await viewModel.saveDayConfig(for: day, using: dayConfigService)` with `onSuccess: { viewModel.advance() }` — read the file and confirm; no code change expected

- [X] T002 [US1] Verify in `Features/NewPlan/ViewModels/NewPlanViewModel.swift` (lines ~199–205) that `WorkoutDayPlanRequest` is constructed with `name: plan.sessionName`, `orderIndex: day.orderIndex`, `isActive: true`, and `exerciseBlocks` mapped from `plan.blocks.enumerated()` — read the file and confirm; no code change expected

- [X] T003 [US1] Verify in `Models/WorkoutDayPlanModels.swift` that `ExerciseBlockRequest.init(block:orderIndex:)` maps `block.sets.enumerated()` to `targetSets` with `orderIndex: idx + 1`, `targetReps: set.targetReps`, `targetWeight: set.targetWeight` — read the file and confirm; no code change expected

- [X] T004 [US1] Verify in `Features/NewPlan/Views/NewPlanWizardView.swift` (lines ~146, ~170) that `stepDaySaving = viewModel.isDayConfigSaving` and that the Continue button is passed `enabled: canContinue && !stepDaySaving` — read the file and confirm; no code change expected

---

### User Story 2 — Error Handling on Save Failure

- [X] T005 [US2] Verify in `Features/NewPlan/ViewModels/NewPlanViewModel.swift` (lines ~189–215) that: (1) `guard !isDayConfigSaving` prevents duplicate requests; (2) `dayConfigSaveError = nil` is set before the request; (3) on catch, `dayConfigSaveError = "Could not save your workout day. Please try again."` is set and `onSuccess` is NOT called — read the file and confirm; no code change expected

- [X] T006 [US2] Verify in `Features/NewPlan/Views/Components/ConfigureDayStepView.swift` (lines ~28–32) that `dayConfigSaveError` is displayed as an error banner when non-nil — read the file and confirm; no code change expected

---

## Phase 3: Build Verification

- [X] T007 Build and verify: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` — confirm BUILD SUCCEEDED; depends on T001–T006

---

## Dependencies

```
T001 [US1] (Continue button wires saveDayConfig)
T002 [US1] (Request payload construction)
T003 [US1] (Per-set targetSets mapping)      ← all parallel (read-only verification)
T004 [US1] (Button disabled during save)
T005 [US2] (Error handling + guard)
T006 [US2] (Error banner display)
    ↓
T007 (build)
```

T001–T006 are all read-only verification tasks in different files — fully parallel.

---

## Notes

- No implementation work needed — all FRs are already satisfied.
- In edit mode, Continue calls `viewModel.advance()` directly without saving. This is intentional (edit mode uses `updatePlan` at the final step, feature 017) and is out of scope for spec 021.
- `WorkoutDayPlanService.saveDayPlan` targets `POST /api/workout-plans/{workoutPlanId}/days` and accepts both 200 and 201 as success — matches the API contract.
- Bearer token injection is handled automatically by `NetworkClient` — no changes needed.
