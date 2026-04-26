# Research: User Profile Fetch & Display

**Feature**: 002-user-profile-fetch
**Date**: 2026-04-09

## R1 — API Authorization

**Decision**: Treat the endpoint as public (no Authorization header) for the
initial implementation.
**Rationale**: The spec does not mention tokens. The endpoint is a read-only
lookup by email, which is common for lightweight profile APIs.
**Alternative rejected**: Sending the Google `idToken` as a Bearer token —
rejected because the spec does not specify it and adding unconfirmed auth
behavior would break the API call silently.
**Follow-up**: If the endpoint returns 401, `UserProfileService` surfaces
`.unauthorized` and the caller must re-authenticate. Confirm with API owner
before release.

## R2 — API Response Shape

**Decision**: Decode the following assumed JSON structure. If fields differ,
update `UserProfile` and `contracts/users-endpoint.md`.
```json
{
  "weight": 75.5,
  "weightUnit": "kg",
  "height": 180.0,
  "heightUnit": "cm"
}
```
**Rationale**: Weight and height with units are the only fields mentioned in
the spec. Additional fields are ignored by the decoder.
**Alternative rejected**: Parsing a flat number without units — rejected because
the display requirement ("with unit") demands the unit string.

## R3 — Create User Screen Scope

**Decision**: `CreateUserView` is a static placeholder screen for this feature.
It shows a message ("Your profile was not found. Please contact support or
create your account.") with no interactive form.
**Rationale**: The spec requires navigation to a "create user" flow on 404,
but does not specify the creation form. Building an empty placeholder satisfies
the navigation requirement without scope creep.
**Alternative rejected**: Full user-creation form — out of scope for this
feature; requires a separate spec.

## R4 — Email Storage Strategy

**Decision**: Store email in `UserDefaults` under the key `bm.profile.email`.
Weight and height also in `UserDefaults` under `bm.profile.weight`,
`bm.profile.height`, `bm.profile.weightUnit`, `bm.profile.heightUnit`.
**Rationale**: Email, weight, and height are display values only. They are not
auth credentials. Keychain is reserved for tokens (Google `idToken`,
`accessToken`). `UserDefaults` is appropriate and simpler.
**Alternative rejected**: Keychain for all profile data — overkill for
non-credential data; complicates unit testing.

## R5 — Fetch Trigger Architecture

**Decision**: `HomeViewModel` owns the fetch-or-cache decision.
- On `init`, it reads `ProfileStore.isComplete`.
- If complete: present cached data immediately (no network call).
- If incomplete: call `UserProfileService.fetchProfile(email:)`.
  - 200 → update `ProfileStore`, update published properties.
  - 404 → set `navigationState = .createUser`.
  - Error → set `errorMessage`, keep cached email visible.
**Rationale**: Centralises the decision in one testable object. `BodyMetricApp`
creates `HomeViewModel` only after `isAuthenticated == true`.
**Alternative rejected**: Putting the fetch logic in `BodyMetricApp` — untestable
and violates separation of concerns.

## URLSession Best Practices (iOS 17+)

- Use `URLSession.shared.data(for:)` with `async/await`.
- Decode with `JSONDecoder()` and `CodingKeys` for resilience to extra fields.
- Set `timeoutIntervalForRequest = 10` seconds.
- Log response status code at INFO level; log body only at DEBUG (never PII).
- All network errors mapped to typed `ProfileFetchError` enum before
  propagating to the ViewModel.
