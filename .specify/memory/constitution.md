<!--
SYNC IMPACT REPORT
==================
Version change: 3.0.0 → 3.1.0
Rationale for MINOR bump: New enforceable commit-message rule added to the
  Development Workflow section requiring Gitmoji icons on every commit.
  Adding a new enforceable rule to an existing section qualifies as a MINOR bump
  per the versioning policy.
Modified principles:
  - None
Added sections:
  - None
Removed sections:
  - None
Workflow rule changes:
  - "Commit hygiene" expanded: every commit message MUST be prefixed with a
    Gitmoji icon (https://gitmoji.dev) that matches the primary intent of the
    commit. The existing task-ID and imperative-mood requirements are retained.
Templates reviewed & status:
  ✅ .specify/templates/tasks-template.md — "Commit after each task" note
     is compatible; no structural change required.
  ✅ .specify/templates/plan-template.md — No commit-hygiene references; no
     update required.
  ✅ .specify/templates/spec-template.md — Generic; no conflicts.
  ✅ .specify/templates/agent-file-template.md — Generic; no conflicts.
  ⚠  .specify/templates/commands/ — Directory does not exist. When added,
     commands MUST be reviewed for alignment with the 6 active principles.
Follow-up TODOs:
  - TODO(ANIMATION_STANDARD): Specific animation duration/curve baseline
    not yet defined. Update Principle V once a design system is adopted.
  - TODO(RATIFICATION_OWNER): Record the ratifying party once known.
  - TODO(LOGGING_BACKEND): Logging destination (OSLog, external service,
    crash reporter) not yet decided. Specify in Principle III once chosen.
  - TODO(TRACING_BACKEND): Tracing/analytics backend not yet decided.
    Specify in Principle IV once chosen.
Impact on existing feature artifacts:
  - specs/001-gym-workout-tracker/plan.md — No commit-hygiene references;
    no update required.
  - specs/001-gym-workout-tracker/tasks.md — No update required.
-->

# BodyMetric Constitution

## Core Principles

### I. Swift-Native Code

BodyMetric is an iOS application. Every line of product code MUST be written
in Swift. No Objective-C new code, no cross-platform runtimes, no generated
non-Swift output committed as source.

- All new source files MUST use the `.swift` extension and conform to the
  Swift API Design Guidelines.
- The app MUST target the latest stable iOS SDK and MUST NOT use deprecated
  APIs without a documented migration plan.
- UI layouts MUST adapt correctly to all supported iOS device sizes and
  Dynamic Type settings.
- Third-party dependencies MUST be integrated via Swift Package Manager;
  CocoaPods and Carthage are prohibited for new dependencies.

**Rationale**: Native Swift delivers the performance, safety, and platform
integration that a real-time tracking experience requires. A single-language
codebase reduces cognitive overhead and eliminates FFI failure modes.

### II. Comprehensive Testing

All production code MUST have corresponding tests. No production code MAY be
merged without tests that cover its observable behaviour.

- The Red-Green-Refactor cycle is mandatory for every feature task: write a
  failing test, make it pass, then refactor.
- The project MUST maintain a minimum of 90% code coverage (lines + branches)
  at all times; a pull request that drops coverage below this threshold MUST
  NOT be merged.
- Unit tests MUST cover all business logic, calculation, and data-transformation
  code paths.
- UI tests MUST cover every primary user journey identified in the feature spec.
- CI MUST run the full test suite and report coverage on every pull request.
- XCTest is the primary framework; Swift Testing is acceptable alongside it.

**Rationale**: Undetected regressions in a personal health/fitness tracking
app corrupt user history and erode trust. 90% coverage is a concrete,
measurable floor — not an aspirational target.

### III. Error Logging & Observability

Every error that can affect user data, app stability, or a business operation
MUST be logged with enough context to reproduce and diagnose the issue.

- All errors caught at a `catch` site or error-handling boundary MUST be
  logged before being handled, swallowed, or surfaced to the user.
- Log entries MUST include: timestamp, severity level (debug/info/warning/
  error/fault), source location (file + function + line), and a human-readable
  message describing what failed and the relevant context.
- Silent failures (errors caught and discarded without logging) are a defect.
- Logging MUST NOT expose personally identifiable information (PII) or
  sensitive health data; redact or omit such fields before writing to any log.
- TODO(LOGGING_BACKEND): Choose and document the logging destination (e.g.,
  Apple Unified Logging / OSLog, a crash-reporting SDK) and update this
  principle once decided.

**Rationale**: Without structured error logs it is impossible to understand
production failures or support users experiencing silent issues. Logging is a
non-optional safety net, not a debugging convenience.

### IV. Interaction Tracing

Every meaningful user interaction and system event MUST be traced to enable
product understanding, debugging, and quality assurance.

- A "meaningful interaction" includes (but is not limited to): screen views,
  button taps that trigger state changes, form submissions, background sync
  events, and any action that modifies persisted data.
- Each trace event MUST capture: event name (snake_case, descriptive), a
  timestamp, and the minimum properties needed to understand context. No
  freeform string payloads.
- Trace events MUST NOT include PII or raw health data; use anonymised
  identifiers (session ID, anonymised user ID) only.
- Tracing instrumentation MUST be added as part of the feature task, not as a
  post-launch patch; untraced features are considered incomplete.
- TODO(TRACING_BACKEND): Choose and document the analytics/tracing backend
  (e.g., TelemetryDeck, custom OSSignpost, or another privacy-first SDK) and
  update this principle once decided.

**Rationale**: Tracing provides the empirical feedback loop needed to make
informed product decisions and to diagnose subtle UX issues that tests cannot
catch. It also enables performance profiling of real user paths.

### V. User-Friendly, Simple & Fast

The app MUST be immediately intuitive to a first-time user, free of
unnecessary complexity, and perceptibly fast on supported devices.

- Every screen MUST have a single, clear primary action; secondary or
  destructive actions MUST be visually subordinate.
- The critical path — starting a workout, logging a set, and finishing a
  session — MUST be completable in the fewest taps possible and MUST require
  no tutorial or onboarding explanation.
- All screen transitions MUST use smooth, intentional animations; abrupt or
  janky transitions are a defect. TODO(ANIMATION_STANDARD): define the
  baseline curve and duration values once a design system is adopted.
- App launch-to-ready MUST be under 1 second on a supported device; any
  operation visible to the user MUST complete or show a loading indicator
  within 300 ms.
- Features that add UI complexity without a clear user need MUST be rejected
  at the spec review stage.

**Rationale**: Simplicity and speed are the primary quality signals for a gym-
floor app used under physical exertion. Complexity is a bug, not a feature.

### VI. Grayscale Visual Design

The entire app UI MUST use only a grayscale color palette. No hue, saturation,
or color tinting of any kind is permitted in production screens.

- All backgrounds, text, icons, borders, and interactive elements MUST be
  expressed exclusively as shades of gray (from pure white `#FFFFFF` to pure
  black `#000000`).
- Semantic meaning conveyed by color in conventional UIs (e.g., red = error,
  green = success) MUST be conveyed through shape, icon, typography weight,
  or explicit text labels — never color alone.
- This constraint applies to all SwiftUI `Color` values, asset catalog colors,
  SF Symbol rendering modes, and any gradients used in the app; all of these
  MUST resolve to grayscale.
- Third-party UI components that render non-grayscale color by default MUST be
  explicitly configured or wrapped to conform.
- Screenshots and design mockups included in specs MUST also be grayscale so
  reviewers can validate compliance visually.

**Rationale**: The grayscale palette is a deliberate product identity decision
that reduces visual distraction during workouts and enforces a disciplined,
accessible design language.

## Technical Stack

- **Language**: Swift (100% of product code); no Objective-C new code.
- **Platform**: iOS (primary); other Apple platforms are out of scope until
  explicitly added via a constitution amendment.
- **UI Framework**: SwiftUI preferred for new screens; UIKit acceptable for
  components where SwiftUI lacks necessary capability (document in plan).
- **Persistence**: Local store MUST use CoreData or SwiftData; raw SQLite
  without an ORM layer requires justification in the plan's Complexity
  Tracking table.
- **Networking**: URLSession (native) preferred; a third-party HTTP client
  requires justification.
- **Logging**: TODO(LOGGING_BACKEND) — OSLog (Unified Logging) is the default
  until a decision is documented in Principle III.
- **Tracing**: TODO(TRACING_BACKEND) — Decision to be documented in Principle IV.
- **Testing**: XCTest for unit and integration tests; XCUITest for UI tests.
  Swift Testing framework is acceptable alongside XCTest.
- **CI**: All tests and coverage reports MUST run on every pull request via an
  automated CI pipeline (GitHub Actions or equivalent).
- **Dependencies**: Swift Package Manager is the sole dependency manager;
  CocoaPods and Carthage are prohibited for new dependencies.

## Development Workflow

- **Branching**: Each feature uses a numbered branch (`###-feature-name`)
  created by the speckit tooling, branched from `main`.
- **Spec before code**: A `spec.md` and `plan.md` MUST exist and be reviewed
  before any implementation task is started.
- **Constitution Check**: Every `plan.md` MUST include a completed Constitution
  Check section (all six principles verified) before Phase 0 research begins.
- **Test gate**: Write tests → confirm they fail → implement → confirm they
  pass. No exceptions. Coverage MUST remain ≥ 90% after every merged PR.
- **Logging gate**: Every error-handling site added or modified MUST include
  the required log call (Principle III) before the PR is considered complete.
- **Tracing gate**: Every user interaction introduced by a feature MUST have
  a corresponding trace event (Principle IV) before the PR is considered
  complete.
- **Grayscale gate**: UI code review MUST verify that no non-grayscale color
  values are introduced (Principle VI).
- **Code review**: All pull requests require at least one human reviewer. The
  reviewer is accountable for verifying the Constitution Check was completed,
  coverage threshold is met, error logging is present, interactions are traced,
  and the grayscale constraint is respected.
- **Commit hygiene**: Every commit message MUST be prefixed with a Gitmoji
  icon (https://gitmoji.dev) that matches the primary intent of the commit.
  Common mappings: ✨ new feature, 🐛 bug fix, 📝 documentation, ♻️ refactor,
  🧪 tests, 🔧 configuration, 🎨 formatting/structure, 🚀 deploy/release,
  🔒 security fix, 💄 UI/cosmetic change. Each commit MUST also reference the
  task ID it satisfies (e.g., `✨ T012: implement check-in model`). Commit
  messages MUST be written in the imperative mood.
- **CI gates**: A pull request MUST NOT be merged if any test fails, coverage
  drops below 90%, linting errors are present, or the Constitution Check is
  absent from the plan.

## Governance

This constitution supersedes all other project-level practices and informal
conventions. When a conflict exists between a team practice and this document,
this document prevails unless an amendment is filed and approved.

**Amendment procedure**:
1. Propose the change as a pull request modifying this file.
2. Describe the motivation, the exact text change, and any migration impact on
   existing features in the PR description.
3. Obtain approval from at least one other contributor.
4. Increment the version number following the policy below.
5. Set `LAST_AMENDED_DATE` to the merge date (ISO format).

**Versioning policy**:
- MAJOR: A principle is removed, materially weakened, or redefined in a
  backward-incompatible way (e.g., dropping the 90% coverage floor, removing
  the grayscale constraint).
- MINOR: A new principle or section is added, or existing guidance is
  materially expanded with new enforceable rules.
- PATCH: Wording clarified, typos fixed, non-semantic refinements, or TODO
  placeholders resolved without rule changes.

**Compliance review**:
- Constitution compliance MUST be reviewed at the start of every feature plan
  (Constitution Check gate in `plan.md`).
- A full constitution review SHOULD be conducted at the start of each
  development quarter or after any significant product pivot.

**Version**: 3.1.0 | **Ratified**: 2026-04-03 | **Last Amended**: 2026-04-05
