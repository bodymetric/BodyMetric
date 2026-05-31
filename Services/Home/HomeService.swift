import Foundation

/// Fetches home screen data from the BodyMetric API.
///
/// Constitution Principle I: pure Swift, URLSession only (via NetworkClient).
/// Constitution Principle III: status codes logged; no PII in logs.
@MainActor
final class HomeService: HomeServiceProtocol {

    // MARK: - Constants

    private static let baseURL = "https://api.bodymetric.com.br/api/home"

    // MARK: - Dependencies

    private let networkClient: any NetworkClientProtocol

    // MARK: - Init

    init(networkClient: any NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    // MARK: - HomeServiceProtocol

    func fetchHomeData() async throws -> HomeScreenData {
        guard let url = URL(string: Self.baseURL) else {
            throw WorkoutPlanError.networkError(URLError(.badURL))
        }

        Logger.info("HomeService: fetchHomeData initiated", category: .network)

        let data: Data
        let http: HTTPURLResponse

        do {
            (data, http) = try await networkClient.data(for: URLRequest(url: url))
        } catch {
            Logger.error("HomeService: network failure", error: error, category: .network)
            throw WorkoutPlanError.networkError(error)
        }

        Logger.info("HomeService: HTTP \(http.statusCode)", category: .network)

        // 400/404 treated as "no data" — endpoint may not be ready yet or user has no data.
        if http.statusCode == 400 || http.statusCode == 404 {
            Logger.info("HomeService: treating \(http.statusCode) as empty home data", category: .network)
            return HomeScreenData(currentWorkoutDayPlan: nil, exercisesForToday: nil)
        }

        guard http.statusCode == 200 else {
            throw WorkoutPlanError.serverError(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(HomeScreenData.self, from: data)
        } catch {
            Logger.error("HomeService: decode failure", error: error, category: .network)
            throw WorkoutPlanError.decodingError
        }
    }
}
