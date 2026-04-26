# Data Model: Home Menu Dropdown

**Feature**: `006-home-menu-dropdown`  
**Date**: 2026-04-25

---

## 1. Menu Domain

### `HomeMenuItem`

Represents a single entry in the top-right dropdown menu.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Stable identifier (e.g., `"today"`, `"newPlan"`) |
| `label` | `String` | Primary display text (e.g., "New Workout Plan") |
| `subtitle` | `String` | One-line description (e.g., "Build a weekly programme") |
| `iconName` | `String` | SF Symbol name |
| `isActive` | `Bool` | `true` → navigable; `false` → "SOON" badge, non-tappable |
| `isPrimary` | `Bool` | `true` → accent icon background (WorkoutPalette); only "New Workout Plan" |
| `destination` | `HomeMenuDestination?` | Navigation target; `nil` for coming-soon items |

### `HomeMenuDestination`

Enum of the two navigable destinations in this iteration.

```
case today          // dismiss menu; stay on TodayView
case newWorkoutPlan // dismiss menu; present NewPlanWizardView
```

**Static catalog** (defined once, read-only):

| id | Label | Subtitle | Icon | isActive | isPrimary |
|----|-------|----------|------|----------|-----------|
| `today` | Today | Your daily workout | `calendar` | ✅ | ❌ |
| `newPlan` | New Workout Plan | Build a weekly programme | `plus` | ✅ | ✅ |
| `myPlans` | My Plans | Saved routines | `dumbbell.fill` | ❌ | ❌ |
| `history` | History | Past sessions | `chart.line.uptrend.xyaxis` | ❌ | ❌ |
| `progress` | Progress | PRs · volume | `bolt.fill` | ❌ | ❌ |
| `profile` | Profile | Account · units | `person.circle` | ❌ | ❌ |
| `settings` | Settings | Preferences | `gearshape.fill` | ❌ | ❌ |

---

## 2. New Plan Wizard Domain

### `DayOfWeek`

```
enum DayOfWeek: Int, CaseIterable, Codable, Identifiable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday
}
```

- `id`: raw `Int` value
- `shortLabel`: "Mon", "Tue", … "Sun"
- `fullLabel`: "Monday", "Tuesday", … "Sunday"
- Display order: Mon → Sun

---

### `Exercise` (catalog item)

Read-only; defined as a static array in source.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Stable slug (e.g., `"bench"`, `"squat"`) |
| `name` | `String` | Display name (e.g., "Barbell Bench Press") |
| `primaryMuscle` | `String` | Group label (e.g., "Chest", "Legs") |

**18 exercises across 8 muscle groups** (Chest, Legs, Hamstrings, Back, Shoulders, Biceps, Triceps, Core) — full list defined in `NewPlanModels.swift`.

---

### `ExerciseBlock`

A single exercise slot within a day's plan.

| Field | Type | Validation | Default |
|-------|------|------------|---------|
| `id` | `UUID` | immutable | auto |
| `exerciseId` | `String` | non-empty to be valid | `""` |
| `targetReps` | `Int` | 1…50 | `8` |
| `targetWeight` | `Double` | 0…500 | `60.0` |
| `restSeconds` | `Int` | 0…600 | `90` |

**Computed**:
- `isValid`: `!exerciseId.isEmpty && targetReps >= 1 && targetWeight >= 0 && restSeconds >= 0`

---

### `DayPlan`

Configuration for a single training day.

| Field | Type | Validation |
|-------|------|------------|
| `day` | `DayOfWeek` | immutable |
| `sessionName` | `String` | non-empty to be valid |
| `blocks` | `[ExerciseBlock]` | ≥ 1 block, all blocks valid |

**Computed**:
- `isValid`: `!sessionName.trimmingCharacters(in:.whitespaces).isEmpty && !blocks.isEmpty && blocks.allSatisfy(\.isValid)`

---

### `WorkoutPlan`

The root persistent model produced by the wizard.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `UUID` | auto-generated on creation |
| `createdAt` | `Date` | timestamp of save |
| `dayPlans` | `[DayPlan]` | ordered Mon → Sun; only selected days present |

**Conforms to**: `Codable`, `Identifiable`

**Validation**: `!dayPlans.isEmpty && dayPlans.allSatisfy(\.isValid)`

---

## 3. Wizard State (ViewModel-owned, not persisted until finish)

| Property | Type | Purpose |
|----------|------|---------|
| `selectedDays` | `Set<DayOfWeek>` | Days toggled in step 1 |
| `dayPlans` | `[DayOfWeek: DayPlan]` | Live configuration per day |
| `currentStep` | `Int` | 1 = day picker; 2…N+1 = day N config; N+2 = review |
| `totalSteps` | `Int` (computed) | `2 + selectedDays.count` |
| `activePickerBlockId` | `UUID?` | Which ExerciseBlock has picker sheet open |
| `isPresentingSuccess` | `Bool` | Drives PlanSavedView |

**Step transitions**:
- `advance()`: `currentStep += 1`, validated — no-op if current step is invalid
- `retreat()`: `currentStep -= 1`; if step == 1 and retreat → cancel wizard
- `jumpTo(step:)`: only allowed when `step ≤ currentStep` (already visited)
- `finish()`: validates all day plans, saves `WorkoutPlan`, sets `isPresentingSuccess = true`

---

## 4. Persistence

| Entity | Storage | Key |
|--------|---------|-----|
| `WorkoutPlan` | `UserDefaults` (Codable JSON) | `"bm.workoutPlan.current"` |

Only the most recent wizard-created plan is stored in this iteration. Future iterations may store a list.

---

## 5. State Transitions

```
Wizard Entry
    │
    ▼
Step 1: Select Days ──── selectedDays.isEmpty ──── [Continue disabled]
    │ selectedDays ≥ 1
    ▼
Step 2…N+1: Configure Day (one per selected day)
    │ Each day: sessionName + ≥1 valid block
    ▼
Step N+2: Review All Days
    │ allDaysValid
    ▼
Finish & Save ──→ PlanSavedView ──→ Dismiss wizard (back to Today)
    
[Cancel] at any step → Dismiss wizard (back to Today, no save)
```
