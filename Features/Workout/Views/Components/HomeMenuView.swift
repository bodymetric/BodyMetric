import SwiftUI

/// Top-right dropdown menu overlay triggered by the mascot chip in `TodayView`.
///
/// Layout: full-screen scrim + positioned panel (top-right, width 268 pt).
/// Animation: `.bmFade` + `scaleEffect(anchor: .topTrailing)`.
///
/// Constitution Principle V: opens in < 300 ms (bmFade = 250 ms).
/// Constitution Principle VI: GrayscalePalette structural colors;
///   WorkoutPalette accent only for the isPrimary icon cell.
/// Constitution Principle IV: Logger.info traces for open/item-tap/dismiss.
struct HomeMenuView: View {

    @Binding var isPresented: Bool
    var activeDestination: HomeMenuDestination = .today
    let userName: String
    var onNavigate: (HomeMenuDestination) -> Void
    var onSignOut: (() -> Void)? = nil

    private let panelWidth: CGFloat = 268
    private let version: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            scrim
            panel
                .padding(.top, 60)
                .padding(.trailing, 14)
        }
        .ignoresSafeArea()
        .allowsHitTesting(isPresented)
        .onAppear {
            if isPresented {
                Logger.info("menu_opened")
            }
        }
        .onChange(of: isPresented) { _, newValue in
            if newValue { Logger.info("menu_opened") }
        }
    }

    // MARK: - Scrim

    private var scrim: some View {
        Color.black
            .opacity(isPresented ? 0.32 : 0)
            .ignoresSafeArea()
            .animation(.bmFade, value: isPresented)
            .onTapGesture { dismiss() }
            .allowsHitTesting(isPresented)
    }

    // MARK: - Panel

    private var panel: some View {
        ZStack(alignment: .topTrailing) {
            // Notch triangle pointing at mascot chip
            notch
                .offset(x: -20, y: -7)
                .zIndex(1)

            VStack(spacing: 0) {
                menuHeader
                Divider()
                    .background(GrayscalePalette.separator)
                itemList
            }
            .frame(width: panelWidth)
            .background(GrayscalePalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(GrayscalePalette.separator, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
            .zIndex(0)
        }
        .scaleEffect(isPresented ? 1 : 0.92, anchor: .topTrailing)
        .opacity(isPresented ? 1 : 0)
        .animation(.bmFade, value: isPresented)
        .accessibilityIdentifier("homeMenuPanel")
    }

    // MARK: - Notch

    private var notch: some View {
        Rectangle()
            .fill(GrayscalePalette.surface)
            .frame(width: 14, height: 14)
            .rotationEffect(.degrees(45))
            .overlay(
                Rectangle()
                    .stroke(GrayscalePalette.separator, lineWidth: 1)
                    .rotationEffect(.degrees(0))
                    .frame(width: 14, height: 14)
            )
            .clipped()
    }

    // MARK: - Header

    private var menuHeader: some View {
        HStack(spacing: 10) {
            // Mascot chip
            ZStack {
                Circle()
                    .fill(WorkoutPalette.accentSoft)
                    .frame(width: 40, height: 40)
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("BodyMetric")
                    .font(.system(size: 13, design: .rounded).weight(.bold))
                    .foregroundStyle(GrayscalePalette.primary)
                    .tracking(-0.1)
                Text("\(userName.uppercased()) · v\(version)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(GrayscalePalette.secondary)
                    .tracking(1.2)
            }

            Spacer()

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GrayscalePalette.secondary)
                    .frame(width: 26, height: 26)
                    .background(GrayscalePalette.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close menu")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(GrayscalePalette.background)
    }

    // MARK: - Item list

    private var itemList: some View {
        VStack(spacing: 2) {
            ForEach(HomeMenuItem.catalog) { item in
                if item.isSeparatorAbove {
                    Divider()
                        .background(GrayscalePalette.separator)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                }
                menuItemRow(item)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
    }

    @ViewBuilder
    private func menuItemRow(_ item: HomeMenuItem) -> some View {
        // Label color: secondary for the Exit sign-out row; primary for everything else.
        let labelColor: Color = item.isSignOut ? GrayscalePalette.secondary : GrayscalePalette.primary
        let iconColor: Color = item.isPrimary ? WorkoutPalette.accentInk : GrayscalePalette.secondary

        Button {
            guard item.isActive else { return }
            if item.isSignOut {
                // Sign-out: close menu first, then invoke callback (spec FR-003/FR-004)
                Logger.info("menu_sign_out_tapped")
                isPresented = false
                onSignOut?()
            } else {
                Logger.info("menu_item_tapped destination:\(item.id)")
                onNavigate(item.destination ?? .today)
            }
        } label: {
            HStack(spacing: 12) {
                // Icon cell
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(item.isPrimary ? WorkoutPalette.accentSoft : GrayscalePalette.background)
                        .frame(width: 32, height: 32)
                    Image(systemName: item.iconName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(iconColor)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(GrayscalePalette.separator, lineWidth: 1)
                )

                // Labels
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.label)
                        .font(.system(size: 14, design: .rounded).weight(.semibold))
                        .foregroundStyle(labelColor)
                        .tracking(-0.1)
                    Text(item.subtitle)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(GrayscalePalette.secondary)
                        .tracking(0.2)
                }

                Spacer()

                // Trailing indicator
                if item.isActive && !item.isSignOut {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(GrayscalePalette.secondary)
                } else if !item.isActive {
                    Text("SOON")
                        .font(.system(size: 9, design: .monospaced).weight(.bold))
                        .foregroundStyle(GrayscalePalette.secondary)
                        .tracking(1.2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(GrayscalePalette.background)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(GrayscalePalette.separator, lineWidth: 1)
                        )
                }
                // isSignOut items show no trailing indicator (Exit stands alone)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                (activeDestination == item.destination && !item.isSignOut)
                    ? GrayscalePalette.surface : .clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(item.isActive ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!item.isActive)
    }

    // MARK: - Dismiss

    private func dismiss() {
        Logger.info("menu_dismissed")
        isPresented = false
    }
}
