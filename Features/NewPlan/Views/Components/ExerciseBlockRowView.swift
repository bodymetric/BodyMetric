import SwiftUI

/// A single exercise block row inside `ConfigureDayStepView`.
///
/// Displays: block number, muscle group label, optional remove button,
/// exercise picker trigger, and a stepper trio (Reps / Weight / Rest).
///
/// Constitution Principle VI: WorkoutPalette accent for valid left-border only.
struct ExerciseBlockRowView: View {

    let index: Int
    let block: ExerciseBlock
    let canRemove: Bool
    let onPick: () -> Void
    let onRemove: () -> Void
    let onChange: (ExerciseBlock) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            blockHeader
            exercisePickerTrigger
                .padding(.top, 10)
            stepperGrid
                .padding(.top, 10)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(GrayscalePalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(GrayscalePalette.separator, lineWidth: 1)
        )
        // Left-border: accent when valid, separator when not
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(block.isValid ? WorkoutPalette.accent : GrayscalePalette.separator)
                .frame(width: 3)
                .padding(.vertical, 2)
        }
    }

    // MARK: - Header

    private var blockHeader: some View {
        HStack(spacing: 10) {
            // Block number
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(GrayscalePalette.background)
                    .frame(width: 26, height: 26)
                Text(String(format: "%02d", index + 1))
                    .font(.system(size: 11, design: .monospaced).weight(.bold))
                    .foregroundStyle(GrayscalePalette.secondary)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(GrayscalePalette.separator, lineWidth: 1)
            )

            // Muscle label
            Text(muscleLabel)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(GrayscalePalette.secondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if canRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(GrayscalePalette.secondary)
                        .frame(width: 28, height: 28)
                        .background(GrayscalePalette.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove block")
            }
        }
    }

    // MARK: - Exercise picker trigger

    private var exercisePickerTrigger: some View {
        Button(action: onPick) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(GrayscalePalette.background)
                        .frame(width: 28, height: 28)
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(GrayscalePalette.secondary)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(GrayscalePalette.separator, lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 1) {
                    Text(exerciseName ?? "Choose exercise")
                        .font(.system(size: 14, design: .rounded).weight(.semibold))
                        .foregroundStyle(exerciseName != nil ? GrayscalePalette.primary : GrayscalePalette.secondary)
                        .lineLimit(1)
                    if let muscle = selectedExercise?.primaryMuscle {
                        Text(muscle)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(GrayscalePalette.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(GrayscalePalette.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(GrayscalePalette.background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(GrayscalePalette.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stepper grid

    private var stepperGrid: some View {
        HStack(spacing: 8) {
            BMStepperView(
                label: "Reps",
                unit: "",
                value: Double(block.targetReps),
                step: 1,
                min: 1, max: 50
            ) { newValue in
                var updated = block
                updated.targetReps = Int(newValue)
                onChange(updated)
            }

            BMStepperView(
                label: "Weight",
                unit: "kg",
                value: block.targetWeight,
                step: 2.5,
                min: 0, max: 500
            ) { newValue in
                var updated = block
                updated.targetWeight = newValue
                onChange(updated)
            }

            BMStepperView(
                label: "Rest",
                unit: "s",
                value: Double(block.restSeconds),
                step: 15,
                min: 0, max: 600
            ) { newValue in
                var updated = block
                updated.restSeconds = Int(newValue)
                onChange(updated)
            }
        }
    }

    // MARK: - Helpers

    private var selectedExercise: Exercise? {
        Exercise.catalog.first { $0.id == block.exerciseId }
    }

    private var exerciseName: String? { selectedExercise?.name }

    private var muscleLabel: String {
        selectedExercise?.primaryMuscle.uppercased() ?? "PICK AN EXERCISE"
    }
}

// MARK: - BMStepperView

/// Inline stepper: label · −  value  + layout used in exercise block rows.
///
/// Constitution Principle VI: GrayscalePalette only.
private struct BMStepperView: View {
    let label: String
    let unit: String
    let value: Double
    let step: Double
    let min: Double
    let max: Double
    let onChange: (Double) -> Void

    private var displayValue: String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(GrayscalePalette.secondary)
                .tracking(1.2)

            HStack(spacing: 4) {
                stepBtn(systemName: "minus") {
                    let next = Swift.max(min, value - step)
                    if next != value { onChange(next) }
                }

                HStack(spacing: 2) {
                    Text(displayValue)
                        .font(.system(size: 17, design: .rounded).weight(.bold))
                        .foregroundStyle(GrayscalePalette.primary)
                        .tracking(-0.3)
                        .frame(minWidth: 24)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(GrayscalePalette.secondary)
                            .tracking(0.5)
                    }
                }

                stepBtn(systemName: "plus") {
                    let next = Swift.min(max, value + step)
                    if next != value { onChange(next) }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(GrayscalePalette.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(GrayscalePalette.separator, lineWidth: 1)
        )
    }

    private func stepBtn(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(GrayscalePalette.primary)
                .frame(width: 28, height: 28)
                .background(GrayscalePalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(GrayscalePalette.separator, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
