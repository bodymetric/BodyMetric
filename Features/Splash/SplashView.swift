import SwiftUI

/// Initial launch screen shown while auth state is being resolved.
///
/// Displays the app logo centered on a grayscale background.
/// The transition away from this view (to `LoginView` or `MainTabView`) is
/// driven by `BodyMetricApp` using `.bmFade` animation.
struct SplashView: View {

    @State private var bouncing = false

    var body: some View {
        ZStack {
            GrayscalePalette.background
                .ignoresSafeArea()

            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .offset(y: bouncing ? -20 : 0)
                .animation(
                    .interpolatingSpring(stiffness: 70, damping: 10)
                        .repeatForever(autoreverses: true),
                    value: bouncing
                )
                .onAppear { bouncing = true }
        }
    }
}

// MARK: - Preview

#Preview {
    SplashView()
}
