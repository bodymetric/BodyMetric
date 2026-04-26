import SwiftUI

struct ActiveSessionView: View {
    @State var viewModel: ActiveSessionViewModel
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            GrayscalePalette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                sessionHeader
                exerciseList
            }

            // Rest timer docked above bottom edge
            if let remaining = viewModel.restRemaining {
                VStack {
                    Spacer()
                    RestTimerView(
                        remaining: remaining,
                        total: viewModel.restTotal,
                        onSkip: {
                            viewModel.skipRest();
                            viewModel.dispose();
                        },
                        onAdd:  { viewModel.addRest(seconds: $0) }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.bmSpring, value: viewModel.restRemaining != nil)
            }

            // Log sheet overlay
            if let target = viewModel.logTarget {
                let ex = viewModel.workout.exercises[target.exIdx]
                let set = viewModel.progress[target.exIdx].sets[target.setIdx]
                LogSetSheet(
                    target: target,
                    initial: set,
                    exerciseName: ex.name,
                    onClose: { viewModel.closeLog() },
                    onCommit: { weight, reps in
                        viewModel.commitSet(
                            exIdx: target.exIdx,
                            setIdx: target.setIdx,
                            weight: weight,
                            reps: reps
                        )
                    }
                )
                .animation(.bmSpring, value: viewModel.logTarget != nil)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: Binding(
            get: { viewModel.completionStats != nil },
            set: { _ in }
        )) {
            if let stats = viewModel.completionStats {
                WorkoutCompleteView(stats: stats, onDone: onComplete)
            }
        }
    }

    // MARK: - Header

    private var sessionHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(GrayscalePalette.primary)
                        .frame(width: 36, height: 36)
                        .background(GrayscalePalette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(GrayscalePalette.separator, lineWidth: 1))
                }

                Spacer()

                VStack(spacing: 1) {
                    Text("ACTIVE · \(viewModel.mood.uppercased())")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(GrayscalePalette.secondary)
                        .tracking(1.2)
                    SessionClock(elapsed: viewModel.elapsedSeconds)
                }

                Spacer()

                Button {} label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(GrayscalePalette.primary)
                        .frame(width: 36, height: 36)
                        .background(GrayscalePalette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(GrayscalePalette.separator, lineWidth: 1))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 10)

            // Progress bar
            HStack(spacing: 10) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(GrayscalePalette.surface).frame(height: 6)
                        Capsule()
                            .fill(GrayscalePalette.primary)
                            .frame(width: geo.size.width * viewModel.completionFraction, height: 6)
                            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: viewModel.completionFraction)
                    }
                }
                .frame(height: 6)

                Text("\(viewModel.doneSets)/\(viewModel.totalSets) SETS")
                    .font(.system(size: 11, design: .monospaced).weight(.semibold))
                    .foregroundStyle(GrayscalePalette.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .background(GrayscalePalette.background)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: - Exercise list

    private var exerciseList: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(Array(viewModel.workout.exercises.enumerated()), id: \.element.id) { i, ex in
                    ExerciseCard(
                        exercise: ex,
                        exIdx: i,
                        progress: viewModel.progress[i],
                        expanded: i == viewModel.activeExIdx,
                        onExpand: { viewModel.activeExIdx = i },
                        onOpenLog: { setIdx in viewModel.openLog(exIdx: i, setIdx: setIdx) }
                    )
                    .padding(.horizontal, 16)
                }

                // Mascot volume footer
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(WorkoutPalette.accentSoft)
                            .frame(width: 48, height: 48)
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                    }
                    Text("Volume today: ")
                        .foregroundStyle(GrayscalePalette.secondary)
                    + Text("\(Int(viewModel.totalVolume).formatted()) kg")
                        .foregroundStyle(GrayscalePalette.primary)
                        .monospacedDigit()
                }
                .font(.system(size: 13))
                .padding(.horizontal, 20)
                .padding(.bottom, viewModel.restRemaining != nil ? 180 : 40)
                .padding(.top, 24)
            }
            .padding(.top, 14)
        }
    }
}

// MARK: - Session clock

private struct SessionClock: View {
    let elapsed: Int

    private var label: String {
        let m = elapsed / 60
        let s = elapsed % 60
        return "\(m):\(String(format: "%02d", s))"
    }

    var body: some View {
        Text(label)
            .font(.system(size: 15, design: .monospaced).weight(.semibold))
            .foregroundStyle(GrayscalePalette.primary)
            .monospacedDigit()
    }
}
