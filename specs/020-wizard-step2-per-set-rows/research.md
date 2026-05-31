# Research: Wizard Step 2 — Per-Set Row Configuration

**Branch**: `020-wizard-step2-per-set-rows` | **Date**: 2026-05-28

## Current State Audit

### ExerciseBlock model — needs replacement of scalar fields with SetConfig array

**Current shape** (`Features/NewPlan/Models/NewPlanModels.swift`):
```
struct ExerciseBlock: Identifiable, Codable {
    var id: UUID           = UUID()
    var exerciseId: String = ""
    var numberOfSets: Int  = 4
    var targetReps: Int    = 8
    var targetWeight: Double = 60.0
    var restSeconds: Int   = 90
}
```

**Decision**: Replace `numberOfSets`, `targetReps`, `targetWeight` with `sets: [SetConfig]` where each `SetConfig` holds its own `targetReps` and `targetWeight`. Keep `restSeconds` at the block level (not per-set).

**Rationale**: The screenshot shows individual rows, each independently configurable. The flat scalar model cannot represent this. `SetConfig` is a new child value type, `Identifiable` and `Codable`.

**Default values**: 4 sets of `SetConfig(targetReps: 8, targetWeight: 60.0)` — matches the screenshot.

**Alternatives considered**: Keeping `numberOfSets` as a counter and adding `perSetOverrides` — rejected as overly complex; direct array is clearer and round-trips cleanly to the server's `targetSets` array.

---

### ExerciseBlockRowView — full UI replacement

**Current**: 2×2 VStack grid (SETS stepper, REPS stepper, WEIGHT stepper, REST stepper — added in feature 019).

**Decision**: Replace the `stepperGrid` with a `setRowsTable` (header row + set rows + Add set button) and add a separate `restStepper` below the table.

**Table structure**:
- Header: SET | REPS | WEIGHT (monospaced labels)
- Each row: numbered badge | REPS inline stepper | WEIGHT inline stepper | × remove button
- Footer: "+ Add set" button

**REST control**: Kept as a single `BMStepperView` below the table, since REST is not per-set.

**Add set behaviour**: Copies `targetReps` and `targetWeight` from the last row (or defaults if empty). Appends at the bottom.

**Remove set behaviour**: Removes by index; sets are re-rendered with ForEach by index so numbering is automatic.

**× button visibility**: Hidden when `block.sets.count == 1`.

**Rationale**: Matches the screenshot exactly. The "Add set" and × pattern is a standard gym-app UX.

---

### ExerciseBlockRequest — trivial update

**Current**: Creates N identical `TargetSetRequest` copies from `block.numberOfSets`.

**Decision**: Replace with `block.sets.enumerated().map { idx, set in TargetSetRequest(orderIndex: idx + 1, targetReps: set.targetReps, targetWeight: set.targetWeight) }`.

**Rationale**: Direct mapping; no logic change, just source of truth changes from scalar to array.

---

### NewPlanViewModel edit-mode loader — update block mapping

**Current** (line ~322):
```swift
let firstSet = block.targetSets.min(by: { $0.orderIndex < $1.orderIndex })
var b = ExerciseBlock()
b.exerciseId   = String(block.exerciseId)
b.restSeconds  = block.restSeconds
b.targetReps   = firstSet?.targetReps   ?? 8
b.targetWeight = firstSet?.targetWeight ?? 0
```

**Decision**: Replace with full set mapping — create one `SetConfig` per `CurrentTargetSet` from the server response:
```swift
var b = ExerciseBlock()
b.exerciseId  = String(block.exerciseId)
b.restSeconds = block.restSeconds
b.sets = block.targetSets
    .sorted { $0.orderIndex < $1.orderIndex }
    .map { SetConfig(targetReps: $0.targetReps, targetWeight: $0.targetWeight) }
if b.sets.isEmpty { b.sets = [SetConfig()] }
```

**Rationale**: The edit-mode now loads real per-set data instead of collapsing it to a single rep/weight value. Users who edit a plan see the actual per-set configuration they previously saved.

---

### Tests — model tests need SetConfig-aware assertions

**`NewPlanModelsTests.swift`**: All tests that set `block.targetReps`, `block.targetWeight`, or `block.numberOfSets` must be updated to manipulate `block.sets` instead.

**`WorkoutDayPlanServiceTests.swift`**: The assertion `decoded.exerciseBlocks[0].targetSets[0].targetReps == 12` remains valid — the serialisation shape is unchanged. Only the source (`block.sets[0]` instead of `block.targetReps`) changes.

---

### No changes needed

- `ConfigureDayStepView.swift` — passes blocks to `ExerciseBlockRowView` via `onChange`; the interface is unchanged.
- `HomeModels.swift` — home screen read path is unaffected.
- `WorkoutExecutionModels.swift` — start session flow is unaffected.
- `NewPlanWizardView.swift` — Continue / Finish gates use `block.isValid` which will be updated on `ExerciseBlock`.

---

## Amendment: Home API Response Mismatch (2026-05-28)

**Trigger**: Runtime decode failure `home_data_load_failed | error: Could not read the server response` from `TodayViewModel.swift:49`.

### Root Cause

Feature 019 changed `TodayExercise` to decode `numberOfSets: Int`, but the actual server returns `"sets": []` (an array). `JSONDecoder` throws "key not found: numberOfSets" on every 200 response, making the home screen permanently broken.

### Decision: Restore `TodayExercise.sets: [HomeExerciseSet]` + computed `numberOfSets`

**Rationale**: The server sends `sets` (array). The client should decode what the server sends. `numberOfSets` is a derived value (`sets.count`) — no need to ask the server for redundant data.

**Alternatives considered**:

| Option | Assessment |
|--------|------------|
| Add `numberOfSets` field to server response | Server change required; adds redundant data; slower |
| Custom `init(from decoder:)` to count `sets` into `Int` | Fragile; breaks if sets key is absent |
| Decode `sets` array + `var numberOfSets: Int { sets.count }` | ✅ Chosen — matches server exactly |

### HomeExerciseSet shape (from server + `HomeServiceTests.swift`)

```json
{ "orderIndex": 1, "targetReps": 12, "targetWeight": 25.0 }
```

| Field | Type | Notes |
|-------|------|-------|
| orderIndex | Int | 1-based position |
| targetReps | Int | target rep count for this set |
| targetWeight | Double | target weight in kg |

### Files Changed by This Amendment

| File | Change |
|------|--------|
| `Models/HomeModels.swift` | Replace `numberOfSets: Int` with `sets: [HomeExerciseSet]` on `TodayExercise`; add `HomeExerciseSet` struct; add `var numberOfSets: Int { sets.count }` |
| `Features/Workout/Views/TodayView.swift` | Preview stubs: change `TodayExercise(…, numberOfSets: N)` → `TodayExercise(…, sets: [])` |
| `BodyMetricTests/Features/TodayViewModelTests.swift` | Fixtures: `numberOfSets: N` → `sets: []` |
| `BodyMetricTests/Services/HomeServiceTests.swift` | Already uses `sets` array format — no change needed ✅ |
