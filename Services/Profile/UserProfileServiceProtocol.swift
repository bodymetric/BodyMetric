import Foundation

/// Contract for fetching a user's physical profile from the BodyMetric API.
///
/// The protocol boundary keeps ViewModels and unit tests independent of
/// URLSession and the concrete service implementation.
///
/// Constitution Principle I: Swift-only protocol; no Objective-C.
@MainActor
protocol UserProfileServiceProtocol: AnyObject {

    /// Fetch the profile for the given email address.
    ///
    /// - Parameter email: The authenticated user's email (URL-encoded by the implementation).
    /// - Returns: A `UserProfile` with the email injected and metrics populated from the API.
    /// - Throws: `ProfileFetchError` on any failure (404, 401, 5xx, network, decode).
    func fetchProfile(email: String) async throws -> UserProfile
}
