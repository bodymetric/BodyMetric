# Research: New Plan Wizard — Day Selection API

**Feature**: `008-wizard-day-selection`  
**Date**: 2026-04-26

## 1. POST semantics: replace-all (upsert)

**Decision**: The POST `/api/workout-plans` is a full replace-all. The app sends every selected day in one request. The server deletes any existing records for the user, then inserts the new set atomically. The client does not need to call a DELETE endpoint or track prior state.

**Rationale**: Confirmed by the user: "Forget this. This will be developed by my API, so just invoke POST with the correct JSON." The client contract is simple — POST the complete array.

**Alternatives considered**:
- Client-side delete-then-insert — rejected by user; handled server-side.
- PATCH/partial update — not offered by the endpoint; server always replaces all.

---

## 2. plannedWeekNumber type in POST body

**Decision**: Send `plannedWeekNumber` as a **String** in the POST request body (e.g., `"1"`, `"7"`). `plannedDayOfWeek` is also a String (e.g., `"monday"`).

**Rationale**: The user's POST body example explicitly shows `"plannedWeekNumber": "1"` (quoted, i.e., a JSON string). The GET response returns it as an Int (`7`). The client must serialize it as a String for POST. Two separate Codable types are needed: a response DTO (Int for weekNumber) and a request DTO (String for weekNumber).

**Alternatives considered**:
- Use Int for both — rejected; the user's example is unambiguous about the POST using String.

---

## 3. Service layer placement

**Decision**: New `WorkoutPlanService` + protocol placed at `Services/WorkoutPlan/` (project root level), following the existing `Services/Profile/UserProfileService.swift` pattern.

**Rationale**: The project has two Services directories. The inner `BodyMetric/Services/` is file-system-synchronized (auto-includes all files) and is used for transport-layer concerns (Network, Keychain, Token). The outer `Services/` at project root is for domain services (Profile, Storage, Auth). The new `WorkoutPlanService` is a domain service and belongs in the outer location.

**Alternatives considered**:
- Put in inner `BodyMetric/Services/` — rejected; that folder is for transport/infra, not domain logic.

---

## 4. ViewModel load/save state machine

**Decision**: Add two async methods to `NewPlanViewModel` — `loadDays(using:)` and `saveDays(using:)` — plus a `SelectDaysLoadState` enum (`idle | loading | loaded | empty | failed(String)`). A separate `isSaving: Bool` flag gates the Continue button.

**Rationale**: The existing `NewPlanViewModel` already owns `selectedDays` and `dayPlans`. Extending it with load/save state keeps the wizard's single source of truth. Two methods (one for GET, one for POST) map cleanly onto the two API calls and make unit testing straightforward.

**Alternatives considered**:
- Separate `SelectDaysViewModel` — rejected; adds a second ViewModel that must be kept in sync with the existing wizard state.
- Pull GET response directly into the View — rejected; business logic must not live in views (testability + Principle II).

---

## 5. Error display

**Decision**: An inline error banner below the day list in `SelectDaysStepView`, using `GrayscalePalette.primary` text + warning SF Symbol. No modal, no sheet. Dismissed when the user changes the selection.

**Rationale**: The spec says "user-friendly error message on the same screen." An inline banner is the least disruptive pattern for a single recoverable error. The error is non-blocking — the user can re-tap Continue without navigating away.

**Alternatives considered**:
- Alert/sheet — rejected; interrupts user flow for a recoverable error.
- Toast — not in the existing design system; would require new infrastructure.

---

## 6. 404 handling on GET

**Decision**: A 404 from `GET /api/workout-plans` is treated as a successful empty state — `loadState = .empty` — and the screen shows all days unchecked. No error banner is displayed.

**Rationale**: Per spec FR-004 and the user description: "If this request returns 404 it means the user has never saved this step on wizard so you have to show an empty form." This is not an error; it is a normal first-time-user state.

**Alternatives considered**:
- Show error on 404 — rejected; spec explicitly says 404 = empty form, not error.

---

## All NEEDS CLARIFICATION Items

None — all questions resolved via the research above.
