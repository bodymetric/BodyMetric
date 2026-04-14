# Research: Complete Missing User Profile Data

**Feature**: 005-profile-completion-form
**Date**: 2026-04-12

---

## Decision 1: Where to detect profile incompleteness

**Decision**: Check profile completeness at auth time using the `user` object already embedded in the `POST /api/auth/google` response.

**Rationale**: The backend already returns `{sessionToken, refreshToken, user}` in the token exchange response. Parsing completeness from this object requires zero additional network calls. Making a separate `GET /api/users` call purely to detect incompleteness would be wasteful and would delay the UX gate.

**Alternatives considered**:
- Check in `HomeViewModel.loadProfile()` after `GET /api/users` — rejected because it incurs an unnecessary network round-trip before the user can even see the loading indicator for the form.
- Check in `BodyMetricApp` on every render — rejected because this would be a polling anti-pattern.

---

## Decision 2: What signals an incomplete profile

**Decision**: A profile is incomplete when any of `name`, `height`, or `weight` is nil, empty string, or `≤ 0`. All three must be present and valid for the profile to be considered complete.

**Rationale**: The spec explicitly names these three fields as the gate. Unit fields (`weightUnit`, `heightUnit`) are omitted — they are display concerns and not required for backend acceptance.

**Alternatives considered**:
- Check only `name` (height/weight already present from fitness tracking) — rejected; spec is explicit about all three.

---

## Decision 3: ProfileStore completeness definition

**Decision**: Update `ProfileStore.isComplete` to require `name` (non-empty), `height > 0`, and `weight > 0`. Remove the `weightUnit`/`heightUnit` requirement from the gate (they remain stored and displayed but do not block navigation).

**Rationale**: The backend `POST /api/users` accepts `name`, `email`, `height`, `weight` — no units. Units are supplemental display data returned from `GET /api/users` and populated later by `HomeViewModel`. Gating on units would cause false "incomplete" states after fresh sign-in.

---

## Decision 4: Navigation ownership

**Decision**: `AuthService` exposes `needsProfileSetup: Bool`. After a successful token exchange, `AuthService` checks the embedded user for completeness and sets this flag. `BodyMetricApp.authenticatedContainer` reads it to decide whether to show `UpdateProfileView` or `HomeView`.

**Rationale**: The `AuthService` already owns the token exchange lifecycle. Placing the flag there keeps the navigation decision at the outermost composition layer (`BodyMetricApp`) rather than inside `HomeViewModel`, which should remain focused on the home screen data.

**Alternatives considered**:
- Add new navigation case to `HomeViewModel` — rejected because `HomeViewModel` would then need to be instantiated before we know whether to show home at all.
- Pass the flag via a shared `AppState` observable — over-engineering for a two-state boolean.

---

## Decision 5: What happens on app restart with an incomplete profile

**Decision**: `AuthService.restorePreviousSignIn()` will check `ProfileStore.isComplete` after restoring the Google session. If the profile is still incomplete, it sets `needsProfileSetup = true` so the gate is re-applied.

**Rationale**: A user who quit the app mid-form should be returned to the form, not to the home screen with broken data.

---

## Decision 6: POST /api/users response on success

**Decision**: Expect HTTP 201 with a user body identical in structure to the auth response `user` object. After 201, decode the returned user, persist it to `ProfileStore`, set `needsProfileSetup = false`.

**Rationale**: The backend pattern (same user structure in auth + profile endpoints) is consistent with the token exchange response observed in production. Decoding the 201 body means we persist the canonical server-side representation.

**Fallback**: If 201 body is empty or unparseable, construct a `UserProfile` from the form fields directly and persist that. This ensures the user reaches home even on a partial backend response.

---

## Decision 7: CreateUserView replacement

**Decision**: Replace `Features/CreateUser/Views/CreateUserView.swift` (current placeholder stub) with the real `UpdateProfileView`. The `HomeViewModel.navigationState == .createUser` case continues to route to this view for both the 404 case and the incomplete-profile gate. Both cases submit to `POST /api/users`.

**Rationale**: The form is identical in both cases. A unified implementation avoids duplication. The feature branch owns the implementation of `CreateUserView` as a real form rather than creating a parallel feature folder.

---

## Decision 8: AuthUser model

**Decision**: Introduce a new `AuthUser` struct decoded from the `user` key in `TokenExchangeResponse`. Fields: `id: Int`, `name: String?`, `email: String`, `height: Double?`, `weight: Double?`. This is a distinct type from `UserProfile` (which represents the `GET /api/users` response with unit strings).

**Rationale**: The two response schemas differ — `AuthUser` has `name` and no unit strings; `UserProfile` has unit strings and no `name`. Separate types prevent field-conflation bugs and keep `CodingKeys` clean.
