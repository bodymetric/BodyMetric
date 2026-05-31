import Foundation

/// Starts a workout execution session via `POST /api/work-executions/start`.
///
/// Uses `NetworkClientProtocol` so Bearer token injection and 401 handling
/// are handled centrally by `NetworkClient` (Constitution Principle VII).
///
/// Constitution Principle I: pure Swift, URLSession only (via NetworkClient).
/// Constitution Principle III: status codes logged at INFO; errors at ERROR; no tokens or PII in logs.
@MainActor
final class WorkoutExecutionService: WorkoutExecutionServiceProtocol {

    // MARK: - Constants

    private static let baseURL = "https://api.bodymetric.com.br/api/work-executions"

    // MARK: - Dependencies

    private let networkClient: any NetworkClientProtocol

    // MARK: - Init

    init(networkClient: any NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    // MARK: - WorkoutExecutionServiceProtocol

    func startSession(_ request: StartSessionRequest) async throws -> StartSessionResponse {
        guard let url = URL(string: "\(Self.baseURL)/start") else {
            throw WorkoutPlanError.networkError(URLError(.badURL))
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            Logger.error("WorkoutExecutionService: startSession encode failure", error: error, category: .network)
            throw WorkoutPlanError.networkError(error)
        }

        Logger.info(
            "WorkoutExecutionService: startSession planId:\(request.planId) feeling:\(request.feeling)",
            category: .network
        )

        let data: Data
        let http: HTTPURLResponse

        do {
            (data, http) = try await networkClient.data(for: urlRequest)
        } catch {
            Logger.error("WorkoutExecutionService: startSession network failure", error: error, category: .network)
            throw WorkoutPlanError.networkError(error)
        }

        Logger.info("WorkoutExecutionService: startSession HTTP \(http.statusCode)", category: .network)

        guard [200, 201].contains(http.statusCode) else {
            throw WorkoutPlanError.serverError(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(StartSessionResponse.self, from: data)
        } catch {
            Logger.error("WorkoutExecutionService: startSession decode failure", error: error, category: .network)
            throw WorkoutPlanError.decodingError
        }
    }
}
