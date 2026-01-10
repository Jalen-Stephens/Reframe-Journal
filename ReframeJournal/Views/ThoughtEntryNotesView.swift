import SwiftUI
import SwiftData

struct ThoughtEntryNotesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var entitlementsManager: EntitlementsManager
    @EnvironmentObject private var limitsManager: LimitsManager
    @EnvironmentObject private var rewardedAdManager: AnyRewardedAdManager
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ThoughtEntryViewModel
    @StateObject private var valuesService: ValuesProfileService
    @FocusState private var focusedField: ThoughtEntryViewModel.Field?
    @State private var isDateSheetPresented = false
    @State private var showEmotionSuggestions = false
    @State private var showEmotionCheck = false
    @State private var wasEmotionsComplete = false
    @State private var showUnlockSheet = false
    @State private var showAdErrorAlert = false
    @State private var showPaywall = false
    @State private var isGeneratingReframe = false
    @State private var isLoadingAd = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    @AppStorage("aiReframeEnabled") private var isAIReframeEnabled = false

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


    init(entryId: String?, modelContext: ModelContext, thoughtUsage: ThoughtUsageService) {
        _viewModel = StateObject(wrappedValue: ThoughtEntryViewModel(entryId: entryId, modelContext: modelContext, thoughtUsage: thoughtUsage))
        let tempContainer = try! ModelContainerConfig.makeContainer()
        _valuesService = StateObject(wrappedValue: ValuesProfileService(modelContext: tempContainer.mainContext))
    }

    var body: some View {
        contentView
    }

    private var contentView: some View {
        ScrollViewReader { proxy in
            scrollContainer(proxy: proxy)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button("Add Line") {
                    insertNewlineForFocusedField()
                }
                Spacer()
                Button("Next") {
                    moveToNextField()
                }
            }
        }
        .sheet(isPresented: $isDateSheetPresented) {
            DateTimeSheet(
                selectedDate: $viewModel.occurredAt,
                onDismiss: { isDateSheetPresented = false },
                onQuickSelect: { date in
                    viewModel.occurredAt = date
                    viewModel.scheduleAutosave()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            valuesService.updateModelContext(modelContext)
        }
        .task {
            await viewModel.loadIfNeeded()
            restoreScrollPosition()
            wasEmotionsComplete = hasCompleteEmotions
        }
        .onChange(of: viewModel.situation) { _, _ in
            viewModel.updateTitleFromSituation()
            viewModel.scheduleAutosave()
        }
        .onChange(of: viewModel.sensations) { _, _ in
            viewModel.scheduleAutosave()
        }
        .onChange(of: viewModel.emotions) { _, _ in
            viewModel.scheduleAutosave()
            let isComplete = hasCompleteEmotions
            if isComplete && !wasEmotionsComplete {
                triggerEmotionCompletion()
            }
            wasEmotionsComplete = isComplete
        }
        .onChange(of: viewModel.automaticThoughts) { _, _ in
            viewModel.scheduleAutosave()
            viewModel.reveal(.adaptiveResponses)
            viewModel.reveal(.outcome)
        }
        .onChange(of: viewModel.adaptiveResponses) { _, _ in
            viewModel.scheduleAutosave()
            if hasAutomaticThoughts {
                viewModel.reveal(.outcome)
            }
        }
        .onChange(of: viewModel.outcomesByThought) { _, _ in
            viewModel.scheduleAutosave()
        }
        .onChange(of: viewModel.beliefAfterMainThought) { _, _ in
            viewModel.scheduleAutosave()
        }
        .onChange(of: viewModel.occurredAt) { _, _ in
            viewModel.scheduleAutosave()
        }
        .onChange(of: viewModel.maxRevealedSection) { _, newValue in
            NotesDraftStore.save(entryId: viewModel.currentRecordId, section: newValue)
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
        .sheet(isPresented: $showUnlockSheet) {
            UnlockReframePromptSheet(
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
        .alert("", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func scrollContainer(proxy: ScrollViewProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                entrySections
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(GlassBackground())
        .onChange(of: focusedField) { _, newValue in
            guard let newValue, newValue != .title else { return }
            let section = viewModel.section(for: newValue)
            NotesDraftStore.save(entryId: viewModel.currentRecordId, section: section)
            withAnimation(.easeInOut(duration: 0.2)) {
                proxy.scrollTo(section, anchor: .top)
            }
        }
        .onChange(of: viewModel.scrollTarget) { _, newTarget in
            guard let newTarget else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                proxy.scrollTo(newTarget, anchor: .top)
            }
            viewModel.scrollTarget = nil
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                GlassIconButton(icon: .chevronLeft, size: AppTheme.iconSizeMedium, accessibilityLabel: "Back") {
                    Task {
                        // Cancel any pending autosave
                        viewModel.cancelAutosave()
                        // Delete entry if it's empty (new entry with no content)
                        await viewModel.deleteIfEmpty()
                        // Clear draft store
                        NotesDraftStore.clear()
                        dismiss()
                    }
                }

                Spacer()

                Text(viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "New Entry" : viewModel.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                GlassPillButton {
                    Task {
                        await viewModel.saveNow()
                        NotesDraftStore.clear()
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 6) {
                        AppIconView(icon: .check, size: AppTheme.iconSizeSmall)
                            .foregroundStyle(notesPalette.textSecondary)
                        Text("Done")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(notesPalette.textSecondary)
                    }
                }
            }

            Button {
                isDateSheetPresented = true
            } label: {
                HStack(spacing: 6) {
                    Text(dateLine)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    AppIconView(icon: .chevronDown, size: AppTheme.iconSizeSmall)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit date and time")
        }
    }

    @ViewBuilder
    private var entrySections: some View {
        headerSection
        GlassDivider()
        situationSection
        if viewModel.isSectionVisible(.sensations) {
            GlassDivider()
            sensationsSection
        }
        if viewModel.isSectionVisible(.emotions) {
            GlassDivider()
            emotionsSection
        }
        if viewModel.isSectionVisible(.automaticThoughts) {
            GlassDivider()
            automaticThoughtsSection
        }
        if viewModel.isSectionVisible(.adaptiveResponses) {
            GlassDivider()
            adaptiveResponsesSection
        }
        if viewModel.isSectionVisible(.values) {
            GlassDivider()
            valuesSection
        }
        if viewModel.isSectionVisible(.outcome) {
            GlassDivider()
            outcomeSection
        }
    }
    
    // MARK: - Values Section
    
    private var valuesSection: some View {
        ValuesSelectionSection(
            selectedValues: Binding(
                get: { viewModel.selectedValues ?? .empty },
                set: { newValue in
                    viewModel.selectedValues = newValue.hasSelection ? newValue : nil
                    viewModel.scheduleAutosave()
                }
            )
        )
        .id(ThoughtEntryViewModel.Section.values)
    }

    private var situationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            GlassSectionHeader(text: "SITUATION")
            GlassCard(padding: AppTheme.cardPaddingCompact) {
                notesEditor(
                    text: $viewModel.situation,
                    placeholder: "Describe what happened...",
                    field: .situation,
                    accessibilityLabel: "Situation"
                )
            }
        }
        .id(ThoughtEntryViewModel.Section.situation)
    }

    private var sensationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            GlassSectionHeader(text: "SENSATIONS")
            GlassCard(padding: AppTheme.cardPaddingCompact) {
                notesEditor(
                    text: $viewModel.sensations,
                    placeholder: "Physical sensations...",
                    field: .sensations,
                    accessibilityLabel: "Sensations"
                )
            }

            if shouldShowSensationSuggestions {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(sensationsSuggestions, id: \.self) { suggestion in
                            Button {
                                applySensationSuggestion(suggestion)
                            } label: {
                                GlassPill(padding: EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)) {
                                    Text(suggestion)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .accessibilityLabel("Suggested sensations")
            }
        }
        .id(ThoughtEntryViewModel.Section.sensations)
    }

    private var emotionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                GlassSectionHeader(text: "EMOTIONS")
                if showEmotionCheck {
                    AppIconView(icon: .check, size: AppTheme.iconSizeSmall)
                        .foregroundStyle(.secondary)
                        .transition(.scale.combined(with: .opacity))
                }
                Spacer()
                if hasEmotions && !emotionSuggestions.isEmpty {
                    GlassPillButton {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showEmotionSuggestions.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(showEmotionSuggestions ? "Hide suggestions" : "Show suggestions")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if shouldShowEmotionSuggestions {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Suggested")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        GlassPillButton {
                            let id = viewModel.addEmotion()
                            focusedField = .emotionName(id)
                        } label: {
                            HStack(spacing: 6) {
                                AppIconView(icon: .plus, size: AppTheme.iconSizeSmall)
                                Text("Add Custom Emotion")
                            }
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                        }
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(emotionSuggestions, id: \.self) { suggestion in
                                Button {
                                    applyEmotionSuggestion(suggestion)
                                } label: {
                                    GlassPill(padding: EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)) {
                                        Text(suggestion.capitalized)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .accessibilityLabel("Suggested emotions")
                }
            } else if hasEmotions {
                HStack {
                    Text("Suggested")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    GlassPillButton {
                        let id = viewModel.addEmotion()
                        focusedField = .emotionName(id)
                    } label: {
                        HStack(spacing: 6) {
                            AppIconView(icon: .plus, size: AppTheme.iconSizeSmall)
                            Text("Add Custom Emotion")
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                    }
                }
            }

            VStack(spacing: 12) {
                ForEach($viewModel.emotions) { $emotion in
                    GlassCard(padding: AppTheme.cardPaddingCompact) {
                        VStack(alignment: .leading, spacing: 8) {
                            NotesTextField(
                                text: $emotion.name,
                                isFocused: bindingForEmotionFocus(id: emotion.id),
                                placeholder: "Emotion"
                            ) {
                                moveToNext(from: .emotionName(emotion.id))
                            } onTab: {
                                moveToNext(from: .emotionName(emotion.id))
                            }

                            HStack(spacing: 12) {
                                Slider(value: Binding(
                                    get: { Double(emotion.intensity) },
                                    set: { emotion.intensity = Int($0) }
                                ), in: 0...100, step: 1)
                                .tint(.secondary)
                                .accessibilityLabel("Intensity")

                                Text("\(emotion.intensity)")
                                    .font(.footnote.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 32, alignment: .trailing)

                                GlassIconButton(icon: .minus, size: AppTheme.iconSizeSmall, accessibilityLabel: "Remove emotion") {
                                    viewModel.removeEmotion(id: emotion.id)
                                }
                            }
                        }
                    }
                }
            }

            if hasCompleteEmotions {
                Button {
                    continueToAutomaticThoughts()
                } label: {
                    GlassCard(padding: AppTheme.cardPaddingCompact) {
                        HStack {
                            Text("Continue to Automatic Thoughts")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            AppIconView(icon: .chevronRight, size: AppTheme.iconSizeSmall)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            GlassPillButton {
                let id = viewModel.addEmotion()
                focusedField = .emotionName(id)
            } label: {
                HStack(spacing: 6) {
                    AppIconView(icon: .plus, size: AppTheme.iconSizeSmall)
                    Text("Add Emotion")
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Add emotion")
        }
        .id(ThoughtEntryViewModel.Section.emotions)
    }

    private var automaticThoughtsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                GlassSectionHeader(text: "AUTOMATIC THOUGHTS")
            }

            VStack(spacing: 12) {
                if let binding = bindingForPrimaryThought() {
                    let thought = binding.wrappedValue
                    GlassCard(padding: AppTheme.cardPaddingCompact) {
                        VStack(alignment: .leading, spacing: 8) {
                            NotesTextField(
                                text: binding.text,
                                isFocused: bindingForAutomaticThoughtFocus(id: thought.id),
                                placeholder: "Automatic thought"
                            ) {
                                moveToNext(from: .automaticThought(thought.id))
                            } onTab: {
                                moveToNext(from: .automaticThought(thought.id))
                            }

                            HStack(spacing: 12) {
                                Slider(value: Binding(
                                    get: { Double(binding.wrappedValue.beliefBefore) },
                                    set: { binding.wrappedValue.beliefBefore = Int($0) }
                                ), in: 0...100, step: 1)
                                .tint(.secondary)
                                .accessibilityLabel("Belief")

                                Text("\(thought.beliefBefore)")
                                    .font(.footnote.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 32, alignment: .trailing)
                            }
                        }
                    }
                }
            }
        }
        .id(ThoughtEntryViewModel.Section.automaticThoughts)
    }

    private var adaptiveResponsesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            GlassSectionHeader(text: "ADAPTIVE RESPONSES")
            if let thought = viewModel.automaticThoughts.first {
                GlassCard(padding: AppTheme.cardPaddingCompact) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(AdaptivePrompts.all, id: \.id) { prompt in
                            adaptiveResponsePrompt(
                                label: prompt.label,
                                placeholder: "Write your response...",
                                thoughtId: thought.id,
                                key: prompt.textKey
                            )
                        }
                    }
                }
            } else {
                GlassCard(padding: AppTheme.cardPaddingCompact) {
                    Text("Add an automatic thought to continue.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .id(ThoughtEntryViewModel.Section.adaptiveResponses)
    }

    private var outcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            GlassSectionHeader(text: "OUTCOME")
            if let thought = viewModel.automaticThoughts.first {
                GlassCard(padding: AppTheme.cardPaddingCompact) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Balanced thought")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                        notesEditor(
                            text: bindingForOutcomeReflection(thoughtId: thought.id),
                            placeholder: "What feels more balanced now?",
                            field: .outcomeReflection(thoughtId: thought.id),
                            accessibilityLabel: "Balanced thought"
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Belief after")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text("\(outcomeBelief(thoughtId: thought.id))")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Slider(value: bindingForOutcomeBelief(thoughtId: thought.id), in: 0...100, step: 1)
                                .tint(.secondary)
                        }

                        if !viewModel.emotions.isEmpty {
                            Text("Re-rate emotions (optional)")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                            ForEach(viewModel.emotions) { emotion in
                                let label = emotion.name.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !label.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(label)
                                                .font(.footnote.weight(.semibold))
                                                .foregroundStyle(.primary)
                                            Spacer()
                                            Text("Before \(emotion.intensity)")
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                        }
                                        Text("\(outcomeEmotionValue(thoughtId: thought.id, emotionId: emotion.id))")
                                            .font(.footnote.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                        Slider(
                                            value: bindingForOutcomeEmotion(thoughtId: thought.id, emotionId: emotion.id),
                                            in: 0...100,
                                            step: 1
                                        )
                                        .tint(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                aiReframeCallToAction
            } else {
                GlassCard(padding: AppTheme.cardPaddingCompact) {
                    Text("Add an automatic thought to reflect on the outcome.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .id(ThoughtEntryViewModel.Section.outcome)
    }

    private func notesEditor(
        text: Binding<String>,
        placeholder: String,
        field: ThoughtEntryViewModel.Field,
        accessibilityLabel: String
    ) -> some View {
        ZStack(alignment: .topLeading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
            NotesTextEditor(
                text: text,
                isFocused: focusBinding(for: field),
                onSubmit: {
                    moveToNext(from: field)
                },
                onTab: {
                    moveToNext(from: field)
                }
            )
            .frame(minHeight: 64)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private func moveToNextField() {
        guard let focusedField else { return }
        moveToNext(from: focusedField)
    }

    private func moveToNext(from field: ThoughtEntryViewModel.Field) {
        if case .outcomeReflection = field {
            focusField(nil)
            dismissKeyboard()
            viewModel.scheduleAutosave()
            return
        }
        let next = viewModel.nextField(after: field)
        focusField(next)
        if next == nil {
            viewModel.scheduleAutosave()
        }
    }

    private func insertNewlineForFocusedField() {
        guard let focusedField else { return }
        viewModel.insertNewline(into: focusedField)
        viewModel.scheduleAutosave()
    }

    private func focusBinding(for field: ThoughtEntryViewModel.Field) -> Binding<Bool> {
        Binding(
            get: { focusedField == field },
            set: { isFocused in
                if isFocused {
                    focusField(field)
                } else if focusedField == field {
                    focusedField = nil
                }
            }
        )
    }

    private func bindingForEmotionFocus(id: UUID) -> Binding<Bool> {
        Binding(
            get: { focusedField == .emotionName(id) },
            set: { isFocused in
                if isFocused {
                    focusField(.emotionName(id))
                } else if focusedField == .emotionName(id) {
                    focusedField = nil
                }
            }
        )
    }

    private var dateLine: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: viewModel.occurredAt)
    }

    private var sensationsSuggestions: [String] {
        let available = commonSensations.filter { !selectedSensations.contains($0.lowercased()) }
        let trimmed = currentSensationInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        guard !lower.isEmpty else { return available }
        return available.filter { $0.lowercased().hasPrefix(lower) }
    }

    private var shouldShowSensationSuggestions: Bool {
        !sensationsSuggestions.isEmpty && (focusedField == .sensations || viewModel.sensations.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private var selectedSensations: Set<String> {
        let tokens = viewModel.sensations
            .split { $0 == "," || $0 == "\n" }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        return Set(tokens)
    }

    private var currentSensationInput: String {
        let lines = viewModel.sensations.split(separator: "\n", omittingEmptySubsequences: false)
        let lastLine = lines.last.map(String.init) ?? ""
        let parts = lastLine.split(separator: ",", omittingEmptySubsequences: false)
        return parts.last.map(String.init) ?? ""
    }

    private func applySensationSuggestion(_ suggestion: String) {
        let lines = viewModel.sensations.split(separator: "\n", omittingEmptySubsequences: false)
        let lastLine = lines.last.map(String.init) ?? ""
        let parts = lastLine.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        let prefix = parts.dropLast().joined(separator: ", ").trimmingCharacters(in: .whitespacesAndNewlines)
        let newLine: String
        if prefix.isEmpty {
            newLine = "\(suggestion), "
        } else {
            newLine = "\(prefix), \(suggestion), "
        }

        if lines.isEmpty {
            viewModel.sensations = newLine
        } else {
            var updated = lines.map(String.init)
            updated[updated.count - 1] = newLine
            viewModel.sensations = updated.joined(separator: "\n")
        }
        viewModel.scheduleAutosave()
    }

    private func bindingForAutomaticThoughtFocus(id: String) -> Binding<Bool> {
        Binding(
            get: { focusedField == .automaticThought(id) },
            set: { isFocused in
                if isFocused {
                    focusField(.automaticThought(id))
                } else if focusedField == .automaticThought(id) {
                    focusedField = nil
                }
            }
        )
    }

    private func bindingForPrimaryThought() -> Binding<AutomaticThought>? {
        guard let first = viewModel.automaticThoughts.first,
              let index = viewModel.automaticThoughts.firstIndex(where: { $0.id == first.id }) else {
            let id = viewModel.addAutomaticThought()
            focusedField = .automaticThought(id)
            return nil
        }
        return $viewModel.automaticThoughts[index]
    }

    private func focusField(_ field: ThoughtEntryViewModel.Field?) {
        guard let field else {
            focusedField = nil
            return
        }
        focusedField = nil
        DispatchQueue.main.async {
            focusedField = field
        }
    }

    private func bindingForOutcomeReflection(thoughtId: String) -> Binding<String> {
        Binding(
            get: { viewModel.outcomeReflection(for: thoughtId) },
            set: { newValue in
                viewModel.updateOutcomeReflection(thoughtId: thoughtId, value: newValue)
            }
        )
    }

    private func bindingForOutcomeBelief(thoughtId: String) -> Binding<Double> {
        Binding(
            get: { Double(outcomeBelief(thoughtId: thoughtId)) },
            set: { newValue in
                updateOutcomeBelief(thoughtId: thoughtId, value: Metrics.clampPercent(newValue))
            }
        )
    }

    private func bindingForOutcomeEmotion(thoughtId: String, emotionId: UUID) -> Binding<Double> {
        Binding(
            get: { Double(outcomeEmotionValue(thoughtId: thoughtId, emotionId: emotionId)) },
            set: { newValue in
                updateOutcomeEmotion(thoughtId: thoughtId, emotionId: emotionId, value: Metrics.clampPercent(newValue))
            }
        )
    }

    private func outcomeBelief(thoughtId: String) -> Int {
        let thought = viewModel.automaticThoughts.first { $0.id == thoughtId }
        let beliefBefore = thought?.beliefBefore ?? 50
        return viewModel.ensureOutcome(for: thoughtId, beliefBefore: beliefBefore).beliefAfter
    }

    private func outcomeEmotionValue(thoughtId: String, emotionId: UUID) -> Int {
        let thought = viewModel.automaticThoughts.first { $0.id == thoughtId }
        let beliefBefore = thought?.beliefBefore ?? 50
        let outcome = viewModel.ensureOutcome(for: thoughtId, beliefBefore: beliefBefore)
        let before = viewModel.emotions.first { $0.id == emotionId }?.intensity ?? 50
        return outcome.emotionsAfter[emotionId.uuidString] ?? before
    }

    private func updateOutcomeBelief(thoughtId: String, value: Int) {
        let thought = viewModel.automaticThoughts.first { $0.id == thoughtId }
        let beliefBefore = thought?.beliefBefore ?? 50
        var outcome = viewModel.ensureOutcome(for: thoughtId, beliefBefore: beliefBefore)
        outcome.beliefAfter = value
        viewModel.outcomesByThought[thoughtId] = outcome
        if thoughtId == viewModel.automaticThoughts.first?.id {
            viewModel.beliefAfterMainThought = value
        }
    }

    private func updateOutcomeEmotion(thoughtId: String, emotionId: UUID, value: Int) {
        let thought = viewModel.automaticThoughts.first { $0.id == thoughtId }
        let beliefBefore = thought?.beliefBefore ?? 50
        var outcome = viewModel.ensureOutcome(for: thoughtId, beliefBefore: beliefBefore)
        outcome.emotionsAfter[emotionId.uuidString] = value
        viewModel.outcomesByThought[thoughtId] = outcome
    }

    private func adaptiveResponsePrompt(
        label: String,
        placeholder: String,
        thoughtId: String,
        key: AdaptivePrompts.TextKey
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            notesEditor(
                text: Binding(
                    get: { viewModel.adaptiveResponseValue(thoughtId: thoughtId, key: key) },
                    set: { newValue in
                        viewModel.updateAdaptiveResponse(thoughtId: thoughtId, key: key, value: newValue)
                    }
                ),
                placeholder: placeholder,
                field: .adaptiveResponseText(thoughtId: thoughtId, key: key),
                accessibilityLabel: label
            )
        }
    }

    private var aiReframeCallToAction: some View {
        let hasReframe = viewModel.aiReframe != nil
        return VStack(alignment: .leading, spacing: 10) {
            if hasReframe {
                Button {
                    router.push(.aiReframeNotes(entryId: viewModel.currentRecordId))
                } label: {
                    GlassCard(padding: AppTheme.cardPaddingCompact) {
                        HStack {
                            AppIconView(icon: .sparkles, size: AppTheme.iconSizeSmall)
                                .foregroundStyle(.secondary)
                            Text("View AI Reframe")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            AppIconView(icon: .chevronRight, size: AppTheme.iconSizeSmall)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            Button {
                handleUnlockTap()
            } label: {
                GlassCard(emphasized: true, padding: AppTheme.cardPaddingCompact) {
                    HStack(spacing: 10) {
                        AppIconView(icon: .sparkles, size: AppTheme.iconSizeSmall)
                            .foregroundStyle(.primary)
                        Text(isGeneratingReframe ? "Unlocking..." : (entitlementsManager.isPro ? "Unlock AI Reframe" : "Unlock AI Reframe"))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .frame(minHeight: AppTheme.minTapSize)
                }
            }
            .buttonStyle(.plain)
            .disabled(!isAIReframeEnabled || isGeneratingReframe)

            if !isAIReframeEnabled {
                Text("AI Reframe is disabled in Settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var hasCompleteEmotions: Bool {
        viewModel.emotions.contains { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var hasEmotions: Bool {
        viewModel.emotions.contains { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var hasAutomaticThoughts: Bool {
        viewModel.automaticThoughts.contains { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var emotionSuggestions: [String] {
        EmotionSuggestionEngine.rankedSuggestions(
            situation: viewModel.situation,
            sensations: viewModel.sensations,
            selected: viewModel.emotions.map { $0.name },
            limit: 12
        )
    }

    private var shouldShowEmotionSuggestions: Bool {
        if !hasEmotions {
            return !emotionSuggestions.isEmpty
        }
        return showEmotionSuggestions && !emotionSuggestions.isEmpty
    }

    private func applyEmotionSuggestion(_ suggestion: String) {
        let normalized = suggestion.lowercased()
        if let existing = viewModel.emotions.first(where: { $0.name.lowercased() == normalized }) {
            focusedField = .emotionName(existing.id)
            return
        }
        let id = viewModel.addEmotion()
        if let index = viewModel.emotions.firstIndex(where: { $0.id == id }) {
            viewModel.emotions[index].name = suggestion.capitalized
            viewModel.emotions[index].intensity = 60
        }
        focusedField = .emotionName(id)
    }


    private func continueToAutomaticThoughts() {
        viewModel.reveal(.automaticThoughts)
        viewModel.scrollTarget = .automaticThoughts
        viewModel.scheduleAutosave()
        if viewModel.automaticThoughts.isEmpty {
            let id = viewModel.addAutomaticThought()
            focusedField = .automaticThought(id)
        } else if let first = viewModel.automaticThoughts.first {
            focusedField = .automaticThought(first.id)
        }
    }

    private func restoreScrollPosition() {
        guard let draft = NotesDraftStore.load(), draft.entryId == viewModel.currentRecordId else { return }
        if !viewModel.isSectionVisible(draft.section) {
            viewModel.reveal(draft.section)
        }
        viewModel.scrollTarget = draft.section
    }

    private func triggerEmotionCompletion() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showEmotionCheck = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            withAnimation(.easeInOut(duration: 0.2)) {
                showEmotionCheck = false
            }
        }
    }

    private func handleUnlockTap() {
        guard isAIReframeEnabled else { return }
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
        let service = AIReframeService(valuesService: valuesService)
        let record = viewModel.currentRecordSnapshot()
        do {
            let depth = viewModel.aiReframeDepth ?? .deep
            let generated = try await service.generateReframe(for: record, depth: depth)
            viewModel.aiReframe = generated
            viewModel.aiReframeCreatedAt = Date()
            viewModel.aiReframeModel = service.modelName
            viewModel.aiReframePromptVersion = service.promptVersion
            viewModel.aiReframeDepth = depth
            await viewModel.saveNow()
            limitsManager.recordReframe()
            router.push(.aiReframeNotes(entryId: viewModel.currentRecordId))
        } catch {
            if let openAIError = error as? LegacyOpenAIClient.OpenAIError {
                switch openAIError {
                case .missingAPIKey:
                    alertMessage = "Missing OpenAI API key. Set OPENAI_API_KEY in build settings or scheme."
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

private struct DateTimeSheet: View {
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedDate: Date
    let onDismiss: () -> Void
    let onQuickSelect: (Date) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    GlassPillButton {
                        onQuickSelect(Date())
                    } label: {
                        Text("Now")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(notesPalette.textSecondary)
                    }

                    GlassPillButton {
                        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
                            onQuickSelect(yesterday)
                        }
                    } label: {
                        Text("Yesterday")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(notesPalette.textSecondary)
                    }
                }

                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(notesPalette.textPrimary)

                Spacer()
            }
            .padding(16)
            .navigationTitle("Edit Date & Time")
            .toolbarBackground(notesPalette.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    GlassPillButton {
                        onDismiss()
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(notesPalette.textSecondary)
                    }
                }
            }
        }
    }
}

private struct UnlockReframePromptSheet: View {
    let isLoading: Bool
    let onWatchAd: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Unlock AI Reframe")
                .font(.headline)
                .foregroundStyle(.primary)
            Text("Watch a short ad to unlock your AI reframe.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            GlassPillButton {
                onWatchAd()
            } label: {
                HStack(spacing: 8) {
                    AppIconView(icon: .sparkles, size: AppTheme.iconSizeSmall)
                        .foregroundStyle(.primary)
                    Text(isLoading ? "Loading ad..." : "Watch ad")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
            GlassPillButton {
                onUpgrade()
            } label: {
                Text("Upgrade to Pro")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(GlassBackground())
    }
}

#Preview("Partial Progress") {
    ThoughtEntryPreviewWrapper(record: PreviewThoughtRecord.partial)
        .modelContainer(.preview)
}

#Preview("Completed + AI Reframe") {
    ThoughtEntryPreviewWrapper(record: PreviewThoughtRecord.completed)
        .modelContainer(.preview)
}

private struct ThoughtEntryPreviewWrapper: View {
    let record: ThoughtRecord

    @State private var isReady = false
    @Environment(\.modelContext) private var modelContext

    init(record: ThoughtRecord) {
        self.record = record
    }

    var body: some View {
        Group {
            if isReady {
                ThoughtEntryNotesView(entryId: record.id, modelContext: modelContext, thoughtUsage: ThoughtUsageService())
                    .environmentObject(AppRouter())
                    .environmentObject(EntitlementsManager())
                    .environmentObject(LimitsManager())
                    .environmentObject(RewardedAdManager(adUnitID: RewardedAdManager.testAdUnitID))
                    .notesTheme()
            } else {
                Color.clear
                    .task {
                        let entry = JournalEntry(from: record)
                        modelContext.insert(entry)
                        try? modelContext.save()
                        isReady = true
                    }
            }
        }
    }
}

private enum PreviewThoughtRecord {
    static let partial: ThoughtRecord = {
        let now = DateUtils.nowIso()
        return ThoughtRecord(
            id: Identifiers.generateId(),
            title: "Morning spiral",
            createdAt: now,
            updatedAt: now,
            situationText: "I got a short reply from my manager and started spiraling.",
            sensations: ["Tight chest", "Racing heart"],
            automaticThoughts: [],
            emotions: [
                Emotion(id: Identifiers.generateId(), label: "anxious", intensityBefore: 65, intensityAfter: nil),
                Emotion(id: Identifiers.generateId(), label: "embarrassed", intensityBefore: 45, intensityAfter: nil)
            ],
            thinkingStyles: [],
            adaptiveResponses: [:],
            outcomesByThought: [:],
            beliefAfterMainThought: nil,
            notes: "",
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil
        )
    }()

    static let completed: ThoughtRecord = {
        let now = DateUtils.nowIso()
        let thoughtId = Identifiers.generateId()
        let emotionId = Identifiers.generateId()
        let reframe = AIReframeResult(
            validation: "That sounded tense and uncertain. It's understandable to feel on edge.",
            whatMightBeHappening: ["Your manager might be busy", "Short replies can feel abrupt"],
            cognitiveDistortions: [
                AIReframeResult.CognitiveDistortion(
                    label: "mind reading",
                    whyItFits: "You're assuming what they meant without evidence.",
                    gentleReframe: "A short reply doesn't necessarily mean dissatisfaction."
                )
            ],
            balancedThought: "I don't have enough information yet. I'll follow up if I need clarity.",
            microActionPlan: [AIReframeResult.MicroActionPlanItem(title: "Right now", steps: ["Take one deep breath", "Write a neutral follow-up"])],
            communicationScript: nil,
            selfCompassion: nil,
            realityCheckQuestions: nil,
            oneSmallExperiment: nil,
            summary: "Give yourself a moment before assuming the worst.",
            rawResponse: nil
        )
        return ThoughtRecord(
            id: Identifiers.generateId(),
            title: "AI Reframe",
            createdAt: now,
            updatedAt: now,
            situationText: "I saw a short reply and assumed the worst.",
            sensations: ["Tight chest"],
            automaticThoughts: [AutomaticThought(id: thoughtId, text: "I'm in trouble.", beliefBefore: 70)],
            emotions: [Emotion(id: emotionId, label: "anxious", intensityBefore: 60, intensityAfter: nil)],
            thinkingStyles: ["Mind reading"],
            adaptiveResponses: [
                thoughtId: AdaptiveResponsesForThought(
                    evidenceText: "They sent a short reply.",
                    evidenceBelief: 60,
                    alternativeText: "They're busy.",
                    alternativeBelief: 40,
                    outcomeText: "Wait for more context.",
                    outcomeBelief: 50,
                    friendText: "",
                    friendBelief: 0
                )
            ],
            outcomesByThought: [
                thoughtId: ThoughtOutcome(beliefAfter: 40, emotionsAfter: [emotionId: 35], reflection: "I can wait to see more.", isComplete: true)
            ],
            beliefAfterMainThought: 40,
            notes: "",
            aiReframe: reframe,
            aiReframeCreatedAt: Date(),
            aiReframeModel: "gpt-4o-mini",
            aiReframePromptVersion: "v2",
            aiReframeDepth: .deep
        )
    }()
}
