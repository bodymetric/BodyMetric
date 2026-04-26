# Quickstart: Gym Workout Tracker with Gamification

**Branch**: `001-gym-workout-tracker` | **Date**: 2026-04-04

---

## Prerequisites

| Tool | Minimum Version | Notes |
|---|---|---|
| Xcode | 15.4 | iOS 17 SDK required |
| macOS | 14.0 (Sonoma) | Xcode 15 requirement |
| iOS Simulator | iOS 17+ | iPhone 15 recommended |
| Swift | 5.10 | Bundled with Xcode 15.4 |
| Git | Any recent | Branch: `001-gym-workout-tracker` |

No Ruby, Node, CocoaPods, or Homebrew required for the app itself.

---

## 1. Clone and Open

```bash
git clone <repo-url>
cd BodyMetric
git checkout 001-gym-workout-tracker
open BodyMetric.xcodeproj
```

If the project does not have an `.xcodeproj` yet, it will be created as part of the first implementation task (T001).

---

## 2. Swift Package Dependencies

All dependencies are resolved automatically by Xcode via SPM on first open. The packages to be added (done as part of T001):

| Package | URL | Version | Purpose |
|---|---|---|---|
| `GoogleSignIn-iOS` | `https://github.com/google/GoogleSignIn-iOS` | `≥ 7.1.0` | Google OAuth2 Sign-In |
| `KeychainSwift` | `https://github.com/evgenyneu/keychain-swift` | `≥ 20.0` | Keychain boilerplate reduction |

To add manually in Xcode: **File → Add Package Dependencies** → paste URL → select version rule.

---

## 3. Google Sign-In Configuration

1. Create a project in [Google Cloud Console](https://console.cloud.google.com).
2. Enable the **Google Sign-In** API.
3. Create an **OAuth 2.0 Client ID** for iOS, entering the app's bundle ID (`com.bodymetric.app`).
4. Download `GoogleService-Info.plist` and add it to the Xcode project root (do NOT commit to source control — add to `.gitignore`).
5. Add the reversed client ID as a URL scheme in `Info.plist`:
   ```xml
   <key>CFBundleURLSchemes</key>
   <array>
     <string><!-- REVERSED_CLIENT_ID from plist --></string>
   </array>
   ```

---

## 4. Environment Configuration

Create a `Config.xcconfig` file (gitignored) with:

```
API_BASE_URL = https://api-dev.bodymetric.app
```

Reference this in `BodyMetric-Info.plist` as `$(API_BASE_URL)` and read it in `AppEnvironment.swift`:

```swift
let apiBaseURL = Bundle.main.infoDictionary?["API_BASE_URL"] as? String ?? ""
```

Never hardcode the base URL in source files.

---

## 5. Build and Run

Select the **BodyMetric** scheme and an iPhone 17 simulator, then press **⌘R**.

Expected first-launch behaviour:
- `LoginView` is displayed (no stored tokens).
- Tap "Sign in with Google" → Google OAuth sheet appears.
- After sign-in, `TabView` appears with Home tab active.

---

## 6. Run Tests

```bash
# Unit + integration tests (no simulator needed for pure Swift targets)
xcodebuild test -scheme BodyMetricTests -destination 'platform=iOS Simulator,name=iPhone 17'

# UI tests (requires simulator)
xcodebuild test -scheme BodyMetricUITests -destination 'platform=iOS Simulator,name=iPhone 17'
```

Or press **⌘U** in Xcode to run all tests.

Coverage report: **Product → Show Build Folder → Logs → Test → Coverage**. Must remain ≥ 90%.

---

## 7. Key Files Reference

| File | Purpose |
|---|---|
| `App/BodyMetricApp.swift` | App entry point; registers Google Sign-In URL handler |
| `App/AppEnvironment.swift` | Root DI container; injects services into the view hierarchy |
| `Core/Navigation/AppRouter.swift` | Centralised navigation state (`@Observable`) |
| `Core/Navigation/Transition.swift` | Shared animation constants (`bmSpring`, `bmFade`) |
| `Core/Logging/Logger.swift` | OSLog wrapper for Principle III |
| `Core/Tracing/Tracer.swift` | Interaction trace events for Principle IV |
| `Core/Keychain/KeychainService.swift` | Secure token read/write |
| `Services/Network/APIClient.swift` | URLSession HTTP client (`async/await`) |
| `Services/Auth/AuthService.swift` | Google Sign-In + token lifecycle |

---

## 8. Architecture Quick Reference

```
SwiftUI View
  └── @Observable ViewModel
        └── Service (APIClient / AuthService / KeychainService)
              └── URLSession / Security.framework / GoogleSignIn
```

- Views only call ViewModel methods and read ViewModel state — no business logic in Views.
- ViewModels only call Service methods — no URLSession calls directly from ViewModels.
- All errors caught in Services are logged before re-throwing (Principle III).
- All meaningful user interactions in ViewModels emit a trace event (Principle IV).
- All UI colors reference `GrayscalePalette` — never literal `Color` values (Principle VI).

---

## 9. Grayscale Design Checklist (for each new View)

- [ ] Every `Color(...)` replaced with `GrayscalePalette.xxx`
- [ ] No SF Symbol uses `.multicolor` rendering mode — use `.hierarchical` or `.monochrome`
- [ ] Error states use SF Symbol + label text, not color alone
- [ ] Success/completion states use checkmark SF Symbol + label text, not color alone
- [ ] All screenshots in PRs are grayscale-verified
