import Foundation

/// User object embedded in the `POST /api/auth/google` token exchange response.
///
/// Represents the backend's view of the user at login time.
/// Distinct from `UserProfile` (the `GET /api/users` response) — `AuthUser`
/// carries `name` but no unit strings; `UserProfile` carries unit strings but
/// historically lacked `name`.
///
/// Constitution Principle I: pure Swift value type.
struct AuthUser: Decodable {

    // MARK: - Fields

    let id: Int
    let name: String?
    let email: String
    let height: Double?
    let weight: Double?

    // MARK: - CodingKeys

    private enum CodingKeys: String, CodingKey {
        case id, name, email, height, weight
    }

    // MARK: - Completeness

    /// `true` when all three required profile fields are present and valid.
    /// Used by `AuthService` to decide whether to gate on `UpdateProfileView`.
    var isComplete: Bool {
        guard let n = name, !n.trimmingCharacters(in: .whitespaces).isEmpty,
              let h = height, h > 0,
              let w = weight, w > 0 else { return false }
        return true
    }

    // MARK: - Memberwise init (tests)

    init(id: Int = 0,
         name: String? = nil,
         email: String = "",
         height: Double? = nil,
         weight: Double? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.height = height
        self.weight = weight
    }
}
