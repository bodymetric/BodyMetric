import SwiftUI
import Foundation
import GoogleSignIn

/// App entry point.
///
/// Launch sequence:
///   SplashView (≥1.5 s, while restoring prior session)
///     → LoginView         (if no prior session)
///     → MainTabView stub  (if authenticated)
@main
struct BodyMetricApp: App {

    // MARK: - Services

    @State private var authService = AuthService()

    // MARK: - Navigation state

    @State private var showSplash = true

    // MARK: - Scene

    init() {
        // Configure GoogleSignIn with the CLIENT_ID from GoogleService-Info.plist.
        // This replaces the need for GIDClientID in Info.plist.
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientID = plist["CLIENT_ID"] as? String else {
            Logger.fault("GoogleService-Info.plist not found or missing CLIENT_ID", category: .auth)
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        Logger.info("GoogleSignIn configured with clientID: \(String(clientID.prefix(20)))...", category: .auth)
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .task { await resolveSplash() }
                .onOpenURL { url in
                    // Required for Google Sign-In redirect back to the app.
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }

    // MARK: - Root view

    @ViewBuilder
    private var rootView: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if authService.isAuthenticated {
                // TODO(T035): Replace with real MainTabView once US1 is implemented.
                authenticatedPlaceholder
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                LoginView(
                    viewModel: LoginViewModel(authService: authService)
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.bmFade, value: showSplash)
        .animation(.bmFade, value: authService.isAuthenticated)
    }

    // MARK: - Splash resolution

    private func resolveSplash() async {
        async let restored: Bool = authService.restorePreviousSignIn()
        async let minDelay: Void = {
            try? await Task.sleep(for: .seconds(1.5))
        }()
        _ = await (restored, minDelay)

        Logger.info(
            "Splash resolved. isAuthenticated=\(authService.isAuthenticated)",
            category: .auth
        )
        showSplash = false
    }

    // MARK: - Authenticated placeholder

    /// Temporary screen shown after login until MainTabView is built (T035).
    private var authenticatedPlaceholder: some View {
        ZStack {
            GrayscalePalette.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(GrayscalePalette.primary)

                Text("Signed in!")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(GrayscalePalette.primary)

                Text("MainTabView coming in the next tasks")
                    .font(.caption)
                    .foregroundStyle(GrayscalePalette.secondary)

                Button("Sign Out") {
                    Task { try? await authService.signOut() }
                }
                .font(.subheadline)
                .foregroundStyle(GrayscalePalette.secondary)
            }
        }
    }
}
