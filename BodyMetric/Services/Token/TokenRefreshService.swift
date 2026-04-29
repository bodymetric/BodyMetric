import Foundation

/// Exchanges the stored refresh token for a new access token.
///
/// Calls `POST /api/auth/refresh` — this endpoint does NOT require an
/// Authorization header; the refresh token itself is the credential.
///
/// Constitution Principle I: pure Swift, URLSession only.
/// Constitution Principle III: errors logged; refresh token NEVER logged.
@MainActor
final class TokenRefreshService: TokenRefreshServiceProtocol {

    // MARK: - Constants

    private static let endpoint = "https://api.bodymetric.com.br/api/auth/refresh"
    private static let timeout: TimeInterval = 10

    // MARK: - Dependencies

    private let session: URLSession

    // MARK: - Init

    init(session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = TokenRefreshService.timeout
        return URLSession(configuration: cfg)
    }()) {
        self.session = session
    }

    // MARK: - TokenRefreshServiceProtocol

    func refresh(using refreshToken: String) async throws -> TokenRefreshResponse {
        guard let url = URL(string: Self.endpoint) else {
            Logger.error("TokenRefreshService: invalid endpoint URL", category: .auth)
            throw AuthError.tokenExchangeFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // NOTE: No Authorization header — the refresh token IS the credential.

        do {
            request.httpBody = try JSONEncoder().encode(["refreshToken": refreshToken])
        } catch {
            Logger.error("TokenRefreshService: failed to encode request body",
                         error: error, category: .auth)
            throw AuthError.tokenExchangeFailed
        }

        Logger.info("TokenRefreshService: refresh started", category: .auth)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            Logger.error("TokenRefreshService: network failure during refresh",
                         error: error, category: .auth)
            throw AuthError.tokenExchangeFailed
        }

        guard let http = response as? HTTPURLResponse else {
            Logger.error("TokenRefreshService: non-HTTP response", category: .auth)
            throw AuthError.tokenExchangeFailed
        }

        Logger.info("TokenRefreshService: response HTTP \(http.statusCode)", category: .auth)

        guard http.statusCode == 200 else {
            Logger.error("TokenRefreshService: refresh rejected (status \(http.statusCode))",
                         category: .auth)
            throw AuthError.tokenExchangeFailed
        }

        do {
            return try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
        } catch {
            Logger.error("TokenRefreshService: failed to decode refresh response",
                         error: error, category: .auth)
            throw AuthError.tokenExchangeFailed
        }
    }
}
