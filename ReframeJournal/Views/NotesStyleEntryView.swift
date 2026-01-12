// File: Views/NotesStyleEntryView.swift
// Apple Notes-inspired entry experience for Reframe Journal
// Design principles: minimal chrome, text-first, typography-driven hierarchy

import SwiftUI
import SwiftData

// MARK: - Main Entry View

struct NotesStyleEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var entitlementsManager: EntitlementsManager
    @EnvironmentObject private var limitsManager: LimitsManager
    @EnvironmentObject private var rewardedAdManager: RewardedAdManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel: ThoughtEntryViewModel
    @State private var focusedField: EntryField?
    
    @State private var isDateSheetPresented = false
    @State private var showAISheet = false
    @State private var showPaywall = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isGeneratingReframe = false
    @State private var showUnlockSheet = false
    @State private var isLoadingAd = false
    @State private var showAdErrorAlert = false
    
    
    // MARK: - Suggestion Data
    
    private let sensationSuggestionList = [
        "Tight chest", "Racing heart", "Shallow breathing", "Tense shoulders",
        "Butterflies", "Sweaty palms", "Headache", "Nausea", "Restlessness", "Fatigue"
    ]
    
    private let emotionSuggestionList = [
        "Anxious", "Sad", "Angry", "Frustrated", "Shame", "Guilty",
        "Lonely", "Overwhelmed", "Embarrassed", "Hopeless", "Worried", "Irritated"
    ]
    
    // MARK: - Focus Field Enum
    
    enum EntryField: Hashable {
        case situation
        case sensations
        case emotions
        case thought
        case evidence
        case alternative
        case outcome
        case friend
        case reflection
    }
    
    init(entryId: String?, modelContext: ModelContext, thoughtUsage: ThoughtUsageService) {
        _viewModel = StateObject(wrappedValue: ThoughtEntryViewModel(entryId: entryId, modelContext: modelContext, thoughtUsage: thoughtUsage))
    }
    
    // MARK: - Body
    
    var body: some View {
        mainContent
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
            .toolbar { keyboardToolbar }
            .task { await loadInitialState() }
            .onChange(of: viewModel.situation) { _, _ in
                viewModel.updateTitleFromSituation()
                viewModel.scheduleAutosave()
            }
            .onChange(of: viewModel.sensations) { _, _ in viewModel.scheduleAutosave() }
            .onChange(of: viewModel.emotions) { _, _ in viewModel.scheduleAutosave() }
            .onChange(of: viewModel.automaticThoughts) { _, _ in viewModel.scheduleAutosave() }
            .onChange(of: viewModel.adaptiveResponses) { _, _ in viewModel.scheduleAutosave() }
            .onChange(of: viewModel.outcomesByThought) { _, _ in viewModel.scheduleAutosave() }
            .sheet(isPresented: $isDateSheetPresented) { dateSheet }
            .sheet(isPresented: $showUnlockSheet) { unlockSheet }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .alert("Ad unavailable", isPresented: $showAdErrorAlert) {
                Button("Retry") { Task { await handleWatchAd() } }
                Button("Upgrade") { showPaywall = true }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Try again later or upgrade to Pro.")
            }
    }
    
    // MARK: - Extracted View Components
    
    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            VStack(spacing: 0) {
                notesHeader
                scrollableContent
            }
        }
    }
    
    @ViewBuilder
    private var scrollableContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    dateSection
                    situationSection.id("situation")
                    conditionalSections
                    Color.clear.frame(height: 300)
                }
                .padding(.horizontal, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: focusedField) { _, newField in
                guard let newField else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(scrollId(for: newField), anchor: .top)
                }
            }
        }
    }
    
    @ViewBuilder
    private var conditionalSections: some View {
        if shouldShowSection(.sensations) {
            sensationsSection.id("sensations")
        }
        if shouldShowSection(.emotions) {
            emotionsSection.id("emotions")
        }
        if shouldShowSection(.automaticThoughts) {
            thoughtSection.id("thought")
        }
        if shouldShowSection(.adaptiveResponses) {
            adaptiveSection.id("adaptive")
        }
        if shouldShowSection(.outcome) {
            outcomeSection.id("outcome")
        }
    }
    
    @ToolbarContentBuilder
    private var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Next") { advanceToNextField() }
                .foregroundStyle(.primary)
        }
    }
    
    private func loadInitialState() async {
        await viewModel.loadIfNeeded()
        restoreState()
    }
    
    @ViewBuilder
    private var dateSheet: some View {
        NotesDateSheet(selectedDate: $viewModel.occurredAt) {
            isDateSheetPresented = false
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    @ViewBuilder
    private var unlockSheet: some View {
        NotesUnlockSheet(
            isLoading: isLoadingAd,
            onWatchAd: { Task { await handleWatchAd() } },
            onUpgrade: {
                showUnlockSheet = false
                showPaywall = true
            }
        )
        .presentationDetents([.medium])
    }
    
    // MARK: - Background Color
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    private var textPrimary: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var textSecondary: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.5)
    }
    
    private var textTertiary: Color {
        colorScheme == .dark ? Color.white.opacity(0.35) : Color.black.opacity(0.3)
    }
    
    private var dividerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08)
    }
    
    private var chipSelectedColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1)
    }
    
    // MARK: - Header
    
    private var notesHeader: some View {
        HStack {
            Button {
                Task {
                    await viewModel.saveNow()
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(textSecondary)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text(viewModel.title.isEmpty ? "New Entry" : viewModel.title)
                .font(.headline)
                .foregroundStyle(textPrimary)
                .lineLimit(1)
            
            Spacer()
            
            Button {
                Task {
                    await viewModel.saveNow()
                    AnalyticsService.shared.trackEvent("thought_completed")
                    NotesDraftStore.clear()
                    dismiss()
                }
            } label: {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(textSecondary)
            }
            .frame(width: 44, height: 44, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
    
    // MARK: - Date Section
    
    private var dateSection: some View {
        Button {
            isDateSheetPresented = true
        } label: {
            HStack(spacing: 4) {
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(textTertiary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(textTertiary)
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: viewModel.occurredAt)
    }
    
    // MARK: - Situation Section
    
    private var situationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("WHAT HAPPENED")
            
            NotesExpandingTextArea(
                text: $viewModel.situation,
                placeholder: "Describe the situation that triggered your feelings...",
                isFocused: focusBinding(for: .situation),
                onSubmit: { advanceToNextField() }
            )
            
            sectionDivider
        }
    }
    
    // MARK: - Sensations Section (Multi-Select Chips)
    
    private var sensationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("PHYSICAL SENSATIONS")
            
            // Text input for custom sensations with smart backspace
            NotesExpandingTextArea(
                text: $viewModel.sensations,
                placeholder: "What did you notice in your body?",
                isFocused: focusBinding(for: .sensations),
                onBackspace: {
                    deleteLastSensation()
                }
            ) {
                advanceToNextField()
            }
            
            // FIXED: Always show suggestions - they don't disappear when selected
            sensationChips
            
            sectionDivider
        }
    }
    
    /// Deletes the last comma-separated sensation when backspace is pressed
    private func deleteLastSensation() {
        let text = viewModel.sensations
        guard !text.isEmpty else { return }
        
        // Split into parts
        var parts = text
            .split(separator: ",", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        // Remove the last part
        if parts.count > 1 {
            parts.removeLast()
            viewModel.sensations = parts.joined(separator: ", ")
        } else {
            // Only one item, clear it
            viewModel.sensations = ""
        }
    }
    
    private var sensationChips: some View {
        let selectedSet = parseCommaSeparated(viewModel.sensations)
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Tap to add:")
                .font(.caption)
                .foregroundStyle(textTertiary)
            
            FlowLayout(spacing: 8) {
                ForEach(sensationSuggestionList, id: \.self) { suggestion in
                    let isSelected = selectedSet.contains(suggestion.lowercased())
                    
                    Button {
                        toggleSuggestion(suggestion, in: &viewModel.sensations)
                    } label: {
                        HStack(spacing: 4) {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            Text(suggestion)
                                .font(.footnote)
                        }
                        .foregroundStyle(isSelected ? textPrimary : textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isSelected ? chipSelectedColor : Color.clear)
                        )
                        .overlay(
                            Capsule()
                                .stroke(dividerColor, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Emotions Section (Multi-Select Chips + Intensity)
    
    private var emotionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("HOW DID YOU FEEL")
            
            // Emotion chips for quick selection
            emotionChips
            
            // Show intensity sliders for selected emotions
            if !viewModel.emotions.isEmpty {
                VStack(spacing: 12) {
                    ForEach($viewModel.emotions) { $emotion in
                        if !emotion.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            emotionIntensityRow(emotion: $emotion)
                        }
                    }
                }
            }
            
            // Custom emotion input
            HStack {
                NotesInlineTextField(
                    text: Binding(
                        get: { customEmotionInput },
                        set: { customEmotionInput = $0 }
                    ),
                    placeholder: "Add custom emotion...",
                    isFocused: focusBinding(for: .emotions)
                ) {
                    // FIXED: If empty, advance to next section. Otherwise add the emotion.
                    if customEmotionInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        advanceToNextField()
                    } else {
                        addCustomEmotion()
                    }
                }
                
                if !customEmotionInput.isEmpty {
                    Button {
                        addCustomEmotion()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            sectionDivider
        }
    }
    
    @State private var customEmotionInput: String = ""
    
    private var emotionChips: some View {
        let selectedNames = Set(viewModel.emotions.map { $0.name.lowercased() })
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Tap to add:")
                .font(.caption)
                .foregroundStyle(textTertiary)
            
            FlowLayout(spacing: 8) {
                ForEach(emotionSuggestionList, id: \.self) { suggestion in
                    let isSelected = selectedNames.contains(suggestion.lowercased())
                    
                    Button {
                        toggleEmotion(suggestion)
                    } label: {
                        HStack(spacing: 4) {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            Text(suggestion)
                                .font(.footnote)
                        }
                        .foregroundStyle(isSelected ? textPrimary : textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isSelected ? chipSelectedColor : Color.clear)
                        )
                        .overlay(
                            Capsule()
                                .stroke(dividerColor, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func emotionIntensityRow(emotion: Binding<EmotionItem>) -> some View {
        HStack(spacing: 12) {
            Text(emotion.wrappedValue.name)
                .font(.subheadline)
                .foregroundStyle(textPrimary)
                .frame(width: 100, alignment: .leading)
            
            Slider(
                value: Binding(
                    get: { Double(emotion.wrappedValue.intensity) },
                    set: { emotion.wrappedValue.intensity = Int($0) }
                ),
                in: 0...100,
                step: 1
            )
            .tint(textSecondary)
            
            Text("\(emotion.wrappedValue.intensity)")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(textTertiary)
                .frame(width: 28, alignment: .trailing)
            
            Button {
                viewModel.removeEmotion(id: emotion.wrappedValue.id)
            } label: {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
    
    private func toggleEmotion(_ name: String) {
        let lowercased = name.lowercased()
        if let index = viewModel.emotions.firstIndex(where: { $0.name.lowercased() == lowercased }) {
            viewModel.emotions.remove(at: index)
        } else {
            let item = EmotionItem(id: UUID(), name: name, intensity: 50)
            viewModel.emotions.append(item)
        }
    }
    
    private func addCustomEmotion() {
        let trimmed = customEmotionInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let lowercased = trimmed.lowercased()
        if !viewModel.emotions.contains(where: { $0.name.lowercased() == lowercased }) {
            let item = EmotionItem(id: UUID(), name: trimmed.capitalized, intensity: 50)
            viewModel.emotions.append(item)
        }
        customEmotionInput = ""
    }
    
    // MARK: - Automatic Thought Section
    
    private var thoughtSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("AUTOMATIC THOUGHT")
            
            Text("What thought went through your mind?")
                .font(.subheadline)
                .foregroundStyle(textTertiary)
            
            if let binding = primaryThoughtBinding {
                NotesExpandingTextArea(
                    text: binding.text,
                    placeholder: "The thought that came up...",
                    isFocused: focusBinding(for: .thought),
                    onSubmit: { advanceToNextField() }
                )
                
                // Belief slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("How much did you believe this?")
                            .font(.footnote)
                            .foregroundStyle(textTertiary)
                        Spacer()
                        Text("\(binding.wrappedValue.beliefBefore)%")
                            .font(.footnote.monospacedDigit().weight(.medium))
                            .foregroundStyle(textSecondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(binding.wrappedValue.beliefBefore) },
                            set: { binding.wrappedValue.beliefBefore = Int($0) }
                        ),
                        in: 0...100,
                        step: 1
                    )
                    .tint(textSecondary)
                }
                .padding(.top, 8)
            }
            
            sectionDivider
        }
    }
    
    private var primaryThoughtBinding: Binding<AutomaticThought>? {
        guard let first = viewModel.automaticThoughts.first,
              let index = viewModel.automaticThoughts.firstIndex(where: { $0.id == first.id }) else {
            let id = viewModel.addAutomaticThought()
            guard let index = viewModel.automaticThoughts.firstIndex(where: { $0.id == id }) else {
                return nil
            }
            return $viewModel.automaticThoughts[index]
        }
        return $viewModel.automaticThoughts[index]
    }
    
    // MARK: - Adaptive Responses Section
    
    private var adaptiveSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("CHALLENGING THE THOUGHT")
            
            if let thoughtId = viewModel.automaticThoughts.first?.id {
                adaptivePrompt(
                    title: "What evidence supports this thought?",
                    text: Binding(
                        get: { viewModel.adaptiveResponseValue(thoughtId: thoughtId, key: .evidenceText) },
                        set: { viewModel.updateAdaptiveResponse(thoughtId: thoughtId, key: .evidenceText, value: $0) }
                    ),
                    field: .evidence
                )
                
                adaptivePrompt(
                    title: "What's an alternative perspective?",
                    text: Binding(
                        get: { viewModel.adaptiveResponseValue(thoughtId: thoughtId, key: .alternativeText) },
                        set: { viewModel.updateAdaptiveResponse(thoughtId: thoughtId, key: .alternativeText, value: $0) }
                    ),
                    field: .alternative
                )
                
                adaptivePrompt(
                    title: "What's the most likely outcome?",
                    text: Binding(
                        get: { viewModel.adaptiveResponseValue(thoughtId: thoughtId, key: .outcomeText) },
                        set: { viewModel.updateAdaptiveResponse(thoughtId: thoughtId, key: .outcomeText, value: $0) }
                    ),
                    field: .outcome
                )
                
                adaptivePrompt(
                    title: "What would you tell a friend?",
                    text: Binding(
                        get: { viewModel.adaptiveResponseValue(thoughtId: thoughtId, key: .friendText) },
                        set: { viewModel.updateAdaptiveResponse(thoughtId: thoughtId, key: .friendText, value: $0) }
                    ),
                    field: .friend
                )
            }
            
            sectionDivider
        }
    }
    
    private func adaptivePrompt(title: String, text: Binding<String>, field: EntryField) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(textTertiary)
            
            NotesExpandingTextArea(
                text: text,
                placeholder: "Your response...",
                isFocused: focusBinding(for: field),
                onSubmit: { advanceToNextField() }
            )
        }
    }
    
    // MARK: - Outcome Section
    
    private var outcomeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("BALANCED PERSPECTIVE")
            
            if let thoughtId = viewModel.automaticThoughts.first?.id {
                NotesExpandingTextArea(
                    text: Binding(
                        get: { viewModel.outcomeReflection(for: thoughtId) },
                        set: { viewModel.updateOutcomeReflection(thoughtId: thoughtId, value: $0) }
                    ),
                    placeholder: "What feels more balanced now?",
                    isFocused: focusBinding(for: .reflection),
                    onSubmit: { focusedField = nil }  // Last field - dismiss keyboard
                )
                
                // Belief after
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("How much do you believe the original thought now?")
                            .font(.footnote)
                            .foregroundStyle(textTertiary)
                        Spacer()
                        Text("\(outcomeBeliefValue(thoughtId: thoughtId))%")
                            .font(.footnote.monospacedDigit().weight(.medium))
                            .foregroundStyle(textSecondary)
                    }
                    
                    Slider(
                        value: outcomeBeliefBinding(thoughtId: thoughtId),
                        in: 0...100,
                        step: 1
                    )
                    .tint(textSecondary)
                    
                    if let original = viewModel.automaticThoughts.first?.beliefBefore {
                        let delta = outcomeBeliefValue(thoughtId: thoughtId) - original
                        Text(delta < 0 ? "↓ \(abs(delta))% from before" : (delta > 0 ? "↑ \(delta)% from before" : "Same as before"))
                            .font(.footnote)
                            .foregroundStyle(textTertiary)
                    }
                }
                .padding(.top, 12)
                
                // Emotion intensity re-ranking
                emotionReRankingSection
                
                // AI Reframe CTA
                aiReframeCTA
            }
        }
    }
    
    /// Section for re-ranking emotion intensity after reframing
    private var emotionReRankingSection: some View {
        let emotionsWithNames = viewModel.emotions.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        return Group {
            if !emotionsWithNames.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("How do these emotions feel now?")
                        .font(.footnote)
                        .foregroundStyle(textTertiary)
                        .padding(.top, 16)
                    
                    ForEach($viewModel.emotions) { $emotion in
                        if !emotion.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            emotionAfterRow(emotion: $emotion)
                        }
                    }
                }
            }
        }
    }
    
    private func emotionAfterRow(emotion: Binding<EmotionItem>) -> some View {
        let originalIntensity = emotion.wrappedValue.intensity
        let afterIntensity = emotionAfterIntensity(for: emotion.wrappedValue.id)
        let delta = afterIntensity - originalIntensity
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(emotion.wrappedValue.name)
                    .font(.subheadline)
                    .foregroundStyle(textPrimary)
                
                Spacer()
                
                Text("\(afterIntensity)")
                    .font(.footnote.monospacedDigit().weight(.medium))
                    .foregroundStyle(textSecondary)
            }
            
            Slider(
                value: emotionAfterBinding(for: emotion.wrappedValue.id, originalIntensity: originalIntensity),
                in: 0...100,
                step: 1
            )
            .tint(textSecondary)
            
            Text(delta < 0 ? "↓ \(abs(delta)) from before" : (delta > 0 ? "↑ \(delta) from before" : "Same as before"))
                .font(.caption)
                .foregroundStyle(textTertiary)
        }
        .padding(.vertical, 4)
    }
    
    private func emotionAfterIntensity(for emotionId: UUID) -> Int {
        if let thoughtId = viewModel.automaticThoughts.first?.id,
           let outcome = viewModel.outcomesByThought[thoughtId],
           let afterValue = outcome.emotionsAfter[emotionId.uuidString] {
            return afterValue
        }
        // Default to original intensity
        return viewModel.emotions.first { $0.id == emotionId }?.intensity ?? 50
    }
    
    private func emotionAfterBinding(for emotionId: UUID, originalIntensity: Int) -> Binding<Double> {
        Binding(
            get: { Double(emotionAfterIntensity(for: emotionId)) },
            set: { newValue in
                guard let thoughtId = viewModel.automaticThoughts.first?.id else { return }
                let thought = viewModel.automaticThoughts.first { $0.id == thoughtId }
                let beliefBefore = thought?.beliefBefore ?? 50
                var outcome = viewModel.ensureOutcome(for: thoughtId, beliefBefore: beliefBefore)
                outcome.emotionsAfter[emotionId.uuidString] = Int(newValue)
                viewModel.outcomesByThought[thoughtId] = outcome
            }
        )
    }
    
    private func outcomeBeliefValue(thoughtId: String) -> Int {
        let thought = viewModel.automaticThoughts.first { $0.id == thoughtId }
        let beliefBefore = thought?.beliefBefore ?? 50
        return viewModel.ensureOutcome(for: thoughtId, beliefBefore: beliefBefore).beliefAfter
    }
    
    private func outcomeBeliefBinding(thoughtId: String) -> Binding<Double> {
        Binding(
            get: { Double(outcomeBeliefValue(thoughtId: thoughtId)) },
            set: { newValue in
                let thought = viewModel.automaticThoughts.first { $0.id == thoughtId }
                let beliefBefore = thought?.beliefBefore ?? 50
                var outcome = viewModel.ensureOutcome(for: thoughtId, beliefBefore: beliefBefore)
                outcome.beliefAfter = Int(newValue)
                viewModel.outcomesByThought[thoughtId] = outcome
                if thoughtId == viewModel.automaticThoughts.first?.id {
                    viewModel.beliefAfterMainThought = Int(newValue)
                }
            }
        )
    }
    
    private var aiReframeCTA: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .background(dividerColor)
                .padding(.vertical, 16)
            
            if viewModel.aiReframe != nil {
                Button {
                    router.push(.aiReframeNotes(entryId: viewModel.currentRecordId))
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                        Text("View AI Reframe")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(textSecondary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(dividerColor, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    handleUnlockTap()
                } label: {
                    HStack(spacing: 8) {
                        if isGeneratingReframe {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                        }
                        Text(isGeneratingReframe ? "Generating..." : "Get AI Reframe")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                    }
                    .foregroundStyle(textPrimary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                    )
                }
                .buttonStyle(.plain)
                .disabled(isGeneratingReframe)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(textTertiary)
            .kerning(1.2)
            .padding(.top, 24)
            .padding(.bottom, 4)
    }
    
    private var sectionDivider: some View {
        Rectangle()
            .fill(dividerColor)
            .frame(height: 1)
            .padding(.top, 20)
    }
    
    // MARK: - Focus Management
    
    private func focusBinding(for field: EntryField) -> Binding<Bool> {
        Binding(
            get: { focusedField == field },
            set: { if $0 { focusedField = field } else if focusedField == field { focusedField = nil } }
        )
    }
    
    private func scrollId(for field: EntryField) -> String {
        switch field {
        case .situation: return "situation"
        case .sensations: return "sensations"
        case .emotions: return "emotions"
        case .thought: return "thought"
        case .evidence, .alternative, .outcome, .friend: return "adaptive"
        case .reflection: return "outcome"
        }
    }
    
    private func advanceToNextField() {
        guard let current = focusedField else { return }
        
        let next: EntryField? = {
            switch current {
            case .situation:
                viewModel.reveal(.sensations)
                return .sensations
            case .sensations:
                viewModel.reveal(.emotions)
                return .emotions
            case .emotions:
                // Always allow advancing (emotions are optional)
                viewModel.reveal(.automaticThoughts)
                ensureThoughtExists()
                return .thought
            case .thought:
                viewModel.reveal(.adaptiveResponses)
                return .evidence
            case .evidence:
                return .alternative
            case .alternative:
                return .outcome
            case .outcome:
                return .friend
            case .friend:
                viewModel.reveal(.outcome)
                return .reflection
            case .reflection:
                return nil
            }
        }()
        
        if let next {
            focusedField = next
        } else {
            focusedField = nil
        }
    }
    
    private func ensureThoughtExists() {
        if viewModel.automaticThoughts.isEmpty {
            _ = viewModel.addAutomaticThought()
        }
    }
    
    // MARK: - Section Visibility
    
    private func shouldShowSection(_ section: ThoughtEntryViewModel.Section) -> Bool {
        viewModel.isSectionVisible(section)
    }
    
    private func restoreState() {
        // Only auto-focus for new/incomplete entries, not completed ones
        // An entry is considered "complete" if it has an AI reframe or outcome reflection
        let hasAIReframe = viewModel.aiReframe != nil
        let hasOutcomeReflection = viewModel.automaticThoughts.first.flatMap { thought in
            viewModel.outcomesByThought[thought.id]?.reflection
        }?.isEmpty == false
        
        let isCompleted = hasAIReframe || hasOutcomeReflection
        
        if !isCompleted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if focusedField == nil {
                    focusedField = .situation
                }
            }
        }
    }
    
    // MARK: - Suggestion Helpers
    
    private func parseCommaSeparated(_ text: String) -> Set<String> {
        Set(
            text
                .split { $0 == "," || $0 == "\n" }
                .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                .filter { !$0.isEmpty }
        )
    }
    
    private func toggleSuggestion(_ suggestion: String, in text: inout String) {
        let existing = parseCommaSeparated(text)
        let lowercased = suggestion.lowercased()
        
        if existing.contains(lowercased) {
            // Remove: rebuild string without this suggestion
            let parts = text
                .split { $0 == "," || $0 == "\n" }
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && $0.lowercased() != lowercased }
            // Keep trailing ", " for easy continuation
            text = parts.isEmpty ? "" : parts.joined(separator: ", ") + ", "
        } else {
            // Add with trailing ", " so user can keep typing
            if text.isEmpty {
                text = suggestion + ", "
            } else {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.hasSuffix(",") {
                    text = trimmed + " " + suggestion + ", "
                } else {
                    text = trimmed + ", " + suggestion + ", "
                }
            }
        }
    }
    
    // MARK: - AI Reframe
    
    private func handleUnlockTap() {
        guard validateReframeLimits() else { return }
        if entitlementsManager.isPro {
            Task { await generateReframe() }
        } else {
            showUnlockSheet = true
        }
    }
    
    private func handleWatchAd() async {
        guard validateReframeLimits() else { return }
        isLoadingAd = true
        do {
            let rewarded = try await rewardedAdManager.presentAd()
            isLoadingAd = false
            if rewarded {
                showUnlockSheet = false
                await generateReframe()
            } else {
                showAdErrorAlert = true
            }
        } catch {
            isLoadingAd = false
            showAdErrorAlert = true
        }
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
        guard !isGeneratingReframe else { return }
        isGeneratingReframe = true
        defer { isGeneratingReframe = false }
        
        let service = AIReframeService()
        let record = viewModel.currentRecordSnapshot()
        let depth = viewModel.aiReframeDepth ?? .deep
        AnalyticsService.shared.trackEvent("ai_reframe_requested", properties: [
            "depth": depth.rawValue
        ])
        do {
            let generated = try await service.generateReframe(for: record, depth: depth)
            viewModel.aiReframe = generated
            viewModel.aiReframeCreatedAt = Date()
            viewModel.aiReframeModel = service.modelName
            viewModel.aiReframePromptVersion = service.promptVersion
            viewModel.aiReframeDepth = depth
            await viewModel.saveNow()
            limitsManager.recordReframe()
            AnalyticsService.shared.trackEvent("ai_reframe_generated", properties: [
                "depth": depth.rawValue
            ])
            router.push(.aiReframeNotes(entryId: viewModel.currentRecordId))
        } catch {
            if let openAIError = error as? LegacyOpenAIClient.OpenAIError {
                switch openAIError {
                case .missingAPIKey:
                    alertMessage = "Missing OpenAI API key."
                default:
                    alertMessage = openAIError.localizedDescription
                }
            } else {
                alertMessage = "Something went wrong generating your reframe."
            }
            showAlert = true
        }
    }
}

// MARK: - Expanding Text Area (Notes-style multiline input)

private struct NotesExpandingTextArea: View {
    @Binding var text: String
    let placeholder: String
    @Binding var isFocused: Bool
    var onBackspace: (() -> Void)? = nil
    var onSubmit: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder text
            if text.isEmpty {
                Text(placeholder)
                    .font(.body)
                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.25))
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }
            
            // The actual text editor - sizeThatFits handles all sizing
            NotesExpandingTextEditor(
                text: $text,
                isFocused: $isFocused,
                onSubmit: onSubmit,
                onTab: onSubmit,
                onBackspaceWhenEmpty: onBackspace
            )
        }
        // Constrain width to parent, let height be determined by sizeThatFits
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Expanding Text Editor (UIKit with proper sizing)

private struct NotesExpandingTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    var onSubmit: (() -> Void)?
    var onTab: (() -> Void)?
    var onBackspaceWhenEmpty: (() -> Void)?
    
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.font = UIFont.preferredFont(forTextStyle: .body)
        view.adjustsFontForContentSizeCategory = true
        view.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        view.textContainer.lineFragmentPadding = 0
        view.textContainer.lineBreakMode = .byWordWrapping
        view.textContainer.widthTracksTextView = true
        view.textColor = .label
        view.returnKeyType = .next
        view.autocorrectionType = .yes
        view.autocapitalizationType = .sentences
        view.keyboardDismissMode = .interactive
        // Low horizontal priority = willing to wrap instead of expand
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
            // Text changed externally, need to re-measure
            uiView.invalidateIntrinsicContentSize()
        }
        if isFocused, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        }
    }
    
    /// CRITICAL: This tells SwiftUI exactly what size we need.
    /// We accept the proposed WIDTH (constrained by parent) and calculate HEIGHT to fit content.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        // Use proposed width, falling back to screen width minus padding
        let width = proposal.width ?? (UIScreen.main.bounds.width - 40)
        
        // Calculate height needed to display all text at this width
        let fittingSize = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let height = max(44, ceil(fittingSize.height))
        
        return CGSize(width: width, height: height)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UITextViewDelegate {
        private let parent: NotesExpandingTextEditor
        
        init(_ parent: NotesExpandingTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            // Tell SwiftUI we need to re-measure (triggers sizeThatFits)
            textView.invalidateIntrinsicContentSize()
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused = true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            // Let SwiftUI manage focus state
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // Handle Enter/Return key
            if text == "\n" {
                parent.onSubmit?()
                return false
            }
            // Handle Tab key
            if text == "\t" {
                parent.onTab?()
                return false
            }
            // Handle Backspace for chip-style deletion
            // Only trigger when: text ends with ", " (user just added a chip, not typing)
            if text.isEmpty && range.length == 1 && parent.onBackspaceWhenEmpty != nil {
                let currentText = textView.text ?? ""
                // Only delete whole item if text ends with ", " (just added a chip)
                if currentText.hasSuffix(", ") {
                    parent.onBackspaceWhenEmpty?()
                    return false
                }
            }
            return true
        }
    }
}

// MARK: - Notes Inline TextField Component

private struct NotesInlineTextField: View {
    @Binding var text: String
    let placeholder: String
    @Binding var isFocused: Bool
    var onSubmit: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NotesTextField(
            text: $text,
            isFocused: $isFocused,
            placeholder: placeholder,
            onSubmit: onSubmit,
            onTab: onSubmit
        )
        .frame(height: 36)
    }
}

// MARK: - Flow Layout for Chips

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalHeight = currentY + lineHeight
        }
        
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

// MARK: - Date Sheet

private struct NotesDateSheet: View {
    @Binding var selectedDate: Date
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("When did this happen?")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    onDismiss()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            HStack(spacing: 12) {
                quickDateButton("Now") { selectedDate = Date() }
                quickDateButton("Yesterday") {
                    if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
                        selectedDate = yesterday
                    }
                }
            }
            .padding(.horizontal, 20)
            
            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .padding(.horizontal, 8)
            
            Spacer()
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
    
    private func quickDateButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Unlock Sheet

private struct NotesUnlockSheet: View {
    let isLoading: Bool
    let onWatchAd: () -> Void
    let onUpgrade: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Unlock AI Reframe")
                .font(.title3.weight(.semibold))
            
            Text("Get personalized insights and a fresh perspective on your thoughts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button(action: onWatchAd) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.rectangle")
                    }
                    Text(isLoading ? "Loading..." : "Watch a short ad")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            
            Button(action: onUpgrade) {
                Text("Upgrade to Pro")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}
