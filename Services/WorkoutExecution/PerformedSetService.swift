import Foundation

/// Records performed sets via `POST /api/exercise-block-executions/{id}/performed-sets`.
///
/// Constitution Principle I: pure Swift, URLSession only (via NetworkClient).
/// Constitution Principle III: status codes logged at INFO; errors at ERROR; no weight/rep values in logs.
/// Constitution Principle VII: Bearer token injected centrally by `NetworkClient`.
@MainActor
final class PerformedSetService: PerformedSetServiceProtocol {

    // MARK: - Constants

    private static let baseURL = "https://api.bodymetric.com.br/api/exercise-block-executions"

    // MARK: - Dependencies

    private let networkClient: any NetworkClientProtocol

    // MARK: - Init

    init(networkClient: any NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    // MARK: - PerformedSetServiceProtocol

    func logPerformedSet(exerciseBlockExecutionId: Int, weight: Double, reps: Int) async throws {
        guard let url = URL(string: "\(Self.baseURL)/\(exerciseBlockExecutionId)/performed-sets") else {
            throw WorkoutPlanError.networkError(URLError(.badURL))
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(LogPerformedSetRequest(weight: weight, reps: reps))
        } catch {
            Logger.error("PerformedSetService: encode failure for executionId:\(exerciseBlockExecutionId)", error: error, category: .network)
            throw WorkoutPlanError.networkError(error)
        }

        Logger.info("PerformedSetService: logPerformedSet executionId:\(exerciseBlockExecutionId)", category: .network)

        let data: Data
        let http: HTTPURLResponse

        do {
            (data, http) = try await networkClient.data(for: urlRequest)
        } catch {
            Logger.error("PerformedSetService: network failure executionId:\(exerciseBlockExecutionId)", error: error, category: .network)
            throw WorkoutPlanError.networkError(error)
        }

        Logger.info("PerformedSetService: HTTP \(http.statusCode) executionId:\(exerciseBlockExecutionId)", category: .network)

        guard [200, 201].contains(http.statusCode) else {
            throw WorkoutPlanError.serverError(http.statusCode)
        }

        _ = data
    }
}
