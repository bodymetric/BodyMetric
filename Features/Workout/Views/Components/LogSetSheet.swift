import SwiftUI

struct LogSetSheet: View {
    let target: LogTarget
    let initial: SetProgress
    let exerciseName: String
    let onClose: () -> Void
    let onCommit: (Double, Int) -> Void

    @State private var weight: Double
    @State private var reps: Int
    @State private var activeField: Field = .reps

    enum Field { case weight, reps }

    init(target: LogTarget, initial: SetProgress, exerciseName: String,
         onClose: @escaping () -> Void, onCommit: @escaping (Double, Int) -> Void) {
        self.target = target
        self.initial = initial
        self.exerciseName = exerciseName
        self.onClose = onClose
        self.onCommit = onCommit
        _weight = State(initialValue: initial.weight)
        _reps   = State(initialValue: initial.reps)
    }

    private var volumeDelta: Double {
        weight * Double(reps) - initial.prevWeight * Double(initial.prevReps)
    }

    private var weightLabel: String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", weight)
            : String(format: "%.1f", weight)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Backdrop
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            // Sheet
            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(GrayscalePalette.separator)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 10)

                // Header
                HStack(alignment: .firstTextBaseline) {
                    Text("SET \(target.setIdx + 1) · TARGET \(initial.targetReps)")
                        .font(.system(size: 11, design: .monospaced).weight(.semibold))
                        .foregroundStyle(GrayscalePalette.secondary)
                        .tracking(1.2)
                    Spacer()
                    Button("Cancel") { onClose() }
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(GrayscalePalette.secondary)
                }
                .padding(.horizontal, 20)

                Text(exerciseName)
                    .font(.system(size: 18, design: .rounded).weight(.bold))
                    .foregroundStyle(GrayscalePalette.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                // Weight & Reps fields
                HStack(spacing: 12) {
                    FieldControl(
                        label: "WEIGHT", unit: "kg",
                        displayValue: weightLabel,
                        active: activeField == .weight,
                        onTap: { activeField = .weight },
                        onInc: { weight = max(0, (weight + 2.5).rounded(toPlaces: 2)) },
                        onDec: { weight = max(0, (weight - 2.5).rounded(toPlaces: 2)) }
                    )
                    FieldControl(
                        label: "REPS", unit: "reps",
                        displayValue: "\(reps)",
                        active: activeField == .reps,
                        onTap: { activeField = .reps },
                        onInc: { reps = max(0, reps + 1) },
                        onDec: { reps = max(0, reps - 1) }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)

                // vs-last line
                let sign = volumeDelta >= 0
                HStack(spacing: 4) {
                    Text("last time: \(String(format: "%.1f", initial.prevWeight)) × \(initial.prevReps)")
                    Text(sign ? "▲" : "▼")
                    Text("\(Int(abs(volumeDelta)))kg vol")
                        .fontWeight(.bold)
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(sign ? WorkoutPalette.accentInk : GrayscalePalette.secondary)
                .padding(.top, 12)

                // Numpad
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(["1","2","3","4","5","6","7","8","9",".","0","⌫"], id: \.self) { key in
                        Button {
                            handleKey(key)
                        } label: {
                            Text(key)
                                .font(.system(size: 20, design: .rounded).weight(.semibold))
                                .foregroundStyle(GrayscalePalette.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(GrayscalePalette.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(GrayscalePalette.separator, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Log button
                Button {
                    onCommit(weight, reps)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                        Text("Log set")
                            .font(.system(size: 17, design: .rounded).weight(.bold))
                    }
                    .foregroundStyle(WorkoutPalette.onAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(WorkoutPalette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.16), radius: 12, y: 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 36)
            }
            .background(GrayscalePalette.background)
            .clipShape(TopRoundedShape(radius: 28))
        }
        .ignoresSafeArea()
        .transition(.move(edge: .bottom))
    }

    private func handleKey(_ key: String) {
        if activeField == .reps {
            switch key {
            case "⌫": reps = Int(String(String(reps).dropLast())) ?? 0
            case ".": break
            default:
                let s = reps == 0 ? key : "\(reps)\(key)"
                reps = Int(s) ?? reps
            }
        } else {
            let current = weightLabel
            switch key {
            case "⌫":
                let trimmed = String(current.dropLast())
                weight = Double(trimmed) ?? 0
            case ".":
                if !current.contains(".") {
                    weight = Double("\(current).") ?? weight
                }
            default:
                weight = Double("\(current)\(key)") ?? weight
            }
        }
    }
}

// MARK: - Field control

private struct FieldControl: View {
    let label: String
    let unit: String
    let displayValue: String
    let active: Bool
    let onTap: () -> Void
    let onInc: () -> Void
    let onDec: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onDec) {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(GrayscalePalette.primary)
                    .frame(width: 36, height: 36)
                    .background(GrayscalePalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(GrayscalePalette.separator, lineWidth: 1))
            }

            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 9, design: .monospaced).weight(.semibold))
                    .foregroundStyle(GrayscalePalette.secondary)
                    .tracking(1.2)
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(displayValue)
                        .font(.system(size: 28, design: .rounded).weight(.bold))
                        .foregroundStyle(GrayscalePalette.primary)
                        .monospacedDigit()
                    Text(unit)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(GrayscalePalette.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            Button(action: onInc) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(GrayscalePalette.primary)
                    .frame(width: 36, height: 36)
                    .background(GrayscalePalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(GrayscalePalette.separator, lineWidth: 1))
            }
        }
        .padding(12)
        .background(active ? WorkoutPalette.accentSoft : GrayscalePalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(active ? GrayscalePalette.primary : GrayscalePalette.separator, lineWidth: active ? 1.5 : 1)
        )
        .onTapGesture { onTap() }
        .animation(.easeInOut(duration: 0.18), value: active)
    }
}

// MARK: - Helpers

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let d = pow(10.0, Double(places))
        return (self * d).rounded() / d
    }
}

// Top-corners-only clip shape for the bottom sheet
private struct TopRoundedShape: Shape {
    var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
