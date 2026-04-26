# Quickstart: Complete Missing User Profile Data

**Feature**: 005-profile-completion-form
**Date**: 2026-04-12

---

## Scenario 1 — Incomplete profile at login (happy path)

**Setup**: Mock `POST /api/auth/google` to return a user with `name: nil`.
Mock `POST /api/users` to return HTTP 201 with a complete user body.

**Steps**:
1. Launch app → tap "Sign in with Google" → complete OAuth sheet
2. `AuthService.signInWithGoogle()` receives token exchange response: `user.name == nil`
3. `AuthService.needsProfileSetup` is set to `true`
4. App renders `UpdateProfileView` (email pre-filled, read-only)
5. User fills in name (≤ 20 chars), height, weight → taps "Update"
6. Button shows loading indicator; is disabled
7. `UpdateProfileViewModel` sends `POST /api/users`
8. Backend returns 201 with complete user body
9. `ProfileStore` is updated with name + height + weight
10. `AuthService.needsProfileSetup = false`
11. Success message displayed
12. After ~4 seconds, `HomeView` is shown with the profile data

**Expected state after**:
- `ProfileStore.name` == submitted name
- `ProfileStore.height` == submitted height
- `ProfileStore.weight` == submitted weight
- `AuthService.needsProfileSetup == false`
- `HomeView` is active

---

## Scenario 2 — Complete profile at login (bypass gate)

**Setup**: Mock `POST /api/auth/google` to return a user with `name`, `height`, `weight` all present.

**Steps**:
1. Launch app → tap "Sign in with Google" → complete OAuth sheet
2. `AuthService.signInWithGoogle()` detects all three fields present
3. `ProfileStore.save(from: user)` called immediately
4. `AuthService.needsProfileSetup = false`
5. `HomeView` shown directly — `UpdateProfileView` never appears

**Expected state after**:
- `ProfileStore.isComplete == true`
- `HomeView` is active immediately after authentication

---

## Scenario 3 — Backend error on submission

**Setup**: Mock `POST /api/auth/google` with incomplete user. Mock `POST /api/users` to return HTTP 422.

**Steps**:
1. Sign in → `UpdateProfileView` shown
2. Fill all fields → tap "Update"
3. Loading indicator appears; button is disabled
4. Backend returns 422
5. Loading indicator removed; "Update" label restored on button
6. Error message shown on form
7. User corrects form → taps "Update" again → new attempt succeeds (mock returns 201)

**Expected state after error**:
- User remains on `UpdateProfileView`
- `ProfileStore` was NOT saved
- `AuthService.needsProfileSetup` is still `true`

---

## Scenario 4 — Client-side validation blocks submission

**Setup**: `UpdateProfileView` open with empty name field.

**Steps**:
1. Leave name empty; fill height = 182.0, weight = 82.0
2. Tap "Update"
3. Inline validation error shown for name; no network request made
4. Fill name (> 20 chars) → tap "Update"
5. Validation error for name length; no network request
6. Fix name → tap "Update" → submission proceeds

**Expected state**:
- `callCount` on `MockUpdateProfileService` == 0 after failed validation
- `callCount` == 1 after valid submission

---

## Scenario 5 — App restarted with incomplete profile in storage

**Setup**: `ProfileStore` has name == nil; Keychain has valid refresh token.

**Steps**:
1. App cold-launches
2. `AuthService.restorePreviousSignIn()` succeeds (Google session + Keychain token present)
3. `ProfileStore.isComplete == false` → `AuthService.needsProfileSetup = true`
4. App shows `UpdateProfileView` instead of `HomeView`
5. User completes form → navigates to home

**Expected state after**:
- `ProfileStore.isComplete == true`
- `HomeView` active

---

## Scenario 6 — Submission disabled while in-flight

**Setup**: `POST /api/users` has artificial delay (0.5 s).

**Steps**:
1. Fill form → tap "Update"
2. Button becomes disabled (loading state)
3. Tap "Update" again while loading → tap is ignored
4. Request completes (201) → navigate to home

**Expected state**:
- `UpdateProfileService.callCount == 1` (only one request sent)
