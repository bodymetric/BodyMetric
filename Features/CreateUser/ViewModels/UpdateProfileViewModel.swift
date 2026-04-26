import Foundation
import Observation

/// Navigation states for the profile completion form.
enum ProfileNavigationState: Equatable {
    case form
    case home
}

/// ViewModel for the mandatory profile completion form.
///
/// Handles: client-side validation, submission, loading / success / error states,
/// ProfileStore persistence on success, and the 4-second success → home redirect.
///
/// Constitution Principle II: @Observable; all state is testable via `MockUpdateProfileService`.
/// Constitution Principle III: errors logged; no field values (name/email) in log messages.
/// Constitution Principle IV: trace events emitted at start/success/failure.
/// Constitution Principle V: loading feedback within 200 ms of tap.
@Observable
@MainActor
final class UpdateProfileViewModel {

    // MARK: - Form state

    var name: String = ""
    var heightText: String = ""
    var weightText: String = ""

    // MARK: - UI state

    private(set) var isLoading: Bool = false
    private(set) var isSuccess: Bool = false
    private(set) var errorMessage: String? = nil
    private(set) var navigationState: ProfileNavigationState = .form

    // MARK: - Read-only email (pre-filled, not editable)

    let email: String

    // MARK: - Dependencies

    private let updateService: UpdateProfileServiceProtocol
    private let profileStore: ProfileStore
    private let authService: AuthServiceProtocol
    private let redirectDelay: TimeInterval

    // MARK: - Init

    /// - Parameters:
    ///   - email: Pre-filled from the authenticated session. Sent with the request.
    ///   - updateService: Injectable for testing.
    ///   - profileStore: Persisted on success.
    ///   - authService: `needsProfileSetup` cleared on success.
    ///   - redirectDelay: Seconds to wait after showing success before navigating home.
    ///     Default is 4.0. Override with a small value (e.g. 0.05) in tests.
    init(
        email: String,
        updateService: UpdateProfileServiceProtocol,
        profileStore: ProfileStore,
        authService: AuthServiceProtocol,
        redirectDelay: TimeInterval = 4.0
    ) {
        self.email = email
        self.updateService = updateService
        self.profileStore = profileStore
        self.authService = authService
        self.redirectDelay = redirectDelay
    }

    // MARK: - Submit

    /// Validates form fields and sends `PUT /api/users/{userId}` if valid.
    /// Sets `isSuccess = true` on HTTP 200/201, then navigates home after `redirectDelay`.
    func submit() async {
        guard validate() else { return }

        let height = Double(heightText) ?? 0
        let weight = Double(weightText) ?? 0
        let request = UpdateProfileRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            email: email,
            height: height,
            weight: weight
        )

        isLoading = true
        errorMessage = nil
        traceEvent("profile_completion_started")
        Logger.info("UpdateProfileViewModel: submission started", category: .network)

        do {
            let user = try await updateService.updateProfile(request)

            profileStore.save(from: user)
            authService.clearNeedsProfileSetup()

            isLoading = false
            isSuccess = true
            traceEvent("profile_completion_succeeded")
            Logger.info("UpdateProfileViewModel: submission succeeded", category: .network)

            // Navigate home after the success message delay.
            try? await Task.sleep(for: .seconds(redirectDelay))
            navigationState = .home

        } catch {
            isLoading = false
            isSuccess = false
            traceEvent("profile_completion_failed")
            Logger.error("UpdateProfileViewModel: submission failed",
                         error: error, category: .network)

            errorMessage = (error as? ProfileUpdateError)?.errorDescription
                ?? "Something went wrong. Please try again."
        }
    }

    // MARK: - Validation

    /// Returns `true` if all fields pass. Sets `errorMessage` and returns `false` on failure.
    @discardableResult
    private func validate() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if trimmedName.isEmpty {
            errorMessage = "Name is required."
            return false
        }
        if trimmedName.count > 20 {
            errorMessage = "Name must be 20 characters or fewer."
            return false
        }
        guard let h = Double(heightText), h > 0 else {
            errorMessage = "Height must be a positive number."
            return false
        }
        guard let w = Double(weightText), w > 0 else {
            errorMessage = "Weight must be a positive number."
            return false
        }
        _ = h; _ = w
        errorMessage = nil
        return true
    }

    // MARK: - Tracing stub (Constitution Principle IV)

    private func traceEvent(_ name: String) {
        // TODO(Tracer): replace with Tracer.shared.trace(name)
        Logger.debug("Trace: \(name)", category: .general)
    }
}

