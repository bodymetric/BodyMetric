import SwiftUI

/// Global header displayed at the top of every authenticated screen.
///
/// Layout: [Logo 32×32 | leading 10 pt] ——— [logout icon | trailing 10 pt]
/// Background: GrayscalePalette.primary (near-black).
/// Safe area is handled automatically by SwiftUI layout.
///
/// Constitution Principle VI: all colors via GrayscalePalette — no hardcoded values.
/// Constitution Principle V: single action (logout); renders synchronously.
struct AppHeader: View {

    // MARK: - ViewModel

    @State var viewModel: AppHeaderViewModel

    // MARK: - Body

    var body: some View {
        HStack {
            // Logo — left side, 10 pt leading padding
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .padding(.leading, 10)

            Spacer()

            // Logout — right side, 10 pt trailing padding
            Button {
                Task { await viewModel.logout() }
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .symbolRenderingMode(.monochrome)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(GrayscalePalette.background)
            }
            .padding(.trailing, 10)
            .accessibilityLabel("Sign out")
        }
        .frame(height: 44)
        .background(GrayscalePalette.primary)
    }
}
