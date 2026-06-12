import SwiftUI

struct TodayView: View {
    let viewModel: TodayViewModel
    let userName: String
    let networkClient: any NetworkClientProtocol
    let onSignOut: @MainActor () -> Void
    let homeService: any HomeServiceProtocol

    @State private var path = NavigationPath()
    @State private var menuOpen = false
    @State private var showWizard = false
    @State private var showEditWizard = false
    @State private var showCheckIn = false

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
                        workoutSection
                            .padding(.horizontal, 20)
                            .padding(.top, 18)
                        if !viewModel.exercisesForToday.isEmpty {
                            exercisesCard
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                        }
                        Spacer().frame(height: 120)
                    }
                }
            }
            .task {
                await viewModel.loadHomeData(using: homeService)
            }
            .onChange(of: showCheckIn) { old, new in
                guard old && !new else { return }
                Task { await viewModel.reload(using: homeService) }
            }
            .overlay {
                HomeMenuView(
                    isPresented: $menuOpen,
                    activeDestination: .today,
                    userName: userName,
                    hasActivePlan: viewModel.hasActivePlan,
                    onNavigate: { destination in
                        menuOpen = false
                        switch destination {
                        case .today:
                            break
                        case .newWorkoutPlan:
                            showWizard = true
                        case .editPlan:
                            showEditWizard = true
                        }
                    },
                    onSignOut: onSignOut
                )
            }
            .fullScreenCover(isPresented: $showWizard, onDismiss: {
                Task { await viewModel.reload(using: homeService) }
            }) {
                NewPlanWizardView(
                    service: WorkoutPlanService(networkClient: networkClient),
                    dayConfigService: WorkoutDayPlanService(networkClient: networkClient),
                    exerciseService: ExerciseService(networkClient: networkClient)
                )
            }
            .fullScreenCover(isPresented: $showEditWizard, onDismiss: {
                Task { await viewModel.reload(using: homeService) }
            }) {
                NewPlanWizardView(
                    service: WorkoutPlanService(networkClient: networkClient),
                    dayConfigService: WorkoutDayPlanService(networkClient: networkClient),
                    exerciseService: ExerciseService(networkClient: networkClient),
                    editPlanId: viewModel.workoutPlan?.id
                )
            }
            .fullScreenCover(isPresented: $showCheckIn) {
                if let plan = viewModel.workoutPlan {
                    CheckInView(
                        planId: plan.id,
                        planName: plan.name,
                        numberOfExercises: plan.numberOfExercisesTotal,
                        estimatedMinutes: plan.timeEstimateToFinish,
                        actualWeekNumber: plan.actualWeekNumber ?? 1,
                        service: WorkoutExecutionService(networkClient: networkClient),
                        performedSetService: PerformedSetService(networkClient: networkClient)
                    )
                }
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

    // MARK: - Streak ribbon (mock — not in GET /api/home yet)

    private var streakRibbon: some View {
        let streak = WorkoutStreak.mockStreak
        return HStack(spacing: 14) {
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
                Text("Keep it up!")
                    .font(.system(size: 13))
                    .foregroundStyle(GrayscalePalette.secondary)
            }

            Spacer()

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

    // MARK: - Workout section (skeleton / populated / empty)

    @ViewBuilder
    private var workoutSection: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            workoutCardSkeleton

        case .loaded:
            if let plan = viewModel.workoutPlan {
                populatedWorkoutCard(plan)
            } else {
                emptyWorkoutCard
            }

        case .failed(let message):
            workoutCardError(message)
        }
    }

    // MARK: - Skeleton

    private var workoutCardSkeleton: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(GrayscalePalette.surface)
            .frame(height: 200)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(GrayscalePalette.separator, lineWidth: 1)
            )
            .opacity(0.7)
    }

    // MARK: - Populated workout card

    private func populatedWorkoutCard(_ plan: WorkoutDayPlanSummary) -> some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(WorkoutPalette.accent.opacity(0.18))
                .frame(width: 160, height: 160)
                .offset(x: 40, y: -40)

            VStack(alignment: .leading, spacing: 0) {
                Text("TODAY'S WORKOUT")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(GrayscalePalette.background.opacity(0.55))
                    .tracking(1.2)
                    .padding(.top, 20)

                Text(plan.name)
                    .font(.system(size: 26, design: .rounded).weight(.bold))
                    .foregroundStyle(GrayscalePalette.background)
                    .tracking(-0.5)
                    .lineLimit(2)
                    .padding(.top, 4)

                Text(plan.dayOfWeek.capitalized)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(GrayscalePalette.background.opacity(0.65))
                    .tracking(1.2)
                    .padding(.top, 2)

                HStack(spacing: 22) {
                    StatBadge(value: "\(plan.numberOfExercisesTotal)", label: "exercises")
                    Rectangle().fill(GrayscalePalette.background.opacity(0.15)).frame(width: 1, height: 30)
                    StatBadge(value: "\(plan.numberSetsTotal)", label: "sets")
                    Rectangle().fill(GrayscalePalette.background.opacity(0.15)).frame(width: 1, height: 30)
                    StatBadge(value: "\(plan.timeEstimateToFinish)", label: "est. min")
                }
                .padding(.top, 18)
                .opacity(0.9)

                Button {
                    showCheckIn = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                        Text("Start Workout")
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

    // MARK: - Empty workout card

    private var emptyWorkoutCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(GrayscalePalette.secondary)

            Text("No workout plan registered")
                .font(.system(size: 17, design: .rounded).weight(.semibold))
                .foregroundStyle(GrayscalePalette.primary)
                .multilineTextAlignment(.center)

            Button {
                showWizard = true
            } label: {
                Text("New Workout Plan")
                    .font(.system(size: 15, design: .rounded).weight(.semibold))
                    .foregroundStyle(WorkoutPalette.onAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(WorkoutPalette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(GrayscalePalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(GrayscalePalette.separator, lineWidth: 1))
    }

    // MARK: - Error card

    private func workoutCardError(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(GrayscalePalette.secondary)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(GrayscalePalette.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.reload(using: homeService) }
            }
            .font(.system(size: 14, design: .rounded).weight(.semibold))
            .foregroundStyle(GrayscalePalette.primary)
        }
        .padding(24)
        .background(GrayscalePalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(GrayscalePalette.separator, lineWidth: 1))
    }

    // MARK: - Exercises card

    private var exercisesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("On the menu")
                    .font(.system(size: 13, design: .rounded).weight(.semibold))
                    .foregroundStyle(GrayscalePalette.secondary)
                    .tracking(0.4)
                    .textCase(.uppercase)
                Spacer()
                Text("\(viewModel.exercisesForToday.count) exercises")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(GrayscalePalette.secondary)
            }
            .padding(.bottom, 10)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.exercisesForToday.enumerated()), id: \.element.id) { i, ex in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(WorkoutPalette.accentSoft)
                                .frame(width: 30, height: 30)
                            Text("\(i + 1)")
                                .font(.system(size: 12, design: .monospaced).weight(.bold))
                                .foregroundStyle(WorkoutPalette.accentInk)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ex.name)
                                .font(.system(size: 15, design: .rounded).weight(.semibold))
                                .foregroundStyle(GrayscalePalette.primary)
                                .tracking(-0.2)
                            Text("\(ex.numberOfSets) sets")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(GrayscalePalette.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                    if i < viewModel.exercisesForToday.count - 1 {
                        Divider().padding(.leading, 58)
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

@MainActor
private final class PreviewNetworkClientStub: NetworkClientProtocol {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        throw NetworkError.noToken
    }
}

@MainActor
private final class PreviewHomeServiceStub: HomeServiceProtocol {
    func fetchHomeData() async throws -> HomeScreenData {
        HomeScreenData(
            currentWorkoutDayPlan: WorkoutDayPlanSummary(
                id: 1,
                name: "Chest and Triceps",
                dayOfWeek: "SUNDAY",
                numberOfExercisesTotal: 5,
                numberSetsTotal: 15,
                timeEstimateToFinish: 52,
                actualWeekNumber: 1
            ),
            exercisesForToday: [
                TodayExercise(id: 1, name: "Bench Press",       orderIndex: 1, sets: []),
                TodayExercise(id: 2, name: "Tricep Extension",  orderIndex: 2, sets: []),
            ]
        )
    }
}

#Preview {
    TodayView(
        viewModel: TodayViewModel(),
        userName: "Alex",
        networkClient: PreviewNetworkClientStub(),
        onSignOut: {},
        homeService: PreviewHomeServiceStub()
    )
}
