import Foundation

/// Contract for submitting a completed user profile to the BodyMetric API.
///
/// Constitution Principle I: Swift-only protocol; no Objective-C.
@MainActor
protocol UpdateProfileServiceProtocol: AnyObject {

    /// Send a `POST /api/users` request with the completed profile payload.
    ///
    /// - Parameter request: Validated profile fields ready to be persisted.
    /// - Returns: The backend-confirmed `AuthUser` on HTTP 201.
    /// - Throws: `ProfileUpdateError` on any failure (non-201, network, decode).
    func updateProfile(_ request: UpdateProfileRequest) async throws -> AuthUser
}
