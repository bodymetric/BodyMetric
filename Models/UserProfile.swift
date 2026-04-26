import Foundation

/// Decodable representation of a user's physical profile as returned by
/// `GET /api/users?email=`. All metric fields are optional at the decode
/// layer so a partial or evolving API response never crashes the app.
///
/// Constitution Principle I: pure Swift value type; no Objective-C.
struct UserProfile: Decodable {

    // MARK: - Fields

    /// The authenticated user's email address (sourced from Google Sign-In,
    /// not from this response body).
    var email: String

    /// Display name. nil if the API omitted the field.
    var name: String?

    /// Body weight numeric value. nil if the API omitted the field.
    var weight: Double?

    /// Unit string for weight (e.g. "kg", "lbs"). nil if API omitted.
    var weightUnit: String?

    /// Body height numeric value. nil if the API omitted the field.
    var height: Double?

    /// Unit string for height (e.g. "cm", "in"). nil if API omitted.
    var heightUnit: String?

    // MARK: - CodingKeys

    private enum CodingKeys: String, CodingKey {
        case name
        case weight
        case weightUnit
        case height
        case heightUnit
        // email is injected externally — not present in API response body.
    }

    // MARK: - Custom init(from:)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name       = try container.decodeIfPresent(String.self, forKey: .name)
        weight     = try container.decodeIfPresent(Double.self, forKey: .weight)
        weightUnit = try container.decodeIfPresent(String.self, forKey: .weightUnit)
        height     = try container.decodeIfPresent(Double.self, forKey: .height)
        heightUnit = try container.decodeIfPresent(String.self, forKey: .heightUnit)
        email = "" // Injected by caller after decode.
    }

    // MARK: - Memberwise init (for tests and ProfileStore hydration)

    init(email: String,
         name: String? = nil,
         weight: Double? = nil,
         weightUnit: String? = nil,
         height: Double? = nil,
         heightUnit: String? = nil) {
        self.email      = email
        self.name       = name
        self.weight     = weight
        self.weightUnit = weightUnit
        self.height     = height
        self.heightUnit = heightUnit
    }
}
