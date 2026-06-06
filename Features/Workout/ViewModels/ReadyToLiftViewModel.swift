import Foundation
import Observation

/// State machine for the "Ready to Lift" check-in screen.
///
/// Owns the `POST /api/work-executions/start` call lifecycle.
/// Constitution Principle III: all errors logged; no PII or tokens in log entries.
/// Constitution Principle IV: interaction traces via Logger.info.
@Observable
@MainActor
final class ReadyToLiftViewModel {

    // MARK: - Load state

    enum LoadState: Equatable {
        case idle
        case submitting
        case failed(String)
    }

    // MARK: - State

    var loadState: LoadState = .idle
    var sessionResponse: StartWorkoutResponse? = nil

    // MARK: - Derived

    var isSubmitting: Bool { loadState == .submitting }

    // MARK: - Begin session

    /// Starts a workout execution session. Re-entry while submitting is blocked.
    func beginSession(
        planId: Int,
        actualWeekNumber: Int,
        feeling: String,
        using service: any WorkoutExecutionServiceProtocol
    ) async {
        guard !isSubmitting else { return }
        loadState = .submitting
        Logger.info("session_begin_started planId:\(planId) feeling:\(feeling.uppercased())")

        let request = StartSessionRequest(
            planId: planId,
            actualWeekNumber: actualWeekNumber,
            feeling: feeling.uppercased()
        )

        do {
            let response = try await service.startSession(request)
            sessionResponse = response
            loadState = .idle
            Logger.info("session_begin_success planId:\(planId)")
        } catch {
            Logger.error("session_begin_failed", error: error)
            loadState = .failed("Could not start your session. Please try again.")
        }
    }
}
