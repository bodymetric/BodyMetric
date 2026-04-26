# API Endpoint Contracts

**Branch**: `001-gym-workout-tracker` | **Date**: 2026-04-04

All requests include `Authorization: Bearer <access_token>` except the auth endpoints.  
All responses are JSON. Dates are ISO 8601 strings. IDs are UUID strings.  
Base URL: configured per environment (dev / staging / prod) — not hardcoded.

---

## Authentication

### POST /auth/google

Exchange a Google `idToken` for a BodyMetric session token pair.

**Request**:
```json
{
  "idToken": "string"   // Google ID token from GIDSignIn
}
```

**Response 200**:
```json
{
  "accessToken": "string",
  "refreshToken": "string",
  "expiresIn": 3600,
  "user": { /* User object */ }
}
```

**Response 401**: Invalid or expired Google token.

---

### POST /auth/refresh

Obtain a new access token using the refresh token.

**Request**:
```json
{
  "refreshToken": "string"
}
```

**Response 200**:
```json
{
  "accessToken": "string",
  "expiresIn": 3600
}
```

**Response 401**: Refresh token expired or revoked → client must re-authenticate via Google.

---

### DELETE /auth/session

Invalidate the current session (logout).

**Response 204**: No content. Client MUST clear Keychain on receipt.

---

## User

### GET /users/me

Fetch the authenticated user's profile, including `totalPoints`, `activeProgramId`.

**Response 200**: `User` object.

---

## Workout Program

### GET /programs/{programId}

Fetch a program with its full training day and exercise tree.

**Response 200**: `WorkoutProgram` object with nested `trainingDays[].plannedExercises[].exercise`.

**Response 404**: Program not found.

---

### GET /programs/{programId}/training-days

List training days for a program (lightweight, no nested exercises).

**Response 200**:
```json
{
  "trainingDays": [ /* TrainingDay[] without plannedExercises */ ]
}
```

---

### GET /training-days/{trainingDayId}

Fetch a single training day with its full `plannedExercises` list.

**Response 200**: `TrainingDay` object with nested `plannedExercises[].exercise`.

---

## Workout Sessions

### POST /sessions

Create and start a new workout session (check-in).

**Request**:
```json
{
  "trainingDayId": "string"
}
```

**Response 201**:
```json
{
  "session": { /* WorkoutSession with status: "inProgress" */ }
}
```

**Response 409**: A session is already in progress for this user today on this training day.

---

### PATCH /sessions/{sessionId}

Update a session's status (complete or abandon).

**Request**:
```json
{
  "status": "completed" | "abandoned"
}
```

**Response 200**: Updated `WorkoutSession`. When `status = "completed"`, `pointsAwarded` and updated `streak` are included:
```json
{
  "session": { /* WorkoutSession with completedAt, pointsAwarded */ },
  "streak": { /* Streak object */ },
  "newBadges": [ /* Badge[] earned this session, may be empty */ ]
}
```

---

### POST /sessions/{sessionId}/exercise-logs

Log or update performance for an exercise within a session.

**Request**:
```json
{
  "plannedExerciseId": "string",
  "skipped": false,
  "sets": [
    { "setNumber": 1, "reps": 10, "weight": 80.0, "weightUnit": "kg" }
  ]
}
```

**Response 201**: Created `ExerciseLog` with embedded `sets`.

**Response 200**: If a log already exists for this `plannedExerciseId` in this session (upsert).

---

## Exercise History

### GET /exercises/{exerciseId}/history

Fetch the user's logged performance for an exercise across past sessions.

**Query params**:
- `limit` (int, default 30, max 100)
- `before` (ISO 8601 date, for pagination)

**Response 200**:
```json
{
  "exerciseId": "string",
  "logs": [
    {
      "sessionId": "string",
      "sessionDate": "2026-04-01T09:00:00Z",
      "sets": [ { "setNumber": 1, "reps": 10, "weight": 80.0, "weightUnit": "kg" } ]
    }
  ],
  "nextBefore": "2026-03-25T09:00:00Z" | null
}
```

---

## Gamification

### GET /users/me/streak

Fetch the authenticated user's current streak.

**Response 200**: `Streak` object.

---

### GET /badges

Fetch the full badge catalogue (earned + unearned) for the authenticated user.

**Response 200**:
```json
{
  "badges": [
    {
      "badge": { /* Badge object */ },
      "earned": true,
      "earnedAt": "2026-04-01T10:00:00Z" | null
    }
  ]
}
```

---

## Error Contract

All error responses follow:

```json
{
  "error": {
    "code": "string",       // machine-readable, e.g., "session_already_active"
    "message": "string"     // human-readable, safe to display
  }
}
```

| HTTP Status | Meaning |
|---|---|
| 400 | Validation error (malformed request body) |
| 401 | Unauthenticated (missing/expired access token) |
| 403 | Forbidden (resource belongs to another user) |
| 404 | Resource not found |
| 409 | Conflict (e.g., duplicate active session) |
| 422 | Unprocessable (request valid but business rule violation) |
| 500 | Server error — client should display generic error message |
