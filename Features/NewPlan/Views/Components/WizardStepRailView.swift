import SwiftUI

/// Horizontal scrollable chip rail showing wizard step progress.
///
/// Active chip: GrayscalePalette.primary fill.
/// Completed & reachable chip: WorkoutPalette.accentSoft + checkmark.
/// Unreachable chip: GrayscalePalette.surface, 50% opacity.
///
/// Constitution Principle VI: palette-only colors throughout.
struct WizardStepRailView: View {

    @Bindable var viewModel: NewPlanViewModel

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(chips.enumerated()), id: \.element.step) { _, chip in
                    stepChip(chip)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(GrayscalePalette.background)
        .overlay(alignment: .bottom) {
            Divider().background(GrayscalePalette.separator)
        }
    }

    // MARK: - Chip model

    private struct ChipInfo {
        let step: Int
        let label: String
    }

    private var chips: [ChipInfo] {
        var result = [ChipInfo(step: 1, label: "Days")]
        for (idx, day) in viewModel.orderedSelectedDays.enumerated() {
            result.append(ChipInfo(step: 2 + idx, label: day.shortLabel))
        }
        result.append(ChipInfo(step: viewModel.totalSteps, label: "Save"))
        return result
    }

    // MARK: - Chip view

    @ViewBuilder
    private func stepChip(_ chip: ChipInfo) -> some View {
        let isActive = viewModel.currentStep == chip.step
        let isCompleted = chip.step < viewModel.currentStep && viewModel.isStepValid(chip.step)
        let isReachable = chip.step <= viewModel.currentStep

        Button {
            viewModel.jumpTo(step: chip.step)
        } label: {
            HStack(spacing: 6) {
                // Step indicator circle
                ZStack {
                    Circle()
                        .fill(isCompleted ? WorkoutPalette.accent : (isActive ? GrayscalePalette.background : GrayscalePalette.surface))
                        .frame(width: 16, height: 16)
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(WorkoutPalette.onAccent)
                    } else {
                        Text("\(chip.step)")
                            .font(.system(size: 9, design: .monospaced).weight(.bold))
                            .foregroundStyle(isActive ? GrayscalePalette.primary : GrayscalePalette.secondary)
                    }
                }

                Text(chip.label)
                    .font(.system(size: 12, design: .rounded).weight(.semibold))
                    .foregroundStyle(isActive ? GrayscalePalette.background : GrayscalePalette.primary)
                    .tracking(-0.1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isActive ? GrayscalePalette.primary : GrayscalePalette.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isActive ? .clear : GrayscalePalette.separator, lineWidth: 1)
            )
            .opacity(isReachable ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!isReachable)
    }
}
