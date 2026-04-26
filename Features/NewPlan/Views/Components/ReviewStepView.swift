import SwiftUI

/// Final wizard step: review all configured days before saving.
///
/// Each day card shows session name, per-block summary, and validity badge.
/// Tapping a card calls `viewModel.jumpTo(step:)` to let the user fix issues.
///
/// Constitution Principle VI: GrayscalePalette for all structural colors;
///   WorkoutPalette.accent for valid left-borders.
struct ReviewStepView: View {

    @Bindable var viewModel: NewPlanViewModel

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeader
                .padding(.bottom, 16)

            daySummaries

            if !viewModel.allDaysValid {
                invalidBanner
                    .padding(.top, 14)
            }
        }
    }

    // MARK: - Step header

    private var stepHeader: some View {
        let totalBlocks = viewModel.orderedSelectedDays
            .compactMap { viewModel.dayPlans[$0] }
            .flatMap(\.blocks).count

        return VStack(alignment: .leading, spacing: 6) {
            Text("FINAL · REVIEW")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(GrayscalePalette.secondary)
                .tracking(1.2)
            Text("One last look.")
                .font(.system(size: 26, design: .rounded).weight(.bold))
                .foregroundStyle(GrayscalePalette.primary)
                .tracking(-0.5)
            Text("\(viewModel.orderedSelectedDays.count) day\(viewModel.orderedSelectedDays.count == 1 ? "" : "s") · \(totalBlocks) exercise block\(totalBlocks == 1 ? "" : "s").")
                .font(.system(size: 13))
                .foregroundStyle(GrayscalePalette.secondary)
                .lineSpacing(3)
        }
    }

    // MARK: - Day summaries

    private var daySummaries: some View {
        VStack(spacing: 10) {
            ForEach(Array(viewModel.orderedSelectedDays.enumerated()), id: \.element) { idx, day in
                if let plan = viewModel.dayPlans[day] {
                    dayCard(day: day, plan: plan, stepIndex: 2 + idx)
                }
            }
        }
    }

    @ViewBuilder
    private func dayCard(day: DayOfWeek, plan: DayPlan, stepIndex: Int) -> some View {
        let isValid = plan.isValid
        let borderColor: Color = isValid ? WorkoutPalette.accent : GrayscalePalette.primary

        Button {
            viewModel.jumpTo(step: stepIndex)
        } label: {
            VStack(spacing: 0) {
                // Card header
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isValid ? WorkoutPalette.accentSoft : GrayscalePalette.surface)
                            .frame(width: 32, height: 32)
                        Text(day.shortLabel.uppercased())
                            .font(.system(size: 11, design: .monospaced).weight(.bold))
                            .foregroundStyle(isValid ? WorkoutPalette.accentInk : GrayscalePalette.secondary)
                            .tracking(0.6)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(day.fullLabel.uppercased())
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(GrayscalePalette.secondary)
                            .tracking(1.2)
                        Text(plan.sessionName.isEmpty ? "Unnamed session" : plan.sessionName)
                            .font(.system(size: 16, design: .rounded).weight(.bold))
                            .foregroundStyle(plan.sessionName.isEmpty ? borderColor : GrayscalePalette.primary)
                            .tracking(-0.2)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Status badge
                    HStack(spacing: 4) {
                        Image(systemName: isValid ? "checkmark" : "xmark")
                            .font(.system(size: 9, weight: .bold))
                        Text(isValid ? "OK" : "FIX")
                            .font(.system(size: 9, design: .monospaced).weight(.bold))
                            .tracking(1)
                    }
                    .foregroundStyle(isValid ? WorkoutPalette.accentInk : borderColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(isValid ? WorkoutPalette.accentSoft : borderColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, plan.blocks.isEmpty ? 12 : 8)

                if !plan.blocks.isEmpty {
                    Divider()
                        .background(GrayscalePalette.separator)
                        .padding(.horizontal, 14)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(plan.blocks.enumerated()), id: \.element.id) { idx, block in
                            blockSummaryRow(index: idx, block: block)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
            }
            .background(GrayscalePalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(GrayscalePalette.separator, lineWidth: 1)
            )
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(borderColor)
                    .frame(width: 3)
                    .padding(.vertical, 2)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func blockSummaryRow(index: Int, block: ExerciseBlock) -> some View {
        let exercise = Exercise.catalog.first { $0.id == block.exerciseId }
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(String(format: "%02d", index + 1))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(GrayscalePalette.secondary)
                .frame(width: 16)
            Text(exercise?.name ?? "No exercise")
                .font(.system(size: 13, design: .rounded).weight(.medium))
                .foregroundStyle(GrayscalePalette.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            Text("\(block.targetReps)×\(formattedWeight(block.targetWeight))kg · \(block.restSeconds)s")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(GrayscalePalette.secondary)
                .lineLimit(1)
        }
    }

    // MARK: - Invalid banner

    private var invalidBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(GrayscalePalette.primary)
            Text("Tap any day above to fix it before finishing.")
                .font(.system(size: 12))
                .foregroundStyle(GrayscalePalette.primary)
                .lineSpacing(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(GrayscalePalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(GrayscalePalette.separator, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func formattedWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", w)
            : String(format: "%.1f", w)
    }
}
