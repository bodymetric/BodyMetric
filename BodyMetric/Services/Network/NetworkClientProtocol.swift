import Foundation

/// Contract for the authenticated HTTP client.
///
/// Injects the `Authorization: Bearer <access-token>` header on every request
/// and transparently handles 401 responses by refreshing the token and
/// retrying the original request once (Constitution Principle VII).
@MainActor
protocol NetworkClientProtocol: AnyObject {

    /// Executes an HTTP request with bearer token injection and 401 retry.
    /// - Parameter request: The `URLRequest` to execute. The `Authorization` header
    ///   will be set or replaced automatically.
    /// - Returns: The response data and HTTP response.
    /// - Throws: `NetworkError.noToken` if no access token is available,
    ///   `NetworkError.unauthorized` if token refresh fails after 401.
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}
