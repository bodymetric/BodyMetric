import SwiftUI

/// Mandatory profile completion form.
///
/// Shown when the authenticated user's profile is missing `name`, `height`, or `weight`.
/// The user cannot dismiss this screen — it is a required gate before reaching HomeView.
///
/// On successful submission (HTTP 201), shows a success message for ~4 seconds
/// then navigates to HomeView. On error, restores the "Update" button and shows
/// an inline error message.
///
/// Constitution Principle V: single primary action ("Update"); loading feedback < 200 ms.
/// Constitution Principle VI: exclusively GrayscalePalette tokens — no hardcoded colors.
struct CreateUserView: View {

    // MARK: - State

    @State var viewModel: UpdateProfileViewModel

    // MARK: - Init

    init(viewModel: UpdateProfileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                GrayscalePalette.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                            .padding(.top, 32)
                            .padding(.bottom, 32)

                        formSection
                            .padding(.horizontal, 24)

                        Spacer(minLength: 40)

                        submitSection
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            // Success overlay
            .overlay {
                if viewModel.isSuccess { successOverlay }
            }
            // Navigate to home after success + delay
            .navigationDestination(
                isPresented: Binding(
                    get: { viewModel.navigationState == .home },
                    set: { _ in }
                )
            ) {
                // HomeView navigation is handled by BodyMetricApp observing
                // authService.needsProfileSetup. This destination is a fallback.
                EmptyView()
            }
        }
        .interactiveDismissDisabled(true)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 52))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(GrayscalePalette.primary)

            Text("Complete Your Profile")
                .font(.title2.weight(.semibold))
                .foregroundStyle(GrayscalePalette.primary)

            Text("Fill in your details to get started.")
                .font(.subheadline)
                .foregroundStyle(GrayscalePalette.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Form fields

    private var formSection: some View {
        VStack(spacing: 20) {
            // Email — read-only
            fieldRow(label: "Email") {
                Text(viewModel.email)
                    .font(.body)
                    .foregroundStyle(GrayscalePalette.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Name
            fieldRow(label: "Name") {
                TextField("Your name", text: $viewModel.name)
                    .font(.body)
                    .foregroundStyle(GrayscalePalette.primary)
                    .autocorrectionDisabled()
            }

            // Height
            fieldRow(label: "Height (cm)") {
                TextField("e.g. 182", text: $viewModel.heightText)
                    .font(.body)
                    .foregroundStyle(GrayscalePalette.primary)
                    .keyboardType(.decimalPad)
            }

            // Weight
            fieldRow(label: "Weight (kg)") {
                TextField("e.g. 82", text: $viewModel.weightText)
                    .font(.body)
                    .foregroundStyle(GrayscalePalette.primary)
                    .keyboardType(.decimalPad)
            }

            // Inline error message
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

    private func fieldRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.caption.weight(.medium))
                .foregroundStyle(GrayscalePalette.secondary)
                .tracking(0.5)

            content()
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(GrayscalePalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(GrayscalePalette.separator, lineWidth: 1)
                )
        }
    }

    // MARK: - Submit button

    private var submitSection: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(GrayscalePalette.primary)
                } else {
                    Text("Update")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(GrayscalePalette.primary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(GrayscalePalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(GrayscalePalette.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoading)
    }

    // MARK: - Success overlay

    private var successOverlay: some View {
        ZStack {
            GrayscalePalette.background
                .ignoresSafeArea()
                .opacity(0.95)

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 64))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(GrayscalePalette.primary)

                Text("Profile updated!")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(GrayscalePalette.primary)

                Text("Taking you home…")
                    .font(.subheadline)
                    .foregroundStyle(GrayscalePalette.secondary)
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Preview

#Preview {
    CreateUserView(
        viewModel: UpdateProfileViewModel(
            email: "preview@example.com",
            updateService: _PreviewUpdateProfileService(),
            profileStore: ProfileStore(),
            authService: _PreviewAuthServiceForProfile()
        )
    )
}

/// Preview stub — not for production use.
@MainActor
private final class _PreviewUpdateProfileService: UpdateProfileServiceProtocol {
    func updateProfile(_ request: UpdateProfileRequest) async throws -> AuthUser {
        try await Task.sleep(for: .seconds(1))
        return AuthUser(id: 1, name: request.name, email: request.email,
                        height: request.height, weight: request.weight)
    }
}

@MainActor
private final class _PreviewAuthServiceForProfile: AuthServiceProtocol {
    var isAuthenticated: Bool = true
    var authenticatedEmail: String? = "preview@example.com"
    var needsProfileSetup: Bool = true
    func signInWithGoogle() async throws {}
    func signOut() async throws {}
    func restorePreviousSignIn() async -> Bool { false }
    func clearNeedsProfileSetup() { needsProfileSetup = false }
}
