# Quickstart: Wizard Review Step — Correct Exercise Names

**Branch**: `023-wizard-review-exercise-names` | **Date**: 2026-05-31

## Verification Scenarios

---

### Scenario 1 — Exercise name resolves from API catalog

**Setup**: `NewPlanViewModel` with `exerciseGroups` containing one group with exercise `{id: 26, name: "Bench Press"}`. `ExerciseBlock` with `exerciseId = "26"`.

**Expected**: `blockSummaryRow` displays `"Bench Press"`.

---

### Scenario 2 — Fallback for unset exercise

**Setup**: `ExerciseBlock` with `exerciseId = ""`.

**Expected**: `blockSummaryRow` displays `"No exercise"`.

---

### Scenario 3 — Multiple blocks show individual names

**Setup**: Day plan with two blocks: `exerciseId = "26"` (Bench Press) and `exerciseId = "17"` (Tricep Extension).

**Expected**: First row shows `"Bench Press"`, second row shows `"Tricep Extension"`.

---

### Scenario 4 — Build passes with zero errors

`xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` exits `BUILD SUCCEEDED`.
