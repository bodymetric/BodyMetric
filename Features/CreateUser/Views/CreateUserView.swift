import SwiftUI

/// Placeholder screen shown when the BodyMetric API returns 404 for the
/// authenticated user's email — meaning no profile record exists yet.
///
/// Full user-creation form is out of scope for this feature and will be
/// addressed in a dedicated spec.
///
/// Constitution Principle VI: exclusively GrayscalePalette tokens.
/// Constitution Principle V: single clear message; no confusing actions.
struct CreateUserView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            GrayscalePalette.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.system(size: 64))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(GrayscalePalette.primary)

                Text("Profile Not Found")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(GrayscalePalette.primary)

                Text("Your profile was not found in the system.\nPlease try again or contact support to create your account.")
                    .font(.body)
                    .foregroundStyle(GrayscalePalette.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)

                Button("Go Back") {
                    dismiss()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(GrayscalePalette.secondary)
                .padding(.top, 8)
            }
            .padding(.horizontal, 32)
        }
        .navigationBarBackButtonHidden(true)
    }
}
