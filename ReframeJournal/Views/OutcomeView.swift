// File: Views/OutcomeView.swift
import SwiftUI

struct OutcomeView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var appState: AppState
    @Environment(\.notesPalette) private var notesPalette
    @EnvironmentObject private var entitlementsManager: EntitlementsManager
    @EnvironmentObject private var limitsManager: LimitsManager
    @EnvironmentObject private var rewardedAdManager: AnyRewardedAdManager

    @AppStorage("aiReframeEnabled") private var isAIReframeEnabled = false

    @State private var showIncompleteHint = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showRegenerateConfirm = false
    @State private var selectedDepth: AIReframeDepth = .deep
    @State private var showUnlockSheet = false
    @State private var showAdErrorAlert = false
    @State private var showPaywall = false
    @State private var isGenerating = false
    @State private var isLoadingAd = false

    var body: some View {
        StepContentContainer(title: "Review", step: 6, total: 6) {
            Text("Notice how your belief and emotions shift after working through the thought.")
                .font(.system(size: 13))
                .foregroundColor(notesPalette.textSecondary)

            HStack {
                Text(completionLabel)
                    .font(.system(size: 12))
                    .foregroundColor(notesPalette.textSecondary)
                if showIncompleteHint {
                    Text("Complete the thought to finish.")
                        .font(.system(size: 12))
                        .foregroundColor(notesPalette.textSecondary)
                }
            }

            if let thought = appState.wizard.draft.automaticThoughts.first {
                outcomeCard(for: thought)
                aiReframeCard()
            } else {
                Text("Add an automatic thought before finishing the outcome.")
                    .font(.system(size: 13))
                    .foregroundColor(notesPalette.textSecondary)
            }
        }
        .background(notesPalette.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            StepBottomNavBar(
                onBack: {
                    Task { @MainActor in
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
        .confirmationDialog("Regenerate AI Reframe?", isPresented: $showRegenerateConfirm) {
            Button("Regenerate", role: .destructive) {
                navigateToReframe(action: .regenerate)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will replace the existing AI Reframe.")
        }
        .sheet(isPresented: $showUnlockSheet) {
            UnlockReframeSheet(
                isLoading: isLoadingAd,
                onWatchAd: {
                    Task { await handleWatchAd() }
                },
                onUpgrade: {
                    showUnlockSheet = false
                    showPaywall = true
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Ad unavailable", isPresented: $showAdErrorAlert) {
            Button("Retry") {
                Task { await handleWatchAd() }
            }
            Button("Upgrade") {
                showPaywall = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Ad unavailable. Try again later or upgrade to Pro.")
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
                    .foregroundColor(notesPalette.textPrimary)
                    .lineLimit(2)
                HStack {
                    Text("Original \(thought.beliefBefore)%")
                        .font(.system(size: 12))
                        .foregroundColor(notesPalette.textSecondary)
                    Text(deltaLabel)
                        .font(.system(size: 12))
                        .foregroundColor(notesPalette.textSecondary)
                    if isComplete {
                        Text("Complete")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(notesPalette.accent)
                            .foregroundColor(notesPalette.onAccent)
                            .clipShape(Capsule())
                    }
                }
            }

            Text("How much do you believe this thought now?")
                .font(.system(size: 12))
                .foregroundColor(notesPalette.textSecondary)
            Text("\(outcome.beliefAfter)%")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(notesPalette.textPrimary)
            Slider(value: bindingForBelief(thoughtId: thought.id), in: 0...100, step: 1)
                .accentColor(notesPalette.accent)
            Text("Original belief: \(thought.beliefBefore)%")
                .font(.system(size: 12))
                .foregroundColor(notesPalette.textSecondary)

            Divider()

            Text("Re-rate emotions")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(notesPalette.textPrimary)
            if appState.wizard.draft.emotions.isEmpty {
                Text("No emotions were selected earlier.")
                    .font(.system(size: 12))
                    .foregroundColor(notesPalette.textSecondary)
            }
            ForEach(appState.wizard.draft.emotions) { emotion in
                let currentIntensity = outcome.emotionsAfter[emotion.id] ?? emotion.intensityBefore
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(emotion.label)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(notesPalette.textPrimary)
                        Spacer()
                        Text("Before: \(emotion.intensityBefore)")
                            .font(.system(size: 12))
                            .foregroundColor(notesPalette.textSecondary)
                    }
                    Text("\(currentIntensity)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(notesPalette.textPrimary)
                    Slider(value: bindingForEmotion(thoughtId: thought.id, emotionId: emotion.id), in: 0...100, step: 1)
                        .accentColor(notesPalette.accent)
                }
            }

            Divider()

            Text("Anything you want to note after this thought?")
                .font(.system(size: 12))
                .foregroundColor(notesPalette.textSecondary)
            TextField("Optional reflection", text: bindingForReflection(thoughtId: thought.id))
                .textFieldStyle(PlainTextFieldStyle())
                .submitLabel(.done)
                .onSubmit {
                    dismissKeyboard()
                }
                .padding(10)
                .foregroundColor(notesPalette.textPrimary)
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

    private func aiReframeCard() -> some View {
        let hasReframe = appState.wizard.draft.aiReframe != nil
        return VStack(alignment: .leading, spacing: 10) {
            Text("AI Reframe")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(notesPalette.textPrimary)

            if hasReframe {
                PrimaryButton(label: "View AI Reframe") {
                    navigateToReframe(action: .view)
                }
                Button("Regenerate") {
                    showRegenerateConfirm = true
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(notesPalette.accent)
                .disabled(!isAIReframeEnabled)
            } else {
                Picker("Depth", selection: $selectedDepth) {
                    ForEach(AIReframeDepth.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!isAIReframeEnabled)
                PrimaryButton(
                    label: isGenerating ? "Generating..." : (entitlementsManager.isPro ? "Generate Reframe" : "Unlock AI Reframe"),
                    onPress: handleGenerateReframe,
                    disabled: !isAIReframeEnabled || isGenerating
                )
                if !entitlementsManager.isPro {
                    Text("Watch a short ad to generate your reframe.")
                        .font(.system(size: 12))
                        .foregroundColor(notesPalette.textSecondary)
                }
            }

            if !isAIReframeEnabled {
                Text("Enable in Settings")
                    .font(.system(size: 12))
                    .foregroundColor(notesPalette.textSecondary)
            }

            Text("Your entry will be sent to OpenAI to generate suggestions.")
                .font(.system(size: 12))
                .foregroundColor(notesPalette.textSecondary)

            Text("AI suggestions aren't a substitute for professional care.")
                .font(.system(size: 12))
                .foregroundColor(notesPalette.textSecondary)
        }
        .padding(12)
        .cardSurface(cornerRadius: 12, shadow: false)
    }

    private func navigateToReframe(action: AIReframeAction) {
        let depth = appState.wizard.draft.aiReframeDepth ?? selectedDepth
        Task { @MainActor in
            await appState.wizard.persistDraft()
            router.push(.aiReframeResult(entryId: appState.wizard.draft.id, action: action, depth: depth))
        }
    }

    private func handleGenerateReframe() {
        guard !isGenerating else { return }
        Task { await startGenerateFlow() }
    }

    private func startGenerateFlow() async {
        guard validateReframeLimits() else { return }
        if entitlementsManager.isPro {
            await generateReframe()
        } else {
            showUnlockSheet = true
        }
    }

    private func handleWatchAd() async {
        guard !isGenerating else { return }
        showUnlockSheet = false
        isLoadingAd = true
        do {
            let rewarded = try await rewardedAdManager.presentAd()
            isLoadingAd = false
            guard rewarded else {
                showAdErrorAlert = true
                return
            }
        } catch {
            isLoadingAd = false
            showAdErrorAlert = true
            return
        }

        guard validateReframeLimits() else { return }
        await generateReframe()
    }

    private func validateReframeLimits() -> Bool {
        do {
            try limitsManager.assertCanGenerateReframe()
            return true
        } catch {
            alertMessage = "You've hit today's AI limit. Try again tomorrow."
            showAlert = true
            return false
        }
    }

    private func generateReframe() async {
        guard !isGenerating else { return }
        isGenerating = true
        defer { isGenerating = false }

        let depth = appState.wizard.draft.aiReframeDepth ?? selectedDepth
        let service = AIReframeService()

        do {
            let record = appState.wizard.draft
            let generated = try await service.generateReframe(for: record, depth: depth)
            var updated = record
            updated.aiReframe = generated
            updated.aiReframeCreatedAt = Date()
            updated.aiReframeModel = service.modelName
            updated.aiReframePromptVersion = service.promptVersion
            updated.aiReframeDepth = depth
            updated.updatedAt = DateUtils.nowIso()
            appState.wizard.draft = updated
            await appState.wizard.persistDraft(updated)
            limitsManager.recordReframe()
            router.push(.aiReframeResult(entryId: updated.id, action: .view, depth: depth))
        } catch let err {
            if let openAIError = err as? LegacyOpenAIClient.OpenAIError {
                switch openAIError {
                case .missingAPIKey:
                    alertMessage = "Missing OpenAI API key. Set OPENAI_API_KEY in build settings or scheme."
                default:
                    alertMessage = openAIError.localizedDescription
                }
            } else {
                alertMessage = err.localizedDescription
            }
            showAlert = true
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

        Task { @MainActor in
            var record = appState.wizard.draft
            let wasEditing = appState.wizard.isEditing
            record.updatedAt = DateUtils.nowIso()
            do {
                try await appState.repository.upsert(record)
                await appState.repository.flushPendingWrites()
                if !wasEditing {
                    appState.thoughtUsage.incrementTodayCount(recordId: record.id, createdAt: record.createdAt)
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

private struct UnlockReframeSheet: View {
    let isLoading: Bool
    let onWatchAd: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Unlock AI Reframe")
                .font(.title3.bold())
            Text("Watch a short ad to generate your reframe.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Button {
                onWatchAd()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                    }
                    Text(isLoading ? "Loading Ad..." : "Watch Ad")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)

            Button("Upgrade to Pro") {
                onUpgrade()
            }
            .disabled(isLoading)
        }
        .padding(24)
    }
}
