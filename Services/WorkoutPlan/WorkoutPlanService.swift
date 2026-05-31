import Foundation

/// Fetches and saves the user's weekly workout-plan day selections via the BodyMetric API.
///
/// Uses `NetworkClientProtocol` so bearer token injection and 401 handling
/// are handled centrally by `NetworkClient` (Constitution Principle VII).
///
/// Constitution Principle I: pure Swift, URLSession only (via NetworkClient).
/// Constitution Principle III: status codes logged at INFO; no tokens or user data in logs.
/// Constitution Principle IV: traces delegated to callers (ViewModel).
@MainActor
final class WorkoutPlanService: WorkoutPlanServiceProtocol {

    // MARK: - Constants

    private static let baseURL = "https://api.bodymetric.com.br/api/workout-plans"

    // MARK: - Dependencies

    private let networkClient: any NetworkClientProtocol

    // MARK: - Init

    init(networkClient: any NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    // MARK: - WorkoutPlanServiceProtocol

    func fetchDays() async throws -> [WorkoutPlanDayResponse] {
        guard let url = URL(string: Self.baseURL) else {
            throw WorkoutPlanError.networkError(URLError(.badURL))
        }

        Logger.info("WorkoutPlanService: fetchDays initiated", category: .network)

        let data: Data
        let http: HTTPURLResponse

        do {
            (data, http) = try await networkClient.data(for: URLRequest(url: url))
        } catch {
            Logger.error("WorkoutPlanService: fetchDays network failure", error: error, category: .network)
            throw WorkoutPlanError.networkError(error)
        }

        Logger.info("WorkoutPlanService: fetchDays HTTP \(http.statusCode)", category: .network)

        switch http.statusCode {
        case 200:
            return try decode(data: data)
        case 404:
            throw WorkoutPlanError.notFound
        default:
            throw WorkoutPlanError.serverError(http.statusCode)
        }
    }

    func saveDays(_ days: [WorkoutPlanDayRequest]) async throws -> [WorkoutPlanDayResponse] {
        guard let url = URL(string: Self.baseURL) else {
            throw WorkoutPlanError.networkError(URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(days)
        } catch {
            Logger.error("WorkoutPlanService: saveDays encode failure", error: error, category: .network)
            throw WorkoutPlanError.networkError(error)
        }

        Logger.info("WorkoutPlanService: saveDays initiated dayCount:\(days.count)", category: .network)

        let data: Data
        let http: HTTPURLResponse

        do {
            (data, http) = try await networkClient.data(for: request)
        } catch {
            Logger.error("WorkoutPlanService: saveDays network failure", error: error, category: .network)
            throw WorkoutPlanError.networkError(error)
        }

        Logger.info("WorkoutPlanService: saveDays HTTP \(http.statusCode)", category: .network)

        guard http.statusCode == 201 else {
            throw WorkoutPlanError.serverError(http.statusCode)
        }

        // Try to decode 201 body; if the server returns a different format, return empty
        // and let the caller fall back to fetchDays() to retrieve the planIds.
        return (try? decodeArray(data: data)) ?? []
    }

    func fetchCurrentPlan() async throws -> CurrentWorkoutPlan {
        guard let url = URL(string: "\(Self.baseURL)/current") else {
            throw WorkoutPlanError.networkError(URLError(.badURL))
        }

        Logger.info("WorkoutPlanService: fetchCurrentPlan initiated", category: .network)

        let data: Data
        let http: HTTPURLResponse

        do {
            (data, http) = try await networkClient.data(for: URLRequest(url: url))
        } catch {
            Logger.error("WorkoutPlanService: fetchCurrentPlan network failure", error: error, category: .network)
            throw WorkoutPlanError.networkError(error)
        }

        Logger.info("WorkoutPlanService: fetchCurrentPlan HTTP \(http.statusCode)", category: .network)

        switch http.statusCode {
        case 200:
            do {
                return try JSONDecoder().decode(CurrentWorkoutPlan.self, from: data)
            } catch {
                Logger.error("WorkoutPlanService: fetchCurrentPlan decode failure", error: error, category: .network)
                throw WorkoutPlanError.decodingError
            }
        case 404:
            throw WorkoutPlanError.notFound
        default:
            throw WorkoutPlanError.serverError(http.statusCode)
        }
    }

    func updatePlan(id: Int, request: UpdateWorkoutPlanRequest) async throws {
        guard let url = URL(string: "\(Self.baseURL)/\(id)") else {
            throw WorkoutPlanError.networkError(URLError(.badURL))
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            Logger.error("WorkoutPlanService: updatePlan encode failure", error: error, category: .network)
            throw WorkoutPlanError.networkError(error)
        }

        Logger.info("WorkoutPlanService: updatePlan initiated planId:\(id)", category: .network)

        let http: HTTPURLResponse

        do {
            (_, http) = try await networkClient.data(for: urlRequest)
        } catch {
            Logger.error("WorkoutPlanService: updatePlan network failure", error: error, category: .network)
            throw WorkoutPlanError.networkError(error)
        }

        Logger.info("WorkoutPlanService: updatePlan HTTP \(http.statusCode)", category: .network)

        guard [200, 204].contains(http.statusCode) else {
            throw WorkoutPlanError.serverError(http.statusCode)
        }
    }

    private func decodeArray(data: Data) throws -> [WorkoutPlanDayResponse] {
        do {
            return try JSONDecoder().decode([WorkoutPlanDayResponse].self, from: data)
        } catch {
            Logger.error("WorkoutPlanService: saveDays decode failure", error: error, category: .network)
            throw WorkoutPlanError.decodingError
        }
    }

    // MARK: - Private

    private func decode(data: Data) throws -> [WorkoutPlanDayResponse] {
        do {
            return try JSONDecoder().decode([WorkoutPlanDayResponse].self, from: data)
        } catch {
            Logger.error("WorkoutPlanService: fetchDays decode failure", error: error, category: .network)
            throw WorkoutPlanError.decodingError
        }
    }
}
