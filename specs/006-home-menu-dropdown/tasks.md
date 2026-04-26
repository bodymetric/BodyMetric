# Tasks: Home Menu Dropdown

**Input**: Design documents from `/specs/006-home-menu-dropdown/`  
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ quickstart.md ✅

**Tests**: Included — required by Constitution Principle II (TDD, ≥ 90% coverage mandatory). Write tests first; verify they FAIL before implementing.

**Organization**: Tasks grouped by user story for independent delivery.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[Story]**: Which user story this task belongs to (US1 / US2 / US3)
- All new Swift files must be added to the **BodyMetric** target in `BodyMetric.xcodeproj`

---

## Phase 1: Setup

**Purpose**: Create the `NewPlan` feature module directory skeleton so all subsequent tasks have a stable target path.

- [x] T001 Create directory tree `Features/NewPlan/Models/`, `Features/NewPlan/ViewModels/`, `Features/NewPlan/Views/`, `Features/NewPlan/Views/Components/` inside the Xcode project (add group references in `BodyMetric.xcodeproj`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Domain models that every user story depends on. No story work can begin until these types compile.

**⚠️ CRITICAL**: All three user stories depend on `HomeMenuItem` / `HomeMenuDestination` existing. The wizard stories depend on `NewPlanModels`. Complete this phase before any story phase.

### Tests (write first — must FAIL before T004/T005)

- [x] T002 [P] Write failing unit tests for `HomeMenuItem` catalog in `BodyMetricTests/Features/HomeMenuModelsTests.swift`: assert catalog contains exactly 7 items; exactly 2 items are active (`isActive == true`); exactly 1 item has `isPrimary == true`; labels match spec ("Today", "New Workout Plan", "My Plans", "History", "Progress", "Profile", "Settings"); `HomeMenuDestination` has cases `.today` and `.newWorkoutPlan`
- [x] T003 [P] Write failing unit tests for `NewPlanModels` in `BodyMetricTests/Features/NewPlanModelsTests.swift`: `ExerciseBlock.isValid` returns false when `exerciseId` is empty; `ExerciseBlock.isValid` returns true with valid values; `DayPlan.isValid` returns false when `sessionName` is blank; `DayPlan.isValid` returns false when all blocks are invalid; `WorkoutPlan` initializes with auto UUID and `createdAt`; `DayOfWeek` has 7 cases; exercise catalog constant has exactly 18 entries grouped across 8 muscle groups

### Implementation

- [x] T004 [P] Create `Features/Workout/Models/HomeMenuModels.swift`: define `HomeMenuItem` struct (`id: String`, `label: String`, `subtitle: String`, `iconName: String`, `isActive: Bool`, `isPrimary: Bool`, `destination: HomeMenuDestination?`); define `HomeMenuDestination` enum (`case today`, `case newWorkoutPlan`); add `static let catalog: [HomeMenuItem]` with the 7 items from `data-model.md` in exact order; add to BodyMetric target; run T002 — all tests must pass
- [x] T005 [P] Create `Features/NewPlan/Models/NewPlanModels.swift`: define `DayOfWeek: Int, CaseIterable, Codable, Identifiable` with `shortLabel` / `fullLabel` computed properties and display order Mon→Sun; define `Exercise: Identifiable` (`id: String`, `name: String`, `primaryMuscle: String`) with `static let catalog: [Exercise]` of 18 exercises (Chest: bench/incline/fly; Legs: squat/leg-press/lunge; Hamstrings: rdl; Back: pullup/row/lat-pull; Shoulders: ohp/lateral; Biceps: curl/hammer; Triceps: tri-ext/skull; Core: plank/cable-crunch); define `ExerciseBlock: Identifiable, Codable` with `id: UUID`, `exerciseId: String = ""`, `targetReps: Int = 8`, `targetWeight: Double = 60`, `restSeconds: Int = 90`, computed `isValid: Bool`; define `DayPlan: Codable` with `day: DayOfWeek`, `sessionName: String = ""`, `blocks: [ExerciseBlock]`, computed `isValid: Bool`; define `WorkoutPlan: Identifiable, Codable` with `id: UUID`, `createdAt: Date`, `dayPlans: [DayPlan]`; add to BodyMetric target; run T003 — all tests must pass

**Checkpoint**: Foundation ready. T002 and T003 pass. User story implementation can now begin.

---

## Phase 3: User Story 1 — Open menu and navigate to New Plan wizard (Priority: P1) 🎯 MVP

**Goal**: User taps the mascot chip → menu opens with 7 items → taps "New Workout Plan" → full multi-step wizard appears and is completable.

**Independent Test**: Launch app to Today screen → tap mascot chip → confirm menu appears with 7 items and BodyMetric header → tap "New Workout Plan" → wizard opens → complete all steps → plan saved → "Back to home" returns to Today.

### Tests for US1 (write first — must FAIL before T008–T019)

- [x] T006 [P] [US1] Write failing unit tests in `BodyMetricTests/Features/NewPlanViewModelTests.swift`: `toggleDay` adds/removes a day and seeds an empty `DayPlan` in `dayPlans`; `totalSteps` equals `2 + selectedDays.count`; `advance()` increments `currentStep` when current step is valid; `advance()` is a no-op when current step is invalid; `retreat()` decrements step; `isStepValid(1)` returns false when no days selected; `isStepValid(2)` returns false when matching `DayPlan.isValid` is false; `finish()` calls `WorkoutPlanStore.save` and sets `isPresentingSuccess = true`; `orderedSelectedDays` is always Mon→Sun sorted; `jumpTo(step:)` succeeds only for `step ≤ currentStep`
- [x] T007 [P] [US1] Write failing UI test `BodyMetricUITests/HomeMenuUITests.swift` — story: tap mascot chip accessibility label "Open menu" → assert element with identifier `homeMenuPanel` exists; tap "New Workout Plan" → assert element with identifier `newPlanWizard` exists

### Implementation for US1

- [x] T008 [US1] Create `Features/NewPlan/Models/WorkoutPlanStore.swift`: `@Observable final class WorkoutPlanStore`; `private(set) var currentPlan: WorkoutPlan?`; `func save(_ plan: WorkoutPlan)` — encodes to JSON and writes to `UserDefaults` key `"bm.workoutPlan.current"`, logs `Logger.info("workout_plan_saved dayCount:\(plan.dayPlans.count)")`; `func load()` — decodes from UserDefaults on init; `init()` calls `load()`; add to BodyMetric target
- [x] T009 [US1] Create `Features/NewPlan/ViewModels/NewPlanViewModel.swift`: `@Observable final class NewPlanViewModel`; properties: `selectedDays: Set<DayOfWeek>`, `dayPlans: [DayOfWeek: DayPlan]`, `currentStep: Int = 1`, `activePickerBlockId: UUID? = nil`, `isPresentingSuccess: Bool = false`; computed: `totalSteps`, `orderedSelectedDays`, `currentDayIndex`, `currentDayPlan`; mutations: `toggleDay(_:)` (seeds empty DayPlan on select, removes on deselect), `advance()`, `retreat(onCancel:)`, `jumpTo(step:)`, `addBlock(for:)`, `removeBlock(id:from:)`, `updateBlock(id:day:patch:)`, `isStepValid(_:) -> Bool`, `finish(store:)`; interaction traces: `Logger.info("wizard_step_advanced step:\(currentStep)")`, `Logger.info("wizard_day_toggled day:\(day) selected:\(selected)")`, `Logger.info("wizard_finished dayCount:\(...) blockCount:\(...)")`, `Logger.info("wizard_cancelled")`; add to BodyMetric target; run T006 — all tests must pass
- [x] T010 [US1] Create `Features/Workout/Views/Components/HomeMenuView.swift`: accepts `@Binding var isPresented: Bool`, `@Binding var destination: HomeMenuDestination?`, `userName: String`; renders full-screen invisible scrim `Color.black.opacity(0.32)` that calls `dismiss()` on tap; renders menu panel ZStack anchored top-right (width 268 pt) with `scaleEffect(isPresented ? 1 : 0.92, anchor: .topTrailing).opacity(isPresented ? 1 : 0).animation(.bmFade, value: isPresented)`; menu header: `AppLogo` image 28×28 + "BodyMetric" label + `userName` + app version string + close (✕) `Button { isPresented = false; Logger.info("menu_dismissed") }`; notch triangle (14×14 rotated 45° anchored top-right of panel); item list from `HomeMenuItem.catalog` — each row: icon cell (WorkoutPalette.accentSoft if `isPrimary`, else GrayscalePalette.surface), label + subtitle, chevron OR "SOON" badge; active item tap: `destination = item.destination; isPresented = false; Logger.info("menu_item_tapped destination:\(item.id)")`; disabled item tap: no-op; active row for `.today` destination shows highlighted background when `currentDestination == .today`; on appear: `Logger.info("menu_opened")`; add `accessibilityIdentifier("homeMenuPanel")` to panel; add to BodyMetric target
- [x] T011 [US1] Modify `Features/Workout/Views/TodayView.swift`: add `@State private var menuOpen = false`; add `@State private var menuDestination: HomeMenuDestination?`; wrap existing mascot `ZStack { Circle()... Image("AppLogo")... }` in `Button("Open menu") { menuOpen = true }` with `.buttonStyle(.plain)` and `.accessibilityLabel("Open menu")`; append `.overlay(alignment: .top) { HomeMenuView(isPresented: $menuOpen, destination: $menuDestination, userName: userName) }` to the outer `NavigationStack`; append `.fullScreenCover(item: $menuDestination) { dest in if dest == .newWorkoutPlan { NewPlanWizardView() } }` to the `NavigationStack`; make `HomeMenuDestination` conform to `Identifiable` (add `var id: Self { self }`) so it can be used with `fullScreenCover(item:)` — add this conformance in `HomeMenuModels.swift`
- [x] T012 [P] [US1] Create `Features/NewPlan/Views/Components/WizardStepRailView.swift`: horizontal `ScrollView(.horizontal, showsIndicators: false)` with `HStack` of step chips; chip style: pill button showing step number OR checkmark (for completed steps), label ("Days", each day shortLabel, "Save"); active chip: `GrayscalePalette.primary` background; completed reachable chip: `WorkoutPalette.accentSoft` background + checkmark; unreached chip: `GrayscalePalette.surface` + 50% opacity; tap on reachable chip calls `viewModel.jumpTo(step:)`; add to BodyMetric target
- [x] T013 [P] [US1] Create `Features/NewPlan/Views/Components/SelectDaysStepView.swift`: step header label "STEP 01 · CADENCE" + title "Which days will you train?"; `VStack` list over `DayOfWeek.allCases` (Mon→Sun order); each row: day short label circle (WorkoutPalette.accent fill when selected, GrayscalePalette.surface otherwise), day full name, "Training day"/"Rest day" subtitle, checkmark badge; tap row calls `viewModel.toggleDay(day)`; mascot tip at bottom showing selected count; all colors via GrayscalePalette except selected circle fill and checkmark (WorkoutPalette.accent / onAccent); add to BodyMetric target
- [x] T014 [P] [US1] Create `Features/NewPlan/Views/Components/ExerciseBlockRowView.swift`: displays a single `ExerciseBlock`; `block.isValid` drives left-border color (WorkoutPalette.accent vs GrayscalePalette.separator); header row: zero-padded block number chip + muscle group label (from catalog lookup) + optional remove button; exercise picker trigger button (dumbbell icon + exercise name or "Choose exercise" placeholder + chevron) calls `onPick(block.id)`; numeric stepper grid (3 columns) for Reps / Weight(kg) / Rest(s) using a local `BMStepper` helper view (label, − button, value display, + button); all stepper changes call `onChange(ExerciseBlock)`; add to BodyMetric target
- [x] T015 [P] [US1] Create `Features/NewPlan/Views/Components/ExercisePickerSheetView.swift`: `.presentationDetents([.large])` sheet; search `TextField` filtering `Exercise.catalog` by name or muscle (case-insensitive); results grouped by `primaryMuscle`; each exercise row: dumbbell icon cell (WorkoutPalette.accent fill when selected), name, checkmark if selected; tap calls `onPick(exercise.id)` and dismisses; cancel button dismisses without selection; zero-results state: "Nothing matches" empty-state text; add to BodyMetric target
- [x] T016 [US1] Create `Features/NewPlan/Views/Components/ConfigureDayStepView.swift`: step header "STEP 0N · DAY N OF M" + day full name + subtitle "Name the session, then stack the exercise blocks."; session name `TextField` in a bordered container (WorkoutPalette.accent border when non-empty, GrayscalePalette.separator otherwise); exercise blocks list using `ExerciseBlockRowView` for each block in `viewModel.currentDayPlan.blocks`; "Add another block" dashed-border button calls `viewModel.addBlock(for: day)`; block count label; `.sheet(item: $viewModel.activePickerBlockId)` presents `ExercisePickerSheetView`; all mutations delegate to `viewModel.updateBlock / removeBlock`; add to BodyMetric target
- [x] T017 [US1] Create `Features/NewPlan/Views/Components/ReviewStepView.swift`: step header "FINAL · REVIEW" + title "One last look." + day/block count summary; for each day in `viewModel.orderedSelectedDays`: summary card showing day short label chip, session name, per-block list (number, exercise name, reps×weight·rest), left-border WorkoutPalette.accent if valid / red(`Color(red:0.75,green:0.22,blue:0.18)`) if invalid, "✓ OK" / "✗ FIX" badge, tap → `viewModel.jumpTo(step: 2 + index)`; all-invalid warning banner if `!viewModel.allDaysValid`; add to BodyMetric target
- [x] T018 [US1] Create `Features/NewPlan/Views/Components/PlanSavedView.swift`: full-screen success view; `AppLogo` image in circular `WorkoutPalette.accentSoft` halo (180×180) with `GrayscalePalette.primary` checkmark badge overlay; "PLAN SAVED" mono label + "Now do the work." title + descriptive subtitle (day count, first session tomorrow); "Back to home" primary button (`GrayscalePalette.primary` fill) calls `onHome()`; "Plan another week" ghost button calls `onRestart()`; soft accent blur ornaments (WorkoutPalette.accentSoft, `blur(radius: 40)`); add `accessibilityIdentifier("planSavedView")` to root; add to BodyMetric target
- [x] T019 [US1] Create `Features/NewPlan/Views/NewPlanWizardView.swift`: `@State private var viewModel = NewPlanViewModel()`; `@State private var store = WorkoutPlanStore()`; `@Environment(\.dismiss) private var dismiss`; `VStack` layout: fixed header (back button + "NEW PLAN · STEP N OF M" mono label + step title) + `WizardStepRailView` + scrollable body + fixed footer CTA; body routes on `viewModel.currentStep`: 1 → `SelectDaysStepView`, 2…N → `ConfigureDayStepView`, N+1 → `ReviewStepView`; footer: Continue button (enabled when `viewModel.isStepValid(viewModel.currentStep)`, WorkoutPalette.accent disabled else GrayscalePalette.disabled) on non-final steps; "Finish & save plan" button (WorkoutPalette.accent) on final step; helper text when step invalid; `.fullScreenCover(isPresented: $viewModel.isPresentingSuccess)` presents `PlanSavedView(onHome: { dismiss() }, onRestart: { viewModel = NewPlanViewModel() })`; back button: `viewModel.retreat(onCancel: { dismiss() })`; add `accessibilityIdentifier("newPlanWizard")` to root; add to BodyMetric target; run T007 UI test — both assertions must pass

**Checkpoint**: User Story 1 is fully functional. User can open menu, navigate to wizard, complete all steps, save a plan, and return home.

---

## Phase 4: User Story 2 — Dismiss the menu without navigating (Priority: P2)

**Goal**: Both dismissal paths (close button and scrim tap) work correctly and return the Today screen to full interactivity.

**Independent Test**: Open menu → tap ✕ → confirm menu gone and Today interactive. Open menu → tap scrim → confirm menu gone and Today interactive.

### Tests for US2 (add to existing test file)

- [x] T020 [P] [US2] Add unit tests to `BodyMetricTests/Features/HomeMenuModelsTests.swift`: instantiate a `HomeMenuView` via `ViewInspector` or `XCTest` harness; assert that binding `isPresented` becomes `false` when close action fires; assert that binding `isPresented` becomes `false` when scrim tap action fires; assert that after dismiss, `destination` binding is unchanged (no unintended navigation)

### Implementation for US2

- [x] T021 [US2] In `Features/Workout/Views/Components/HomeMenuView.swift` verify and confirm: the scrim `Color.black.opacity(0.32)` tap calls `isPresented = false` AND `Logger.info("menu_dismissed")`; the close (✕) `Button` action calls `isPresented = false` AND `Logger.info("menu_dismissed")`; the `.animation(.bmFade, value: isPresented)` modifier applies to both panel and scrim so the out-transition plays; `TodayView` content (scroll view, Start workout button) is fully tappable after `menuOpen` returns to `false` — verify by confirming overlay has `allowsHitTesting(isPresented)` so underlying views regain touches; run T020 — all tests must pass

**Checkpoint**: User Stories 1 AND 2 independently functional.

---

## Phase 5: User Story 3 — View coming-soon items without navigating (Priority: P3)

**Goal**: The five SOON items are visible and visually distinct from active items; tapping them produces no navigation and keeps the menu open.

**Independent Test**: Open menu → tap "My Plans" (or any SOON item) → menu stays open, no screen change.

### Tests for US3 (add to existing test file)

- [x] T022 [P] [US3] Add unit tests to `BodyMetricTests/Features/HomeMenuModelsTests.swift`: for each item in `HomeMenuItem.catalog` where `isActive == false`, assert `destination == nil`; assert exactly 5 items have `isActive == false`; assert each inactive item's `label` is one of {"My Plans", "History", "Progress", "Profile", "Settings"}

### Implementation for US3

- [x] T023 [US3] In `Features/Workout/Views/Components/HomeMenuView.swift` verify and confirm: inactive items render a "SOON" badge (text "SOON", mono font, small, GrayscalePalette.secondary color, bordered chip); inactive item rows have `.opacity(0.45)` applied; inactive item `Button` has `.disabled(true)` or the tap closure guards `guard item.isActive else { return }`; tapping an inactive item does NOT change `destination` and does NOT change `isPresented`; run T022 — all tests must pass

**Checkpoint**: All three user stories independently functional.

---

## Final Phase: Polish & Cross-Cutting Concerns

- [x] T024 [P] Verify all new Swift source files are correctly referenced in the BodyMetric target inside `BodyMetric.xcodeproj` — confirm no "file not found" warnings; confirm build succeeds clean (`xcodebuild build -scheme BodyMetric -destination 'generic/platform=iOS Simulator'`)
- [x] T025 [P] Audit interaction trace calls against the `quickstart.md` event table: confirm `Logger.info` calls exist for `menu_opened`, `menu_item_tapped`, `menu_dismissed` in `HomeMenuView.swift`; `wizard_step_advanced`, `wizard_day_toggled`, `wizard_finished`, `wizard_cancelled` in `NewPlanViewModel.swift`; `workout_plan_saved` in `WorkoutPlanStore.swift` (Constitution Principle IV)
- [x] T026 [P] Audit Constitution Principle VI compliance: run `grep -r "Color(" Features/Workout/Views/Components/HomeMenuView.swift Features/NewPlan/` and confirm no raw `Color(red:green:blue:)` values outside `GrayscalePalette` / `WorkoutPalette` token references; confirm `WorkoutPalette` tokens are used ONLY within `HomeMenuView.swift` and `Features/NewPlan/` files (not elsewhere)
- [x] T027 Run full test suite and confirm ≥ 90% line+branch coverage across all new files: `xcodebuild test -scheme BodyMetric -destination 'platform=iOS Simulator,name=iPhone 16' -enableCodeCoverage YES`; if coverage is below 90%, add targeted unit tests for uncovered branches in `NewPlanViewModel`, `WorkoutPlanStore`, and `HomeMenuView`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — **blocks all story phases**
- **Phase 3 (US1)**: Depends on Phase 2 — can start after T004 and T005 compile
- **Phase 4 (US2)**: Depends on T010 (`HomeMenuView` exists) — can run in parallel with late US1 wizard tasks
- **Phase 5 (US3)**: Depends on T010 (`HomeMenuView` exists) — can run in parallel with Phase 4
- **Final Phase**: Depends on all story phases complete

### User Story Dependencies

- **US1 (P1)**: Needs Phase 2 complete. No dependency on US2 or US3.
- **US2 (P2)**: Needs T010 complete (HomeMenuView skeleton with scrim/close button). Independent from US1 wizard work.
- **US3 (P3)**: Needs T010 complete (HomeMenuView with item rendering). Independent from US1 wizard work.

### Within User Story 1

- T006, T007 (tests) must be written and confirmed **failing** before T008–T019
- T008 (`WorkoutPlanStore`) → T009 (`NewPlanViewModel` uses store) → T019 (`NewPlanWizardView` wires them)
- T010 (`HomeMenuView`) → T011 (`TodayView` integration)
- T012–T015 (leaf wizard components) can be written in parallel
- T016 (`ConfigureDayStepView`) needs T014 (`ExerciseBlockRowView`) + T015 (`ExercisePickerSheetView`)
- T017 (`ReviewStepView`) can run parallel to T016
- T018 (`PlanSavedView`) can run parallel to T016, T017
- T019 (`NewPlanWizardView`) needs T012–T018 all present

---

## Parallel Opportunities

### Parallel Example: Phase 2 (Foundational)

```
Parallel batch 1 (tests — write and verify FAIL):
  T002: HomeMenuModelsTests.swift
  T003: NewPlanModelsTests.swift

Parallel batch 2 (implementation — run tests to confirm PASS):
  T004: HomeMenuModels.swift
  T005: NewPlanModels.swift
```

### Parallel Example: User Story 1

```
Sequential start:
  T006: NewPlanViewModelTests.swift (write + verify FAIL)
  T007: HomeMenuUITests.swift (write + verify FAIL)

Parallel batch (leaf wizard components — no shared file):
  T008: WorkoutPlanStore.swift
  T010: HomeMenuView.swift
  T012: WizardStepRailView.swift
  T013: SelectDaysStepView.swift
  T014: ExerciseBlockRowView.swift
  T015: ExercisePickerSheetView.swift
  T017: ReviewStepView.swift
  T018: PlanSavedView.swift

Then sequentially (each needs prior files):
  T009: NewPlanViewModel.swift (needs T008)
  T011: TodayView.swift modification (needs T010)
  T016: ConfigureDayStepView.swift (needs T014, T015)
  T019: NewPlanWizardView.swift (needs T009, T012–T018)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002–T005) — **do not skip**
3. Complete Phase 3: User Story 1 (T006–T019)
4. **STOP and VALIDATE**: tap mascot → menu opens → tap "New Workout Plan" → wizard completes → plan saved
5. Ship MVP

### Incremental Delivery

1. Phase 1 + 2 → models compile and tests pass
2. Phase 3 (US1) → menu + wizard end-to-end works → **demo-able MVP**
3. Phase 4 (US2) → dismissal paths verified
4. Phase 5 (US3) → SOON items confirmed non-navigable
5. Final Phase → test coverage confirmed ≥ 90%, traces audited, Constitution compliance checked

---

## Notes

- `[P]` tasks touch different files — they have no shared mutable state and can be assigned to separate agents or developers
- TDD is mandatory per Constitution Principle II: every test in this list must FAIL before the corresponding implementation task is started
- `WorkoutPalette` tokens are permitted in `HomeMenuView.swift` (workout-flow screen) and all `Features/NewPlan/` views. They must NOT appear elsewhere.
- The exercise catalog and `HomeMenuItem.catalog` are compile-time constants — no migration, no seeding step needed
- `HomeMenuDestination` must conform to `Identifiable` for `fullScreenCover(item:)` — add this in T011 when the conformance is needed
- Commit after each task using a Gitmoji prefix + task ID (e.g., `✨ T010: implement HomeMenuView`)
