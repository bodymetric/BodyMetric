# Feature Specification: Wizard Review Step — Correct Exercise Names

**Feature Branch**: `023-wizard-review-exercise-names`
**Created**: 2026-05-31
**Status**: Draft
**Input**: Bug report — in the "One last look" review screen (step 3 of the workout plan wizard), every exercise block shows "No exercise" instead of the exercise name the user selected

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Review Screen Shows Correct Exercise Names (Priority: P1)

After configuring exercises in the day steps, the user reaches the "One last look" summary. Each exercise block card must display the actual exercise name the user picked (e.g., "Bench Press"), not the placeholder text "No exercise".

**Why this priority**: This is a regression that makes the review step unusable — the user cannot verify their plan configuration before saving. It is the only user story in this spec.

**Independent Test**: Load a wizard session with one day and one `ExerciseBlock` whose `exerciseId` is a valid API integer ID (e.g., `"26"`). Render `ReviewStepView` with a `NewPlanViewModel` whose `exerciseGroups` contains that exercise. Assert the label reads the exercise name, not `"No exercise"`.

**Acceptance Scenarios**:

1. **Given** a day has one exercise block with `exerciseId = "26"` and the catalog contains an exercise with `id = 26, name = "Bench Press"`, **When** the review screen is displayed, **Then** the block row shows `"Bench Press"`
2. **Given** a block with no exercise selected (`exerciseId = ""`), **When** the review screen is displayed, **Then** the row shows the fallback `"No exercise"`
3. **Given** multiple blocks on a day, **When** the review screen is displayed, **Then** every block shows its correct individual exercise name

---

### Edge Cases

- What if `exerciseGroups` is empty? `exerciseName(for:)` returns `nil` → fallback "No exercise" is acceptable; catalog is loaded during step 2 before the user can reach step 3.
- What if `exerciseId` is an empty string (block never configured)? `exerciseName(for:)` returns `nil` → fallback "No exercise" is correct.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: In `ReviewStepView.blockSummaryRow`, the exercise name MUST be resolved via `viewModel.exerciseName(for: block.exerciseId)` — NOT via `Exercise.catalog`
- **FR-002**: If `viewModel.exerciseName(for: block.exerciseId)` returns `nil`, the label MUST fall back to `"No exercise"`

### Key Entities

- **ExerciseBlock.exerciseId**: `String` storing a stringified integer API ID (e.g., `"26"`)
- **NewPlanViewModel.exerciseName(for:)**: Looks up exercise name from `exerciseGroups` (API catalog)
- **Exercise.catalog**: Static hardcoded catalog with non-integer string IDs — NOT used for name lookup after this fix

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every exercise block in the review step displays the name the user selected during step 2
- **SC-002**: Blocks with no exercise still show "No exercise" as the fallback (no regression)

## Assumptions

- The exercise catalog is loaded during step 2; by the time the user reaches step 3, `exerciseGroups` is populated
- `viewModel.exerciseName(for:)` is the correct and already-tested lookup method for this purpose
