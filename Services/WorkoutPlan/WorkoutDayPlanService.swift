import Foundation

/// Persists step-2 wizard data: unified day plan with embedded exercise blocks.
///
/// Feature 013: single POST per day (replaces two-step save from feature 011).
/// Accepts both 200 and 201 as success. Response body is not consumed.
///
/// Constitution Principle I: pure Swift, URLSession only (via NetworkClient).
/// Constitution Principle III: status codes logged; no tokens or PII in logs.
@MainActor
final class WorkoutDayPlanService: WorkoutDayPlanServiceProtocol {

    // MARK: - Constants

    private static let baseURL = "https://api.bodymetric.com.br/api"

    // MARK: - Dependencies

    private let networkClient: any NetworkClientProtocol

    // MARK: - Init

    init(networkClient: any NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    // MARK: - WorkoutDayPlanServiceProtocol

    func saveDayPlan(workoutPlanId: Int, request: WorkoutDayPlanRequest) async throws {
        guard let url = URL(string: "\(Self.baseURL)/workout-plans/\(workoutPlanId)/days") else {
            throw WorkoutPlanError.networkError(URLError(.badURL))
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            Logger.error("WorkoutDayPlanService: saveDayPlan encode failure", error: error, category: .network)
            throw WorkoutPlanError.networkError(error)
        }

        Logger.info(
            "WorkoutDayPlanService: saveDayPlan initiated workoutPlanId:\(workoutPlanId) blocks:\(request.exerciseBlocks.count)",
            category: .network
        )

        let http: HTTPURLResponse

        do {
            (_, http) = try await networkClient.data(for: urlRequest)
        } catch {
            Logger.error("WorkoutDayPlanService: saveDayPlan network failure", error: error, category: .network)
            throw WorkoutPlanError.networkError(error)
        }

        Logger.info("WorkoutDayPlanService: saveDayPlan HTTP \(http.statusCode)", category: .network)

        // Accept 200 OK and 201 Created (spec FR-005)
        guard [200, 201].contains(http.statusCode) else {
            throw WorkoutPlanError.serverError(http.statusCode)
        }
    }
}
