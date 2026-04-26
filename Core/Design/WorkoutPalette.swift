import SwiftUI

/// Sage accent tokens — used exclusively in the workout flow.
///
/// The main app is grayscale-only (Constitution Principle VI).
/// This palette adds the single low-chroma sage accent that echoes
/// the mascot apple, as specified in the workout flow design.
/// It must NOT leak into non-workout screens.
enum WorkoutPalette {

    /// Sage green — primary accent. Used on logged sets, CTAs, streak dots.
    /// oklch(0.82 0.08 135) light / oklch(0.78 0.09 135) dark
    static let accent = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.60, green: 0.80, blue: 0.55, alpha: 1)
            : UIColor(red: 0.68, green: 0.85, blue: 0.62, alpha: 1)
    })

    /// Dark sage — text/icon on light sage backgrounds.
    /// oklch(0.38 0.06 140) light / oklch(0.92 0.05 135) dark
    static let accentInk = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.82, green: 0.93, blue: 0.79, alpha: 1)
            : UIColor(red: 0.22, green: 0.37, blue: 0.25, alpha: 1)
    })

    /// Very light sage tint — fill behind icons, completed set rows.
    /// oklch(0.94 0.03 135) light / oklch(0.28 0.05 135) dark
    static let accentSoft = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.27, blue: 0.20, alpha: 1)
            : UIColor(red: 0.88, green: 0.95, blue: 0.86, alpha: 1)
    })

    /// Slightly elevated surface — used in forms and card interiors.
    static let surfaceAlt = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 0.18, alpha: 1)
            : UIColor(white: 0.91, alpha: 1)
    })

    /// Content color to place on top of `accent` fill.
    /// Dark in both modes (the mascot-green background is always light).
    static let onAccent = Color(uiColor: UIColor(red: 0.08, green: 0.16, blue: 0.09, alpha: 1))
}
