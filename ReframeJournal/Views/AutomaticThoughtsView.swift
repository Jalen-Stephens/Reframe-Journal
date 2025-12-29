import SwiftUI

struct AutomaticThoughtsView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var thoughtText: String = ""
    @State private var beliefValue: Double = 50
    @State private var isEditOpen = false
    @State private var editId: String? = nil
    @State private var editText: String = ""
    @State private var editBelief: Double = 50
    @State private var pendingDeleteId: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                WizardProgressView(step: 3, total: 6)
                Text("What thought/s or image/s went through your mind? How much did you believe the thought at the time (0-100%)?")
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

                PrimaryButton(label: "Add thought", onPress: addThought, disabled: thoughtText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                VStack(spacing: 12) {
                    ForEach(appState.wizard.draft.automaticThoughts) { thought in
                        ThoughtCardView(
                            text: thought.text,
                            belief: thought.beliefBefore,
                            onEdit: { openEdit(thought) },
                            onRemove: { pendingDeleteId = thought.id }
                        )
                    }
                }
            }
            .padding(16)
        }
        .background(themeManager.theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            StepHeaderView(title: "Automatic Thoughts") {
                router.pop()
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(label: "Next", onPress: nextStep, disabled: appState.wizard.draft.automaticThoughts.isEmpty)
                .padding(16)
                .background(themeManager.theme.background)
        }
        .sheet(isPresented: $isEditOpen) {
            editSheet
        }
        .confirmationDialog("Remove thought?", isPresented: Binding(
            get: { pendingDeleteId != nil },
            set: { if !$0 { pendingDeleteId = nil } }
        )) {
            Button("Remove", role: .destructive) {
                if let id = pendingDeleteId {
                    appState.wizard.draft.automaticThoughts.removeAll { $0.id == id }
                }
                pendingDeleteId = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteId = nil
            }
        }
    }

    private func addThought() {
        let trimmed = thoughtText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let belief = Metrics.clampPercent(beliefValue)
        appState.wizard.draft.automaticThoughts.append(
            AutomaticThought(id: Identifiers.generateId(), text: trimmed, beliefBefore: belief)
        )
        thoughtText = ""
        beliefValue = 50
    }

    private func nextStep() {
        Task {
            await appState.wizard.persistDraft()
            router.push(.wizardStep4)
        }
    }

    private func openEdit(_ thought: AutomaticThought) {
        editId = thought.id
        editText = thought.text
        editBelief = Double(thought.beliefBefore)
        isEditOpen = true
    }

    private var editSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit thought")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.theme.textPrimary)
            LabeledInput(label: "Automatic thought", placeholder: "e.g. \"I'm going to mess this up\"", text: $editText)
            VStack(spacing: 10) {
                Text("How strongly did you believe this?")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.theme.textSecondary)
                Slider(value: $editBelief, in: 0...100, step: 1)
                    .accentColor(themeManager.theme.accent)
                Text("0 = not at all, 100 = completely")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.theme.textSecondary)
            }
            HStack {
                Button("Cancel") { isEditOpen = false }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.theme.textSecondary)
                Spacer()
                PrimaryButton(label: "Save", onPress: saveEdit, disabled: editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .frame(maxWidth: 160)
            }
        }
        .padding(16)
        .presentationDetents([.medium])
    }

    private func saveEdit() {
        guard let editId else { return }
        let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let belief = Metrics.clampPercent(editBelief)
        appState.wizard.draft.automaticThoughts = appState.wizard.draft.automaticThoughts.map {
            if $0.id == editId {
                return AutomaticThought(id: $0.id, text: trimmed, beliefBefore: belief)
            }
            return $0
        }
        isEditOpen = false
    }
}
