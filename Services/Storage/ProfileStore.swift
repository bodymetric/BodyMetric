import Foundation

/// UserDefaults-backed store for the authenticated user's display profile.
///
/// Stores name, email, weight, weightUnit, height, and heightUnit. These are
/// non-sensitive display values; auth tokens live in Keychain (separate concern).
/// Data survives app termination and relaunch.
///
/// Completeness gate (feature 005): `isComplete` requires name + height + weight.
/// Unit fields are supplemental and do NOT block the gate.
///
/// Constitution Principle I: pure Swift; no Objective-C.
/// Constitution Principle III: no PII written to any log in this class.
final class ProfileStore {

    // MARK: - Keys

    private enum Key {
        static let userId     = "bm.profile.userId"
        static let name       = "bm.profile.name"
        static let email      = "bm.profile.email"
        static let weight     = "bm.profile.weight"
        static let weightUnit = "bm.profile.weightUnit"
        static let height     = "bm.profile.height"
        static let heightUnit = "bm.profile.heightUnit"
    }

    // MARK: - Dependencies

    private let defaults: UserDefaults

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Read

    /// The backend-assigned user ID. `nil` if the user has never signed in on this device.
    var userId: Int? {
        let v = defaults.integer(forKey: Key.userId)
        return v > 0 ? v : nil
    }

    var name: String?   { defaults.string(forKey: Key.name) }
    var email: String?  { defaults.string(forKey: Key.email) }
    var weight: Double? {
        defaults.object(forKey: Key.weight) == nil ? nil : defaults.double(forKey: Key.weight)
    }
    var weightUnit: String? { defaults.string(forKey: Key.weightUnit) }
    var height: Double? {
        defaults.object(forKey: Key.height) == nil ? nil : defaults.double(forKey: Key.height)
    }
    var heightUnit: String? { defaults.string(forKey: Key.heightUnit) }

    /// `true` when name, height, and weight are all present and valid.
    /// Unit fields are NOT required for the gate — they are display supplements.
    var isComplete: Bool {
        guard let n = name, !n.trimmingCharacters(in: .whitespaces).isEmpty,
              let h = height, h > 0,
              let w = weight, w > 0 else { return false }
        return true
    }

    // MARK: - Write

    /// Persist all profile fields from a fetched `UserProfile`.
    func save(_ profile: UserProfile) {
        if let n = profile.name        { defaults.set(n, forKey: Key.name) }
        defaults.set(profile.email, forKey: Key.email)
        if let w = profile.weight      { defaults.set(w, forKey: Key.weight) }
        if let wu = profile.weightUnit { defaults.set(wu, forKey: Key.weightUnit) }
        if let h = profile.height      { defaults.set(h, forKey: Key.height) }
        if let hu = profile.heightUnit { defaults.set(hu, forKey: Key.heightUnit) }
    }

    /// Persist all available fields from an `AuthUser` (login-time response).
    /// Always saves `userId` so it is available for subsequent API calls even
    /// when the profile is incomplete (name/height/weight may be nil).
    func save(from user: AuthUser) {
        defaults.set(user.id, forKey: Key.userId)
        if let n = user.name   { defaults.set(n, forKey: Key.name) }
        defaults.set(user.email, forKey: Key.email)
        if let h = user.height { defaults.set(h, forKey: Key.height) }
        if let w = user.weight { defaults.set(w, forKey: Key.weight) }
    }

    /// Persist only the email (e.g. right after sign-in, before API call).
    func saveEmail(_ email: String) {
        defaults.set(email, forKey: Key.email)
    }

    /// Remove all profile data (e.g. on sign-out).
    func clear() {
        [Key.userId, Key.name, Key.email, Key.weight, Key.weightUnit, Key.height, Key.heightUnit]
            .forEach { defaults.removeObject(forKey: $0) }
    }
}
