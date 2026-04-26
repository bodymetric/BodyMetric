# Data Model: Gym Workout Tracker with Gamification

**Branch**: `001-gym-workout-tracker` | **Date**: 2026-04-04

All entities are decoded from the REST API as Swift `Codable` structs. Local caching (read-only) via SwiftData is noted where applicable. No entity is stored exclusively on device; the API is the source of truth.

---

## Entity Map

```
User ──────────────── has one ──────────────── WorkoutProgram
  │                                                 │
  │                                         has many TrainingDay
  │                                                 │
  │                                         has many PlannedExercise
  │                                                 │
  │                                         references Exercise
  │
  ├── has many ──── WorkoutSession
  │                     │
  │                 has many ──── ExerciseLog
  │                                   │
  │                               has many ──── ExerciseSet
  │
  ├── has one ────── Streak
  └── has many ───── UserBadge ──── references ──── Badge
```

---

## Entities

### User

Represents the authenticated person using the app.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `id` | `String` (UUID) | Required, unique | Server-generated |
| `email` | `String` | Required, valid email format | From Google account; never logged (PII) |
| `displayName` | `String` | Required, non-empty | From Google account |
| `avatarURL` | `URL?` | Optional | Google profile photo; display only |
| `weightUnit` | `WeightUnit` (enum: `kg`, `lbs`) | Required, default `kg` | Set once at onboarding |
| `activeProgramId` | `String?` (UUID) | Optional | Null if no program assigned |
| `totalPoints` | `Int` | Required, ≥ 0 | Cumulative gamification score |
| `createdAt` | `Date` | Required | ISO 8601 |

**State transitions**: A user without `activeProgramId` cannot initiate a check-in.

---

### WorkoutProgram

A curated multi-week training plan.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `id` | `String` (UUID) | Required, unique | |
| `name` | `String` | Required, non-empty | e.g., "Hypertrophy Block A" |
| `description` | `String` | Required | Brief program overview |
| `weekCount` | `Int` | Required, ≥ 1 | Total program duration |
| `trainingDays` | `[TrainingDay]` | Required, ≥ 1 | Ordered by day-of-week |
| `createdAt` | `Date` | Required | |

---

### TrainingDay

A single scheduled training day within a program.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `id` | `String` (UUID) | Required, unique | |
| `programId` | `String` | Required | FK → WorkoutProgram |
| `dayOfWeek` | `DayOfWeek` (enum: Mon–Sun) | Required | Which day this targets |
| `label` | `String` | Required | e.g., "Chest & Triceps" |
| `muscleGroups` | `[String]` | Required, ≥ 1 | e.g., `["chest", "triceps"]` |
| `plannedExercises` | `[PlannedExercise]` | Required, ≥ 1 | Ordered sequence |
| `isRestDay` | `Bool` | Required, default `false` | Rest days don't break streaks |

---

### Exercise

A reusable movement definition (shared across programs).

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `id` | `String` (UUID) | Required, unique | |
| `name` | `String` | Required, non-empty | e.g., "Barbell Bench Press" |
| `primaryMuscle` | `String` | Required | e.g., "chest" |
| `secondaryMuscles` | `[String]` | Optional | |
| `instructions` | `String` | Required | Plain-language cue text |
| `videoURL` | `URL?` | Optional | Demonstration video |

---

### PlannedExercise

The instance of an exercise within a specific training day, with targets.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `id` | `String` (UUID) | Required, unique | |
| `trainingDayId` | `String` | Required | FK → TrainingDay |
| `exerciseId` | `String` | Required | FK → Exercise |
| `exercise` | `Exercise` | Required (embedded) | Denormalised for display |
| `order` | `Int` | Required, ≥ 0 | Display order within the day |
| `targetSets` | `Int` | Required, 1–10 | |
| `targetRepsMin` | `Int` | Required, 1–100 | Lower bound of rep range |
| `targetRepsMax` | `Int` | Required, ≥ targetRepsMin | Upper bound of rep range |
| `restSeconds` | `Int?` | Optional | Recommended rest interval |
| `notes` | `String?` | Optional | Coaching cues |

---

### WorkoutSession

A single gym visit / workout execution record.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `id` | `String` (UUID) | Required, unique | |
| `userId` | `String` | Required | FK → User |
| `trainingDayId` | `String` | Required | FK → TrainingDay |
| `status` | `SessionStatus` (enum) | Required | `inProgress`, `completed`, `abandoned` |
| `startedAt` | `Date` | Required | Check-in timestamp |
| `completedAt` | `Date?` | Present when `status == .completed` | |
| `exerciseLogs` | `[ExerciseLog]` | Required, may be empty during session | |
| `pointsAwarded` | `Int?` | Present when `status == .completed` | |

**State transitions**:
```
[none] → inProgress (on check-in)
inProgress → completed (user taps "Finish Workout")
inProgress → abandoned (user cancels with no sets logged)
```

---

### ExerciseLog

The user's performance record for one exercise within a session.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `id` | `String` (UUID) | Required, unique | |
| `sessionId` | `String` | Required | FK → WorkoutSession |
| `plannedExerciseId` | `String` | Required | FK → PlannedExercise |
| `exerciseId` | `String` | Required | FK → Exercise (for history queries) |
| `skipped` | `Bool` | Required, default `false` | If `true`, sets may be empty |
| `sets` | `[ExerciseSet]` | Required, may be empty | |

---

### ExerciseSet

A single logged effort within an exercise log.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `id` | `String` (UUID) | Required, unique | |
| `exerciseLogId` | `String` | Required | FK → ExerciseLog |
| `setNumber` | `Int` | Required, ≥ 1 | 1-indexed within the log |
| `reps` | `Int` | Required, 1–999 | |
| `weight` | `Double` | Required, ≥ 0 | In user's preferred unit |
| `weightUnit` | `WeightUnit` | Required | Matches User.weightUnit at time of logging |
| `completedAt` | `Date` | Required | |

**Validation rules**:
- `weight == 0` is valid (bodyweight exercise).
- `weight > 500 kg` or `weight > 1100 lbs` triggers a client-side warning prompt before saving ("Is this weight correct?"). Not blocked.
- `reps == 0` is not permitted (minimum 1).

---

### Badge

An achievement definition (catalogue, server-managed).

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `id` | `String` (UUID) | Required, unique | |
| `name` | `String` | Required | e.g., "First Rep" |
| `description` | `String` | Required | What earned this badge |
| `iconName` | `String` | Required | SF Symbol name (grayscale-safe) |
| `unlockCondition` | `BadgeCondition` | Required | Structured condition (see below) |

**BadgeCondition** (discriminated union encoded as JSON):
```
type: "session_count"   → { count: Int }
type: "streak_days"     → { days: Int }
type: "total_points"    → { points: Int }
type: "exercise_pr"     → { exerciseId: String }
```

---

### UserBadge

The join record indicating a user has earned a badge.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `id` | `String` (UUID) | Required, unique | |
| `userId` | `String` | Required | FK → User |
| `badgeId` | `String` | Required | FK → Badge |
| `badge` | `Badge` | Required (embedded) | |
| `earnedAt` | `Date` | Required | |

---

### Streak

The user's consecutive training day record.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `id` | `String` (UUID) | Required, unique | |
| `userId` | `String` | Required | FK → User |
| `currentCount` | `Int` | Required, ≥ 0 | Resets to 0 on missed scheduled day |
| `longestCount` | `Int` | Required, ≥ 0 | All-time record |
| `lastCompletedDate` | `Date?` | Present after first workout | |

**Streak rules** (enforced server-side, displayed client-side):
- Completing a session on a scheduled training day increments `currentCount`.
- Rest days (TrainingDay.isRestDay = true) do NOT break the streak.
- Missing a scheduled training day resets `currentCount` to 0.
- `longestCount` is only updated if `currentCount` exceeds it.

---

## Local Keychain Storage

Two Keychain items only (not entities, not Codable):

| Keychain Key | Value | Access Level |
|---|---|---|
| `"bodymetric.access_token"` | JWT string | `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` |
| `"bodymetric.refresh_token"` | Opaque string | `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` |

Both items have `kSecAttrSynchronizable = false` (no iCloud Keychain sync).

---

## SwiftData Cache Scope

Read-only local cache to reduce network round-trips and support fast UI rendering:

| Cached Entity | Eviction | Notes |
|---|---|---|
| `WorkoutProgram` + `TrainingDay` + `PlannedExercise` | On program change or app logout | Program data changes rarely |
| Current `WorkoutSession` (in-progress) | On session completion or app termination | Prevents data loss on crash mid-session |
| Recent `ExerciseLog` history (last 30 sessions per exercise) | 7-day TTL | Powers history screen without network |

All cache reads are validated against ETag / last-modified headers from the API; stale cache triggers a background refresh.
