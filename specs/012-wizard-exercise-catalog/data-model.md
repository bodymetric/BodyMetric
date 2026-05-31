# Data Model: Wizard Step 2 — Live Exercise Catalog

**Date**: 2026-05-01

---

## 1. New response DTOs (GET /api/exercises)

### ApiExercise

| Field | Type | Description |
|-------|------|-------------|
| `id` | `Int` | Stable integer identifier (e.g., 26) — used as picker value |
| `name` | `String` | Display name (e.g., "Back Extension") — used as picker label |

**Conforms to**: `Decodable`, `Identifiable`

### ExerciseCatalogGroup

| Field | Type | Description |
|-------|------|-------------|
| `group` | `String` | Muscle group name (e.g., "back", "biceps") — used as section title |
| `exercises` | `[ApiExercise]` | Ordered list of exercises in this group |

**Conforms to**: `Decodable`, `Identifiable` (via `group`)

---

## 2. ViewModel state additions

| Property | Type | Purpose |
|----------|------|---------|
| `exerciseGroups` | `[ExerciseCatalogGroup]` | Loaded catalog; empty until first successful fetch |
| `exerciseCatalogLoadState` | `ExerciseCatalogLoadState` | Loading lifecycle |

### ExerciseCatalogLoadState

```
enum ExerciseCatalogLoadState: Equatable {
    case idle       // not yet triggered
    case loading    // request in flight
    case loaded     // exerciseGroups populated
    case failed(String)  // message for error banner
}
```

---

## 3. ExerciseBlockPlanRequest — exerciseId type change

**Before**: `let exerciseId: String`  
**After**: `let exerciseId: Int`

```swift
init(block: ExerciseBlock) {
    self.exerciseId = Int(block.exerciseId) ?? 0
    ...
}
```

---

## 4. ViewModel helper

```swift
func exerciseName(for exerciseId: String) -> String? {
    guard let id = Int(exerciseId) else { return nil }
    return exerciseGroups
        .flatMap(\.exercises)
        .first { $0.id == id }?
        .name
}
```

---

## 5. Load state flow

```
idle → (ConfigureDayStepView .task fires) → loading
loading → 200 OK → loaded (exerciseGroups populated)
loading → error → failed(message)
failed → user taps Retry → loading (exerciseGroups cleared)
loaded → subsequent ConfigureDayStepView appearances → idle guard prevents re-fetch
```
