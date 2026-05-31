import Foundation

/// Fetches the exercise catalogue from the BodyMetric API.
///
/// Uses `NetworkClientProtocol` so bearer token injection and 401 handling
/// are handled centrally by `NetworkClient` (Constitution Principle VII).
///
/// Constitution Principle I: pure Swift, URLSession only (via NetworkClient).
/// Constitution Principle III: status codes logged; no tokens or PII in logs.
@MainActor
final class ExerciseService: ExerciseServiceProtocol {

    // MARK: - Constants

    private static let baseURL = "https://api.bodymetric.com.br/api/exercises"

    // MARK: - Dependencies

    private let networkClient: any NetworkClientProtocol

    // MARK: - Init

    init(networkClient: any NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    // MARK: - ExerciseServiceProtocol

    func fetchExerciseCatalog() async throws -> [ExerciseCatalogGroup] {
        guard let url = URL(string: Self.baseURL) else {
            throw WorkoutPlanError.networkError(URLError(.badURL))
        }

        Logger.info("ExerciseService: fetchExerciseCatalog initiated", category: .network)

        let data: Data
        let http: HTTPURLResponse

        do {
            (data, http) = try await networkClient.data(for: URLRequest(url: url))
        } catch {
            Logger.error("ExerciseService: network failure", error: error, category: .network)
            throw WorkoutPlanError.networkError(error)
        }

        Logger.info("ExerciseService: HTTP \(http.statusCode)", category: .network)

        guard http.statusCode == 200 else {
            throw WorkoutPlanError.serverError(http.statusCode)
        }

        do {
            return try JSONDecoder().decode([ExerciseCatalogGroup].self, from: data)
        } catch {
            Logger.error("ExerciseService: decode failure", error: error, category: .network)
            throw WorkoutPlanError.decodingError
        }
    }
}
