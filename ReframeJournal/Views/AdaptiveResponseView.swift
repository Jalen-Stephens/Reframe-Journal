import SwiftUI

struct AdaptiveResponseView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var expandedThoughtId: String? = nil
    @State private var promptIndexByThought: [String: Int] = [:]
    @State private var showIncompleteHint = false

    private let quickSetValues: [Int] = [0, 25, 50, 75, 100]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                WizardProgressView(step: 5, total: 6)
                Text("Respond to each automatic thought using the prompts below. Add at least one grounded response per thought.")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.theme.textSecondary)
                if showIncompleteHint {
                    Text("Complete at least one response for each thought before continuing.")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.theme.textSecondary)
                }

                ForEach(appState.wizard.draft.automaticThoughts) { thought in
                    let isExpanded = expandedThoughtId == thought.id
                    let answeredCount = countAnsweredPrompts(for: thought.id)
                    let isComplete = answeredCount == AdaptivePrompts.all.count
                    let currentIndex = promptIndexByThought[thought.id] ?? 0
                    let prompt = AdaptivePrompts.all[currentIndex]
                    let currentText = textValue(for: prompt.textKey, thoughtId: thought.id)
                    let currentBelief = beliefValue(for: prompt.beliefKey, thoughtId: thought.id)
                    let isLastPrompt = currentIndex == AdaptivePrompts.all.count - 1
                    let canAdvance = !currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

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
                                Text("\(answeredCount) / \(AdaptivePrompts.all.count) answered")
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.theme.textSecondary)
                                Text(isComplete ? "Complete" : "Incomplete")
                                    .font(.system(size: 11, weight: .semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(isComplete ? themeManager.theme.accent : themeManager.theme.muted)
                                    .foregroundColor(isComplete ? themeManager.theme.onAccent : themeManager.theme.textSecondary)
                                    .clipShape(Capsule())
                            }
                        }
                    } content: {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Responding to: \"\(thought.text)\"")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.theme.textSecondary)
                            Text("Question \(currentIndex + 1) of \(AdaptivePrompts.all.count)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(themeManager.theme.textSecondary)

                            Text(prompt.label)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(themeManager.theme.textPrimary)
                            ZStack(alignment: .topLeading) {
                                if currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text("Write a grounded response")
                                        .font(.system(size: 13))
                                        .foregroundColor(themeManager.theme.placeholder)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 10)
                                }
                                TextEditor(text: bindingForText(prompt.textKey, thoughtId: thought.id))
                                    .frame(minHeight: 90)
                                    .padding(6)
                                    .background(themeManager.theme.background)
                                    .scrollContentBackground(.hidden)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(themeManager.theme.border, lineWidth: 1)
                            )

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("How much do you believe this response?")
                                        .font(.system(size: 12))
                                        .foregroundColor(themeManager.theme.textSecondary)
                                    Spacer()
                                    Text("\(currentBelief)%")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(themeManager.theme.textSecondary)
                                }
                                Slider(value: bindingForBelief(prompt.beliefKey, thoughtId: thought.id), in: 0...100, step: 1)
                                    .accentColor(themeManager.theme.accent)
                                HStack(spacing: 8) {
                                    ForEach(quickSetValues, id: \.self) { value in
                                        Button("\(value)") {
                                            updateBelief(thoughtId: thought.id, key: prompt.beliefKey, value: value)
                                        }
                                        .font(.system(size: 12, weight: .semibold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(value == currentBelief ? themeManager.theme.accent : themeManager.theme.muted)
                                        .foregroundColor(value == currentBelief ? themeManager.theme.onAccent : themeManager.theme.textSecondary)
                                        .clipShape(Capsule())
                                    }
                                }
                            }

                            HStack {
                                Button("Back") {
                                    retreatPrompt(thoughtId: thought.id)
                                }
                                .disabled(currentIndex == 0)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(currentIndex == 0 ? themeManager.theme.textSecondary.opacity(0.5) : themeManager.theme.textSecondary)

                                Spacer()
                                PrimaryButton(
                                    label: isLastPrompt ? "Mark Thought Complete" : "Save & Continue",
                                    onPress: {
                                        guard canAdvance else { return }
                                        if isLastPrompt {
                                            moveToNextThought(after: thought.id)
                                        } else {
                                            advancePrompt(thoughtId: thought.id)
                                        }
                                    },
                                    disabled: !canAdvance
                                )
                                .frame(maxWidth: 220)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(themeManager.theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            StepHeaderView(title: "Adaptive Response") {
                router.pop()
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(label: "Next", onPress: nextStep, disabled: !canProceed())
                .padding(16)
                .background(themeManager.theme.background)
        }
        .onAppear {
            ensureResponses()
            if expandedThoughtId == nil {
                expandedThoughtId = appState.wizard.draft.automaticThoughts.first?.id
            }
        }
    }

    private func ensureResponses() {
        var draft = appState.wizard.draft
        var changed = false
        for thought in draft.automaticThoughts {
            if draft.adaptiveResponses[thought.id] == nil {
                draft.adaptiveResponses[thought.id] = emptyResponses()
                changed = true
            }
            if promptIndexByThought[thought.id] == nil {
                promptIndexByThought[thought.id] = 0
            }
        }
        if changed {
            appState.wizard.draft = draft
        }
    }

    private func emptyResponses() -> AdaptiveResponsesForThought {
        AdaptiveResponsesForThought(
            evidenceText: "",
            evidenceBelief: 0,
            alternativeText: "",
            alternativeBelief: 0,
            outcomeText: "",
            outcomeBelief: 0,
            friendText: "",
            friendBelief: 0
        )
    }

    private func countAnsweredPrompts(for thoughtId: String) -> Int {
        guard let responses = appState.wizard.draft.adaptiveResponses[thoughtId] else { return 0 }
        return AdaptivePrompts.all.reduce(0) { count, prompt in
            let text = textValue(for: prompt.textKey, responses: responses)
            return count + (text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0 : 1)
        }
    }

    private func canProceed() -> Bool {
        let thoughts = appState.wizard.draft.automaticThoughts
        guard !thoughts.isEmpty else { return false }
        return thoughts.allSatisfy { countAnsweredPrompts(for: $0.id) >= 1 }
    }

    private func nextStep() {
        if canProceed() {
            Task {
                await appState.wizard.persistDraft()
                router.push(.wizardStep6)
            }
            return
        }
        if let firstIncomplete = appState.wizard.draft.automaticThoughts.first(where: { countAnsweredPrompts(for: $0.id) < 1 }) {
            expandedThoughtId = firstIncomplete.id
        }
        showIncompleteHint = true
    }

    private func moveToNextThought(after thoughtId: String) {
        if let index = appState.wizard.draft.automaticThoughts.firstIndex(where: { $0.id == thoughtId }) {
            let next = appState.wizard.draft.automaticThoughts.dropFirst(index + 1).first
            expandedThoughtId = next?.id
        }
    }

    private func advancePrompt(thoughtId: String) {
        let current = promptIndexByThought[thoughtId] ?? 0
        promptIndexByThought[thoughtId] = min(current + 1, AdaptivePrompts.all.count - 1)
    }

    private func retreatPrompt(thoughtId: String) {
        let current = promptIndexByThought[thoughtId] ?? 0
        promptIndexByThought[thoughtId] = max(current - 1, 0)
    }

    private func bindingForText(_ key: AdaptivePrompts.TextKey, thoughtId: String) -> Binding<String> {
        Binding(
            get: { textValue(for: key, thoughtId: thoughtId) },
            set: { updateText(thoughtId: thoughtId, key: key, value: $0) }
        )
    }

    private func textValue(for key: AdaptivePrompts.TextKey, thoughtId: String) -> String {
        guard let responses = appState.wizard.draft.adaptiveResponses[thoughtId] else { return "" }
        return textValue(for: key, responses: responses)
    }

    private func textValue(for key: AdaptivePrompts.TextKey, responses: AdaptiveResponsesForThought) -> String {
        switch key {
        case .evidenceText:
            return responses.evidenceText
        case .alternativeText:
            return responses.alternativeText
        case .outcomeText:
            return responses.outcomeText
        case .friendText:
            return responses.friendText
        }
    }

    private func updateText(thoughtId: String, key: AdaptivePrompts.TextKey, value: String) {
        var draft = appState.wizard.draft
        var responses = draft.adaptiveResponses[thoughtId] ?? emptyResponses()
        switch key {
        case .evidenceText:
            responses.evidenceText = value
        case .alternativeText:
            responses.alternativeText = value
        case .outcomeText:
            responses.outcomeText = value
        case .friendText:
            responses.friendText = value
        }
        draft.adaptiveResponses[thoughtId] = responses
        appState.wizard.draft = draft
    }

    private func bindingForBelief(_ key: AdaptivePrompts.BeliefKey, thoughtId: String) -> Binding<Double> {
        Binding(
            get: { Double(beliefValue(for: key, thoughtId: thoughtId)) },
            set: { updateBelief(thoughtId: thoughtId, key: key, value: Metrics.clampPercent($0)) }
        )
    }

    private func beliefValue(for key: AdaptivePrompts.BeliefKey, thoughtId: String) -> Int {
        guard let responses = appState.wizard.draft.adaptiveResponses[thoughtId] else { return 0 }
        return beliefValue(for: key, responses: responses)
    }

    private func beliefValue(for key: AdaptivePrompts.BeliefKey, responses: AdaptiveResponsesForThought) -> Int {
        switch key {
        case .evidenceBelief:
            return responses.evidenceBelief
        case .alternativeBelief:
            return responses.alternativeBelief
        case .outcomeBelief:
            return responses.outcomeBelief
        case .friendBelief:
            return responses.friendBelief
        }
    }

    private func updateBelief(thoughtId: String, key: AdaptivePrompts.BeliefKey, value: Int) {
        var draft = appState.wizard.draft
        var responses = draft.adaptiveResponses[thoughtId] ?? emptyResponses()
        switch key {
        case .evidenceBelief:
            responses.evidenceBelief = value
        case .alternativeBelief:
            responses.alternativeBelief = value
        case .outcomeBelief:
            responses.outcomeBelief = value
        case .friendBelief:
            responses.friendBelief = value
        }
        draft.adaptiveResponses[thoughtId] = responses
        appState.wizard.draft = draft
    }
}
