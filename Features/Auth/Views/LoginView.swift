import SwiftUI

/// Authentication screen shown after `SplashView` when the user is not signed in.
///
/// Provides a single primary action: "Sign in with Google".
/// All colors reference `GrayscalePalette` (Constitution Principle VI).
/// The Google Sign-In button is wrapped in a grayscale-compliant shell — the
/// SDK button is not used directly because it renders non-grayscale colors.
struct LoginView: View {

    // MARK: - State

    @State private var viewModel: LoginViewModel

    // MARK: - Init

    init(viewModel: LoginViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            GrayscalePalette.background
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // MARK: Brand
                VStack(spacing: 16) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)

                    Text("BodyMetric")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(GrayscalePalette.primary)

                    Text("Track your hypertrophy journey")
                        .font(.subheadline)
                        .foregroundStyle(GrayscalePalette.secondary)
                }

                Spacer()

                // MARK: Sign-in area
                VStack(spacing: 12) {
                    signInButton
                    errorLabel
                }
                .padding(.horizontal, 32)

                Spacer()
                    .frame(height: 60)
            }
        }
        .disabled(viewModel.isLoading)
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var signInButton: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(GrayscalePalette.primary)
                .frame(height: 52)
        } else {
            Button {
                Task { await viewModel.signIn() }
            } label: {
                HStack(spacing: 10) {
                    // Person icon standing in for the Google "G" logo.
                    // Semantic meaning is provided by the label text (Principle VI).
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 20))
                        .symbolRenderingMode(.monochrome)

                    Text("Sign in with Google2")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundStyle(GrayscalePalette.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(GrayscalePalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(GrayscalePalette.separator, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var errorLabel: some View {
        if let errorMessage = viewModel.errorMessage {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle")
                    .symbolRenderingMode(.monochrome)
                    .font(.caption)
                Text(errorMessage)
                    .font(.caption)
            }
            .foregroundStyle(GrayscalePalette.secondary)
            .multilineTextAlignment(.center)
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView(viewModel: LoginViewModel(authService: _PreviewAuthService()))
}

/// In-preview stub. Not for use in production.
private final class _PreviewAuthService: AuthServiceProtocol {
    var isAuthenticated: Bool = false
    func signInWithGoogle() async throws {
        try await Task.sleep(for: .seconds(1)) // simulate network
    }
    func signOut() async throws {}
}
