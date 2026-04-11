# Data Model: User Profile Fetch & Display

**Feature**: 002-user-profile-fetch
**Date**: 2026-04-09

## Entities

### UserProfile

Represents the user's physical metrics as returned by the BodyMetric API and
persisted locally.

| Field       | Type   | Source  | Notes                                        |
|-------------|--------|---------|----------------------------------------------|
| email       | String | Google  | Unique identifier; stored in UserDefaults    |
| weight      | Double | API     | Numeric value; nil if not yet fetched        |
| weightUnit  | String | API     | e.g., "kg" or "lbs"; nil if not yet fetched |
| height      | Double | API     | Numeric value; nil if not yet fetched        |
| heightUnit  | String | API     | e.g., "cm" or "in"; nil if not yet fetched  |

**Validation rules**:
- `email` MUST be non-empty; sourced from `GIDGoogleUser.profile?.email`.
- `weight` and `height` MUST be positive numbers; if the API returns 0 or
  negative, treat as invalid and log a warning.
- `weightUnit` and `heightUnit` default to `"kg"` and `"cm"` if absent from
  the API response.

**State transitions**:
```
[Not fetched]
     │  sign-in or restored session + incomplete cache
     ▼
[Fetching]  ──── 404 ────▶  [Not Found → CreateUser screen]
     │
     │ 200
     ▼
[Loaded]  ──── app relaunch with complete cache ────▶  [Loaded (cached)]
     │
     │ error
     ▼
[Error]  (email still visible; weight/height show placeholder)
```

## Storage Layout (UserDefaults)

| Key                   | Value Type | Description              |
|-----------------------|------------|--------------------------|
| `bm.profile.email`    | String     | Authenticated user email |
| `bm.profile.weight`   | Double     | Last fetched weight      |
| `bm.profile.weightUnit` | String   | Weight unit string       |
| `bm.profile.height`   | Double     | Last fetched height      |
| `bm.profile.heightUnit` | String   | Height unit string       |

**Completeness check**: `ProfileStore.isComplete` returns `true` when weight,
weightUnit, height, and heightUnit are all non-nil and non-empty (email is
always present once authenticated).

## API Decoding Contract

```swift
// Decodable representation of GET /api/users?email= response (200)
struct UserProfileResponse: Decodable {
    let weight: Double?
    let weightUnit: String?
    let height: Double?
    let heightUnit: String?
}
```

All fields are optional at the decode layer to prevent a crash if the API
schema changes. Missing fields are logged as warnings and treated as an
incomplete profile (triggers re-fetch on next launch).
