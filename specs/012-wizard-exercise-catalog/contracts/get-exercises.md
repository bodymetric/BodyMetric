# Contract: GET /api/exercises

**Endpoint**: `GET https://api.bodymetric.com.br/api/exercises`  
**Purpose**: Returns the complete exercise catalogue grouped by muscle.

## Request

```
GET /api/exercises
Authorization: Bearer <access_token>
```

No query parameters.

## Success Response — 200 OK

```json
[
  {
    "group": "back",
    "exercises": [
      { "id": 26, "name": "Back Extension" },
      { "id": 17, "name": "Barbell Row" }
    ]
  },
  {
    "group": "biceps",
    "exercises": [
      { "id": 56, "name": "Barbell Curl" }
    ]
  }
]
```

## Mobile response handling

| Response | Action |
|----------|--------|
| 200 | Decode `[ExerciseCatalogGroup]`, set `exerciseCatalogLoadState = .loaded` |
| Any non-200 | Set `exerciseCatalogLoadState = .failed(message)` |
| Network error | Set `exerciseCatalogLoadState = .failed(message)` |
