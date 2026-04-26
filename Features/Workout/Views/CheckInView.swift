import SwiftUI

struct CheckInView: View {
    let workout: WorkoutSession
    let onBegin: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var mood: Mood? = nil
    @State private var warmups: [WarmupItem: Bool] = Dictionary(
        uniqueKeysWithValues: WarmupItem.allCases.map { ($0, false) }
    )

    private var allWarmedUp: Bool { warmups.values.allSatisfy { $0 } }

    enum Mood: String, CaseIterable {
        case low   = "low"
        case ok    = "ok"
        case high  = "high"

        var label: String {
            switch self { case .low: "Low"; case .ok: "Good"; case .high: "Strong" }
        }
        var sub: String {
            switch self { case .low: "take it easy"; case .ok: "standard day"; case .high: "push for PR" }
        }
    }

    enum WarmupItem: String, CaseIterable, Hashable {
        case mobility = "mobility"
        case cardio   = "cardio"
        case emptyBar = "emptyBar"

        var title: String {
            switch self {
            case .mobility: "5 min shoulder mobility"
            case .cardio:   "3 min light cardio"
            case .emptyBar: "Empty-bar bench × 10"
            }
        }
        var subtitle: String {
            switch self {
            case .mobility: "band dislocates · wall slides"
            case .cardio:   "row or bike, easy pace"
            case .emptyBar: "grease the groove"
            }
        }
    }

    var body: some View {
        ZStack {
            GrayscalePalette.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Program label
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(workout.program.uppercased()) · DAY \(workout.dayIndex)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(GrayscalePalette.secondary)
                            .tracking(1.2)

                        Text("Ready to lift?")
                            .font(.system(size: 30, design: .rounded).weight(.bold))
                            .foregroundStyle(GrayscalePalette.primary)
                            .tracking(-0.7)

                        Text("\(workout.name.lowercased()) — \(workout.exercises.count) exercises, about \(workout.estimatedMinutes) minutes.")
                            .font(.system(size: 15))
                            .foregroundStyle(GrayscalePalette.secondary)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 18)

                    // Mood selector
                    VStack(alignment: .leading, spacing: 10) {
                        Text("HOW DO YOU FEEL?")
                            .font(.system(size: 12, design: .monospaced).weight(.semibold))
                            .foregroundStyle(GrayscalePalette.secondary)
                            .tracking(1)

                        HStack(spacing: 8) {
                            ForEach(Mood.allCases, id: \.self) { m in
                                MoodButton(m: m, selected: mood == m) { mood = m }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 22)

                    // Warm-up checklist
                    VStack(alignment: .leading, spacing: 10) {
                        Text("WARM-UP")
                            .font(.system(size: 12, design: .monospaced).weight(.semibold))
                            .foregroundStyle(GrayscalePalette.secondary)
                            .tracking(1)

                        VStack(spacing: 0) {
                            ForEach(Array(WarmupItem.allCases.enumerated()), id: \.element) { i, item in
                                WarmupRow(
                                    item: item,
                                    done: warmups[item] ?? false,
                                    isLast: i == WarmupItem.allCases.count - 1
                                ) {
                                    warmups[item]?.toggle()
                                }
                            }
                        }
                        .background(GrayscalePalette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(GrayscalePalette.separator, lineWidth: 1))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 22)

                    // Begin CTA
                    VStack(spacing: 14) {
                        Button {
                            guard let m = mood else { return }
                            onBegin(m.rawValue)
                        } label: {
                            HStack(spacing: 8) {
                                Text("Begin session")
                                    .font(.system(size: 17, design: .rounded).weight(.bold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundStyle(mood != nil ? GrayscalePalette.background : GrayscalePalette.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(mood != nil ? GrayscalePalette.primary : GrayscalePalette.disabled)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: mood != nil ? .black.opacity(0.12) : .clear, radius: 12, y: 4)
                        }
                        .disabled(mood == nil)
                        .animation(.easeInOut(duration: 0.18), value: mood)

                        Text(allWarmedUp ? "✓ WARMED UP — LET'S GO" : "warm-up optional but recommended")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(GrayscalePalette.secondary)
                            .tracking(0.5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .padding(.bottom, 60)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(GrayscalePalette.primary)
                        .frame(width: 36, height: 36)
                        .background(GrayscalePalette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(GrayscalePalette.separator, lineWidth: 1))
                }
            }
            ToolbarItem(placement: .principal) {
                Text("CHECK IN")
                    .font(.system(size: 13, design: .monospaced).weight(.semibold))
                    .foregroundStyle(GrayscalePalette.secondary)
                    .tracking(1)
            }
        }
    }
}

// MARK: - Mood button

private struct MoodButton: View {
    let m: CheckInView.Mood
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(m.label)
                    .font(.system(size: 15, design: .rounded).weight(.bold))
                Text(m.sub)
                    .font(.system(size: 11, design: .monospaced))
                    .opacity(0.7)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(selected ? GrayscalePalette.background : GrayscalePalette.primary)
            .background(selected ? GrayscalePalette.primary : GrayscalePalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(selected ? GrayscalePalette.primary : GrayscalePalette.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: selected)
    }
}

// MARK: - Warmup row

private struct WarmupRow: View {
    let item: CheckInView.WarmupItem
    let done: Bool
    let isLast: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(done ? WorkoutPalette.accent : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(done ? Color.clear : GrayscalePalette.separator, lineWidth: 1.8)
                        )
                        .frame(width: 26, height: 26)
                    if done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(WorkoutPalette.onAccent)
                    }
                }
                .animation(.easeInOut(duration: 0.15), value: done)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 15, design: .rounded).weight(.semibold))
                        .foregroundStyle(GrayscalePalette.primary)
                        .strikethrough(done)
                        .opacity(done ? 0.5 : 1)
                    Text(item.subtitle)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(GrayscalePalette.secondary)
                        .opacity(done ? 0.5 : 1)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)

        if !isLast {
            Divider().padding(.leading, 56)
        }
    }
}
