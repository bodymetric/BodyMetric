import SwiftUI

struct ExerciseCard: View {
    let exercise: WorkoutExercise
    let exIdx: Int
    let progress: ExerciseProgress
    let expanded: Bool
    let onExpand: () -> Void
    let onOpenLog: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header row — always visible
            Button(action: onExpand) {
                HStack(spacing: 12) {
                    // Index badge / checkmark
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(progress.allDone ? WorkoutPalette.accent : GrayscalePalette.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(GrayscalePalette.separator, lineWidth: progress.allDone ? 0 : 1)
                            )
                            .frame(width: 32, height: 32)
                        if progress.allDone {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(WorkoutPalette.onAccent)
                        } else {
                            Text("\(exIdx + 1)")
                                .font(.system(size: 13, design: .monospaced).weight(.bold))
                                .foregroundStyle(GrayscalePalette.secondary)
                        }
                    }

                    // Name + sub
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.system(size: 16, design: .rounded).weight(.bold))
                            .foregroundStyle(GrayscalePalette.primary)
                            .strikethrough(progress.allDone)
                        Text("\(progress.doneCount)/\(progress.sets.count) sets · \(exercise.muscle)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(GrayscalePalette.secondary)
                    }

                    Spacer()

                    // PR badge
                    if let pr = exercise.pr, !progress.allDone {
                        Text("PR \(formattedWeight(pr.weight))kg")
                            .font(.system(size: 9, design: .monospaced).weight(.bold))
                            .foregroundStyle(WorkoutPalette.accentInk)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(WorkoutPalette.accentSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .tracking(1)
                    }

                    // Chevron when collapsed
                    if !expanded {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(GrayscalePalette.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .disabled(expanded)

            // Expanded set rows
            if expanded {
                VStack(spacing: 0) {
                    // Column headers
                    HStack {
                        Text("SET")
                            .frame(width: 38, alignment: .leading)
                        Text("PREVIOUS")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("KG")
                            .frame(width: 72, alignment: .center)
                        Text("REPS")
                            .frame(width: 70, alignment: .center)
                        Spacer().frame(width: 52)
                    }
                    .font(.system(size: 10, design: .monospaced).weight(.semibold))
                    .foregroundStyle(GrayscalePalette.secondary)
                    .tracking(1)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                    ForEach(Array(progress.sets.enumerated()), id: \.offset) { i, set in
                        SetRowView(idx: i, set: set, onTap: {
                            if !set.done { onOpenLog(i) }
                        })
                        .padding(.horizontal, 12)
                    }

                    // Add warm-up set button
                    Button {
                        let firstIncomplete = progress.sets.firstIndex(where: { !$0.done }) ?? 0
                        onOpenLog(firstIncomplete)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("Add warm-up set")
                                .font(.system(size: 13, design: .rounded).weight(.semibold))
                        }
                        .foregroundStyle(GrayscalePalette.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(GrayscalePalette.separator, style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
            }
        }
        .background(GrayscalePalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(GrayscalePalette.separator, lineWidth: 1)
        )
        .opacity(progress.allDone && !expanded ? 0.6 : 1)
        .animation(.easeInOut(duration: 0.25), value: progress.allDone)
    }

    private func formattedWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", w) : String(format: "%.1f", w)
    }
}

// MARK: - Set row

struct SetRowView: View {
    let idx: Int
    let set: SetProgress
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                // Set number badge
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(set.done ? WorkoutPalette.accent : GrayscalePalette.surfaceAlt)
                        .frame(width: 24, height: 24)
                    if set.done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(WorkoutPalette.onAccent)
                    } else {
                        Text("\(idx + 1)")
                            .font(.system(size: 12, design: .monospaced).weight(.bold))
                            .foregroundStyle(GrayscalePalette.secondary)
                    }
                }
                .frame(width: 38, alignment: .leading)

                // Previous
                Text("\(formattedWeight(set.prevWeight))kg × \(set.prevReps)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(set.done ? WorkoutPalette.accentInk : GrayscalePalette.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Logged weight
                Text(set.done ? formattedWeight(set.weight) : "—")
                    .font(.system(size: 15, design: .rounded).weight(.bold))
                    .foregroundStyle(set.done ? WorkoutPalette.accentInk : GrayscalePalette.primary)
                    .frame(width: 72, alignment: .center)

                // Logged reps
                Text(set.done ? "\(set.reps)" : "—")
                    .font(.system(size: 15, design: .rounded).weight(.bold))
                    .foregroundStyle(set.done ? WorkoutPalette.accentInk : GrayscalePalette.primary)
                    .frame(width: 70, alignment: .center)

                // Action indicator
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(set.done ? WorkoutPalette.accent : GrayscalePalette.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(GrayscalePalette.separator, lineWidth: set.done ? 0 : 1)
                        )
                        .frame(width: 28, height: 28)
                    Image(systemName: set.done ? "checkmark" : "chevron.right")
                        .font(.system(size: set.done ? 12 : 11, weight: .bold))
                        .foregroundStyle(set.done ? WorkoutPalette.onAccent : GrayscalePalette.secondary)
                }
                .frame(width: 52, alignment: .center)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .background(set.done ? WorkoutPalette.accentSoft : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(set.done)
        .animation(.easeInOut(duration: 0.2), value: set.done)
    }

    private func formattedWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", w) : String(format: "%.1f", w)
    }
}

// MARK: - Surface alt for set rows
private extension GrayscalePalette {
    static let surfaceAlt = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 0.18, alpha: 1)
            : UIColor(white: 0.91, alpha: 1)
    })
}
