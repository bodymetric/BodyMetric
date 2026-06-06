# API Contract: GET /api/home

**Feature**: 022-home-refresh-post-workout
**Endpoint**: `GET https://api.bodymetric.com.br/api/home`
**Auth**: Bearer token required (`Authorization: Bearer <id_token>` — injected by `NetworkClient`)
**Trigger**: (1) Home screen initial load; (2) after workout completion

---

## Request

### Query Parameters

| Parameter | Type | Required | Notes |
|-----------|------|----------|-------|
| currentDayOfWeek | String | yes | Uppercase English weekday: `MONDAY` `TUESDAY` `WEDNESDAY` `THURSDAY` `FRIDAY` `SATURDAY` `SUNDAY` |

**Example**: `GET https://api.bodymetric.com.br/api/home?currentDayOfWeek=MONDAY`

The parameter value is computed at request time from the device calendar:
```swift
DateFormatter("EEEE", locale: en_US).string(from: Date()).uppercased()
```

---

## Response

### Success

| Status | Body | Meaning |
|--------|------|---------|
| 200 OK | `HomeScreenData` JSON | Home data for the specified day |
| 400 Bad Request | any | Treated as empty — `HomeScreenData(nil, nil)` |
| 404 Not Found | any | Treated as empty — `HomeScreenData(nil, nil)` |

### Errors

| Status | Client behaviour |
|--------|-----------------|
| 5xx | `TodayViewModel.loadState = .failed(message)`; error banner shown |
| Network failure | Same as 5xx |

---

## Client Model

```swift
// Models/HomeMenuModels.swift (existing)
struct HomeScreenData: Decodable, Equatable {
    let currentWorkoutDayPlan: WorkoutDayPlanSummary?
    let exercisesForToday: [TodayExercise]?
}
```

No response model changes for this feature.
