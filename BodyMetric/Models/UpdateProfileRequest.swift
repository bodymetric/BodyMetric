import Foundation

/// Payload sent to `PUT /api/users` to complete a user's profile.
///
/// The server looks up the user by `email`; name, height, and weight are updated.
///
/// Constitution Principle I: pure Swift value type; no Objective-C.
struct UpdateProfileRequest: Encodable {

    let name: String
    let email: String
    let height: Double
    let weight: Double
}
