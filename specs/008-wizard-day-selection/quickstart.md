# Quickstart: New Plan Wizard — Day Selection API

**Feature**: `008-wizard-day-selection`  
**Date**: 2026-04-26

---

## What This Feature Adds

1. **`WorkoutPlanService`** — new service at `Services/WorkoutPlan/` that fetches existing day selections (GET) and saves selected days (POST).
2. **`NewPlanViewModel` mutations** — `loadDays(using:)` and `saveDays(using:)` async methods + `loadState` + `isSaving` + `saveErrorMessage`.
3. **`SelectDaysStepView` mutations** — loading skeleton while GET is in progress, inline error banner on POST failure.

---

## New Files

| File | Purpose |
|------|---------|
| `Services/WorkoutPlan/WorkoutPlanService.swift` | Concrete service: GET + POST `/api/workout-plans` |
| `Services/WorkoutPlan/WorkoutPlanServiceProtocol.swift` | Protocol for testability |
| `Services/WorkoutPlan/WorkoutPlanError.swift` | Domain error enum |
| `BodyMetricTests/Services/WorkoutPlanServiceTests.swift` | Unit tests using mock `NetworkClient` |

## Modified Files

| File | What Changes |
|------|-------------|
| `Features/NewPlan/ViewModels/NewPlanViewModel.swift` | Add `loadDays`, `saveDays`, `loadState`, `isSaving`, `saveErrorMessage` |
| `Features/NewPlan/Views/Components/SelectDaysStepView.swift` | Add loading overlay + inline error banner |
| `BodyMetricTests/Features/NewPlanViewModelTests.swift` | Add tests for `loadDays`/`saveDays`, states |

---

## WorkoutPlanService API

```swift
protocol WorkoutPlanServiceProtocol {
    func fetchDays() async throws -> [WorkoutPlanDayResponse]
    func saveDays(_ days: [WorkoutPlanDayRequest]) async throws
}
```

**`fetchDays()`**:
- Success (200) → returns array of `WorkoutPlanDayResponse`
- 404 → throws `WorkoutPlanError.notFound` (the ViewModel maps this to `.empty` state)
- Other → throws `WorkoutPlanError.serverError(statusCode)` or `.networkError`

**`saveDays(_:)`**:
- 201 → returns normally
- Other → throws `WorkoutPlanError.serverError(statusCode)`

---

## ViewModel Integration

### Load flow (triggered on-appear of SelectDaysStepView)

```swift
func loadDays(using service: WorkoutPlanServiceProtocol) async {
    loadState = .loading
    do {
        let days = try await service.fetchDays()
        // Pre-check matching DayOfWeek values
        selectedDays = Set(days.compactMap { DayOfWeek(rawValue: $0.plannedWeekNumber) })
        loadState = days.isEmpty ? .empty : .loaded
    } catch WorkoutPlanError.notFound {
        selectedDays = []
        loadState = .empty
    } catch {
        Logger.error("loadDays failed", error: error)
        selectedDays = []
        loadState = .failed(error.localizedDescription)
    }
    Logger.info("wizard_days_load: \(loadState)")
}
```

### Save flow (triggered by Continue button on step 1)

```swift
func saveDays(using service: WorkoutPlanServiceProtocol, onSuccess: () -> Void) async {
    isSaving = true
    saveErrorMessage = nil
    let requests = orderedSelectedDays.map { $0.toRequest }
    do {
        try await service.saveDays(requests)
        Logger.info("wizard_days_save_success dayCount:\(requests.count)")
        onSuccess()
    } catch {
        Logger.error("wizard_days_save_failed", error: error)
        saveErrorMessage = "Could not save your training days. Please try again."
    }
    isSaving = false
}
```

---

## DayOfWeek Extension

```swift
extension DayOfWeek {
    var toRequest: WorkoutPlanDayRequest {
        WorkoutPlanDayRequest(
            plannedWeekNumber: String(rawValue),
            plannedDayOfWeek: fullLabel.lowercased()
        )
    }
}
```

---

## Interaction Trace Events

| Event | When |
|-------|------|
| `wizard_days_load_started` | `loadState` transitions to `.loading` |
| `wizard_days_load_success` | GET 200 with ≥1 day |
| `wizard_days_load_empty` | GET 200 empty or 404 |
| `wizard_days_load_failed` | GET non-200 / non-404 |
| `wizard_days_save_started` | `saveDays` called |
| `wizard_days_save_success` | POST 201 |
| `wizard_days_save_failed` | POST non-201 |

---

## Design Token Reference

| Use case | Token |
|----------|-------|
| Loading spinner | `GrayscalePalette.secondary` tint |
| Error banner background | `GrayscalePalette.surface` |
| Error banner text + icon | `GrayscalePalette.primary` |
| Selected day chip | `WorkoutPalette.accent` (existing pattern) |
| Continue button | `GrayscalePalette.primary` when enabled; `GrayscalePalette.surface` when disabled |

---

## Testing Guide

### WorkoutPlanServiceTests

- Mock `NetworkClientProtocol`
- Test: 200 → returns decoded array
- Test: 404 → throws `.notFound`
- Test: 500 → throws `.serverError(500)`
- Test: malformed JSON → throws `.decodingError`
- Test: POST 201 → returns normally
- Test: POST 400 → throws `.serverError(400)`

### NewPlanViewModelTests (additions)

- Test: `loadDays` with success → `loadState == .loaded`, `selectedDays` pre-filled
- Test: `loadDays` with 404 → `loadState == .empty`, `selectedDays` empty
- Test: `loadDays` with network error → `loadState == .failed`, `selectedDays` empty
- Test: `saveDays` 201 → `isSaving = false`, `saveErrorMessage == nil`, `onSuccess` called
- Test: `saveDays` error → `isSaving = false`, `saveErrorMessage != nil`
- Test: rapid taps don't create concurrent saves (isSaving gate)
