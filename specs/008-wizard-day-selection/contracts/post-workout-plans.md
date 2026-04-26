# Contract: POST /api/workout-plans

**Feature**: `008-wizard-day-selection`  
**Endpoint**: `POST https://api.bodymetric.com.br/api/workout-plans`  
**Purpose**: Save (replace-all) the user's weekly training day selections.

## Semantics

This is a **replace-all upsert**. The server deletes all existing workout-plan records for the authenticated user, then inserts the submitted array as the new set. The mobile app sends the complete current selection in every POST.

## Request

```
POST /api/workout-plans
Authorization: Bearer <access_token>
Content-Type: application/json

[
  {
    "plannedWeekNumber": "1",
    "plannedDayOfWeek": "monday"
  },
  {
    "plannedWeekNumber": "7",
    "plannedDayOfWeek": "sunday"
  }
]
```

**Important**: `plannedWeekNumber` is serialised as a **JSON string** (`"1"`, `"7"`), not an integer. This differs from the GET response where it is an integer.

### Request body schema

| Field | Type | Value range | Example |
|-------|------|-------------|---------|
| `plannedWeekNumber` | String | `"1"` to `"7"` | `"1"` = Monday, `"7"` = Sunday |
| `plannedDayOfWeek` | String | `"monday"` … `"sunday"` | `"monday"` |

### Full week number → day name mapping

| `plannedWeekNumber` | `plannedDayOfWeek` |
|--------------------|--------------------|
| `"1"` | `"monday"` |
| `"2"` | `"tuesday"` |
| `"3"` | `"wednesday"` |
| `"4"` | `"thursday"` |
| `"5"` | `"friday"` |
| `"6"` | `"saturday"` |
| `"7"` | `"sunday"` |

## Success Response — 201 Created

The server returns 201 when all records were inserted successfully. Response body content is not consumed by the app; only the status code matters.

## Error Responses

| Status | Meaning | App behaviour |
|--------|---------|---------------|
| 401 | Token invalid | `NetworkClient` retries once with refreshed token; if still 401 → user signed out |
| 400 | Invalid request body | Save fails; inline error banner shown |
| 500+ | Server error | Save fails; inline error banner shown |
| Any non-201 | Unexpected | Save fails; inline error banner shown |

## Mobile app response handling

| Response | Action |
|----------|--------|
| 201 | Dismiss error banner (if any); advance wizard to step 2 |
| Any other | Set `saveErrorMessage`; show inline error banner; keep user on screen |
