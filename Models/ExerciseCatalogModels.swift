import Foundation

// MARK: - GET /api/exercises response DTOs

/// One exercise returned within an `ExerciseCatalogGroup`.
struct ApiExercise: Decodable, Identifiable {
    let id: Int
    let name: String
}

/// One muscle-group entry returned by `GET /api/exercises`.
///
/// `group` is used as the section heading in the exercise picker.
/// `exercises` are displayed within that section.
struct ExerciseCatalogGroup: Decodable, Identifiable {
    let group: String
    let exercises: [ApiExercise]

    var id: String { group }
}

// MARK: - Load state

enum ExerciseCatalogLoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
}
