import SwiftUI

/// Home screen shown after successful authentication.
///
/// Displays the authenticated user's email, weight, and height.
/// Handles all states: loading, loaded, partial data, error, and
/// 404-driven navigation to CreateUserView.
///
/// Constitution Principle V: single primary action per screen; data visible within 300 ms.
/// Constitution Principle VI: exclusively GrayscalePalette tokens — no hardcoded Color values.
struct HomeView: View {

    // MARK: - ViewModel

    @State var viewModel: HomeViewModel

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                GrayscalePalette.background.ignoresSafeArea()

                VStack(spacing: 32) {
                    profileSection
                    if viewModel.isLoading { loadingIndicator }
                    if let message = viewModel.errorMessage { errorBanner(message) }
                }
                .padding(.horizontal, 24)
            }
        }
        .task { await viewModel.loadProfile() }
    }

    // MARK: - Profile section

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            metricRow(label: "Email", value: viewModel.email)
            metricRow(
                label: "Weight",
                value: formattedMetric(value: viewModel.weight, unit: viewModel.weightUnit)
            )
            metricRow(
                label: "Height",
                value: formattedMetric(value: viewModel.height, unit: viewModel.heightUnit)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(GrayscalePalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func metricRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption.weight(.medium))
                .foregroundStyle(GrayscalePalette.secondary)
                .tracking(0.5)
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(GrayscalePalette.primary)
        }
    }

    // MARK: - Loading

    private var loadingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(GrayscalePalette.secondary)
            Text("Loading profile…")
                .font(.subheadline)
                .foregroundStyle(GrayscalePalette.secondary)
        }
    }

    // MARK: - Error banner

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(GrayscalePalette.primary)
            Text(message)
                .font(.footnote)
                .foregroundStyle(GrayscalePalette.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(GrayscalePalette.separator.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Helpers

    private func formattedMetric(value: Double?, unit: String?) -> String {
        guard let v = value, v > 0 else { return "–– \(unit ?? "")" }
        let formatted = v.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", v)
            : String(format: "%.1f", v)
        return "\(formatted) \(unit ?? "")".trimmingCharacters(in: .whitespaces)
    }
}
