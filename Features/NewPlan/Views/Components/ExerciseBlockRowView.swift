import SwiftUI

/// A single exercise block row inside `ConfigureDayStepView`.
///
/// Displays: block number, muscle group label, optional remove button,
/// exercise picker trigger, per-set row table (SET | REPS | WEIGHT), and REST stepper.
///
/// Constitution Principle VI: WorkoutPalette accent for valid left-border only.
struct ExerciseBlockRowView: View {

    let index: Int
    let block: ExerciseBlock
    let canRemove: Bool
    let exerciseName: String?   // supplied by parent from the API catalog
    let onPick: () -> Void
    let onRemove: () -> Void
    let onChange: (ExerciseBlock) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            blockHeader
            exercisePickerTrigger
                .padding(.top, 10)
            setRowsTable
                .padding(.top, 12)
            restStepper
                .padding(.top, 8)
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
                    if exerciseName != nil {
                        Text(block.exerciseId)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(GrayscalePalette.secondary)
                            .opacity(0)  // hidden — preserves layout height
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

    // MARK: - Set rows table

    private var setRowsTable: some View {
        VStack(spacing: 0) {
            // Column header
            HStack(spacing: 0) {
                Text("SET")
                    .frame(width: 36, alignment: .leading)
                Text("REPS")
                    .frame(maxWidth: .infinity)
                Text("WEIGHT")
                    .frame(maxWidth: .infinity)
                Spacer().frame(width: 32)
            }
            .font(.system(size: 9, design: .monospaced))
            .foregroundStyle(GrayscalePalette.secondary)
            .tracking(1.2)
            .padding(.horizontal, 4)
            .padding(.bottom, 6)

            // Set rows
            ForEach(Array(block.sets.enumerated()), id: \.element.id) { idx, set in
                setRow(idx: idx, set: set)
                if idx < block.sets.count - 1 {
                    Divider()
                        .padding(.vertical, 4)
                }
            }

            // Add set button
            Button {
                var updated = block
                let last = updated.sets.last ?? SetConfig()
                updated.sets.append(SetConfig(targetReps: last.targetReps, targetWeight: last.targetWeight))
                onChange(updated)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Add set")
                        .font(.system(size: 13, design: .rounded).weight(.semibold))
                }
                .foregroundStyle(GrayscalePalette.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(GrayscalePalette.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(GrayscalePalette.separator, lineWidth: 1)
        )
    }

    private func setRow(idx: Int, set: SetConfig) -> some View {
        HStack(spacing: 0) {
            // Set number badge
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(GrayscalePalette.surface)
                    .frame(width: 26, height: 26)
                Text("\(idx + 1)")
                    .font(.system(size: 11, design: .monospaced).weight(.bold))
                    .foregroundStyle(GrayscalePalette.secondary)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(GrayscalePalette.separator, lineWidth: 1)
            )
            .frame(width: 36, alignment: .leading)

            // Reps inline stepper
            inlineStepper(value: Double(set.targetReps), step: 1, min: 1, max: 50, unit: "") { newValue in
                var updated = block
                updated.sets[idx].targetReps = Int(newValue)
                onChange(updated)
            }
            .frame(maxWidth: .infinity)

            // Weight inline stepper
            inlineStepper(value: set.targetWeight, step: 2.5, min: 0, max: 500, unit: "kg") { newValue in
                var updated = block
                updated.sets[idx].targetWeight = newValue
                onChange(updated)
            }
            .frame(maxWidth: .infinity)

            // Remove button
            Button {
                var updated = block
                updated.sets.remove(at: idx)
                onChange(updated)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(GrayscalePalette.secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .opacity(block.sets.count > 1 ? 1 : 0)
            .disabled(block.sets.count <= 1)
            .frame(width: 32)
        }
        .padding(.vertical, 2)
    }

    private func inlineStepper(value: Double, step: Double, min: Double, max: Double, unit: String, onChange: @escaping (Double) -> Void) -> some View {
        HStack(spacing: 6) {
            Button {
                let next = Swift.max(min, value - step)
                if next != value { onChange(next) }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GrayscalePalette.primary)
                    .frame(width: 26, height: 26)
                    .background(GrayscalePalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(GrayscalePalette.separator, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(value <= min)

            HStack(spacing: 2) {
                Text(value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(format: "%.1f", value))
                    .font(.system(size: 15, design: .rounded).weight(.bold))
                    .foregroundStyle(GrayscalePalette.primary)
                    .frame(minWidth: 20)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(GrayscalePalette.secondary)
                }
            }

            Button {
                let next = Swift.min(max, value + step)
                if next != value { onChange(next) }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GrayscalePalette.primary)
                    .frame(width: 26, height: 26)
                    .background(GrayscalePalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(GrayscalePalette.separator, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(value >= max)
        }
    }

    // MARK: - REST stepper (block-level)

    private var restStepper: some View {
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

    // MARK: - Helpers

    private var muscleLabel: String {
        exerciseName != nil ? "" : "PICK AN EXERCISE"
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
