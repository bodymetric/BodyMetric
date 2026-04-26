import SwiftUI

/// Bottom-sheet exercise picker for the New Plan wizard.
///
/// Shows the 18-exercise catalog grouped by muscle with live search.
/// Tapping an exercise calls `onPick(exerciseId)` and dismisses the sheet.
///
/// Constitution Principle VI: GrayscalePalette + WorkoutPalette for selected cell only.
struct ExercisePickerSheetView: View {

    let currentExerciseId: String
    let onPick: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                Divider().background(GrayscalePalette.separator)

                if filteredGroups.isEmpty {
                    emptyState
                } else {
                    exerciseList
                }
            }
            .background(GrayscalePalette.background)
            .navigationTitle("Choose exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 14, design: .rounded).weight(.semibold))
                        .foregroundStyle(GrayscalePalette.primary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(GrayscalePalette.secondary)
            TextField("Search exercises or muscle…", text: $query)
                .font(.system(size: 14))
                .foregroundStyle(GrayscalePalette.primary)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(GrayscalePalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(GrayscalePalette.separator, lineWidth: 1)
        )
    }

    // MARK: - Exercise list

    private var exerciseList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(filteredGroups, id: \.muscle) { group in
                    muscleSection(group)
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func muscleSection(_ group: MuscleGroup) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(group.muscle.uppercased())
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(GrayscalePalette.secondary)
                .tracking(1.2)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(group.exercises.enumerated()), id: \.element.id) { idx, ex in
                    exerciseRow(ex: ex, isLast: idx == group.exercises.count - 1)
                }
            }
            .background(GrayscalePalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(GrayscalePalette.separator, lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func exerciseRow(ex: Exercise, isLast: Bool) -> some View {
        let isSelected = ex.id == currentExerciseId
        Button {
            onPick(ex.id)
            dismiss()
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? WorkoutPalette.accent : GrayscalePalette.background)
                        .frame(width: 28, height: 28)
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(isSelected ? WorkoutPalette.onAccent : GrayscalePalette.secondary)
                }

                Text(ex.name)
                    .font(.system(size: 14, design: .rounded).weight(.semibold))
                    .foregroundStyle(GrayscalePalette.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(WorkoutPalette.accentInk)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if !isLast {
                Divider()
                    .padding(.leading, 52)
                    .background(GrayscalePalette.separator)
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("Nothing matches \"\(query)\".")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(GrayscalePalette.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Filtered data

    private struct MuscleGroup {
        let muscle: String
        let exercises: [Exercise]
    }

    private var filteredGroups: [MuscleGroup] {
        let trimmed = query.trimmingCharacters(in: .whitespaces).lowercased()
        let filtered = trimmed.isEmpty
            ? Exercise.catalog
            : Exercise.catalog.filter {
                $0.name.lowercased().contains(trimmed) ||
                $0.primaryMuscle.lowercased().contains(trimmed)
              }

        var seen: [String: [Exercise]] = [:]
        for ex in filtered {
            seen[ex.primaryMuscle, default: []].append(ex)
        }
        return seen.sorted { $0.key < $1.key }
                   .map { MuscleGroup(muscle: $0.key, exercises: $0.value) }
    }
}
