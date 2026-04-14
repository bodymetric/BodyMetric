import Foundation

/// Submits a completed user profile to the BodyMetric API via `PUT /api/users/{userId}`.
///
/// Bearer token injection and 401 handling are provided by `NetworkClient`.
///
/// Constitution Principle I: pure Swift, URLSession via NetworkClient.
/// Constitution Principle III: errors logged before surfacing; no field values logged.
/// Constitution Principle IV: tracing stubs for profile_completion events.
/// Constitution Principle VII: bearer header injected by NetworkClient automatically.
@MainActor
final class UpdateProfileService: UpdateProfileServiceProtocol {

    // MARK: - Constants

    private static let endpoint = "https://api.bodymetric.com.br/api/users"

    // MARK: - Dependencies

    private let networkClient: NetworkClientProtocol

    // MARK: - Init

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    // MARK: - UpdateProfileServiceProtocol

    func updateProfile(_ request: UpdateProfileRequest) async throws -> AuthUser {
        guard let url = URL(string: Self.endpoint) else {
            Logger.error("UpdateProfileService: invalid endpoint URL", category: .network)
            throw ProfileUpdateError.networkError
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            Logger.error("UpdateProfileService: failed to encode request body",
                         error: error, category: .network)
            throw ProfileUpdateError.networkError
        }

        Logger.info("UpdateProfileService: sending PUT /api/users", category: .network)

        let data: Data
        let response: HTTPURLResponse

        do {
            (data, response) = try await networkClient.data(for: urlRequest)
        } catch {
            Logger.error("UpdateProfileService: network failure",
                         error: error, category: .network)
            throw ProfileUpdateError.networkError
        }

        Logger.info("UpdateProfileService: response HTTP \(response.statusCode)",
                    category: .network)

        guard response.statusCode == 200 || response.statusCode == 201 else {
            Logger.error("UpdateProfileService: server rejected update (status \(response.statusCode))",
                         category: .network)
            throw ProfileUpdateError.serverError(response.statusCode)
        }

        do {
            return try JSONDecoder().decode(AuthUser.self, from: data)
        } catch {
            Logger.error("UpdateProfileService: failed to decode response",
                         error: error, category: .network)
            throw ProfileUpdateError.decodingError
        }
    }
}

// MARK: - Error type

/// Errors thrown by `UpdateProfileService`.
enum ProfileUpdateError: LocalizedError {
    case serverError(Int)
    case networkError
    case decodingError

    var errorDescription: String? {
        switch self {
        case .serverError(let code):
            return "Server returned an error (\(code)). Please try again."
        case .networkError:
            return "Could not reach the server. Check your connection and try again."
        case .decodingError:
            return "Received an unexpected response. Please try again."
        }
    }
}
