import Foundation

/// Fetches a user's profile from the BodyMetric API.
///
/// Uses `NetworkClientProtocol` so bearer token injection and 401 handling
/// are handled centrally by `NetworkClient` (Constitution Principle VII).
///
/// Constitution Principle I: pure Swift.
/// Constitution Principle III: status code logged at INFO; email never logged.
@MainActor
final class UserProfileService: UserProfileServiceProtocol {

    // MARK: - Constants

    private static let baseURL = "https://api.bodymetric.com.br/api/users"

    // MARK: - Dependencies

    private let networkClient: NetworkClientProtocol

    // MARK: - Init

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    // MARK: - UserProfileServiceProtocol

    func fetchProfile(email: String) async throws -> UserProfile {
        let url = try buildURL(email: email)
        Logger.info("Profile fetch initiated", category: .network)

        let data: Data
        let http: HTTPURLResponse

        do {
            (data, http) = try await networkClient.data(for: URLRequest(url: url))
        } catch let netErr as NetworkError {
            Logger.error("Profile fetch blocked by auth layer: \(netErr)", category: .network)
            throw ProfileFetchError.unauthorized
        } catch {
            Logger.error("Profile fetch network failure", error: error, category: .network)
            throw ProfileFetchError.networkError(error)
        }

        Logger.info("Profile fetch response: HTTP \(http.statusCode)", category: .network)

        switch http.statusCode {
        case 200:
            return try decode(data: data, email: email)
        case 404:
            throw ProfileFetchError.userNotFound
        case 401:
            throw ProfileFetchError.unauthorized
        default:
            throw ProfileFetchError.serverError(http.statusCode)
        }
    }

    // MARK: - Private helpers

    private func buildURL(email: String) throws -> URL {
        var components = URLComponents(string: Self.baseURL)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]
        guard let url = components?.url else {
            throw ProfileFetchError.networkError(URLError(.badURL))
        }
        return url
    }

    private func decode(data: Data, email: String) throws -> UserProfile {
        do {
            var profile = try JSONDecoder().decode(UserProfile.self, from: data)
            profile.email = email
            if let w = profile.weight, w <= 0 {
                Logger.warning("Profile fetch: weight value ≤0, treating as invalid",
                               category: .network)
            }
            if let h = profile.height, h <= 0 {
                Logger.warning("Profile fetch: height value ≤0, treating as invalid",
                               category: .network)
            }
            return profile
        } catch {
            Logger.error("Profile fetch decode failure", error: error, category: .network)
            throw ProfileFetchError.decodingError
        }
    }
}
