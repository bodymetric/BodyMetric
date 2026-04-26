# Contract: Update User Profile

**Endpoint**: `POST /api/users`
**Auth**: Required — `Authorization: Bearer <access-token>` header (injected by `NetworkClient`)
**Feature**: 005-profile-completion-form

---

## Request

**Method**: POST
**Path**: `/api/users`

### Headers

| Header        | Value                      | Required |
|---------------|----------------------------|----------|
| Content-Type  | `application/json`         | Yes      |
| Authorization | `Bearer <access-token>`    | Yes      |

### Body

```json
{
  "name":   "string, required, max 20 characters",
  "email":  "string, required, valid email",
  "height": "positive number (decimal)",
  "weight": "positive number (decimal)"
}
```

### Validation (client-side, enforced before sending)

| Field  | Rule                             | Error message                          |
|--------|----------------------------------|----------------------------------------|
| name   | Non-empty, ≤ 20 characters       | "Name is required (max 20 characters)" |
| email  | Non-empty, valid email format    | "Valid email is required"              |
| height | Numeric, > 0                     | "Height must be a positive number"     |
| weight | Numeric, > 0                     | "Weight must be a positive number"     |

---

## Response

### Success — HTTP 201

```json
{
  "id":     5,
  "name":   "string",
  "email":  "string",
  "height": 182.0,
  "weight": 82.0
}
```

**App behaviour on 201**:
1. Decode response as `AuthUser`
2. `ProfileStore.save(from: user)` — persists all fields
3. `AuthService.needsProfileSetup = false`
4. Show success message
5. After ~4 seconds, navigate to `HomeView`

### Failure — non-201

Any status code other than 201 is treated as a failure:

| Status | Meaning             | App behaviour                                    |
|--------|---------------------|--------------------------------------------------|
| 400    | Validation rejected | Show error message; stay on form; restore button |
| 401    | Unauthorized        | Token refresh handled by `NetworkClient`; if refresh fails, force logout |
| 409    | Conflict            | Show error message; stay on form                 |
| 5xx    | Server error        | Show error message; stay on form                 |
| timeout / network | N/A      | Show error message; stay on form                 |

---

## Test Contract

### Happy path

```
Given: User is authenticated, form fields are valid
When: POST /api/users → 201 with user body
Then: ProfileStore has name + height + weight
      AuthService.needsProfileSetup == false
      Success message shown
      HomeView shown after ~4 s
```

### Validation blocked

```
Given: Name field is empty
When: User taps "Update"
Then: POST is NOT sent
      Inline validation error shown for name
```

### Server error

```
Given: All fields are valid
When: POST /api/users → 422
Then: POST was sent once
      Error message shown
      "Update" button label restored
      User stays on form
```

### Concurrent submission guard

```
Given: Request is in-flight
When: User taps "Update" again
Then: Button is disabled; no second request is sent
```
