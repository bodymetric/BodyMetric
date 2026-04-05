import SwiftUI

// MARK: - Animation baseline (Constitution Principle V)
//
// All screen transitions MUST use these values.
// Hardcoding durations or curves in individual views is a violation.
// TODO(ANIMATION_STANDARD): Update response/damping when design system baseline is finalized.

extension Animation {

    /// Standard spring (~350 ms). Used for push/pop navigation and hero transitions.
    /// Slight physical overshoot gives the UI a tactile, gym-floor feel.
    static let bmSpring = Animation.spring(response: 0.35, dampingFraction: 0.82)

    /// Standard cross-dissolve (250 ms). Used for tab switches and auth state swaps.
    static let bmFade = Animation.easeInOut(duration: 0.25)
}

// MARK: - Transition definitions

extension AnyTransition {

    /// Push/pop: slides in from the trailing edge, slides out to the leading edge.
    /// Use for `NavigationStack` push destinations.
    static var bmSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal:   .move(edge: .leading).combined(with: .opacity)
        )
    }

    /// Hero expand: scales up slightly on insertion, scales out on removal.
    /// Use for card → full-screen hero transitions (e.g., CheckInView → ActiveSessionView).
    static var bmScaleUp: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.92).combined(with: .opacity),
            removal:   .scale(scale: 1.05).combined(with: .opacity)
        )
    }
}
