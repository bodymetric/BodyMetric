import Foundation
import Observation

/// Navigation states driven by profile fetch outcomes.
enum HomeNavigationState: Equatable {
    case home
    case createUser
}

/// ViewModel for HomeView.
///
/// Owns the fetch-or-cache decision:
/// - If `ProfileStore.isComplete` → present cached data immediately (no network).
/// - If incomplete → call `UserProfileService.fetchProfile`, persist result.
/// - On 404 → set `navigationState = .createUser`.
/// - On other errors → set `errorMessage`; keep email visible.
///
/// Constitution Principle II: @Observable; all state is testable.
/// Constitution Principle III: errors logged with context; no PII in messages.
/// Constitution Principle IV: trace stubs present (wired when Tracer lands).
/// Constitution Principle V: `isLoading` set within 300 ms of call; no blocking work on MainActor.
@Observable
@MainActor
final class HomeViewModel {

    // MARK: - Published state

    private(set) var email: String
    private(set) var weight: Double?
    private(set) var weightUnit: String?
    private(set) var height: Double?
    private(set) var heightUnit: String?
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    private(set) var navigationState: HomeNavigationState = .home

    // MARK: - Dependencies

    private let profileService: UserProfileServiceProtocol
    private let profileStore: ProfileStore

    // MARK: - Init

    init(email: String,
         profileService: UserProfileServiceProtocol,
         profileStore: ProfileStore) {
        self.email = email
        self.profileService = profileService
        self.profileStore = profileStore
    }

    // MARK: - Load

    /// Entry point called from HomeView.onAppear and on session restore.
    func loadProfile() async {
        // Hydrate from cache first so the email is always visible.
        hydrateFromCache()

        guard !profileStore.isComplete else {
            Logger.info("Profile cache hit — skipping API call", category: .general)
            traceEvent("profile_cached_hit")
            return
        }

        isLoading = true
        errorMessage = nil
        traceEvent("profile_fetch_started")
        Logger.info("Profile fetch started", category: .network)

        defer { isLoading = false }

        do {
            var profile = try await profileService.fetchProfile(email: email)
            profile.email = email

            // Persist — log write outcome without exposing values (FR-003, G1 guard)
            persistProfile(profile)

            weight     = profile.weight
            weightUnit = profile.weightUnit
            height     = profile.height
            heightUnit = profile.heightUnit
            navigationState = .home

            traceEvent("profile_fetch_succeeded")
            Logger.info("Profile fetch succeeded", category: .network)

        } catch ProfileFetchError.userNotFound {
            Logger.info("Profile fetch: user not found — navigating to CreateUser", category: .network)
            traceEvent("profile_fetch_404")
            navigationState = .createUser

        } catch {
            let fetchError = error as? ProfileFetchError
            Logger.error("Profile fetch failed", error: error, category: .network)
            errorMessage = fetchError?.errorDescription
                ?? "Could not load profile. Please try again."
        }
    }

    // MARK: - Private helpers

    private func hydrateFromCache() {
        if let e = profileStore.email, !e.isEmpty { email = e }
        weight     = profileStore.weight
        weightUnit = profileStore.weightUnit
        height     = profileStore.height
        heightUnit = profileStore.heightUnit
    }

    /// Persist profile and handle write-failure gracefully (G1 remediation).
    private func persistProfile(_ profile: UserProfile) {
        // UserDefaults.set(_:forKey:) does not throw, but we log to signal
        // any future storage migration issues.
        profileStore.save(profile)
        // Verify the write round-tripped for the most critical field (weight).
        if profileStore.weight == nil {
            Logger.warning("ProfileStore write may have failed — weight not readable after save", category: .general)
            errorMessage = "Profile loaded but could not be saved locally. Data will reload next launch."
        }
    }

    // MARK: - Tracing stubs (Constitution Principle IV)
    // These are no-ops until the Tracer service is wired (feature 001 T008).
    // Event names use snake_case; no PII included in properties.

    private func traceEvent(_ name: String) {
        // TODO(Tracer): replace with Tracer.shared.trace(name, properties: [...])
        Logger.debug("Trace: \(name)", category: .general)
    }
}
