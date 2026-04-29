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
/// `isActive`       → tappable; navigable or sign-out depending on `isSignOut`.
/// `isPrimary`      → uses WorkoutPalette accent on icon cell (only "New Workout Plan").
/// `isSignOut`      → triggers the `onSignOut` callback instead of navigation (only "Exit").
/// `isSeparatorAbove` → renders a `Divider()` above the row (only "Exit").
/// `destination`    is `nil` for coming-soon items and for sign-out.
struct HomeMenuItem: Identifiable {
    let id: String
    let label: String
    let subtitle: String
    let iconName: String
    let isActive: Bool
    let isPrimary: Bool
    let destination: HomeMenuDestination?
    let isSignOut: Bool
    let isSeparatorAbove: Bool

    // Convenience init keeps existing call sites unmodified (new fields default to false).
    init(
        id: String,
        label: String,
        subtitle: String,
        iconName: String,
        isActive: Bool,
        isPrimary: Bool,
        destination: HomeMenuDestination?,
        isSignOut: Bool = false,
        isSeparatorAbove: Bool = false
    ) {
        self.id = id
        self.label = label
        self.subtitle = subtitle
        self.iconName = iconName
        self.isActive = isActive
        self.isPrimary = isPrimary
        self.destination = destination
        self.isSignOut = isSignOut
        self.isSeparatorAbove = isSeparatorAbove
    }

    // MARK: - Static catalog (8 items, spec FR-001 / FR-002)

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
        // Exit — last item; triggers sign-out rather than navigation (spec FR-001)
        HomeMenuItem(
            id: "exit",
            label: "Exit",
            subtitle: "Sign out of your account",
            iconName: "rectangle.portrait.and.arrow.right",
            isActive: true,
            isPrimary: false,
            destination: nil,
            isSignOut: true,
            isSeparatorAbove: true
        ),
    ]
}
