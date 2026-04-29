import SwiftUI

struct TodayView: View {
    let workout: WorkoutSession
    let streak: WorkoutStreak
    let userName: String
    let networkClient: any NetworkClientProtocol
    let onSignOut: @MainActor () -> Void

    @State private var path = NavigationPath()
    @State private var menuOpen = false
    @State private var showWizard = false

    private enum Destination: Hashable {
        case checkIn
        case activeSession(mood: String)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                GrayscalePalette.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        greetingHeader
                        streakRibbon
                            .padding(.horizontal, 20)
                            .padding(.top, 14)
                        workoutHeroCard
                            .padding(.horizontal, 20)
                            .padding(.top, 18)
                        exerciseMenuSection
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        Spacer().frame(height: 120)
                    }
                }
            }
            .navigationDestination(for: Destination.self) { dest in
                switch dest {
                case .checkIn:
                    CheckInView(workout: workout) { mood in
                        path.append(Destination.activeSession(mood: mood))
                    }
                case .activeSession(let mood):
                    ActiveSessionView(
                        viewModel: ActiveSessionViewModel(workout: workout, mood: mood)
                    ) {
                        path = NavigationPath()
                    }
                }
            }
            .overlay {
                HomeMenuView(
                    isPresented: $menuOpen,
                    activeDestination: .today,
                    userName: userName,
                    onNavigate: { destination in
                        menuOpen = false
                        switch destination {
                        case .today:
                            break
                        case .newWorkoutPlan:
                            showWizard = true
                        }
                    },
                    onSignOut: onSignOut
                )
            }
            .fullScreenCover(isPresented: $showWizard) {
                NewPlanWizardView(
                    service: WorkoutPlanService(networkClient: networkClient),
                    dayConfigService: WorkoutDayPlanService(networkClient: networkClient)
                )
            }
        }
    }

    // MARK: - Greeting

    private var greetingHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateLabel)
                    .font(.system(size: 13, design: .rounded).weight(.medium))
                    .foregroundStyle(GrayscalePalette.secondary)
                    .tracking(0.4)
                    .textCase(.uppercase)
                Text("Morning, \(userName)")
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                    .foregroundStyle(GrayscalePalette.primary)
                    .tracking(-0.6)
            }
            Spacer()
            // Mascot chip — tapping opens the home menu (FR-001)
            Button {
                menuOpen = true
            } label: {
                ZStack {
                    Circle()
                        .fill(WorkoutPalette.accentSoft)
                        .frame(width: 52, height: 52)
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open menu")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    // MARK: - Streak ribbon

    private var streakRibbon: some View {
        HStack(spacing: 14) {
            // Flame icon
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(WorkoutPalette.accentSoft)
                    .frame(width: 44, height: 44)
                Image(systemName: "flame.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(WorkoutPalette.accentInk)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("\(streak.days)-day streak")
                    .font(.system(size: 17, design: .rounded).weight(.semibold))
                    .foregroundStyle(GrayscalePalette.primary)
                Text("4 of 5 sessions this week")
                    .font(.system(size: 13))
                    .foregroundStyle(GrayscalePalette.secondary)
            }

            Spacer()

            // Week dots
            HStack(spacing: 4) {
                ForEach(Array(zip(["M","T","W","T","F","S","S"], streak.weekDone)), id: \.0) { day, done in
                    VStack(spacing: 4) {
                        Text(day)
                            .font(.system(size: 10, design: .rounded).weight(.semibold))
                            .foregroundStyle(GrayscalePalette.secondary)
                        ZStack {
                            Circle()
                                .fill(done ? WorkoutPalette.accent : Color.clear)
                                .frame(width: 16, height: 16)
                            if !done {
                                Circle()
                                    .strokeBorder(GrayscalePalette.separator, style: StrokeStyle(lineWidth: 1.5, dash: [2]))
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(WorkoutPalette.onAccent)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(GrayscalePalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(GrayscalePalette.separator, lineWidth: 1))
    }

    // MARK: - Workout hero card

    private var workoutHeroCard: some View {
        ZStack(alignment: .topTrailing) {
            // Decorative circle ornament
            Circle()
                .fill(WorkoutPalette.accent.opacity(0.18))
                .frame(width: 160, height: 160)
                .offset(x: 40, y: -40)

            VStack(alignment: .leading, spacing: 0) {
                Text(workout.program.uppercased())
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(GrayscalePalette.background.opacity(0.55))
                    .tracking(1.2)
                    .padding(.top, 20)

                Text(workout.name)
                    .font(.system(size: 26, design: .rounded).weight(.bold))
                    .foregroundStyle(GrayscalePalette.background)
                    .tracking(-0.5)
                    .lineLimit(2)
                    .padding(.top, 4)

                HStack(spacing: 22) {
                    StatBadge(value: "\(workout.exercises.count)", label: "exercises")
                    Rectangle().fill(GrayscalePalette.background.opacity(0.15)).frame(width: 1, height: 30)
                    StatBadge(value: "\(workout.totalSets)", label: "sets")
                    Rectangle().fill(GrayscalePalette.background.opacity(0.15)).frame(width: 1, height: 30)
                    StatBadge(value: "\(workout.estimatedMinutes)", label: "est. min")
                }
                .padding(.top, 18)
                .opacity(0.9)

                Button {
                    path.append(Destination.checkIn)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                        Text("Start workout")
                            .font(.system(size: 17, design: .rounded).weight(.bold))
                    }
                    .foregroundStyle(WorkoutPalette.onAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(WorkoutPalette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
                }
                .padding(.top, 18)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
        }
        .background(GrayscalePalette.primary)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 20, y: 6)
    }

    // MARK: - Exercise menu

    private var exerciseMenuSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("On the menu")
                    .font(.system(size: 13, design: .rounded).weight(.semibold))
                    .foregroundStyle(GrayscalePalette.secondary)
                    .tracking(0.4)
                    .textCase(.uppercase)
                Spacer()
                Text("\(workout.exercises.count) lifts")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(GrayscalePalette.secondary)
            }
            .padding(.bottom, 10)

            VStack(spacing: 0) {
                ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { i, ex in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(WorkoutPalette.accentSoft)
                                .frame(width: 30, height: 30)
                            Text("\(i + 1)")
                                .font(.system(size: 12, design: .monospaced).weight(.bold))
                                .foregroundStyle(WorkoutPalette.accentInk)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(ex.name)
                                .font(.system(size: 15, design: .rounded).weight(.semibold))
                                .foregroundStyle(GrayscalePalette.primary)
                                .tracking(-0.2)
                            let prevWeight = ex.sets[0].prevWeight
                            Text("\(ex.sets.count) × \(ex.sets[0].targetReps)  ·  last \(formattedWeight(prevWeight))kg")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(GrayscalePalette.secondary)
                        }

                        Spacer()

                        if ex.pr != nil {
                            Text("PR")
                                .font(.system(size: 9, design: .monospaced).weight(.bold))
                                .foregroundStyle(WorkoutPalette.accentInk)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(WorkoutPalette.accentSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .tracking(1)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                    if i < workout.exercises.count - 1 {
                        Divider()
                            .padding(.leading, 58)
                    }
                }
            }
            .background(GrayscalePalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(GrayscalePalette.separator, lineWidth: 1))
        }
    }

    // MARK: - Helpers

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE · MMM d"
        return f.string(from: Date())
    }

    private func formattedWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", w) : String(format: "%.1f", w)
    }
}

// MARK: - Sub-views

private struct StatBadge: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 22, design: .rounded).weight(.bold))
                .foregroundStyle(GrayscalePalette.background)
                .tracking(-0.4)
            Text(label)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(GrayscalePalette.background.opacity(0.65))
                .tracking(1.2)
                .textCase(.uppercase)
        }
    }
}

// Preview uses a no-op stub so Xcode canvas doesn't require a live NetworkClient.
@MainActor
private final class PreviewNetworkClientStub: NetworkClientProtocol {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        throw NetworkError.noToken
    }
}

#Preview {
    TodayView(
        workout: .mockToday,
        streak: .init(days: 12, weekDone: [true, true, false, true, true, false, false]),
        userName: "Alex",
        networkClient: PreviewNetworkClientStub(),
        onSignOut: {}
    )
}
