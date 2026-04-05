import SwiftUI

/// The sole source of color values for the entire app.
///
/// Every SwiftUI view MUST reference these constants instead of raw `Color` values.
/// Constitution Principle VI: all UI colors must be grayscale; semantic meaning
/// is conveyed through shape, icon, typography weight, or explicit text labels —
/// never through color alone.
enum GrayscalePalette {

    // MARK: - Semantic color tokens

    /// Page/screen background. White in light mode, near-black in dark mode.
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.08, alpha: 1)
            : UIColor(white: 1.00, alpha: 1)
    })

    /// Card and sheet surface. Slightly off-white / dark-surface in dark mode.
    static let surface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.14, alpha: 1)
            : UIColor(white: 0.95, alpha: 1)
    })

    /// Primary content: headings, labels, icons, primary button fills.
    static let primary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1.00, alpha: 1)
            : UIColor(white: 0.00, alpha: 1)
    })

    /// Secondary content: captions, hints, subordinate labels.
    static let secondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.60, alpha: 1)
            : UIColor(white: 0.45, alpha: 1)
    })

    /// Disabled state: inactive controls, placeholder text.
    static let disabled = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.35, alpha: 1)
            : UIColor(white: 0.75, alpha: 1)
    })

    /// Dividers, borders, hairline strokes.
    static let separator = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.22, alpha: 1)
            : UIColor(white: 0.88, alpha: 1)
    })
}
