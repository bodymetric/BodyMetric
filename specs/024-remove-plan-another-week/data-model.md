# Data Model: Remove "Plan Another Week" Button

**Branch**: `024-remove-plan-another-week` | **Date**: 2026-05-31

## No Model Changes

This change involves no data model changes. It is a pure UI removal.

## Affected View

### PlanSavedView (modified)

| Property | Type | Change |
|----------|------|--------|
| `dayCount` | `Int` | Unchanged |
| `onHome` | `() -> Void` | Unchanged |
| ~~`onRestart`~~ | ~~`() -> Void`~~ | **Removed** |
