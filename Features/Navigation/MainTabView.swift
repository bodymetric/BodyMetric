import SwiftUI

/// Root tab container shown after successful authentication.
///
/// Tabs: Today (workout), History (placeholder), You (profile / settings).
/// Constitution Principle VI: tab bar uses grayscale only; workout accent
/// is scoped to the Today tab and its child screens.
struct MainTabView: View {

    // Injected from BodyMetricApp so the profile tab can share the same ViewModel.
    let homeViewModel: HomeViewModel
    let authService: AuthServiceProtocol
    let profileStore: ProfileStore
    let networkClient: any NetworkClientProtocol
    
    @State private var selectedTab: Tab = .today

    enum Tab { case today, history, profile }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabContent(selectedTab: selectedTab, homeViewModel: homeViewModel)
            customTabBar
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Tab content

    @ViewBuilder
    private func TabContent(selectedTab: Tab, homeViewModel: HomeViewModel) -> some View {
        switch selectedTab {
        case .today:
            TodayView(
                workout: .mockToday,
                streak: .mockStreak,
                userName: profileStore.name ?? "You",
                networkClient: networkClient
            )
            .transition(.opacity)

        case .history:
            HistoryPlaceholderView()
                .transition(.opacity)

        case .profile:
            NavigationStack {
                HomeView(viewModel: homeViewModel)
            }
            .transition(.opacity)
        }
    }

    // MARK: - Custom tab bar

    private var customTabBar: some View {
        HStack {
            ForEach([Tab.today, .history, .profile], id: \.self) { tab in
                Spacer()
                TabBarButton(tab: tab, selected: selectedTab == tab) {
                    withAnimation(.bmFade) { selectedTab = tab }
                }
                Spacer()
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 28)
        .background(
            GrayscalePalette.background
                .opacity(0.95)
                .background(.ultraThinMaterial)
        )
        .overlay(alignment: .top) { Divider() }
    }
}

// MARK: - Tab bar button

private struct TabBarButton: View {
    let tab: MainTabView.Tab
    let selected: Bool
    let action: () -> Void

    private var icon: String {
        switch tab {
        case .today:   "calendar"
        case .history: "chart.line.uptrend.xyaxis"
        case .profile: "person.circle"
        }
    }
    private var label: String {
        switch tab {
        case .today:   "Today"
        case .history: "History"
        case .profile: "You"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: selected ? icon + (tab == .today ? "" : ".fill") : icon)
                    .font(.system(size: 22, weight: selected ? .semibold : .regular))
                Text(label)
                    .font(.system(size: 10, design: .rounded).weight(.semibold))
                    .tracking(0.2)
            }
            .foregroundStyle(selected ? GrayscalePalette.primary : GrayscalePalette.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - History placeholder

private struct HistoryPlaceholderView: View {
    var body: some View {
        ZStack {
            GrayscalePalette.background.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(GrayscalePalette.secondary)
                Text("History coming soon")
                    .font(.system(size: 17, design: .rounded).weight(.semibold))
                    .foregroundStyle(GrayscalePalette.primary)
                Text("Your past sessions will appear here.")
                    .font(.system(size: 14))
                    .foregroundStyle(GrayscalePalette.secondary)
            }
        }
    }
}
