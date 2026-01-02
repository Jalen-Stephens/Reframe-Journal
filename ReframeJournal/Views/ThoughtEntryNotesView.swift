import SwiftUI

struct ThoughtEntryNotesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ThoughtEntryViewModel
    @State private var focusedField: ThoughtEntryViewModel.Field?
    @State private var isDateSheetPresented = false

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

    init(entryId: String?, repository: ThoughtRecordRepository, thoughtUsage: ThoughtUsageService) {
        let store = ThoughtEntryStore(repository: repository)
        _viewModel = StateObject(wrappedValue: ThoughtEntryViewModel(entryId: entryId, store: store, thoughtUsage: thoughtUsage))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
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
                        placeholderSection(section: .automaticThoughts, title: "AUTOMATIC THOUGHTS", message: "Coming soon")
                    }
                    if viewModel.isSectionVisible(.evidence) {
                        GlassDivider()
                        placeholderSection(section: .evidence, title: "EVIDENCE FOR / AGAINST", message: "Coming soon")
                    }
                    if viewModel.isSectionVisible(.balanced) {
                        GlassDivider()
                        placeholderSection(section: .balanced, title: "BALANCED THOUGHT", message: "Coming soon")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(GlassBackground())
            .onChange(of: focusedField) { newValue in
                guard let newValue, newValue != .title else { return }
                let section = viewModel.section(for: newValue)
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(section, anchor: .top)
                }
            }
            .onChange(of: viewModel.scrollTarget) { newTarget in
                guard let newTarget else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(newTarget, anchor: .top)
                }
                viewModel.scrollTarget = nil
            }
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
            .presentationDetents([.medium])
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .onChange(of: viewModel.situation) { _ in
            viewModel.updateTitleFromSituation()
            viewModel.scheduleAutosave()
        }
        .onChange(of: viewModel.sensations) { _ in
            viewModel.scheduleAutosave()
        }
        .onChange(of: viewModel.emotions) { _ in
            viewModel.scheduleAutosave()
        }
        .onChange(of: viewModel.occurredAt) { _ in
            viewModel.scheduleAutosave()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                GlassIconButton(icon: .chevronLeft, size: AppTheme.iconSizeMedium, accessibilityLabel: "Back") {
                    dismiss()
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
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 6) {
                        AppIconView(icon: .check, size: AppTheme.iconSizeSmall)
                            .foregroundStyle(.primary)
                        Text("Done")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.primary)
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

            if focusedField == .sensations, !sensationsSuggestions.isEmpty {
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
            GlassSectionHeader(text: "EMOTIONS")

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

    private func placeholderSection(section: ThoughtEntryViewModel.Section, title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            GlassSectionHeader(text: title)
            GlassCard(padding: AppTheme.cardPaddingCompact) {
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            }
        }
        .id(section)
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
        let next = viewModel.nextField(after: field)
        focusedField = next
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
                    focusedField = field
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
                    focusedField = .emotionName(id)
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

}

private struct DateTimeSheet: View {
    @Binding var selectedDate: Date
    let onDismiss: () -> Void
    let onQuickSelect: (Date) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Button("Now") {
                        onQuickSelect(Date())
                    }
                    .buttonStyle(.bordered)

                    Button("Yesterday") {
                        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
                            onQuickSelect(yesterday)
                        }
                    }
                    .buttonStyle(.bordered)

                    Button("Custom...") {}
                        .buttonStyle(.bordered)
                }

                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)

                Spacer()
            }
            .padding(16)
            .navigationTitle("Edit Date & Time")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ThoughtEntryNotesView(entryId: nil, repository: ThoughtRecordRepository(store: ThoughtRecordStore()), thoughtUsage: ThoughtUsageService())
        .environmentObject(ThemeManager())
}
