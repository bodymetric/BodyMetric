import SwiftUI

/// Step 1 of the New Plan wizard: pick which days to train.
///
/// On appear, fetches previously saved day selections via `service` (FR-001/FR-003).
/// Shows a loading skeleton while the GET is in progress (FR-002).
/// Shows an inline error banner if the POST save fails (FR-012).
///
/// Constitution Principle VI: WorkoutPalette.accent for selected day circle only.
/// Constitution Principle VII: token injection handled by NetworkClient; no auth code here.
struct SelectDaysStepView: View {

    @Bindable var viewModel: NewPlanViewModel
    let service: any WorkoutPlanServiceProtocol

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeader
                .padding(.bottom, 16)

            // Loading overlay: shown while GET is in progress
            if viewModel.loadState == .loading {
                loadingPlaceholder
            } else {
                dayList
            }

            // Inline save error banner (FR-012)
            if let errorMessage = viewModel.saveErrorMessage {
                errorBanner(errorMessage)
                    .padding(.top, 12)
                    .transition(.opacity)
            }

            mascotTip
                .padding(.top, 14)
        }
        .animation(.bmFade, value: viewModel.loadState == .loading)
        .animation(.bmFade, value: viewModel.saveErrorMessage != nil)
        .task {
            // Load existing day selections on first appearance (FR-001)
            await viewModel.loadDays(using: service)
        }
    }

    // MARK: - Step header

    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("STEP 01 · CADENCE")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(GrayscalePalette.secondary)
                .tracking(1.2)
            Text("Which days will\nyou train?")
                .font(.system(size: 26, design: .rounded).weight(.bold))
                .foregroundStyle(GrayscalePalette.primary)
                .tracking(-0.5)
                .lineSpacing(2)
            Text("Pick as many as your week allows. You'll name and programme each one next.")
                .font(.system(size: 13))
                .foregroundStyle(GrayscalePalette.secondary)
                .lineSpacing(3)
        }
    }

    // MARK: - Loading placeholder

    private var loadingPlaceholder: some View {
        VStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { _ in
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(GrayscalePalette.surface)
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(GrayscalePalette.surface)
                            .frame(width: 80, height: 14)
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(GrayscalePalette.surface)
                            .frame(width: 56, height: 10)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                Divider().padding(.leading, 70)
            }
        }
        .background(GrayscalePalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(GrayscalePalette.separator, lineWidth: 1)
        )
        .overlay {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(GrayscalePalette.secondary)
                Text("Loading your plan…")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(GrayscalePalette.secondary)
            }
        }
        .opacity(0.6)
    }

    // MARK: - Day list

    private var dayList: some View {
        VStack(spacing: 0) {
            ForEach(Array(DayOfWeek.displayOrder.enumerated()), id: \.element) { idx, day in
                dayRow(day: day, isLast: idx == DayOfWeek.displayOrder.count - 1)
            }
        }
        .background(GrayscalePalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(GrayscalePalette.separator, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func dayRow(day: DayOfWeek, isLast: Bool) -> some View {
        let isSelected = viewModel.selectedDays.contains(day)
        Button {
            viewModel.toggleDay(day)  // toggleDay also clears saveErrorMessage
        } label: {
            HStack(spacing: 14) {
                // Day chip
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? WorkoutPalette.accent : GrayscalePalette.background)
                        .frame(width: 40, height: 40)
                    Text(day.shortLabel.uppercased())
                        .font(.system(size: 11, design: .monospaced).weight(.bold))
                        .foregroundStyle(isSelected ? WorkoutPalette.onAccent : GrayscalePalette.secondary)
                        .tracking(0.6)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? .clear : GrayscalePalette.separator, lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 1) {
                    Text(day.fullLabel)
                        .font(.system(size: 16, design: .rounded).weight(.semibold))
                        .foregroundStyle(GrayscalePalette.primary)
                        .tracking(-0.2)
                    Text(isSelected ? "Training day" : "Rest day")
                        .font(.system(size: 12))
                        .foregroundStyle(GrayscalePalette.secondary)
                }

                Spacer()

                // Checkmark badge
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isSelected ? GrayscalePalette.primary : .clear)
                        .frame(width: 24, height: 24)
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(isSelected ? .clear : GrayscalePalette.separator, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(GrayscalePalette.background)
                    }
                }
                .animation(.bmFade, value: isSelected)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if !isLast {
                Divider()
                    .padding(.leading, 70)
                    .background(GrayscalePalette.separator)
            }
        }
        .animation(.bmFade, value: isSelected)
    }

    // MARK: - Inline save error banner

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(GrayscalePalette.primary)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(GrayscalePalette.primary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GrayscalePalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(GrayscalePalette.separator, lineWidth: 1)
        )
    }

    // MARK: - Mascot tip

    private var mascotTip: some View {
        HStack(spacing: 10) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)

            Group {
                if viewModel.selectedDays.isEmpty {
                    Text("Pick at least one day to continue.")
                } else {
                    Text("\(viewModel.selectedDays.count) day\(viewModel.selectedDays.count == 1 ? "" : "s") selected — you'll configure each next.")
                }
            }
            .font(.system(size: 12, design: .rounded))
            .foregroundStyle(viewModel.selectedDays.isEmpty ? GrayscalePalette.secondary : WorkoutPalette.accentInk)
            .lineSpacing(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(viewModel.selectedDays.isEmpty ? GrayscalePalette.surface : WorkoutPalette.accentSoft)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(GrayscalePalette.separator, lineWidth: 1)
        )
        .animation(.bmFade, value: viewModel.selectedDays.isEmpty)
    }
}
