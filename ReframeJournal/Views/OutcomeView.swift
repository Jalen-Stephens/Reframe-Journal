import SwiftUI

struct OutcomeView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var expandedThoughtId: String? = nil
    @State private var showIncompleteHint = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                WizardProgressView(step: 6, total: 6)
                Text("Outcome")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.theme.textPrimary)
                Text("Notice how your belief and emotions shift after working through each thought.")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.theme.textSecondary)

                HStack {
                    Text("\(completedCount()) / \(appState.wizard.draft.automaticThoughts.count) thoughts completed")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.theme.textSecondary)
                    if showIncompleteHint {
                        Text("Complete each thought to finish.")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.theme.textSecondary)
                    }
                }

                ForEach(appState.wizard.draft.automaticThoughts) { thought in
                    let outcome = mergeOutcome(for: thought)
                    let isExpanded = expandedThoughtId == thought.id
                    let isComplete = outcome.isComplete
                    let beliefDelta = outcome.beliefAfter - thought.beliefBefore
                    let deltaLabel: String = {
                        if beliefDelta == 0 {
                            return "\(thought.beliefBefore)% → \(outcome.beliefAfter)% 0%"
                        }
                        if beliefDelta < 0 {
                            return "\(thought.beliefBefore)% → \(outcome.beliefAfter)% ↓ \(abs(beliefDelta))%"
                        }
                        return "\(thought.beliefBefore)% → \(outcome.beliefAfter)% ↑ \(beliefDelta)%"
                    }()

                    AccordionView(isExpanded: Binding(
                        get: { expandedThoughtId == thought.id },
                        set: { expandedThoughtId = $0 ? thought.id : nil }
                    )) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(thought.text)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeManager.theme.textPrimary)
                                .lineLimit(1)
                            HStack {
                                Text("Original \(thought.beliefBefore)%")
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.theme.textSecondary)
                                Text(deltaLabel)
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.theme.textSecondary)
                                if isComplete {
                                    Text("Complete")
                                        .font(.system(size: 11, weight: .semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(themeManager.theme.accent)
                                        .foregroundColor(themeManager.theme.onAccent)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    } content: {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How much do you believe this thought now?")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.theme.textSecondary)
                            Text("\(outcome.beliefAfter)%")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(themeManager.theme.textPrimary)
                            Slider(value: bindingForBelief(thoughtId: thought.id), in: 0...100, step: 1)
                                .accentColor(themeManager.theme.accent)
                            Text("Original belief: \(thought.beliefBefore)%")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.theme.textSecondary)

                            Divider()

                            Text("Re-rate emotions")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(themeManager.theme.textPrimary)
                            if appState.wizard.draft.emotions.isEmpty {
                                Text("No emotions were selected earlier.")
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.theme.textSecondary)
                            }
                            ForEach(appState.wizard.draft.emotions) { emotion in
                                let currentIntensity = outcome.emotionsAfter[emotion.id] ?? emotion.intensityBefore
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(emotion.label)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(themeManager.theme.textPrimary)
                                        Spacer()
                                        Text("Before: \(emotion.intensityBefore)")
                                            .font(.system(size: 12))
                                            .foregroundColor(themeManager.theme.textSecondary)
                                    }
                                    Text("\(currentIntensity)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(themeManager.theme.textPrimary)
                                    Slider(value: bindingForEmotion(thoughtId: thought.id, emotionId: emotion.id), in: 0...100, step: 1)
                                        .accentColor(themeManager.theme.accent)
                                }
                            }

                            Divider()

                            Text("Anything you want to note after this thought?")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.theme.textSecondary)
                            ZStack(alignment: .topLeading) {
                                if (appState.wizard.draft.outcomesByThought[thought.id]?.reflection ?? "").isEmpty {
                                    Text("Optional reflection")
                                        .font(.system(size: 13))
                                        .foregroundColor(themeManager.theme.placeholder)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 10)
                                }
                                TextEditor(text: bindingForReflection(thoughtId: thought.id))
                                    .frame(minHeight: 80)
                                    .padding(6)
                                    .background(themeManager.theme.background)
                                    .scrollContentBackground(.hidden)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(themeManager.theme.border, lineWidth: 1)
                            )

                            PrimaryButton(
                                label: isComplete ? "Thought Complete" : "Mark Thought Complete",
                                onPress: { markComplete(thoughtId: thought.id) },
                                disabled: isComplete
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(themeManager.theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button("Back") {
                    Task {
                        await appState.wizard.persistDraft()
                        router.path.removeLast()
                    }
                }
                .font(.system(size: 13, weight: .semibold))
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(themeManager.theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(themeManager.theme.border, lineWidth: 1)
                )
                .foregroundColor(themeManager.theme.textSecondary)

                PrimaryButton(
                    label: "Save & Finish",
                    onPress: handleFinish,
                    disabled: !allComplete(),
                    onDisabledPress: handleFinish
                )
            }
            .padding(16)
            .background(themeManager.theme.background)
        }
        .alert("", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            ensureOutcomes()
            if expandedThoughtId == nil {
                expandedThoughtId = appState.wizard.draft.automaticThoughts.first(where: { !(appState.wizard.draft.outcomesByThought[$0.id]?.isComplete ?? false) })?.id
            }
        }
    }

    private func ensureOutcomes() {
        var draft = appState.wizard.draft
        var changed = false
        for thought in draft.automaticThoughts {
            let merged = mergeOutcome(for: thought, draft: draft)
            let existing = draft.outcomesByThought[thought.id]
            if existing == nil || existing != merged {
                draft.outcomesByThought[thought.id] = merged
                changed = true
            }
        }
        if changed {
            appState.wizard.draft = draft
        }
    }

    private func mergeOutcome(for thought: AutomaticThought, draft: ThoughtRecord? = nil) -> ThoughtOutcome {
        let base = draft ?? appState.wizard.draft
        let existing = base.outcomesByThought[thought.id]
        let defaults = ThoughtOutcome(
            beliefAfter: thought.beliefBefore,
            emotionsAfter: base.emotions.reduce(into: [:]) { partial, emotion in
                partial[emotion.id] = emotion.intensityBefore
            },
            reflection: "",
            isComplete: false
        )
        let mergedEmotions = defaults.emotionsAfter.merging(existing?.emotionsAfter ?? [:]) { _, new in new }
        return ThoughtOutcome(
            beliefAfter: existing?.beliefAfter ?? defaults.beliefAfter,
            emotionsAfter: mergedEmotions,
            reflection: existing?.reflection ?? defaults.reflection,
            isComplete: existing?.isComplete ?? false
        )
    }

    private func bindingForBelief(thoughtId: String) -> Binding<Double> {
        Binding(
            get: {
                guard let thought = thoughtById(thoughtId) else { return 0 }
                let outcome = appState.wizard.draft.outcomesByThought[thoughtId] ?? mergeOutcome(for: thought)
                return Double(outcome.beliefAfter)
            },
            set: { value in
                updateBeliefAfter(thoughtId: thoughtId, value: Metrics.clampPercent(value))
            }
        )
    }

    private func bindingForEmotion(thoughtId: String, emotionId: String) -> Binding<Double> {
        Binding(
            get: {
                guard let thought = thoughtById(thoughtId) else { return 0 }
                let outcome = appState.wizard.draft.outcomesByThought[thoughtId] ?? mergeOutcome(for: thought)
                return Double(outcome.emotionsAfter[emotionId] ?? 0)
            },
            set: { value in
                updateEmotionAfter(thoughtId: thoughtId, emotionId: emotionId, value: Metrics.clampPercent(value))
            }
        )
    }

    private func bindingForReflection(thoughtId: String) -> Binding<String> {
        Binding(
            get: {
                appState.wizard.draft.outcomesByThought[thoughtId]?.reflection ?? ""
            },
            set: { value in
                updateReflection(thoughtId: thoughtId, text: value)
            }
        )
    }

    private func updateBeliefAfter(thoughtId: String, value: Int) {
        guard let thought = thoughtById(thoughtId) else { return }
        var draft = appState.wizard.draft
        var outcome = mergeOutcome(for: thought, draft: draft)
        outcome.beliefAfter = value
        draft.outcomesByThought[thoughtId] = outcome
        appState.wizard.draft = draft
    }

    private func updateEmotionAfter(thoughtId: String, emotionId: String, value: Int) {
        guard let thought = thoughtById(thoughtId) else { return }
        var draft = appState.wizard.draft
        var outcome = mergeOutcome(for: thought, draft: draft)
        outcome.emotionsAfter[emotionId] = value
        draft.outcomesByThought[thoughtId] = outcome
        appState.wizard.draft = draft
    }

    private func updateReflection(thoughtId: String, text: String) {
        guard let thought = thoughtById(thoughtId) else { return }
        var draft = appState.wizard.draft
        var outcome = mergeOutcome(for: thought, draft: draft)
        outcome.reflection = text
        draft.outcomesByThought[thoughtId] = outcome
        appState.wizard.draft = draft
    }

    private func markComplete(thoughtId: String) {
        guard let thought = thoughtById(thoughtId) else { return }
        var draft = appState.wizard.draft
        var outcome = mergeOutcome(for: thought, draft: draft)
        outcome.isComplete = true
        draft.outcomesByThought[thoughtId] = outcome
        appState.wizard.draft = draft
        let next = appState.wizard.draft.automaticThoughts.first { $0.id != thoughtId && !(draft.outcomesByThought[$0.id]?.isComplete ?? false) }
        expandedThoughtId = next?.id
    }

    private func thoughtById(_ id: String) -> AutomaticThought? {
        appState.wizard.draft.automaticThoughts.first { $0.id == id }
    }

    private func completedCount() -> Int {
        appState.wizard.draft.automaticThoughts.reduce(0) { count, thought in
            count + ((appState.wizard.draft.outcomesByThought[thought.id]?.isComplete ?? false) ? 1 : 0)
        }
    }

    private func allComplete() -> Bool {
        let thoughts = appState.wizard.draft.automaticThoughts
        return !thoughts.isEmpty && completedCount() == thoughts.count
    }

    private func handleFinish() {
        if !allComplete() {
            if let firstIncomplete = appState.wizard.draft.automaticThoughts.first(where: { !(appState.wizard.draft.outcomesByThought[$0.id]?.isComplete ?? false) }) {
                expandedThoughtId = firstIncomplete.id
            }
            showIncompleteHint = true
            return
        }
        if !Metrics.isRequiredTextValid(appState.wizard.draft.situationText) {
            alertMessage = "Add a situation before saving."
            showAlert = true
            return
        }

        Task {
            var record = appState.wizard.draft
            let wasEditing = appState.wizard.isEditing
            record.updatedAt = DateUtils.nowIso()
            do {
                try await appState.repository.upsert(record)
                await appState.wizard.clearDraft()
                if wasEditing {
                    router.path = [.entryDetail(id: record.id)]
                } else {
                    router.popToRoot()
                }
            } catch {
                alertMessage = "Failed to save entry."
                showAlert = true
            }
        }
    }
}
