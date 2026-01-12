// File: Views/UrgeEntryView.swift
// Urge entry view with mindfulness skills integration

import SwiftUI
import SwiftData

struct UrgeEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: AppRouter
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel: UrgeEntryViewModel
    @State private var isDateSheetPresented = false
    @State private var showStatusPicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @FocusState private var focusedField: UrgeField?
    
    enum UrgeField: Hashable {
        case situation
        case sensations
        case urgeDescription
    }
    
    private let sensationSuggestionList = [
        "Tight chest", "Racing heart", "Shallow breathing", "Tense shoulders",
        "Butterflies", "Sweaty palms", "Headache", "Nausea", "Restlessness", "Fatigue"
    ]
    
    private let emotionSuggestionList = [
        "Anxious", "Sad", "Angry", "Frustrated", "Shame", "Guilty",
        "Lonely", "Overwhelmed", "Embarrassed", "Hopeless", "Worried", "Irritated"
    ]
    
    private let mindfulnessSkills = [
        "Observe", "Describe", "Participate", "Nonjudgmentally", "One-Mindfully", "Effectively"
    ]
    
    init(entryId: String?, modelContext: ModelContext, thoughtUsage: ThoughtUsageService) {
        _viewModel = StateObject(wrappedValue: UrgeEntryViewModel(entryId: entryId, modelContext: modelContext, thoughtUsage: thoughtUsage))
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            dateSection
                            situationSection
                                .id("situation")
                            if viewModel.isSectionVisible(.sensations) {
                                sensationsSection
                                    .id("sensations")
                            }
                            if viewModel.isSectionVisible(.emotions) {
                                emotionsSection
                                    .id("emotions")
                            }
                            if viewModel.isSectionVisible(.urgeDescription) {
                                urgeDescriptionSection
                                    .id("urgeDescription")
                            }
                            if viewModel.isSectionVisible(.mindfulnessSkills) {
                                mindfulnessSkillsSection
                            }
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
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task { await viewModel.loadIfNeeded() }
        .onChange(of: viewModel.situation) { _, _ in
            viewModel.updateTitleFromSituation()
            viewModel.scheduleAutosave()
        }
        .onChange(of: viewModel.sensations) { _, _ in viewModel.scheduleAutosave() }
        .onChange(of: viewModel.emotions) { _, _ in viewModel.scheduleAutosave() }
        .onChange(of: viewModel.urgeDescription) { _, _ in viewModel.scheduleAutosave() }
        .onChange(of: viewModel.mindfulnessSkillsPracticed) { _, _ in viewModel.scheduleAutosave() }
        .sheet(isPresented: $isDateSheetPresented) { dateSheet }
        .sheet(isPresented: $showStatusPicker) {
            EntryStatusPicker(selectedStatus: .constant(nil)) {
                showStatusPicker = false
            }
        }
        .alert("", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
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
            
            Text(viewModel.title.isEmpty ? "New Urge Entry" : viewModel.title)
                .font(.headline)
                .foregroundStyle(textPrimary)
                .lineLimit(1)
            
            Spacer()
            
            Button {
                showStatusPicker = true
            } label: {
                Image(systemName: "tag")
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
    
    @ViewBuilder
    private var dateSheet: some View {
        VStack(spacing: 16) {
            HStack {
                Text("When did this happen?")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    isDateSheetPresented = false
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            DatePicker(
                "",
                selection: $viewModel.occurredAt,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .padding(.horizontal, 8)
            
            Spacer()
        }
        .background(backgroundColor)
    }
    
    // MARK: - Situation Section
    
    private var situationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("WHAT HAPPENED")
            
            UrgeExpandingTextArea(
                text: $viewModel.situation,
                placeholder: "Describe the situation...",
                isFocused: focusBinding(for: .situation),
                onSubmit: {
                    #if DEBUG
                    print("🟢 Situation onSubmit called")
                    #endif
                    advanceToNextField(from: .situation)
                }
            )
            
            sectionDivider
        }
    }
    
    // MARK: - Sensations Section
    
    private var sensationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("PHYSICAL SENSATIONS")
            
            UrgeExpandingTextArea(
                text: $viewModel.sensations,
                placeholder: "What did you notice in your body?",
                isFocused: focusBinding(for: .sensations),
                onSubmit: {
                    #if DEBUG
                    print("🟢 Sensations onSubmit called")
                    #endif
                    advanceToNextField(from: .sensations)
                }
            )
            
            sectionDivider
        }
    }
    
    // MARK: - Emotions Section
    
    private var emotionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("HOW DID YOU FEEL")
            
            // Emotion chips
            VStack(alignment: .leading, spacing: 8) {
                Text("Tap to add:")
                    .font(.caption)
                    .foregroundStyle(textTertiary)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(emotionSuggestionList, id: \.self) { emotion in
                        let isSelected = viewModel.emotions.contains { $0.name.lowercased() == emotion.lowercased() }
                        Button {
                            toggleEmotion(emotion)
                        } label: {
                            HStack(spacing: 4) {
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                Text(emotion)
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
            
            // Intensity sliders
            if !viewModel.emotions.isEmpty {
                VStack(spacing: 12) {
                    ForEach($viewModel.emotions) { $emotion in
                        if !emotion.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            HStack(spacing: 12) {
                                Text(emotion.name)
                                    .font(.subheadline)
                                    .foregroundStyle(textPrimary)
                                    .frame(width: 100, alignment: .leading)
                                
                                Slider(
                                    value: Binding(
                                        get: { Double(emotion.intensity) },
                                        set: { emotion.intensity = Int($0) }
                                    ),
                                    in: 0...100,
                                    step: 1
                                )
                                .tint(textSecondary)
                                
                                Text("\(emotion.intensity)")
                                    .font(.footnote.monospacedDigit())
                                    .foregroundStyle(textTertiary)
                                    .frame(width: 28, alignment: .trailing)
                                
                                Button {
                                    viewModel.removeEmotion(id: emotion.id)
                                } label: {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 16))
                                        .foregroundStyle(textTertiary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.top, 8)
            }
            
            sectionDivider
        }
        .onAppear {
            viewModel.reveal(.urgeDescription)
        }
    }
    
    // MARK: - Urge Description Section
    
    private var urgeDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("THE URGE")
            
            UrgeExpandingTextArea(
                text: $viewModel.urgeDescription,
                placeholder: "Describe the urge...",
                isFocused: focusBinding(for: .urgeDescription),
                onSubmit: {
                    #if DEBUG
                    print("🟢 UrgeDescription onSubmit called")
                    #endif
                    viewModel.reveal(.mindfulnessSkills)
                    focusedField = nil
                }
            )
            
            sectionDivider
        }
    }
    
    // MARK: - Mindfulness Skills Section
    
    private var mindfulnessSkillsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("MINDFULNESS SKILLS")
            
            Text("Which mindfulness skills did you practice?")
                .font(.subheadline)
                .foregroundStyle(textSecondary)
                .padding(.bottom, 8)
            
            // Skill selection chips
            VStack(alignment: .leading, spacing: 8) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                    ForEach(mindfulnessSkills, id: \.self) { skill in
                        let isSelected = viewModel.mindfulnessSkillsPracticed.contains(skill)
                        Button {
                            viewModel.toggleMindfulnessSkill(skill)
                        } label: {
                            HStack(spacing: 4) {
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                Text(skill)
                                    .font(.footnote)
                            }
                            .foregroundStyle(isSelected ? textPrimary : textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
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
            
            // Mindfulness guidance cards
            if !viewModel.mindfulnessSkillsPracticed.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Practice guidance:")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(textSecondary)
                        .padding(.top, 8)
                    
                    ForEach(viewModel.mindfulnessSkillsPracticed, id: \.self) { skill in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(skill)
                                .font(.headline)
                                .foregroundStyle(textPrimary)
                            Text(descriptionForSkill(skill))
                                .font(.subheadline)
                                .foregroundStyle(textSecondary)
                            if !instructionsForSkill(skill).isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(instructionsForSkill(skill), id: \.self) { instruction in
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("•")
                                                .foregroundStyle(textTertiary)
                                            Text(instruction)
                                                .font(.caption)
                                                .foregroundStyle(textSecondary)
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                        )
                    }
                }
            }
            
            sectionDivider
        }
    }
    
    // MARK: - Helper Functions
    
    private func toggleEmotion(_ name: String) {
        let lowercased = name.lowercased()
        if let index = viewModel.emotions.firstIndex(where: { $0.name.lowercased() == lowercased }) {
            viewModel.emotions.remove(at: index)
        } else {
            let item = EmotionItem(id: UUID(), name: name, intensity: 50)
            viewModel.emotions.append(item)
        }
        if viewModel.emotions.isEmpty {
            _ = viewModel.addEmotion()
        }
    }
    
    private func descriptionForSkill(_ skill: String) -> String {
        switch skill {
        case "Observe": return MindfulnessContent.Observe.description
        case "Describe": return MindfulnessContent.Describe.description
        case "Participate": return MindfulnessContent.Participate.description
        case "Nonjudgmentally": return MindfulnessContent.Nonjudgmentally.description
        case "One-Mindfully": return MindfulnessContent.OneMindfully.description
        case "Effectively": return MindfulnessContent.Effectively.description
        default: return ""
        }
    }
    
    private func instructionsForSkill(_ skill: String) -> [String] {
        switch skill {
        case "Observe": return MindfulnessContent.Observe.instructions
        case "Describe": return MindfulnessContent.Describe.instructions
        case "Participate": return MindfulnessContent.Participate.instructions
        case "Nonjudgmentally": return MindfulnessContent.Nonjudgmentally.instructions
        case "One-Mindfully": return MindfulnessContent.OneMindfully.instructions
        case "Effectively": return MindfulnessContent.Effectively.instructions
        default: return []
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
    
    // MARK: - Colors
    
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
    
    // MARK: - Focus Management
    
    private func focusBinding(for field: UrgeField) -> Binding<Bool> {
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
    
    private func advanceToNextField(from current: UrgeField) {
        #if DEBUG
        print("🟡 advanceToNextField: Current field = \(current)")
        #endif
        
        let next: UrgeField? = {
            switch current {
            case .situation:
                viewModel.reveal(.sensations)
                return .sensations
            case .sensations:
                viewModel.reveal(.emotions)
                viewModel.reveal(.urgeDescription)
                return .urgeDescription
            case .urgeDescription:
                viewModel.reveal(.mindfulnessSkills)
                return nil
            }
        }()
        
        if let next {
            #if DEBUG
            print("🟡 advanceToNextField: Setting focus to \(next)")
            #endif
            // Small delay to ensure view updates
            DispatchQueue.main.async {
                self.focusedField = next
            }
        } else {
            #if DEBUG
            print("🟡 advanceToNextField: Clearing focus (reached end)")
            #endif
            focusedField = nil
        }
    }
    
    private func scrollId(for field: UrgeField) -> String {
        switch field {
        case .situation: return "situation"
        case .sensations: return "sensations"
        case .urgeDescription: return "urgeDescription"
        }
    }
}

// MARK: - Expanding Text Area Component

private struct UrgeExpandingTextArea: View {
    @Binding var text: String
    let placeholder: String
    @Binding var isFocused: Bool
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
            
            // The actual text editor
            UrgeExpandingTextEditor(
                text: $text,
                isFocused: $isFocused,
                onSubmit: onSubmit
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Expanding Text Editor (UIKit with proper sizing)

private struct UrgeExpandingTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    var onSubmit: (() -> Void)?
    
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
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        // Ensure delegate is set
        if view.delegate == nil {
            view.delegate = context.coordinator
        }
        return view
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
            uiView.invalidateIntrinsicContentSize()
        }
        if isFocused, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        }
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? (UIScreen.main.bounds.width - 40)
        let fittingSize = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let height = max(44, ceil(fittingSize.height))
        return CGSize(width: width, height: height)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UITextViewDelegate {
        private let parent: UrgeExpandingTextEditor
        
        init(_ parent: UrgeExpandingTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text ?? ""
            textView.invalidateIntrinsicContentSize()
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            #if DEBUG
            print("🔵 UrgeExpandingTextEditor: textViewDidBeginEditing")
            #endif
            parent.isFocused = true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            // Let SwiftUI manage focus state
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // Handle Enter/Return key
            if text == "\n" {
                #if DEBUG
                print("🔵 UrgeExpandingTextEditor: Enter key pressed, calling onSubmit")
                #endif
                parent.onSubmit?()
                return false
            }
            return true
        }
    }
}
