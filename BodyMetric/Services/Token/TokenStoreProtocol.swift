import Foundation

/// Contract for the in-memory access token store.
///
/// The access token is NEVER written to disk. It lives only in memory
/// for the duration of the current app session (Constitution Principle VII).
///
/// Call `setRefreshAction(_:)` once after creating the coordinator to wire
/// up the proactive timer without creating a circular dependency at init time.
protocol TokenStoreProtocol: AnyObject, Sendable {

    /// The current in-memory access token, or `nil` if not authenticated.
    var accessToken: String? { get async }

    /// Stores the access token in memory and restarts the proactive refresh timer.
    func store(accessToken: String) async

    /// Clears the access token and cancels the proactive refresh timer.
    func clearAccessToken() async

    /// Wires up the action the proactive timer calls after its interval elapses.
    /// Call this once at app startup after both `TokenStore` and
    /// `TokenRefreshCoordinator` are fully initialized.
    func setRefreshAction(_ action: (@Sendable () async -> Void)?) async
}
