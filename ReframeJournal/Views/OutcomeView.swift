import SwiftUI

struct OutcomeView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeManager: ThemeManager

    @AppStorage("aiReframeEnabled") private var isAIReframeEnabled = false
    @StateObject private var aiViewModel = AIReframeViewModel(service: AIReframeService())

    @State private var showIncompleteHint = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        StepContentContainer(title: "Review", step: 6, total: 6) {
            Text("Notice how your belief and emotions shift after working through the thought.")
                .font(.system(size: 13))
                .foregroundColor(themeManager.theme.textSecondary)

            HStack {
                Text(completionLabel)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.theme.textSecondary)
                if showIncompleteHint {
                    Text("Complete the thought to finish.")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.theme.textSecondary)
                }
            }

            if let thought = appState.wizard.draft.automaticThoughts.first {
                outcomeCard(for: thought)
                aiControlsCard()
                if let aiResult = aiViewModel.aiResult {
                    aiResultCard(aiResult)
                }
            } else {
                Text("Add an automatic thought before finishing the outcome.")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.theme.textSecondary)
            }
        }
        .background(themeManager.theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            StepBottomNavBar(
                onBack: {
                    Task {
                        await appState.wizard.persistDraft()
                        router.pop()
                    }
                },
                onNext: handleFinish,
                nextLabel: "Save & Finish",
                isNextDisabled: !allComplete()
            )
        }
        .alert("", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            ensureOutcomes()
        }
    }

    private func outcomeCard(for thought: AutomaticThought) -> some View {
        let outcome = mergeOutcome(for: thought)
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

        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(thought.text)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.theme.textPrimary)
                    .lineLimit(2)
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
            TextField("Optional reflection", text: bindingForReflection(thoughtId: thought.id))
                .textFieldStyle(PlainTextFieldStyle())
                .submitLabel(.done)
                .onSubmit {
                    dismissKeyboard()
                }
                .padding(10)
                .foregroundColor(themeManager.theme.textPrimary)
                .cardSurface(cornerRadius: 10, shadow: false)

            PrimaryButton(
                label: isComplete ? "Thought Complete" : "Mark Thought Complete",
                onPress: { markComplete(thoughtId: thought.id) },
                disabled: isComplete
            )
        }
        .padding(12)
        .cardSurface(cornerRadius: 12, shadow: false)
    }

    private func aiControlsCard() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AI Reframe")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeManager.theme.textPrimary)

            Button(action: generateReframe) {
                HStack(spacing: 8) {
                    if aiViewModel.isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: themeManager.theme.onAccent))
                    }
                    Text(aiViewModel.isGenerating ? "Generating..." : "Generate Reframe")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.theme.onAccent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(themeManager.theme.accent)
                .clipShape(Capsule())
                .opacity(isGenerateDisabled ? 0.5 : 1)
            }
            .disabled(isGenerateDisabled)

            if !isAIReframeEnabled {
                Text("Enable in Settings")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.theme.textSecondary)
            }

            Text("Your entry will be sent to OpenAI to generate suggestions.")
                .font(.system(size: 12))
                .foregroundColor(themeManager.theme.textSecondary)

            Text("AI suggestions aren't a substitute for professional care.")
                .font(.system(size: 12))
                .foregroundColor(themeManager.theme.textSecondary)

            if let error = aiViewModel.aiError {
                VStack(alignment: .leading, spacing: 6) {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.theme.textSecondary)
                    Button("Retry") {
                        generateReframe()
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(themeManager.theme.accent)
                }
            }
        }
        .padding(12)
        .cardSurface(cornerRadius: 12, shadow: false)
    }

    private func aiResultCard(_ result: AIReframeResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !result.validation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(result.validation)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.theme.textSecondary)
            }

            Text("Reframe")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeManager.theme.textPrimary)
            Text(result.reframeSummary)
                .font(.system(size: 13))
                .foregroundColor(themeManager.theme.textPrimary)

            if let balanced = result.balancedThought?.trimmingCharacters(in: .whitespacesAndNewlines),
               !balanced.isEmpty {
                Text("Balanced thought")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(themeManager.theme.textPrimary)
                Text(balanced)
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.theme.textPrimary)
            }

            if !result.suggestions.isEmpty {
                Text("Try this")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(themeManager.theme.textPrimary)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(result.suggestions, id: \.self) { suggestion in
                        Text("- \(suggestion)")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.theme.textSecondary)
                    }
                }
            }
        }
        .padding(12)
        .cardSurface(cornerRadius: 12, shadow: false)
    }

    private var isGenerateDisabled: Bool {
        !isAIReframeEnabled || aiViewModel.isGenerating
    }

    private func generateReframe() {
        guard isAIReframeEnabled else { return }
        Task {
            await aiViewModel.generateReframe(for: appState.wizard.draft)
        }
    }

    private func ensureOutcomes() {
        var draft = appState.wizard.draft
        var changed = false
        if let thought = draft.automaticThoughts.first {
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

    private var completionLabel: String {
        guard let thought = appState.wizard.draft.automaticThoughts.first else {
            return "0 / 0 thoughts completed"
        }
        let isComplete = appState.wizard.draft.outcomesByThought[thought.id]?.isComplete == true
        return isComplete ? "1 / 1 thought completed" : "0 / 1 thought completed"
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
    }

    private func thoughtById(_ id: String) -> AutomaticThought? {
        appState.wizard.draft.automaticThoughts.first { $0.id == id }
    }

    private func completedCount() -> Int {
        guard let thought = appState.wizard.draft.automaticThoughts.first else { return 0 }
        return appState.wizard.draft.outcomesByThought[thought.id]?.isComplete == true ? 1 : 0
    }

    private func allComplete() -> Bool {
        guard !appState.wizard.draft.automaticThoughts.isEmpty else { return false }
        return completedCount() == 1
    }

    private func handleFinish() {
        if !allComplete() {
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
                await appState.repository.flushPendingWrites()
                if !wasEditing {
                    await appState.thoughtUsage.incrementTodayCount()
                }
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
