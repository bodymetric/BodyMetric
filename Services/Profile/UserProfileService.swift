import Foundation

/// Concrete implementation of `UserProfileServiceProtocol`.
///
/// Makes a single GET request to the BodyMetric API with the user's email
/// as a query parameter and decodes the JSON response into a `UserProfile`.
///
/// Constitution Principle I: pure Swift; URLSession only.
/// Constitution Principle III: status code logged at INFO; email never logged.
@MainActor
final class UserProfileService: UserProfileServiceProtocol {

    // MARK: - Constants

    private static let baseURL = "https://api.bodymetric.com.br/api/users"
    private static let timeoutInterval: TimeInterval = 10

    // MARK: - Dependencies

    private let session: URLSession

    // MARK: - Init

    init(session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = UserProfileService.timeoutInterval
        return URLSession(configuration: config)
    }()) {
        self.session = session
    }

    // MARK: - UserProfileServiceProtocol

    func fetchProfile(email: String) async throws -> UserProfile {
        let url = try buildURL(email: email)
        Logger.info("Profile fetch initiated", category: .network)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: url)
        } catch {
            Logger.error("Profile fetch network failure", error: error, category: .network)
            throw ProfileFetchError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            Logger.error("Profile fetch received non-HTTP response", category: .network)
            throw ProfileFetchError.networkError(URLError(.badServerResponse))
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
            profile.email = email // inject email — not present in response body
            if let w = profile.weight, w <= 0 {
                Logger.warning("Profile fetch: weight value ≤0, treating as invalid", category: .network)
            }
            if let h = profile.height, h <= 0 {
                Logger.warning("Profile fetch: height value ≤0, treating as invalid", category: .network)
            }
            return profile
        } catch {
            Logger.error("Profile fetch decode failure", error: error, category: .network)
            throw ProfileFetchError.decodingError
        }
    }
}
