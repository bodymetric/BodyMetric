# Quickstart: Remove "Plan Another Week" Button

**Branch**: `024-remove-plan-another-week` | **Date**: 2026-05-31

## Verification Scenarios

### Scenario 1 — Success screen has no "Plan another week" button

**Setup**: Complete the new-plan wizard through to the `PlanSavedView`.

**Expected**: The screen shows the app logo badge, "PLAN SAVED" label, "Now do the work." heading, the body copy, and the single "Back to home" button. No second button is visible.

---

### Scenario 2 — "Back to home" still works

**Setup**: `PlanSavedView` is presented; user taps "Back to home".

**Expected**: The wizard is dismissed and the home screen is shown.

---

### Scenario 3 — Build passes with zero errors

`xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'` exits `BUILD SUCCEEDED`.
