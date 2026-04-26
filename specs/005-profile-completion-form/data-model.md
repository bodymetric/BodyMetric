# Data Model: Complete Missing User Profile Data

**Feature**: 005-profile-completion-form
**Date**: 2026-04-12

---

## Entities

### AuthUser *(new)*

Decoded from the `user` key in the `POST /api/auth/google` response.
Represents the backend's view of the user at login time.

| Field    | Swift Type  | JSON Key  | Notes                                 |
|----------|-------------|-----------|---------------------------------------|
| id       | Int         | `id`      | Backend user ID                       |
| name     | String?     | `name`    | nil → profile is incomplete           |
| email    | String      | `email`   | Always present; injected from auth    |
| height   | Double?     | `height`  | nil or ≤ 0 → profile is incomplete   |
| weight   | Double?     | `weight`  | nil or ≤ 0 → profile is incomplete   |

**Completeness rule**: `name != nil && !name.isEmpty && height > 0 && weight > 0`

---

### TokenExchangeResponse *(modified)*

Adds the `user` field to the existing model.

| Field        | Swift Type | JSON Key       | Change           |
|--------------|------------|----------------|------------------|
| accessToken  | String     | `sessionToken` | existing         |
| refreshToken | String     | `refreshToken` | existing         |
| user         | AuthUser   | `user`         | **new**          |

---

### UserProfile *(modified)*

Adds `name` to the existing GET-response model.

| Field       | Swift Type | JSON Key      | Change           |
|-------------|------------|---------------|------------------|
| email       | String     | injected      | existing         |
| name        | String?    | `name`        | **new**          |
| weight      | Double?    | `weight`      | existing         |
| weightUnit  | String?    | `weightUnit`  | existing         |
| height      | Double?    | `height`      | existing         |
| heightUnit  | String?    | `heightUnit`  | existing         |

---

### ProfileStore *(modified)*

Adds `name` persistence and updates `isComplete`.

| Field      | Storage Key           | Change                        |
|------------|-----------------------|-------------------------------|
| name       | `bm.profile.name`     | **new**                       |
| email      | `bm.profile.email`    | existing                      |
| weight     | `bm.profile.weight`   | existing                      |
| weightUnit | `bm.profile.weightUnit` | existing                    |
| height     | `bm.profile.height`   | existing                      |
| heightUnit | `bm.profile.heightUnit` | existing                    |

**Updated `isComplete`**: requires `name` non-empty + `height > 0` + `weight > 0`.
Unit fields (`weightUnit`, `heightUnit`) are no longer required for the completeness gate.

---

### UpdateProfileRequest *(new)*

Payload sent to `POST /api/users`.

| Field  | Swift Type | JSON Key | Validation                       |
|--------|------------|----------|----------------------------------|
| name   | String     | `name`   | non-empty, max 20 characters     |
| email  | String     | `email`  | non-empty, valid email format    |
| height | Double     | `height` | > 0                              |
| weight | Double     | `weight` | > 0                              |

---

## State Transitions

```
AuthService.signInWithGoogle()
    │
    ├─ token exchange succeeds
    │       │
    │       ├─ user.name && user.height > 0 && user.weight > 0
    │       │       → ProfileStore.save(from: user)
    │       │       → needsProfileSetup = false
    │       │       → isAuthenticated = true
    │       │       → App routes to HomeView
    │       │
    │       └─ any field missing / invalid
    │               → ProfileStore NOT saved
    │               → needsProfileSetup = true
    │               → isAuthenticated = true
    │               → App routes to UpdateProfileView
    │
    └─ token exchange fails → throw AuthError

UpdateProfileViewModel.submit()
    │
    ├─ POST /api/users → HTTP 201
    │       → decode AuthUser from response body
    │       → ProfileStore.save(from: user)
    │       → AuthService.needsProfileSetup = false
    │       → show success message
    │       → after ~4 s → App routes to HomeView
    │
    └─ non-201 / network error
            → show error message
            → restore "Update" button
            → remain on UpdateProfileView
```
