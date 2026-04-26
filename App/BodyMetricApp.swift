import SwiftUI
import Foundation
import GoogleSignIn
import Observation

/// App entry point.
///
/// Launch sequence:
///   SplashView (≥1.5 s, while restoring prior session)
///     → LoginView         (if no prior session)
///     → MainTabView stub  (if authenticated)
///
/// Dependency wiring order (avoids init-time circular references):
///   1. KeychainService, TokenStore, TokenRefreshService (no deps)
///   2. TokenRefreshCoordinator (needs refreshService + keychainService + onForceLogout box)
///   3. NetworkClient (needs tokenStore + coordinator)
///   4. AuthService (needs exchangeService + tokenStore + keychainService + coordinator)
///   5. Wire proactive timer on tokenStore (needs coordinator + tokenStore — post-init)
///   6. Wire onForceLogout box to point at authService (post-init)
@main
struct BodyMetricApp: App {

    // MARK: - Services

    @State private var authService: AuthService
    @State private var profileStore = ProfileStore()

    // Shared singletons retained for dependency injection into HomeViewModel
    private let tokenStore: TokenStore
    private let keychainService: KeychainService
    private let coordinator: TokenRefreshCoordinator
    private let networkClient: NetworkClient


    // MARK: - Navigation state

    @State private var showSplash = true

    // MARK: - Init

    init() {
        // Step 1: leaf services
        let ks = KeychainService()
        let ts = TokenStore()
        let trs = TokenRefreshService()

        // Step 2: coordinator — onForceLogout wired via box after authService is created
        let authBox = AuthServiceBox()
        let coord = TokenRefreshCoordinator(
            refreshService: trs,
            keychainService: ks,
            onForceLogout: { [weak authBox] in
                await authBox?.service?.forceSignOut()
            }
        )

        // Step 3: NetworkClient
        let client = NetworkClient(tokenStore: ts, coordinator: coord)

        // Step 4: AuthService (shares the same ProfileStore instance as the app)
        let ps = ProfileStore()
        let auth = AuthService(
            tokenExchangeService: TokenExchangeService(),
            tokenStore: ts,
            keychainService: ks,
            coordinator: coord,
            profileStore: ps
        )

        // Step 5: Wire proactive timer (post-init, avoids circular init)
        Task {
            await ts.setRefreshAction { [weak coord] in
                guard let c = coord else { return }
                try? await c.refresh(tokenStore: ts)
            }
        }

        // Step 6: Wire force-logout box
        authBox.service = auth

        // Configure Google Sign-In
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientID = plist["CLIENT_ID"] as? String {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            Logger.info("GoogleSignIn configured with clientID: \(String(clientID.prefix(20)))...",
                        category: .auth)
        } else {
            Logger.fault("GoogleService-Info.plist not found or missing CLIENT_ID", category: .auth)
        }

        // Assign stored properties
        self.keychainService = ks
        self.tokenStore = ts
        self.coordinator = coord
        self.networkClient = client
        _authService = State(wrappedValue: auth)
        _profileStore = State(wrappedValue: ps)
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            rootView
                .task { await resolveSplash() }
                .onOpenURL { url in
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
                authenticatedContainer
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
        .animation(.bmFade, value: authService.needsProfileSetup)
    }

    // MARK: - Splash resolution

    private func resolveSplash() async {
        async let restored: Bool = authService.restorePreviousSignIn()
        async let minDelay: Void = {
            try? await Task.sleep(for: .seconds(1.5))
        }()
        _ = await (restored, minDelay)

        if authService.isAuthenticated && authService.authenticatedEmail == nil {
            Logger.warning("Session restored but email unavailable — signing out", category: .auth)
            try? await authService.signOut()
        }

        Logger.info(
            "Splash resolved. isAuthenticated=\(authService.isAuthenticated)",
            category: .auth
        )
        showSplash = false
    }

    // MARK: - Authenticated container

    @ViewBuilder
    private var authenticatedContainer: some View {
        if authService.needsProfileSetup {
            // Profile completion gate — mandatory; no back navigation.
            CreateUserView(
                viewModel: makeUpdateProfileViewModel()
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        } else {
            MainTabView(
                homeViewModel: makeHomeViewModel(),
                authService: authService,
                profileStore: profileStore,
                networkClient: networkClient
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
    }

    // MARK: - HomeViewModel factory

    private func makeHomeViewModel() -> HomeViewModel {
        let email = authService.authenticatedEmail ?? profileStore.email ?? ""
        return HomeViewModel(
            email: email,
            profileService: UserProfileService(networkClient: networkClient),
            profileStore: profileStore
        )
    }

    // MARK: - UpdateProfileViewModel factory

    private func makeUpdateProfileViewModel() -> UpdateProfileViewModel {
        let email = authService.authenticatedEmail ?? profileStore.email ?? ""
        return UpdateProfileViewModel(
            email: email,
            updateService: UpdateProfileService(networkClient: networkClient),
            profileStore: profileStore,
            authService: authService
        )
    }
}

// MARK: - AuthServiceBox

/// Breaks the coordinator → authService circular init dependency.
/// The coordinator captures this box in its `onForceLogout` closure;
/// `authBox.service` is set after `AuthService` is fully initialized.
private final class AuthServiceBox: @unchecked Sendable {
    weak var service: AuthService?
}
