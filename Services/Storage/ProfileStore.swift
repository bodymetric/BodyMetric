import Foundation

/// UserDefaults-backed store for the authenticated user's display profile.
///
/// Stores email, weight, weightUnit, height, and heightUnit. These are
/// non-sensitive display values; auth tokens live in Keychain (separate
/// concern). Data survives app termination and relaunch (FR-007).
///
/// Constitution Principle I: pure Swift; no Objective-C.
/// Constitution Principle III: no PII written to any log in this class.
final class ProfileStore {

    // MARK: - Keys

    private enum Key {
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

    var email: String? { defaults.string(forKey: Key.email) }
    var weight: Double? {
        defaults.object(forKey: Key.weight) == nil ? nil : defaults.double(forKey: Key.weight)
    }
    var weightUnit: String? { defaults.string(forKey: Key.weightUnit) }
    var height: Double? {
        defaults.object(forKey: Key.height) == nil ? nil : defaults.double(forKey: Key.height)
    }
    var heightUnit: String? { defaults.string(forKey: Key.heightUnit) }

    /// `true` when all five profile fields are present and non-empty.
    /// Used by HomeViewModel to skip redundant API calls (FR-008).
    var isComplete: Bool {
        guard let e = email, !e.isEmpty,
              let w = weight, w > 0,
              let wu = weightUnit, !wu.isEmpty,
              let h = height, h > 0,
              let hu = heightUnit, !hu.isEmpty else { return false }
        return true
    }

    // MARK: - Write

    /// Persist all profile fields from a fetched `UserProfile`.
    func save(_ profile: UserProfile) {
        defaults.set(profile.email, forKey: Key.email)
        if let w = profile.weight      { defaults.set(w, forKey: Key.weight) }
        if let wu = profile.weightUnit { defaults.set(wu, forKey: Key.weightUnit) }
        if let h = profile.height      { defaults.set(h, forKey: Key.height) }
        if let hu = profile.heightUnit { defaults.set(hu, forKey: Key.heightUnit) }
    }

    /// Persist only the email (e.g. right after sign-in, before API call).
    func saveEmail(_ email: String) {
        defaults.set(email, forKey: Key.email)
    }

    /// Remove all profile data (e.g. on sign-out).
    func clear() {
        [Key.email, Key.weight, Key.weightUnit, Key.height, Key.heightUnit]
            .forEach { defaults.removeObject(forKey: $0) }
    }
}
