import SwiftUI

/// Success screen shown after the wizard finishes and the plan is saved.
///
/// "Back to home" → onHome(); "Plan another week" → onRestart().
///
/// Constitution Principle VI: WorkoutPalette accent for mascot halo + CTA;
///   all structural colors via GrayscalePalette.
struct PlanSavedView: View {

    let dayCount: Int
    let onHome: () -> Void
    let onRestart: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            GrayscalePalette.background.ignoresSafeArea()

            // Soft blur ornaments
            WorkoutPalette.accentSoft
                .opacity(0.6)
                .blur(radius: 40)
                .frame(width: 160, height: 160)
                .clipShape(Circle())
                .offset(x: 80, y: -200)
                .allowsHitTesting(false)

            WorkoutPalette.accentSoft
                .opacity(0.5)
                .blur(radius: 40)
                .frame(width: 130, height: 130)
                .clipShape(Circle())
                .offset(x: -100, y: -60)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                mascotBadge
                    .padding(.top, 40)

                textSection
                    .padding(.top, 20)

                actionButtons
                    .padding(.top, 32)

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .accessibilityIdentifier("planSavedView")
    }

    // MARK: - Mascot badge

    private var mascotBadge: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .fill(WorkoutPalette.accentSoft)
                    .frame(width: 180, height: 180)
                    .overlay(
                        Circle()
                            .stroke(GrayscalePalette.separator, lineWidth: 1)
                    )
                    .shadow(color: WorkoutPalette.accent.opacity(0.25), radius: 30, y: 10)

                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
            }

            // Checkmark badge
            ZStack {
                Circle()
                    .fill(GrayscalePalette.primary)
                    .frame(width: 54, height: 54)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 3)
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(GrayscalePalette.background)
            }
            .offset(x: 4, y: 4)
        }
    }

    // MARK: - Text

    private var textSection: some View {
        VStack(spacing: 8) {
            Text("PLAN SAVED")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(GrayscalePalette.secondary)
                .tracking(1.2)

            Text("Now do the work.")
                .font(.system(size: 32, design: .rounded).weight(.bold))
                .foregroundStyle(GrayscalePalette.primary)
                .tracking(-0.7)

            Text("Your plan is locked in. \(dayCount) training day\(dayCount == 1 ? "" : "s") set. Tomorrow morning, the first session is waiting on the home screen.")
                .font(.system(size: 14))
                .foregroundStyle(GrayscalePalette.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Buttons

    private var actionButtons: some View {
        VStack(spacing: 8) {
            Button(action: onHome) {
                Text("Back to home")
                    .font(.system(size: 17, design: .rounded).weight(.bold))
                    .foregroundStyle(GrayscalePalette.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(GrayscalePalette.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
            }
            .buttonStyle(.plain)

            Button(action: onRestart) {
                Text("Plan another week")
                    .font(.system(size: 14, design: .rounded).weight(.semibold))
                    .foregroundStyle(GrayscalePalette.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
        }
    }
}
