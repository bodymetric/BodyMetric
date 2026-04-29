import SwiftUI

/// Wizard step for configuring a single training day.
///
/// Displays: session name input + ordered exercise blocks.
/// Each block is rendered by `ExerciseBlockRowView`.
/// Exercise picker sheet is driven by `viewModel.activePickerBlockId`.
///
/// Constitution Principle VI: palette-only colors throughout.
struct ConfigureDayStepView: View {

    @Bindable var viewModel: NewPlanViewModel
    let day: DayOfWeek
    let dayIndex: Int
    let totalDays: Int

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeader
                .padding(.bottom, 18)

            sessionNameField

            // Inline save error banner (spec FR-010/FR-011; feature 011)
            if let errorMessage = viewModel.dayConfigSaveError {
                dayConfigErrorBanner(errorMessage)
                    .padding(.top, 12)
                    .transition(.opacity)
            }

            blockSection
                .padding(.top, 18)
        }
        .animation(.bmFade, value: viewModel.dayConfigSaveError != nil)
        .sheet(item: Binding(
            get: { viewModel.activePickerBlockId.map { PickerID(id: $0) } },
            set: { viewModel.activePickerBlockId = $0?.id }
        )) { pickerID in
            ExercisePickerSheetView(
                currentExerciseId: viewModel.dayPlans[day]?.blocks
                    .first(where: { $0.id == pickerID.id })?.exerciseId ?? "",
                onPick: { exerciseId in
                    viewModel.updateBlock(id: pickerID.id, day: day) { $0.exerciseId = exerciseId }
                    viewModel.activePickerBlockId = nil
                }
            )
        }
    }

    // MARK: - Step header

    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("STEP \(String(format: "%02d", 2 + dayIndex)) · DAY \(dayIndex + 1) OF \(totalDays)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(GrayscalePalette.secondary)
                .tracking(1.2)
            Text(day.fullLabel)
                .font(.system(size: 26, design: .rounded).weight(.bold))
                .foregroundStyle(GrayscalePalette.primary)
                .tracking(-0.5)
            Text("Name the session, then stack the exercise blocks.")
                .font(.system(size: 13))
                .foregroundStyle(GrayscalePalette.secondary)
                .lineSpacing(3)
        }
    }

    // MARK: - Session name field

    private var sessionNameField: some View {
        let sessionName = Binding<String>(
            get: { viewModel.dayPlans[day]?.sessionName ?? "" },
            set: { viewModel.dayPlans[day]?.sessionName = $0 }
        )

        return VStack(alignment: .leading, spacing: 6) {
            Text("WORKOUT NAME")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(GrayscalePalette.secondary)
                .tracking(1.2)

            HStack {
                TextField("e.g. Chest and Triceps", text: sessionName)
                    .font(.system(size: 18, design: .rounded).weight(.bold))
                    .foregroundStyle(GrayscalePalette.primary)
                    .autocorrectionDisabled()
                    .onChange(of: sessionName.wrappedValue) { _, _ in
                        // Dismiss step-2 save error when user edits the name (spec FR-012)
                        viewModel.dayConfigSaveError = nil
                    }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(GrayscalePalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        (viewModel.dayPlans[day]?.sessionName.isEmpty == false)
                            ? WorkoutPalette.accent
                            : GrayscalePalette.separator,
                        lineWidth: 1.5
                    )
                    .animation(.bmFade, value: viewModel.dayPlans[day]?.sessionName.isEmpty)
            )
        }
    }

    // MARK: - Block section

    private var blockSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("EXERCISE BLOCKS")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(GrayscalePalette.secondary)
                    .tracking(1.2)
                Spacer()
                if let count = viewModel.dayPlans[day]?.blocks.count {
                    Text("\(count) block\(count == 1 ? "" : "s")")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(GrayscalePalette.secondary)
                }
            }
            .padding(.bottom, 8)

            if let blocks = viewModel.dayPlans[day]?.blocks {
                VStack(spacing: 10) {
                    ForEach(Array(blocks.enumerated()), id: \.element.id) { idx, block in
                        ExerciseBlockRowView(
                            index: idx,
                            block: block,
                            canRemove: blocks.count > 1,
                            onPick: {
                                viewModel.activePickerBlockId = block.id
                            },
                            onRemove: {
                                viewModel.removeBlock(id: block.id, from: day)
                            },
                            onChange: { updated in
                                viewModel.updateBlock(id: block.id, day: day) { $0 = updated }
                            }
                        )
                    }
                }
            }

            addBlockButton
                .padding(.top, 10)
        }
    }

    private var addBlockButton: some View {
        Button {
            viewModel.addBlock(for: day)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                Text("Add another block")
                    .font(.system(size: 14, design: .rounded).weight(.semibold))
            }
            .foregroundStyle(GrayscalePalette.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(GrayscalePalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                    .foregroundStyle(GrayscalePalette.separator)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step-2 save error banner (feature 011, spec FR-010/FR-011)

    private func dayConfigErrorBanner(_ message: String) -> some View {
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
}

// MARK: - PickerID (Identifiable wrapper for sheet(item:))

private struct PickerID: Identifiable {
    let id: UUID
}
