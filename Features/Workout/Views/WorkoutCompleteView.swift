import SwiftUI

struct WorkoutCompleteView: View {
    let stats: WorkoutCompletionStats
    let onDone: () -> Void

    private var timeLabel: String {
        let m = stats.elapsedSeconds / 60
        return "\(m)"
    }

    var body: some View {
        ZStack {
            GrayscalePalette.background.ignoresSafeArea()

            // Soft blurred glow ornaments
            Circle()
                .fill(WorkoutPalette.accentSoft)
                .frame(width: 240, height: 240)
                .blur(radius: 50)
                .opacity(0.8)
                .offset(x: 80, y: -160)

            Circle()
                .fill(WorkoutPalette.accentSoft)
                .frame(width: 160, height: 160)
                .blur(radius: 40)
                .opacity(0.5)
                .offset(x: -80, y: 40)

            ScrollView {
                VStack(spacing: 0) {

                    // Mascot hero
                    ZStack(alignment: .bottomTrailing) {
                        ZStack {
                            Circle()
                                .fill(WorkoutPalette.accentSoft)
                                .shadow(color: WorkoutPalette.accent.opacity(0.35), radius: 40, y: 10)
                                .overlay(Circle().stroke(GrayscalePalette.separator, lineWidth: 1))
                                .frame(width: 180, height: 180)
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                        }

                        // Checkmark badge
                        ZStack {
                            Circle()
                                .fill(GrayscalePalette.primary)
                                .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
                                .frame(width: 54, height: 54)
                            Image(systemName: "checkmark")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(GrayscalePalette.background)
                        }
                        .offset(x: 4, y: 4)
                    }
                    .padding(.top, 44)

                    // Title
                    VStack(spacing: 8) {
                        Text("SESSION COMPLETE")
                            .font(.system(size: 12, design: .monospaced).weight(.semibold))
                            .foregroundStyle(GrayscalePalette.secondary)
                            .tracking(1.2)
                            .padding(.top, 22)

                        Text("Nice work.")
                            .font(.system(size: 32, design: .rounded).weight(.bold))
                            .foregroundStyle(GrayscalePalette.primary)
                            .tracking(-0.7)

                        (Text("You moved ")
                            .foregroundStyle(GrayscalePalette.secondary)
                         + Text("\(Int(stats.totalVolume).formatted()) kg")
                            .foregroundStyle(GrayscalePalette.primary)
                            .fontWeight(.semibold))
                        .font(.system(size: 15))
                    }
                    .multilineTextAlignment(.center)

                    // Stats grid
                    HStack(spacing: 0) {
                        SummaryCell(key: "Total volume", value: "\(Int(stats.totalVolume).formatted())", unit: "kg")
                        Divider().frame(width: 1)
                        SummaryCell(key: "Sets", value: "\(stats.totalSets)", unit: "")
                        Divider().frame(width: 1)
                        SummaryCell(key: "Time", value: timeLabel, unit: "min")
                    }
                    .frame(height: 80)
                    .background(GrayscalePalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(GrayscalePalette.separator, lineWidth: 1))
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    // PR callout
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(WorkoutPalette.accentSoft)
                                .frame(width: 40, height: 40)
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(WorkoutPalette.accentInk)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("New PR unlocked")
                                .font(.system(size: 14, design: .rounded).weight(.bold))
                                .foregroundStyle(GrayscalePalette.primary)
                            Text("Bench Press · 82.5kg × 6")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(GrayscalePalette.secondary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(GrayscalePalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(GrayscalePalette.separator, lineWidth: 1))
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                    // Actions
                    VStack(spacing: 8) {
                        Button(action: onDone) {
                            Text("Done")
                                .font(.system(size: 17, design: .rounded).weight(.bold))
                                .foregroundStyle(GrayscalePalette.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(GrayscalePalette.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }

                        Button(action: onDone) {
                            Text("Share to journal")
                                .font(.system(size: 14, design: .rounded).weight(.semibold))
                                .foregroundStyle(GrayscalePalette.secondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
                }
            }
        }
    }
}

// MARK: - Summary cell

private struct SummaryCell: View {
    let key: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Text(key.uppercased())
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(GrayscalePalette.secondary)
                .tracking(1)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, design: .rounded).weight(.bold))
                    .foregroundStyle(GrayscalePalette.primary)
                    .monospacedDigit()
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(GrayscalePalette.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
