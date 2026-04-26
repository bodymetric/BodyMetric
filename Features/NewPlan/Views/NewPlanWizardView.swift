import SwiftUI

/// Multi-step New Plan wizard root view.
///
/// Presented via `.fullScreenCover` from `TodayView`.
/// Owns `NewPlanViewModel` and `WorkoutPlanStore`; routes step body and
/// manages the sticky header + footer CTA.
///
/// Constitution Principle V: single primary action per step (Continue / Finish & Save).
/// Constitution Principle VI: GrayscalePalette structural colors;
///   WorkoutPalette for primary CTA fills.
/// Constitution Principle IV: all traces delegated to NewPlanViewModel.
struct NewPlanWizardView: View {

    let service: any WorkoutPlanServiceProtocol

    @State private var viewModel = NewPlanViewModel()
    @State private var store = WorkoutPlanStore()
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        ZStack {
            GrayscalePalette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                wizardHeader

                WizardStepRailView(viewModel: viewModel)

                stepBody

                wizardFooter
            }
        }
        .fullScreenCover(isPresented: $viewModel.isPresentingSuccess) {
            PlanSavedView(
                dayCount: viewModel.orderedSelectedDays.count,
                onHome: { dismiss() },
                onRestart: {
                    viewModel = NewPlanViewModel()
                }
            )
        }
        .accessibilityIdentifier("newPlanWizard")
    }

    // MARK: - Header

    private var wizardHeader: some View {
        HStack(spacing: 10) {
            // Back / Cancel button
            Button {
                viewModel.retreat(onCancel: { dismiss() })
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(GrayscalePalette.primary)
                    .frame(width: 36, height: 36)
                    .background(GrayscalePalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(GrayscalePalette.separator, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            VStack(alignment: .leading, spacing: 1) {
                Text("NEW PLAN · STEP \(viewModel.currentStep) OF \(viewModel.totalSteps)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(GrayscalePalette.secondary)
                    .tracking(1.2)
                Text(stepTitle)
                    .font(.system(size: 17, design: .rounded).weight(.bold))
                    .foregroundStyle(GrayscalePalette.primary)
                    .tracking(-0.2)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) {
            Divider().background(GrayscalePalette.separator)
        }
    }

    // MARK: - Step body

    private var stepBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Group {
                    if viewModel.currentStep == 1 {
                        SelectDaysStepView(viewModel: viewModel, service: service)
                    } else if viewModel.currentStep == viewModel.totalSteps {
                        ReviewStepView(viewModel: viewModel)
                    } else if let day = viewModel.currentDayOfWeek {
                        ConfigureDayStepView(
                            viewModel: viewModel,
                            day: day,
                            dayIndex: viewModel.currentStep - 2,
                            totalDays: viewModel.orderedSelectedDays.count
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Spacer().frame(height: 40)
            }
        }
    }

    // MARK: - Footer

    private var wizardFooter: some View {
        let isLast = viewModel.currentStep == viewModel.totalSteps
        let canContinue = viewModel.isStepValid(viewModel.currentStep)
        // Step 1 Continue is also disabled while a save is in progress (FR-010)
        let step1Saving = viewModel.currentStep == 1 && viewModel.isSaving
        let canFinish = isLast && viewModel.allDaysValid

        return VStack(spacing: 0) {
            Divider().background(GrayscalePalette.separator)

            VStack(spacing: 8) {
                // Helper text when step is blocked
                if !canContinue && !isLast {
                    Text(footerHelperText)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(GrayscalePalette.secondary)
                        .tracking(0.5)
                        .multilineTextAlignment(.center)
                }
                if isLast && !canFinish {
                    Text("Some days are incomplete")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(GrayscalePalette.secondary)
                        .tracking(0.5)
                }

                if !isLast {
                    continueButton(enabled: canContinue && !step1Saving, isSaving: step1Saving)
                } else {
                    finishButton(enabled: canFinish)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .background(GrayscalePalette.background.opacity(0.97))
        }
    }

    private func continueButton(enabled: Bool, isSaving: Bool = false) -> some View {
        Button {
            if viewModel.currentStep == 1 {
                // Step 1: POST selected days first, then advance on success (FR-009, FR-011)
                Task {
                    await viewModel.saveDays(using: service) {
                        viewModel.advance()
                    }
                }
            } else {
                viewModel.advance()
            }
        } label: {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .tint(GrayscalePalette.background)
                        .scaleEffect(0.9)
                } else {
                    Text("Continue")
                        .font(.system(size: 16, design: .rounded).weight(.bold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundStyle(enabled ? GrayscalePalette.background : GrayscalePalette.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(enabled ? GrayscalePalette.primary : GrayscalePalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(
                color: enabled ? .black.opacity(0.12) : .clear,
                radius: 10, y: 3
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .animation(.bmFade, value: enabled)
    }

    private func finishButton(enabled: Bool) -> some View {
        Button {
            viewModel.finish(store: store)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
                Text("Finish & save plan")
                    .font(.system(size: 16, design: .rounded).weight(.bold))
            }
            .foregroundStyle(enabled ? WorkoutPalette.onAccent : GrayscalePalette.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(enabled ? WorkoutPalette.accent : GrayscalePalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(
                color: enabled ? WorkoutPalette.accent.opacity(0.3) : .clear,
                radius: 10, y: 3
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .animation(.bmFade, value: enabled)
    }

    // MARK: - Helpers

    private var stepTitle: String {
        if viewModel.currentStep == 1 { return "Days" }
        if viewModel.currentStep == viewModel.totalSteps { return "Review" }
        if let day = viewModel.currentDayOfWeek {
            let idx = viewModel.currentStep - 2
            return "\(day.fullLabel) · \(idx + 1)/\(viewModel.orderedSelectedDays.count)"
        }
        return "Configure"
    }

    private var footerHelperText: String {
        if viewModel.currentStep == 1 { return "Select at least one day to continue" }
        if let day = viewModel.currentDayOfWeek,
           let plan = viewModel.dayPlans[day] {
            if plan.sessionName.trimmingCharacters(in: .whitespaces).isEmpty {
                return "Add a name to continue"
            }
            return "Each block needs an exercise selected"
        }
        return "Complete all fields to continue"
    }
}
