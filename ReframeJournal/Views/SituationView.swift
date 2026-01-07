import SwiftUI

struct SituationView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var appState: AppState
    @Environment(\.notesPalette) private var notesPalette

    private let commonSensations = [
        "Tight chest",
        "Racing heart",
        "Sweaty palms",
        "Shallow breathing",
        "Nausea",
        "Headache",
        "Tense shoulders",
        "Butterflies",
        "Restlessness",
        "Fatigue"
    ]

    @State private var situationText: String = ""
    // Keep selection in @State and render with LazyVGrid to avoid GeometryReader layout delays.
    @State private var selectedSensations: [String] = []
    @State private var isPickerPresented = false

    var body: some View {
        StepContentContainer(title: "Situation", step: 2, total: 6) {
            Text("What led to the unpleasant emotion? What distressing physical sensations did you have?")
                .font(.system(size: 13))
                .foregroundColor(notesPalette.textSecondary)

            LabeledInput(
                label: "Situation",
                placeholder: "e.g., I got a critical email from my manager.",
                text: $situationText,
                isMultiline: false
            )

            Text("Physical sensations")
                .font(.system(size: 14))
                .foregroundColor(notesPalette.textSecondary)

            Button {
                isPickerPresented = true
            } label: {
                HStack {
                    Text("Select common sensations")
                        .font(.system(size: 14))
                        .foregroundColor(notesPalette.textPrimary)
                    Spacer()
                    Text("▼")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(notesPalette.textSecondary)
                }
                .padding(10)
                .pillSurface(cornerRadius: 6)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $isPickerPresented) {
                SensationPickerSheetView(
                    selectedSensations: $selectedSensations,
                    isPresented: $isPickerPresented,
                    commonSensations: commonSensations
                )
            }

            if selectedSensations.isEmpty {
                Text("No sensations selected.")
                    .font(.system(size: 13))
                    .foregroundColor(notesPalette.textSecondary)
            } else {
                LazyVGrid(columns: chipColumns, alignment: .leading, spacing: 8) {
                    ForEach(displayedSensations, id: \.self) { item in
                        SelectedChipView(label: item) {
                            removeSensation(item)
                        }
                    }
                }
            }
        }
        .background(notesPalette.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            StepBottomNavBar(
                onBack: { router.pop() },
                onNext: {
                    Task { @MainActor in
                        var draft = appState.wizard.draft
                        draft.situationText = situationText
                        draft.sensations = selectedSensations
                        appState.wizard.draft = draft
                        await appState.wizard.persistDraft(draft)
                        router.push(.wizardStep3)
                    }
                }
            )
        }
        .onAppear {
            situationText = appState.wizard.draft.situationText
            selectedSensations = dedupedSensations(appState.wizard.draft.sensations)
        }
    }

    private var chipColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 120), spacing: 8, alignment: .leading)]
    }

    private var displayedSensations: [String] {
        selectedSensations
    }

    private func dedupedSensations(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for value in values {
            let key = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(value)
        }
        return result
    }

    @MainActor
    private func removeSensation(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let index = selectedSensations.firstIndex(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            selectedSensations.remove(at: index)
        }
    }
}
