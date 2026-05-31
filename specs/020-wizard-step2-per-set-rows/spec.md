# Feature Specification: Wizard Step 2 — Per-Set Row Configuration

**Feature Branch**: `020-wizard-step2-per-set-rows`  
**Created**: 2026-05-28  
**Status**: Draft  
**Input**: User screenshot showing redesigned step 2 of the new plan wizard

## User Scenarios & Testing *(mandatory)*

### User Story 1 — View and Configure Individual Sets in an Exercise Block (Priority: P1)

When a user is on step 2 of the plan creation wizard (configuring a training day), each exercise block now shows a table of individual set rows instead of a single "SETS / REPS / WEIGHT / REST" stepper grid. Each row in the table represents one set, with its own REPS stepper and WEIGHT stepper. By default, a new exercise block starts with 4 sets, each pre-filled with 8 reps and 60 kg. The user can adjust reps and weight independently per set.

**Why this priority**: This is the core visual and interaction change. All other stories depend on the table being rendered.

**Independent Test**: Open step 2 of the wizard with one exercise block. Verify: the block shows 4 rows labeled 1–4; each row has a REPS stepper (default 8) and a WEIGHT stepper (default 60 kg); changing row 2's reps to 10 does not affect row 1 or row 3.

**Acceptance Scenarios**:

1. **Given** a new exercise block is added, **When** step 2 renders, **Then** the block shows exactly 4 set rows, each with REPS = 8 and WEIGHT = 60 kg.
2. **Given** a set row is visible, **When** the user taps − or + on the REPS stepper, **Then** only that row's rep count changes.
3. **Given** a set row is visible, **When** the user taps − or + on the WEIGHT stepper, **Then** only that row's weight changes, displayed with a "kg" unit suffix.
4. **Given** the exercise block has multiple set rows, **When** the screen renders, **Then** each row displays its set number (1, 2, 3…) as a badge on the left.

---

### User Story 2 — Add and Remove Sets Within an Exercise Block (Priority: P2)

The user can add more sets to an exercise block by tapping "Add set" at the bottom of the set table, or remove any individual set by tapping the × button on that row.

**Why this priority**: Dynamic set management is required for flexible workout design. Without it the default of 4 sets cannot be changed.

**Independent Test**: Start with 4 set rows. Tap "Add set" → verify 5 rows appear. Tap × on row 3 → verify 4 rows remain, renumbered sequentially 1–4.

**Acceptance Scenarios**:

1. **Given** an exercise block with 4 sets, **When** the user taps "+ Add set", **Then** a new row (set 5) appears with the same default values as the previous row (reps and weight copied from the last row).
2. **Given** an exercise block with 2+ sets, **When** the user taps × on any row, **Then** that set is removed and remaining sets are renumbered sequentially from 1.
3. **Given** an exercise block has exactly 1 set, **When** that set is displayed, **Then** the × remove button is hidden (minimum 1 set enforced).
4. **Given** a set is removed, **When** the block re-renders, **Then** the exercise block's set count badge ("1 block", etc.) in the section header reflects the new count.

---

### User Story 3 — Rest Time Configuration Preserved Per Block (Priority: P3)

Rest time between sets remains configurable at the exercise block level (not per individual set). The rest time stepper was previously part of the 2×2 grid. In the new design it is shown as a single control on the exercise block card, separate from the per-set rows table.

**Why this priority**: Rest time is still needed for workout timing, but it is a block-level setting, not a per-set setting. It is lower priority because the core set-row interaction works without it.

**Independent Test**: Verify that changing the rest time on one exercise block does not change another block's rest time. Verify rest time appears on the card, distinct from the set rows table.

**Acceptance Scenarios**:

1. **Given** an exercise block, **When** step 2 renders, **Then** a REST stepper (in seconds) is visible on the card, separate from the set rows.
2. **Given** a user adjusts the REST value on block 1, **When** block 2 is viewed, **Then** block 2's REST value is unchanged.
3. **Given** rest time defaults, **When** a new block is added, **Then** its REST is pre-set to 90 seconds.

---

### Edge Cases

- What happens if the user adds many sets (e.g., 10+)? The set table must be scrollable; no hard cap below 10 sets.
- What happens if REPS is decremented below 1? The minimum is 1 rep; the − button disables at 1.
- What happens if WEIGHT is decremented below 0? The minimum is 0 kg (bodyweight exercises); the − button disables at 0.
- What happens when an exercise has not been chosen and the user tries to continue? The Continue button remains disabled with the hint "Add a name to continue" until the workout name field is filled and all blocks have an exercise chosen.
- What happens if the workout name is empty? The Continue button is disabled; a hint message "Add a name to continue" is displayed above the button.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Each exercise block in step 2 MUST display a table of individual set rows, where each row shows a numbered set badge, a REPS stepper, a WEIGHT (kg) stepper, and a × remove button.
- **FR-002**: A new exercise block MUST default to 4 set rows, each pre-filled with 8 reps and 60 kg.
- **FR-003**: Reps and weight values MUST be independently configurable per set row; changing one row MUST NOT affect any other row.
- **FR-004**: Tapping "+ Add set" MUST append a new row at the bottom of the table, pre-filled with the same reps and weight as the last existing row.
- **FR-005**: Tapping × on a set row MUST remove that row and renumber all remaining rows sequentially starting from 1.
- **FR-006**: The × remove button MUST be hidden when the exercise block has exactly 1 set (minimum 1 set enforced).
- **FR-007**: Rest time MUST remain configurable at the exercise block level as a single stepper (seconds), distinct from the per-set row table.
- **FR-008**: The exercise block section header MUST display the current block count (e.g., "1 block", "2 blocks").
- **FR-009**: The Continue button MUST be disabled and a hint "Add a name to continue" MUST be displayed when the workout name is empty or any exercise block has no exercise selected.
- **FR-010**: The step header MUST show "STEP 02 · DAY N OF M" and the day name (e.g., "Monday") as the primary title.
- **FR-011**: The set data (per-set reps and weight) MUST be sent to the server when the day is saved, with each set as a separate entry in the exercise block's set list.

### Key Entities

- **SetConfig**: One row in an exercise block's set table. Fields: set number (1-based, derived from position), targetReps (Int, min 1), targetWeight (Double, min 0, unit: kg).
- **ExerciseBlock**: One exercise slot in a training day. Now contains an ordered list of SetConfig items (replacing the previous single `targetReps`/`targetWeight`/`numberOfSets` fields). Retains `restSeconds` (Int) as a block-level field.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can configure a 4-exercise day plan with customised per-set reps and weights in under 3 minutes.
- **SC-002**: 100% of existing wizard unit tests continue to pass after the data model change; no tests are deleted, only updated or added.
- **SC-003**: The step 2 screen renders the set table with correct row count within 300 ms of the user navigating to that step.
- **SC-004**: Adding and removing sets requires no more than 1 tap per operation, with instant visual feedback.

## Assumptions

- REST time is retained as a per-block field (not per-set) and remains visible on the exercise block card, though it was not visible in the screenshot due to cropping.
- The REPS stepper step size is 1 (integer); the WEIGHT stepper step size is 2.5 kg (same as before).
- Maximum reps per set is 50; minimum is 1. Maximum weight is 500 kg; minimum is 0.
- The maximum number of sets per exercise block is not capped below 20.
- "Add set" copies reps and weight from the last existing row (not from a global default) to reduce user friction.
- The existing server API for saving days accepts a `targetSets` array per exercise block — the new per-set model maps directly to this array.
- The wizard step rail (Days → Mon → Wed → Fri → Save) and the overall 5-step navigation structure are unchanged.
- No changes are made to step 1 (day selection) or steps 3–5 of the wizard.
