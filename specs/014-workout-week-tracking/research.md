# Research: Automated Training Week Tracking

**Date**: 2026-05-02

---

## 1. This is a server-side feature

**Decision**: The mobile app only removes `plannedWeekNumber` from payloads and adds `actualWeekNumber` consumption. All cycle-completion detection and week-increment logic runs on the server.

**Rationale**: The spec explicitly states: "The server is responsible for all training week tracking logic; the mobile app only reads `actualWeekNumber` from the server response and removes `plannedWeekNumber` from all outgoing requests." (spec Assumptions)

---

## 2. plannedWeekNumber is already unused in app logic

**Decision**: Simply remove `plannedWeekNumber` from both request and response models. No logic changes needed.

**Rationale**: Since feature 008, all day identification uses `plannedDayOfWeek` ("MONDAY" etc.) via `DayOfWeek.init?(fromApiString:)`. The `plannedWeekNumber` field in `WorkoutPlanDayResponse` is decoded but never read. Removing it has zero functional impact.

---

## 3. actualWeekNumber added as optional field

**Decision**: Add `actualWeekNumber: Int?` as an optional field to `WorkoutPlanDayResponse`. Optional so existing tests and pre-feature server responses decode without error.

**Rationale**: The server will start returning `actualWeekNumber` when it implements the backend logic. Making it optional means the app decodes cleanly both before and after the server upgrade.

---

## 4. WorkoutPlanDayRequest simplified

**Decision**: Remove `plannedWeekNumber: String` from `WorkoutPlanDayRequest`. The POST body now only contains `plannedDayOfWeek: String`.

**Rationale**: The server no longer expects `plannedWeekNumber` in the request — it derives the day identifier from `plannedDayOfWeek` alone.

---

## 5. DayOfWeek.toRequest simplified

**Decision**: Remove `plannedWeekNumber: String(rawValue)` from `DayOfWeek.toRequest`. The computed property only sets `plannedDayOfWeek: fullLabel.lowercased()`.

---

## 6. actualWeekNumber display — deferred

**Decision**: Display of `actualWeekNumber` in the UI is deferred to a future feature once the server implements the backend. The model change (optional field) is the only app change in this feature.

**Rationale**: The server-side implementation is not complete yet. Updating the model now ensures the app is ready when the server ships.
