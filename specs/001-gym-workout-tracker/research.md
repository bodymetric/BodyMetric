# Research: Gym Workout Tracker with Gamification

**Branch**: `001-gym-workout-tracker` | **Date**: 2026-04-04

---

## 1. Google Sign-In for iOS (SPM)

**Decision**: Use the official `GoogleSignIn-iOS` Swift Package Manager package (`GoogleSignIn` + `GoogleSignInSwift` targets).

**Rationale**:
- Official Google SDK, actively maintained, supports iOS 13+.
- Ships a `GoogleSignInButton` SwiftUI component that can be wrapped to enforce grayscale.
- Provides `GIDSignIn.sharedInstance.restorePreviousSignIn()` for silent re-authentication using a stored refresh token.
- SPM-native — no CocoaPods required, fully compliant with Principle I.

**Integration pattern**:
```swift
// In BodyMetricApp.swift
.onOpenURL { url in
    GIDSignIn.sharedInstance.handle(url)
}

// In AuthService
GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
    // Extract idToken + accessToken
}
```

**Alternatives considered**:
- Firebase Auth (Google provider): heavier dependency; full Firebase SDK not needed for v1.
- Manual OAuth2 flow via ASWebAuthenticationSession: viable but re-implements what GoogleSignIn-iOS already provides safely.

**Token model**: Google returns an `idToken` (JWT, short-lived) and an `accessToken`. The backend should accept the `idToken` to create/verify a server-side session and return its own `accessToken` + `refreshToken` pair, which are stored in the Keychain.

---

## 2. Keychain for Secure Token Storage

**Decision**: Use the iOS Security framework directly, wrapped in a `KeychainService` struct. Optionally add `KeychainSwift` via SPM to reduce boilerplate.

**Rationale**:
- Keychain is the only iOS-sanctioned store for secrets; `UserDefaults` and CoreData/SwiftData files are unencrypted at rest.
- Items stored with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` are protected by the Secure Enclave and cannot be migrated to another device — appropriate for auth tokens.
- `kSecAttrSynchronizable = false` ensures tokens do NOT sync to iCloud Keychain (avoids cross-device token reuse).
- `KeychainSwift` (MIT licence) is a thin SPM wrapper that eliminates the verbose Security framework boilerplate while adding no logic of its own.

**Storage attributes**:
```
kSecClass:              kSecClassGenericPassword
kSecAttrService:        "com.bodymetric.app"
kSecAttrAccount:        "access_token" | "refresh_token"
kSecAttrAccessible:     kSecAttrAccessibleWhenUnlockedThisDeviceOnly
kSecAttrSynchronizable: false
```

**Alternatives considered**:
- `UserDefaults`: Unencrypted; rejected.
- Encrypted CoreData / SwiftData: Overkill for two string values; Keychain is the standard.
- Third-party secure storage (e.g., Valet): Adds abstraction without meaningful benefit over `KeychainSwift`.

---

## 3. SwiftUI Animated Screen Transitions

**Decision**: Use SwiftUI's native `.navigationTransition` (iOS 18+) combined with `matchedGeometryEffect` for hero animations, and `AnyTransition` custom transitions for modal-style presentations. Fallback to `.navigationTransition(.slide)` for iOS 17.

**Rationale**:
- iOS 17's `NavigationStack` with `navigationDestination` supports the `.slide` and `.zoom` transitions natively.
- iOS 18 adds `NavigationTransition` protocol for fully custom transitions without UIKit bridging.
- `matchedGeometryEffect` is ideal for the workout card → active session hero transition.
- Using native APIs avoids third-party animation libraries and stays SPM-clean.

**Animation baseline** (per Principle V TODO(ANIMATION_STANDARD)):
```swift
.animation(.spring(response: 0.35, dampingFraction: 0.82), value: state)
```
- Duration: ~350 ms (spring response)
- Curve: Spring with 0.82 damping (slight overshoot, feels physical)
- All transitions defined in `Core/Navigation/Transition.swift` as reusable `AnyTransition` extensions.

**Patterns**:
- Check-in → Active session: slide-up with scale (card expands to full screen).
- Active session → Session complete: cross-dissolve + scale-down of exercise list.
- Drawer / sheet: `.sheet` with `.presentationDetents([.medium, .large])` for exercise detail.
- Tab switching: `.tabItem` native; no custom animation needed.

**Alternatives considered**:
- Lottie: Appropriate for illustrations/icons, not screen transitions.
- UIKit `UIViewControllerTransitioningDelegate`: Viable for complex cases; not needed for v1.
- Third-party (Hero library): Not SPM-compatible; rejected.

---

## 4. API Service Layer Architecture

**Decision**: `APIClient` as a protocol-based, `async/await` URLSession wrapper. Each feature domain has its own `Endpoints` file defining typed request builders.

**Rationale**:
- `async/await` + `URLSession` is idiomatic Swift 5.5+; no third-party HTTP client needed (Principle I, URLSession native preferred).
- Protocol-based `APIClientProtocol` enables clean mock injection in unit tests without third-party mocking frameworks.
- Typed endpoint builders (each returning a `URLRequest`) keep networking logic out of ViewModels.

**Pattern**:
```swift
protocol APIClientProtocol {
    func send<T: Decodable>(_ request: URLRequest) async throws -> T
}

struct APIClient: APIClientProtocol { ... }  // URLSession implementation
struct MockAPIClient: APIClientProtocol { ... }  // Test double
```

**Token refresh flow**:
- On `401` response: `AuthService.refreshToken()` → updates Keychain → retry original request (max 1 retry).
- On refresh failure: clear Keychain → post `NotificationCenter` event → app navigates to login.

**Error handling**: All `catch` sites log via `Logger` before propagating (Principle III). API errors map to a `APIError` enum surfaced as user-friendly messages in ViewModels.

**Alternatives considered**:
- Alamofire: Popular but unnecessary given native `async/await` URLSession; adds SPM weight.
- Combine publishers: Valid; `async/await` is simpler and more readable for request/response patterns.

---

## 5. Architecture: Service Layer + Vision Layer (MVVM)

**Decision**: MVVM — `@Observable` ViewModels (iOS 17 `Observation` framework) bridging the Service Layer and SwiftUI Views.

**Rationale**:
- `@Observable` (replacing `ObservableObject`) is the iOS 17 standard; eliminates `@Published` boilerplate.
- ViewModels own all business logic and state; Views are pure rendering.
- Services are injected into ViewModels via initialiser (testable, no singletons exposed to Views).
- Dependency injection via `AppEnvironment` passed through SwiftUI `.environment`.

**Layer responsibilities**:
```
Vision Layer:  SwiftUI Views (rendering only, bind to @Observable ViewModel)
               ↕ @Binding / @Environment
ViewModel:     State management, business logic, calls Service Layer
               ↕ async/await
Service Layer: APIClient, AuthService, KeychainService (stateless, testable)
               ↕ URLSession / Security framework
Remote:        REST API
```

**Alternatives considered**:
- VIPER: Over-engineered for this scope; MVVM with protocol services achieves the same testability.
- Redux/TCA (The Composable Architecture): Valid but complex; out of scope for v1.
- `ObservableObject` / Combine: Functional but superseded by `@Observable` on iOS 17.

---

## 6. Grayscale SwiftUI Design System

**Decision**: Define a `GrayscalePalette` enum with semantic aliases, enforced project-wide. All SwiftUI `Color` values MUST reference this enum only.

**Rationale**:
- Centralised palette makes constitution compliance reviewable at a glance.
- Semantic names (`GrayscalePalette.surface`, `.primary`, `.secondary`, `.disabled`) allow design intent to be clear without colour.

**Palette definition** (light/dark adaptive):
```swift
enum GrayscalePalette {
    static let background  = Color(light: .white, dark: Color(white: 0.08))
    static let surface     = Color(light: Color(white: 0.95), dark: Color(white: 0.14))
    static let primary     = Color(light: .black, dark: .white)
    static let secondary   = Color(light: Color(white: 0.45), dark: Color(white: 0.60))
    static let disabled    = Color(light: Color(white: 0.75), dark: Color(white: 0.35))
    static let separator   = Color(light: Color(white: 0.88), dark: Color(white: 0.22))
}
```

**Semantic meaning without colour**:
- Error states: Red-equivalent → bold text + "⚠" SF Symbol.
- Success states: Green-equivalent → checkmark SF Symbol + "Completed" label.
- Streak active: Filled circle SF Symbol vs. empty circle.
- Badge earned: Solid fill vs. outlined icon.

**Google Sign-In button**: Wrapped in `GrayscaleGoogleSignInButton` that overrides background to `GrayscalePalette.surface` and foreground to `GrayscalePalette.primary`.

**Alternatives considered**:
- `UIColor` asset catalog: Acceptable; SwiftUI `Color` init from asset catalog is equally valid and preferred for SwiftUI-first development.

---

## 7. Resolved Clarifications

All NEEDS CLARIFICATION items were resolved via informed defaults:

| Topic | Decision | Basis |
|-------|----------|-------|
| Auth method | Google Sign-In (OAuth2) | User explicitly specified |
| Token storage | iOS Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`) | User specified high security; Keychain is iOS standard |
| Token refresh | Automatic on 401, via AuthService | Industry standard for OAuth2 mobile flows |
| Animation style | Spring curve, ~350 ms, native SwiftUI | User specified smooth + animated; constitution Principle V |
| UI framework | SwiftUI (primary) | Constitution Technical Stack; user confirmed Swift |
| Logging backend | OSLog (Unified Logging) | Constitution TODO(LOGGING_BACKEND) default |
| Tracing backend | TBD — placeholder `Tracer` struct | Constitution TODO(TRACING_BACKEND) — backend not yet decided |
| Offline support | SwiftData cache for program/session data | Spec assumes connectivity; light cache reduces perceived latency |
