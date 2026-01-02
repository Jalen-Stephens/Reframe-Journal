import SwiftUI

struct AutomaticThoughtsView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var thoughtText: String = ""
    @State private var beliefValue: Double = 50
    @State private var thoughtId: String? = nil

    var body: some View {
        StepContentContainer(title: "Automatic Thought", step: 3, total: 6) {
            Text("What thought or image went through your mind? How much did you believe the thought at the time (0-100%)?")
                .font(.system(size: 13))
                .foregroundColor(themeManager.theme.textSecondary)

            LabeledInput(label: "Automatic thought", placeholder: "e.g. \"I'm going to mess this up\"", text: $thoughtText)

            VStack(spacing: 10) {
                Text("\(Metrics.clampPercent(beliefValue))%")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(themeManager.theme.textPrimary)
                Text("How strongly did you believe this?")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.theme.textSecondary)
                Slider(value: $beliefValue, in: 0...100, step: 1)
                    .accentColor(themeManager.theme.accent)
                Text("0 = not at all, 100 = completely")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.theme.textSecondary)
            }

        }
        .background(themeManager.theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            StepBottomNavBar(
                onBack: { router.pop() },
                onNext: nextStep,
                isNextDisabled: thoughtText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        }
        .onAppear {
            if let existing = appState.wizard.draft.automaticThoughts.first {
                if appState.wizard.draft.automaticThoughts.count > 1 {
                    var draft = appState.wizard.draft
                    draft.automaticThoughts = [existing]
                    appState.wizard.draft = draft
                }
                thoughtId = existing.id
                thoughtText = existing.text
                beliefValue = Double(existing.beliefBefore)
            }
        }
    }

    private func saveThought() {
        let trimmed = thoughtText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        dismissKeyboard()
        let belief = Metrics.clampPercent(beliefValue)
        let id = thoughtId ?? Identifiers.generateId()
        appState.wizard.draft.automaticThoughts = [
            AutomaticThought(id: id, text: trimmed, beliefBefore: belief)
        ]
        thoughtId = id
    }

    private func nextStep() {
        Task { @MainActor in
            saveThought()
            await appState.wizard.persistDraft()
            router.push(.wizardStep4)
        }
    }
}
