# UI Contract: Exercise Block Row — Per-Set Table

**Feature**: 020-wizard-step2-per-set-rows  
**Applies to**: `ExerciseBlockRowView` in step 2 of the new-plan wizard

## Layout Structure

```
┌─────────────────────────────────────────────────────────┐
│  [01]  PICK AN EXERCISE                          [×]     │  ← block header (unchanged)
├─────────────────────────────────────────────────────────┤
│  [🏋] Choose exercise                             >      │  ← exercise picker trigger (unchanged)
├─────────────────────────────────────────────────────────┤
│  SET        REPS              WEIGHT                     │  ← column header row
│──────────────────────────────────────────────────────── │
│  [1]   [−]  8  [+]      [−]  60 kg  [+]         [×]    │  ← set row 1
│  [2]   [−]  8  [+]      [−]  60 kg  [+]         [×]    │  ← set row 2
│  [3]   [−]  8  [+]      [−]  60 kg  [+]         [×]    │  ← set row 3
│  [4]   [−]  8  [+]      [−]  60 kg  [+]         [×]    │  ← set row 4
│──────────────────────────────────────────────────────── │
│              +  Add set                                  │  ← add set button
└─────────────────────────────────────────────────────────┘
```

## Component Contracts

### Set Row

| Element | Type | Behaviour |
|---------|------|-----------|
| Set number badge | Text + RoundedRect bg | Shows 1-based index; auto-updates when rows removed |
| REPS stepper | − value + | Min 1, max 50, step 1; integer display |
| WEIGHT stepper | − value kg + | Min 0, max 500, step 2.5; displays "X kg" or "X.X kg" if fractional |
| × remove button | Icon button | Removes this set; hidden when `sets.count == 1` |

### Column Header Row

| Column | Label | Style |
|--------|-------|-------|
| Left | "SET" | monospaced 9pt, secondary color, tracking 1.2 |
| Center | "REPS" | same |
| Right | "WEIGHT" | same |

### Add Set Button

- Label: "+ Add set" 
- Action: appends new `SetConfig` with `targetReps` and `targetWeight` copied from the last existing set row
- Style: centered text, monospaced, secondary color; no border needed (inline with table)

### REST Stepper (block-level, separate from table)

- Label: "REST"
- Unit: "s"
- Min: 0, Max: 600, Step: 15
- Position: below the set rows table, as a single full-width stepper cell

## State Contracts

| State | Visual |
|-------|--------|
| `sets.count == 1` | × button hidden on that row |
| `sets.count >= 2` | × button shown on all rows |
| `SetConfig.targetReps == 1` | − button disabled on that row's REPS stepper |
| `SetConfig.targetWeight == 0` | − button disabled on that row's WEIGHT stepper |

## ExerciseBlockRowView Interface (Swift)

The view's `onChange` callback receives an updated `ExerciseBlock`. The parent (`ConfigureDayStepView`) calls `viewModel.updateBlock(id:day:mutate:)` with the updated block — no interface change needed at the parent level.

```swift
// Unchanged external interface:
struct ExerciseBlockRowView: View {
    let index: Int
    let block: ExerciseBlock         // now carries block.sets: [SetConfig]
    let canRemove: Bool
    let exerciseName: String?
    let onPick: () -> Void
    let onRemove: () -> Void
    let onChange: (ExerciseBlock) -> Void
}
```
