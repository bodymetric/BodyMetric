import Foundation

/// Persists step-2 wizard data: training day plans and exercise blocks.
///
/// Uses `NetworkClientProtocol` so bearer token injection and 401 handling
/// are handled centrally by `NetworkClient` (Constitution Principle VII).
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

    func saveDayPlan(workoutPlanId: Int, request: WorkoutDayPlanRequest) async throws -> WorkoutDayPlanResponse {
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

        Logger.info("WorkoutDayPlanService: saveDayPlan initiated workoutPlanId:\(workoutPlanId)", category: .network)

        let data: Data
        let http: HTTPURLResponse

        do {
            (data, http) = try await networkClient.data(for: urlRequest)
        } catch {
            Logger.error("WorkoutDayPlanService: saveDayPlan network failure", error: error, category: .network)
            throw WorkoutPlanError.networkError(error)
        }

        Logger.info("WorkoutDayPlanService: saveDayPlan HTTP \(http.statusCode)", category: .network)

        guard http.statusCode == 201 else {
            throw WorkoutPlanError.serverError(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(WorkoutDayPlanResponse.self, from: data)
        } catch {
            Logger.error("WorkoutDayPlanService: saveDayPlan decode failure", error: error, category: .network)
            throw WorkoutPlanError.decodingError
        }
    }

    func saveExerciseBlock(workoutDayPlanId: Int, request: ExerciseBlockPlanRequest) async throws {
        guard let url = URL(string: "\(Self.baseURL)/workout-day-plans/\(workoutDayPlanId)/exercise-blocks") else {
            throw WorkoutPlanError.networkError(URLError(.badURL))
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            Logger.error("WorkoutDayPlanService: saveExerciseBlock encode failure", error: error, category: .network)
            throw WorkoutPlanError.networkError(error)
        }

        Logger.info("WorkoutDayPlanService: saveExerciseBlock initiated workoutDayPlanId:\(workoutDayPlanId)", category: .network)

        let http: HTTPURLResponse

        do {
            (_, http) = try await networkClient.data(for: urlRequest)
        } catch {
            Logger.error("WorkoutDayPlanService: saveExerciseBlock network failure", error: error, category: .network)
            throw WorkoutPlanError.networkError(error)
        }

        Logger.info("WorkoutDayPlanService: saveExerciseBlock HTTP \(http.statusCode)", category: .network)

        guard http.statusCode == 201 else {
            throw WorkoutPlanError.serverError(http.statusCode)
        }
    }
}
