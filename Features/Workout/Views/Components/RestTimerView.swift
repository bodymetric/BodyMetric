import SwiftUI

struct RestTimerView: View {
    let remaining: Int
    let total: Int
    let onSkip: () -> Void
    let onAdd: (Int) -> Void

    private var fraction: Double {
        total > 0 ? 1.0 - Double(remaining) / Double(total) : 0
    }

    private var timeLabel: String {
        let m = remaining / 60
        let s = remaining % 60
        return m > 0 ? "\(m):\(String(format: "%02d", s))" : "\(s)s"
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Timer icon + countdown
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "timer")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(GrayscalePalette.background)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("REST")
                            .font(.system(size: 10, design: .monospaced).weight(.semibold))
                            .foregroundStyle(GrayscalePalette.background.opacity(0.6))
                            .tracking(1.2)
                        Text(timeLabel)
                            .font(.system(size: 26, design: .rounded).weight(.bold))
                            .foregroundStyle(GrayscalePalette.background)
                            .monospacedDigit()
                    }
                }

                Spacer()

                // Controls
                HStack(spacing: 6) {
                    Button { onAdd(15) } label: {
                        Text("+15s")
                            .font(.system(size: 12, design: .monospaced).weight(.semibold))
                            .foregroundStyle(GrayscalePalette.background)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    Button { onSkip() } label: {
                        HStack(spacing: 4) {
                            Text("Skip")
                                .font(.system(size: 13, design: .rounded).weight(.bold))
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(WorkoutPalette.onAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(WorkoutPalette.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                    Capsule()
                        .fill(WorkoutPalette.accent)
                        .frame(width: geo.size.width * fraction)
                        .animation(.linear(duration: 1), value: fraction)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(GrayscalePalette.primary)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
