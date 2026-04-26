import Foundation

/// Exchanges a Google Sign-In id token for a BodyMetric session token pair.
///
/// Calls `POST /api/auth/google` with the Google id token and decodes
/// the backend-issued access token and refresh token from the response.
///
/// Constitution Principle I: pure Swift, URLSession only.
/// Constitution Principle III: errors logged before surfacing; id token never logged.
@MainActor
final class TokenExchangeService: TokenExchangeServiceProtocol {

    // MARK: - Constants

    private static let endpoint = "https://api.bodymetric.com.br/api/auth/google"
    private static let timeout: TimeInterval = 10

    // MARK: - Dependencies

    private let session: URLSession

    // MARK: - Init

    init(session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = TokenExchangeService.timeout
        return URLSession(configuration: cfg)
    }()) {
        self.session = session
    }

    // MARK: - TokenExchangeServiceProtocol

    func exchange(googleIdToken: String) async throws -> TokenExchangeResponse {
        guard let url = URL(string: Self.endpoint) else {
            Logger.error("TokenExchangeService: invalid endpoint URL", category: .auth)
            throw AuthError.tokenExchangeFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(["googleToken": googleIdToken])
        } catch {
            Logger.error("TokenExchangeService: failed to encode request body", error: error,
                         category: .auth)
            throw AuthError.tokenExchangeFailed
        }

        if let bodyData = request.httpBody {
               print("➡️ BODY:", String(data: bodyData, encoding: .utf8) ?? "")
           }
        
        Logger.info("TokenExchangeService: exchange started", category: .auth)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
            
        } catch {
            Logger.error("TokenExchangeService: network failure during exchange",
                         error: error, category: .auth)
            throw AuthError.tokenExchangeFailed
        }

        guard let http = response as? HTTPURLResponse else {
            Logger.error("TokenExchangeService: non-HTTP response received", category: .auth)
            throw AuthError.tokenExchangeFailed
        }

        Logger.info("TokenExchangeService: response HTTP \(http.statusCode)", category: .auth)

        let responseBody = String(data: data, encoding: .utf8) ?? ""
                    print("⬅️ BODY:", responseBody)
        
        guard http.statusCode == 200 else {
            Logger.error("TokenExchangeService: exchange rejected (status \(http.statusCode))",
                         category: .auth)
            throw AuthError.tokenExchangeFailed
        }

        do {
            return try JSONDecoder().decode(TokenExchangeResponse.self, from: data)
        } catch {
            Logger.error("TokenExchangeService: failed to decode exchange response",
                         error: error, category: .auth)
            throw AuthError.tokenExchangeFailed
        }
    }
}
