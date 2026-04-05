import SwiftUI

/// Initial launch screen shown while auth state is being resolved.
///
/// Displays the app logo centered on a grayscale background.
/// The transition away from this view (to `LoginView` or `MainTabView`) is
/// driven by `BodyMetricApp` using `.bmFade` animation.
struct SplashView: View {

    var body: some View {
        let _ = print("🚀 SplashView appeared")  // temporary test
        ZStack {
            GrayscalePalette.background
                .ignoresSafeArea()

            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
        }
    }
}

// MARK: - Preview

#Preview {
    SplashView()
}
