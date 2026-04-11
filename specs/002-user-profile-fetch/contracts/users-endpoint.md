# API Contract: GET /api/users

**Feature**: 002-user-profile-fetch
**Date**: 2026-04-09
**Status**: Assumed (to be confirmed with API owner)

## Endpoint

```
GET https://api.bodymetric.com.br/api/users?email={email}
```

## Request

| Parameter | Location    | Type   | Required | Description            |
|-----------|-------------|--------|----------|------------------------|
| `email`   | Query string | String | Yes      | URL-encoded user email |

**Headers**: None assumed. If auth is required, add:
```
Authorization: Bearer {google_id_token}
```

## Responses

### 200 OK — User found

```json
{
  "weight": 75.5,
  "weightUnit": "kg",
  "height": 180.0,
  "heightUnit": "cm"
}
```

| Field        | Type   | Nullable | Description               |
|--------------|--------|----------|---------------------------|
| `weight`     | Double | No       | User's body weight        |
| `weightUnit` | String | No       | Unit: "kg" or "lbs"       |
| `height`     | Double | No       | User's height             |
| `heightUnit` | String | No       | Unit: "cm" or "in"        |

**App behaviour**: Extract weight + height + units → persist to ProfileStore
→ navigate to HomeView.

### 404 Not Found — User does not exist

```json
{ "error": "user not found" }
```

**App behaviour**: Navigate to CreateUserView.

### 401 Unauthorized (contingency)

**App behaviour**: Log error, surface message "Authentication required",
do not navigate away from current screen.

### 5xx Server Error

**App behaviour**: Log error with status code, show retry message on home
screen. Do not clear existing cached data.

## Error Mapping

| HTTP Status | `ProfileFetchError` case | User-facing message                         |
|-------------|--------------------------|---------------------------------------------|
| 404         | `.userNotFound`          | (navigation to CreateUserView, no toast)    |
| 401         | `.unauthorized`          | "Authentication required. Please sign in."  |
| 5xx         | `.serverError(Int)`      | "Could not load profile. Please try again." |
| Network fail | `.networkError(Error)`  | "No connection. Please check your network." |
| Decode fail | `.decodingError`         | "Unexpected response. Please try again."    |
