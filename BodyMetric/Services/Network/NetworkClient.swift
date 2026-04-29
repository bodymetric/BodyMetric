import Foundation

/// Authenticated HTTP client.
///
/// Injects `Authorization: Bearer <access-token>` on every request and
/// transparently handles 401 responses by:
///   1. Delegating to `TokenRefreshCoordinator` (serialized — one refresh at a time).
///   2. Retrying the original request once with the refreshed token.
///
/// If token refresh fails, `NetworkError.unauthorized` is thrown and the coordinator
/// is responsible for signing the user out.
///
/// Constitution Principle I: pure Swift, URLSession only.
/// Constitution Principle III: tokens never logged; only status codes and error categories.
/// Constitution Principle IV: `token_refresh_on_401` event traced.
/// Constitution Principle VII: bearer token injected on every authenticated request.
@MainActor
final class NetworkClient: NetworkClientProtocol {

    // MARK: - Dependencies

    private let tokenStore: any TokenStoreProtocol
    private let coordinator: any TokenRefreshCoordinatorProtocol
    private let session: URLSession

    // MARK: - Init

    init(
        tokenStore: any TokenStoreProtocol,
        coordinator: any TokenRefreshCoordinatorProtocol,
        session: URLSession = URLSession.shared
    ) {
        self.tokenStore = tokenStore
        self.coordinator = coordinator
        self.session = session
    }

    // MARK: - Exempt path prefixes (FR-002)

    private static let exemptPathPrefixes = ["/api/auth/", "/q/", "/version"]

    private func isExemptPath(_ request: URLRequest) -> Bool {
        guard let path = request.url?.path else { return false }
        return Self.exemptPathPrefixes.contains { path.hasPrefix($0) }
    }

    // MARK: - NetworkClientProtocol

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        // Exempt paths (auth, public query, version) skip token injection entirely (FR-002).
        if isExemptPath(request) {
            return try await executeUnauthenticated(request)
        }

        guard let token = await tokenStore.accessToken else {
            Logger.warning("NetworkClient: no access token — request blocked", category: .network)
            throw NetworkError.noToken
        }

        let firstResponse = try await execute(request, bearerToken: token)

        // If 401: refresh token and retry exactly once.
        guard firstResponse.1.statusCode == 401 else {
            return firstResponse
        }

        Logger.info("NetworkClient: received 401 — triggering token refresh", category: .network)
        traceEvent("token_refresh_on_401")

        do {
            try await coordinator.refresh(tokenStore: tokenStore)
        } catch {
            Logger.error("NetworkClient: token refresh failed after 401",
                         error: error, category: .network)
            throw NetworkError.unauthorized
        }

        guard let refreshedToken = await tokenStore.accessToken else {
            throw NetworkError.unauthorized
        }

        Logger.info("NetworkClient: retrying original request with refreshed token",
                    category: .network)
        return try await execute(request, bearerToken: refreshedToken)
    }

    // MARK: - Private

    private func executeUnauthenticated(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.httpError(-1)
        }
        return (data, http)
    }

    private func execute(_ request: URLRequest, bearerToken: String) async throws -> (Data, HTTPURLResponse) {
        var req = request
        req.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.httpError(-1)
        }
        return (data, http)
    }

    // MARK: - Tracing stub (Constitution Principle IV)

    private func traceEvent(_ name: String) {
        Logger.debug("Trace: \(name)", category: .general)
    }
}
