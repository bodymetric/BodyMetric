# Research: Home Refresh After Workout Completion

**Branch**: `022-home-refresh-post-workout` | **Date**: 2026-05-31

## Audit: Existing Code

### Navigation flow (workout → home)

`TodayView` presents `CheckInView` as a `.fullScreenCover(isPresented: $showCheckIn)`.

Inside `CheckInView`, a `NavigationStack(path: $path)` navigates to `ActiveSessionView` when a session begins. `ActiveSessionView` presents `WorkoutCompleteView` as its own `.fullScreenCover` when `viewModel.completionStats != nil`.

`WorkoutCompleteView.onDone` is wired to `onComplete` which is currently `{ path.removeLast() }` — this only pops `ActiveSessionView` from `CheckInView`'s stack, leaving the user on `CheckInView`'s root. **The user is not returned to `TodayView` automatically.** This is the bug this feature fixes.

### TodayViewModel.reload()

`TodayViewModel` already exposes:
```swift
func reload(using service: any HomeServiceProtocol) async {
    loadState = .idle
    await loadHomeData(using: service)
}
```
No new ViewModel code is needed.

### HomeService — missing query parameter

`HomeService.fetchHomeData()` currently calls `GET https://api.bodymetric.com.br/api/home` with no query parameters. The user spec requires `?currentDayOfWeek=<WEEKDAY>`. This param is absent from every existing call.

---

## Finding 1: currentDayOfWeek computation

**Decision**: Compute the weekday string inside `HomeService` using `DateFormatter` with `"EEEE"` format, `en_US` locale, uppercased.

```swift
private static func currentDayOfWeekString() -> String {
    let f = DateFormatter()
    f.dateFormat = "EEEE"
    f.locale = Locale(identifier: "en_US")
    return f.string(from: Date()).uppercased()   // "MONDAY", "TUESDAY", …
}
```

**Rationale**: Pure Foundation, zero new dependencies. `en_US` locale guarantees English day names regardless of device language. Uppercasing matches the API contract. No protocol signature change — the computation is a service-layer detail invisible to callers.

**Alternatives considered**:
- Mapping from the `DayOfWeek` enum in `Features/NewPlan/Models` — rejected; that enum lives in the wizard feature layer, not the service layer, and mixing concerns would create an improper dependency.
- Passing `currentDayOfWeek` as a parameter to `fetchHomeData(currentDayOfWeek:)` — rejected; it would require protocol and caller changes everywhere for zero testability benefit, since the only meaningful test is "does the URL contain the right day for today."

---

## Finding 2: How to trigger the home reload after workout completion

**Decision**: Use SwiftUI's `.onChange(of: showCheckIn)` in `TodayView` to detect the boolean transitioning `true → false` and call `viewModel.reload(using: homeService)`.

```swift
// TodayView.swift — inside the NavigationStack's modifier chain
.onChange(of: showCheckIn) { old, new in
    guard old && !new else { return }
    Task { await viewModel.reload(using: homeService) }
}
```

**Rationale**: SwiftUI's `.onChange` fires synchronously on the main actor when the binding changes. Detecting `true → false` correctly targets the dismiss event. Refreshing on any dismissal (including user back-tap) is acceptable — it keeps data current with minimal complexity.

**Alternatives considered**:
- Adding `onWorkoutComplete: (() -> Void)?` callback to `CheckInView` — rejected; adds indirection and requires distinguishing "completed" from "cancelled" dismissal, which provides no practical benefit (a refresh on cancel is harmless).
- `NotificationCenter` / Combine publisher — rejected; overkill for a two-file SwiftUI change.

---

## Finding 3: Dismissing CheckInView after workout completion

**Decision**: Change `onComplete: { path.removeLast() }` in `CheckInView` to `onComplete: { dismiss() }`.

**Rationale**: `dismiss()` (from `@Environment(\.dismiss)`) dismisses the entire `.fullScreenCover` containing `CheckInView`, returning the user to `TodayView`. `path.removeLast()` alone only pops `ActiveSessionView` within `CheckInView`'s internal NavigationStack, stranding the user. With `dismiss()`, SwiftUI also cleans up the NavigationStack and its child presentations.

**Alternatives considered**:
- Keeping `path.removeLast()` and adding a separate `dismiss()` call — rejected; `dismiss()` alone is sufficient because dismissing the parent fullScreenCover implicitly removes all child views.

---

## Conclusion

Three file edits deliver the full feature:

| File | Change |
|------|--------|
| `Features/Workout/Views/CheckInView.swift` | `onComplete: { dismiss() }` replaces `onComplete: { path.removeLast() }` |
| `Features/Workout/Views/TodayView.swift` | Add `.onChange(of: showCheckIn)` → `viewModel.reload(using: homeService)` |
| `Services/Home/HomeService.swift` | Build URL with `URLComponents` + `currentDayOfWeek` query item |

No new types, no protocol changes, no new files.
