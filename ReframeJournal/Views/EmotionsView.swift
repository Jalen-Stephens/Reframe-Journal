import SwiftUI

struct EmotionsView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeManager: ThemeManager

    @FocusState private var focusedField: FocusField?

    private let commonEmotions = [
        "Anxious",
        "Sad",
        "Angry",
        "Frustrated",
        "Shame",
        "Guilty",
        "Lonely",
        "Overwhelmed",
        "Embarrassed",
        "Hopeless"
    ]

    @State private var emotionLabel: String = ""
    @State private var customEmotion: String = ""
    @State private var isCustomEmotion: Bool = false
    @State private var intensityValue: Double = 50
    @State private var showPicker = false
    @State private var editId: String? = nil
    @State private var pendingDeleteId: String? = nil

    private let customEmotionFieldId = "customEmotionField"

    private enum FocusField: Hashable {
        case customEmotion
    }

    var body: some View {
        ScrollViewReader { proxy in
            StepContentContainer(title: "Emotions", step: 4, total: 6) {
                Text("What emotion/s did you feel at the time? How intense was the emotion (0-100%)?")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.theme.textSecondary)

                Text("Emotion")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.theme.textSecondary)

                Button {
                    showPicker = true
                } label: {
                    HStack {
                        Text(displayLabel())
                            .font(.system(size: 15))
                            .foregroundColor(emotionLabel.isEmpty ? themeManager.theme.placeholder : themeManager.theme.textPrimary)
                        Spacer()
                        Text("▼")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(themeManager.theme.textSecondary)
                    }
                    .padding(10)
                    .pillSurface(cornerRadius: 6)
                }
                .buttonStyle(.plain)

                if isCustomSelected() {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Custom emotion")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.theme.textSecondary)
                        TextField("Describe your emotion", text: $customEmotion)
                            .textFieldStyle(PlainTextFieldStyle())
                            .submitLabel(.done)
                            .onSubmit {
                                dismissKeyboard()
                            }
                            .padding(10)
                            .foregroundColor(themeManager.theme.textPrimary)
                            .cardSurface(cornerRadius: 8, shadow: false)
                            .focused($focusedField, equals: .customEmotion)
                    }
                    .id(customEmotionFieldId)
                }

                if editId != nil {
                    HStack {
                        Text("Editing emotion")
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.theme.textSecondary)
                        Spacer()
                        Button("Cancel edit") {
                            resetInputs()
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(themeManager.theme.accent)
                    }
                }

                VStack(spacing: 10) {
                    Text("\(Metrics.clampPercent(intensityValue))%")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(themeManager.theme.textPrimary)
                    Text("How intense was this emotion?")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.theme.textSecondary)
                    Slider(value: $intensityValue, in: 0...100, step: 1)
                        .accentColor(themeManager.theme.accent)
                    Text("0 = not at all, 100 = most intense")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.theme.textSecondary)
                }

                PrimaryButton(
                    label: editId != nil ? "Save changes" : "Add emotion",
                    onPress: submitEmotion,
                    disabled: resolvedLabel().isEmpty
                )

                if appState.wizard.draft.emotions.isEmpty {
                    Text("Add at least one emotion to continue.")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.theme.textSecondary)
                        .padding(.top, 4)
                }

                VStack(spacing: 12) {
                    ForEach(appState.wizard.draft.emotions) { emotion in
                        ThoughtCardView(
                            text: emotion.label,
                            belief: emotion.intensityBefore,
                            badgeLabel: "Intensity",
                            onEdit: { startEdit(emotion) },
                            onRemove: { pendingDeleteId = emotion.id }
                        )
                    }
                }
            }
            .background(themeManager.theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                StepBottomNavBar(
                    onBack: { router.pop() },
                    onNext: nextStep,
                    isNextDisabled: appState.wizard.draft.emotions.isEmpty
                )
            }
            .sheet(isPresented: $showPicker) {
                emotionPicker
            }
            .confirmationDialog("Remove emotion?", isPresented: Binding(
                get: { pendingDeleteId != nil },
                set: { if !$0 { pendingDeleteId = nil } }
            )) {
                Button("Remove", role: .destructive) {
                    if let id = pendingDeleteId {
                        appState.wizard.draft.emotions.removeAll { $0.id == id }
                    }
                    pendingDeleteId = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingDeleteId = nil
                }
            }
            .onChange(of: isCustomEmotion) { newValue in
                if newValue {
                    DispatchQueue.main.async {
                        focusedField = .customEmotion
                        withAnimation {
                            proxy.scrollTo(customEmotionFieldId, anchor: .center)
                        }
                    }
                } else {
                    focusedField = nil
                }
            }
        }
    }

    private func displayLabel() -> String {
        if isCustomSelected() {
            return customEmotion.isEmpty ? "Custom..." : customEmotion
        }
        return emotionLabel.isEmpty ? "Select an emotion" : emotionLabel
    }

    private func isCustomSelected() -> Bool {
        isCustomEmotion
    }

    private func resolvedLabel() -> String {
        let label = isCustomSelected() ? customEmotion : emotionLabel
        return label.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func submitEmotion() {
        let label = resolvedLabel()
        guard !label.isEmpty else { return }
        let intensity = Metrics.clampPercent(intensityValue)
        if let editId {
            appState.wizard.draft.emotions = appState.wizard.draft.emotions.map { emotion in
                if emotion.id == editId {
                    return Emotion(id: emotion.id, label: label, intensityBefore: intensity, intensityAfter: emotion.intensityAfter)
                }
                return emotion
            }
        } else {
            appState.wizard.draft.emotions.append(
                Emotion(id: Identifiers.generateId(), label: label, intensityBefore: intensity, intensityAfter: nil)
            )
        }
        resetInputs()
    }

    private func startEdit(_ emotion: Emotion) {
        editId = emotion.id
        intensityValue = Double(emotion.intensityBefore)
        if commonEmotions.contains(emotion.label) {
            emotionLabel = emotion.label
            customEmotion = ""
            isCustomEmotion = false
        } else {
            emotionLabel = "Custom..."
            customEmotion = emotion.label
            isCustomEmotion = true
        }
    }

    private func resetInputs() {
        emotionLabel = ""
        customEmotion = ""
        intensityValue = 50
        editId = nil
        isCustomEmotion = false
    }

    private func nextStep() {
        Task {
            await appState.wizard.persistDraft()
            router.push(.wizardStep5)
        }
    }

    private var emotionPicker: some View {
        let usedLabels = appState.wizard.draft.emotions.map { $0.label }
        let available = commonEmotions.filter { emotion in
            if let editId, emotionLabel == emotion {
                return true
            }
            return !usedLabels.contains(emotion)
        }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Select an emotion")
                .font(.system(size: 16, weight: .semibold))
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(available, id: \.self) { emotion in
                        Button(emotion) {
                            emotionLabel = emotion
                            customEmotion = ""
                            isCustomEmotion = false
                            showPicker = false
                        }
                        .font(.system(size: 15))
                        .foregroundColor(themeManager.theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button("Custom...") {
                        emotionLabel = "Custom..."
                        isCustomEmotion = true
                        showPicker = false
                    }
                    .font(.system(size: 15))
                    .foregroundColor(themeManager.theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(16)
        .presentationDetents([.medium])
    }
}
