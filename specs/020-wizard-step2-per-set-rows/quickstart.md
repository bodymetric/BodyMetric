# Quickstart: Wizard Step 2 — Per-Set Row Configuration

**Branch**: `020-wizard-step2-per-set-rows` | **Date**: 2026-05-28

## Integration Scenarios

### Scenario 1 — New exercise block defaults to 4 set rows

**Setup**: Create a new `ExerciseBlock()` with default values.

**Expected**:
```swift
let block = ExerciseBlock()
assert(block.sets.count == 4)
assert(block.sets[0].targetReps == 8)
assert(block.sets[0].targetWeight == 60.0)
assert(block.restSeconds == 90)
// numberOfSets, targetReps, targetWeight no longer exist on ExerciseBlock
```

---

### Scenario 2 — Add set copies last row's values

**Setup**: Start with block having sets `[{8 reps, 60 kg}, {10 reps, 80 kg}]`.

**Action**: Tap "+ Add set".

**Expected**: 
- `block.sets.count == 3`
- `block.sets[2].targetReps == 10`  (copied from last row)
- `block.sets[2].targetWeight == 80.0`

---

### Scenario 3 — Remove middle set renumbers remaining rows

**Setup**: Block with 4 sets.

**Action**: Tap × on set row 2.

**Expected**:
- `block.sets.count == 3`
- Display shows rows labeled 1, 2, 3 (auto-renumbered by index)
- No gaps in numbering

---

### Scenario 4 — ExerciseBlockRequest sends correct targetSets array

**Setup**: `ExerciseBlock` with `sets = [{8 reps, 60 kg}, {10 reps, 80 kg}, {12 reps, 60 kg}]`.

**Expected request body**:
```json
{
  "exerciseId": 1,
  "orderIndex": 0,
  "restSeconds": 90,
  "isOptional": false,
  "targetSets": [
    { "orderIndex": 1, "targetReps": 8,  "targetWeight": 60.0 },
    { "orderIndex": 2, "targetReps": 10, "targetWeight": 80.0 },
    { "orderIndex": 3, "targetReps": 12, "targetWeight": 60.0 }
  ]
}
```

---

### Scenario 5 — Edit mode loads per-set data from server

**Setup**: Server returns plan with 1 exercise block, 3 target sets (reps: 8, 10, 12; weights: 60, 70, 60).

**Expected after `loadCurrentPlan(using:)`**:
- `viewModel.dayPlans[day]!.blocks[0].sets.count == 3`
- `viewModel.dayPlans[day]!.blocks[0].sets[0].targetReps == 8`
- `viewModel.dayPlans[day]!.blocks[0].sets[1].targetReps == 10`
- `viewModel.dayPlans[day]!.blocks[0].sets[2].targetReps == 12`

---

### Scenario 6 — isValid gates Continue button correctly

**Setup**: Block with `exerciseId = "bench"` and `sets = [{targetReps: 1, targetWeight: 0}]` — minimum valid set.

**Expected**: `block.isValid == true` → Continue button enabled.

**Setup 2**: Block with `sets = [{targetReps: 0, targetWeight: 60}]` — reps below minimum.

**Expected**: `block.isValid == false` → Continue disabled.

---

### Scenario 7 — Build passes with zero compilation errors

After all changes: `xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` exits with `BUILD SUCCEEDED`. No references to `block.numberOfSets`, `block.targetReps`, or `block.targetWeight` remain.
