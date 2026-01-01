import SwiftUI

struct AdaptiveResponseView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeManager: ThemeManager

    @FocusState private var focusedField: FocusField?
    @State private var promptIndex: Int = 0
    @State private var showIncompleteHint = false

    private let quickSetValues: [Int] = [0, 25, 50, 75, 100]

    private enum FocusField: Hashable {
        case response(thoughtId: String, key: AdaptivePrompts.TextKey)
    }

    var body: some View {
        StepContentContainer(title: "Adaptive Response", step: 5, total: 6) {
            Text("Respond to the automatic thought using the prompts below. Add at least one grounded response.")
                .font(.system(size: 13))
                .foregroundColor(themeManager.theme.textSecondary)
            if showIncompleteHint {
                Text("Complete at least one response before continuing.")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.theme.textSecondary)
            }

            if let thought = appState.wizard.draft.automaticThoughts.first {
                let answeredCount = countAnsweredPrompts(for: thought.id)
                let isComplete = answeredCount == AdaptivePrompts.all.count
                let prompt = AdaptivePrompts.all[promptIndex]
                let currentBelief = beliefValue(for: prompt.beliefKey, thoughtId: thought.id)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(thought.text)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.theme.textPrimary)
                            .lineLimit(2)
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

                    Text("Question \(promptIndex + 1) of \(AdaptivePrompts.all.count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeManager.theme.textSecondary)

                    Text(prompt.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(themeManager.theme.textPrimary)
                    TextField(
                        "Write a grounded response",
                        text: bindingForText(prompt.textKey, thoughtId: thought.id)
                    )
                    .textFieldStyle(PlainTextFieldStyle())
                    .submitLabel(.done)
                    .onSubmit {
                        dismissKeyboard()
                    }
                    .padding(10)
                    .foregroundColor(themeManager.theme.textPrimary)
                    .cardSurface(cornerRadius: 10, shadow: false)
                    .focused($focusedField, equals: .response(thoughtId: thought.id, key: prompt.textKey))

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
                            retreatPrompt()
                        }
                        .disabled(promptIndex == 0)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(promptIndex == 0 ? themeManager.theme.textSecondary.opacity(0.5) : themeManager.theme.textSecondary)

                        Spacer()

                        Button(isLastPrompt() ? "Save & finish" : "Save & continue") {
                            handleInlineContinue()
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(themeManager.theme.accent)
                    }
                }
                .padding(12)
                .cardSurface(cornerRadius: 12, shadow: false)
            } else {
                Text("Add an automatic thought before writing adaptive responses.")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.theme.textSecondary)
            }
        }
        .background(themeManager.theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            StepBottomNavBar(
                onBack: { router.pop() },
                onNext: handleNext,
                isNextDisabled: isNextDisabled
            )
        }
        .onAppear {
            ensureResponses()
        }
    }

    private func ensureResponses() {
        var draft = appState.wizard.draft
        var changed = false
        if let thought = draft.automaticThoughts.first {
            if draft.adaptiveResponses[thought.id] == nil {
                draft.adaptiveResponses[thought.id] = emptyResponses()
                changed = true
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
        guard let thought = appState.wizard.draft.automaticThoughts.first else { return false }
        return countAnsweredPrompts(for: thought.id) >= 1
    }

    private func nextStep() {
        if canProceed() {
            Task {
                await appState.wizard.persistDraft()
                router.push(.wizardStep6)
            }
            return
        }
        showIncompleteHint = true
    }

    private func advancePrompt() {
        promptIndex = min(promptIndex + 1, AdaptivePrompts.all.count - 1)
    }

    private func retreatPrompt() {
        promptIndex = max(promptIndex - 1, 0)
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

    private var activeThoughtId: String? {
        switch focusedField {
        case .response(let thoughtId, _):
            return thoughtId
        case .none:
            return appState.wizard.draft.automaticThoughts.first?.id
        }
    }

    private func activePrompt() -> AdaptivePrompts.Prompt? {
        guard AdaptivePrompts.all.indices.contains(promptIndex) else { return nil }
        return AdaptivePrompts.all[promptIndex]
    }

    private func isLastPrompt() -> Bool {
        promptIndex == AdaptivePrompts.all.count - 1
    }

    private func canAdvancePrompt(thoughtId: String, prompt: AdaptivePrompts.Prompt) -> Bool {
        let currentText = textValue(for: prompt.textKey, thoughtId: thoughtId)
        return !currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isNextDisabled: Bool {
        guard let activeThoughtId, let activePrompt = activePrompt() else {
            return !canProceed()
        }

        if focusedField == nil || isLastPrompt() {
            return !canProceed()
        }

        return !canAdvancePrompt(thoughtId: activeThoughtId, prompt: activePrompt)
    }

    private func handleNext() {
        guard let activeThoughtId, let activePrompt = activePrompt() else {
            nextStep()
            return
        }

        if focusedField != nil && !isLastPrompt() {
            guard canAdvancePrompt(thoughtId: activeThoughtId, prompt: activePrompt) else { return }
            advancePrompt()
            return
        }

        nextStep()
    }

    private func handleInlineContinue() {
        guard let thought = appState.wizard.draft.automaticThoughts.first else { return }
        let prompt = AdaptivePrompts.all[promptIndex]
        guard canAdvancePrompt(thoughtId: thought.id, prompt: prompt) else {
            showIncompleteHint = true
            return
        }
        Task {
            await appState.wizard.persistDraft()
            if isLastPrompt() {
                nextStep()
            } else {
                advancePrompt()
            }
        }
    }
}
