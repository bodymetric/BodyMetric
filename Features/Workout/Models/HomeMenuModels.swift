import Foundation

// MARK: - Destination

/// The two navigable destinations reachable from the home dropdown menu.
///
/// Conforms to `Identifiable` so it can drive `fullScreenCover(item:)`.
/// Constitution Principle I: pure Swift value type; no UIKit dependency.
enum HomeMenuDestination: Equatable, Hashable, Identifiable {
    case today
    case newWorkoutPlan

    var id: Self { self }
}

// MARK: - Menu item

/// A single entry in the top-right dropdown menu.
///
/// `isActive`  → tappable and navigable.
/// `isPrimary` → uses WorkoutPalette accent on icon cell (only "New Workout Plan").
/// `destination` is `nil` for coming-soon items.
struct HomeMenuItem: Identifiable {
    let id: String
    let label: String
    let subtitle: String
    let iconName: String
    let isActive: Bool
    let isPrimary: Bool
    let destination: HomeMenuDestination?

    // MARK: - Static catalog (7 items, order matches spec FR-005)

    static let catalog: [HomeMenuItem] = [
        HomeMenuItem(
            id: "today",
            label: "Today",
            subtitle: "Your daily workout",
            iconName: "calendar",
            isActive: true,
            isPrimary: false,
            destination: .today
        ),
        HomeMenuItem(
            id: "newPlan",
            label: "New Workout Plan",
            subtitle: "Build a weekly programme",
            iconName: "plus",
            isActive: true,
            isPrimary: true,
            destination: .newWorkoutPlan
        ),
        HomeMenuItem(
            id: "myPlans",
            label: "My Plans",
            subtitle: "Saved routines",
            iconName: "dumbbell.fill",
            isActive: false,
            isPrimary: false,
            destination: nil
        ),
        HomeMenuItem(
            id: "history",
            label: "History",
            subtitle: "Past sessions",
            iconName: "chart.line.uptrend.xyaxis",
            isActive: false,
            isPrimary: false,
            destination: nil
        ),
        HomeMenuItem(
            id: "progress",
            label: "Progress",
            subtitle: "PRs · volume",
            iconName: "bolt.fill",
            isActive: false,
            isPrimary: false,
            destination: nil
        ),
        HomeMenuItem(
            id: "profile",
            label: "Profile",
            subtitle: "Account · units",
            iconName: "person.circle",
            isActive: false,
            isPrimary: false,
            destination: nil
        ),
        HomeMenuItem(
            id: "settings",
            label: "Settings",
            subtitle: "Preferences",
            iconName: "gearshape.fill",
            isActive: false,
            isPrimary: false,
            destination: nil
        ),
    ]
}
