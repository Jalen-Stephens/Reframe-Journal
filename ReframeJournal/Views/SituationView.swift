import SwiftUI

struct SituationView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeManager: ThemeManager

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

    @State private var situationText: String = ""
    @State private var sensations: [String] = []
    @State private var customSensation: String = ""
    @State private var showCustomInput = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                WizardProgressView(step: 2, total: 6)
                Text("What led to the unpleasant emotion? What distressing physical sensations did you have?")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.theme.textSecondary)

                LabeledInput(label: "Situation", placeholder: "What happened?", text: $situationText, isMultiline: true)

                Text("Physical sensations")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.theme.textSecondary)

                Menu {
                    ForEach(availableSensations(), id: \.self) { sensation in
                        Button(sensation) {
                            addSensation(sensation)
                            showCustomInput = false
                        }
                    }
                    Button("Custom...") {
                        showCustomInput = true
                    }
                } label: {
                    HStack {
                        Text("Select common sensations")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.theme.textPrimary)
                        Spacer()
                        Text("▼")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(themeManager.theme.textSecondary)
                    }
                    .padding(10)
                    .background(themeManager.theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(themeManager.theme.border, lineWidth: 1)
                    )
                }

                if showCustomInput {
                    TextField("Describe your sensation (e.g., pressure in throat)", text: $customSensation)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(10)
                        .background(themeManager.theme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(themeManager.theme.border, lineWidth: 1)
                        )
                        .onSubmit {
                            addSensation(customSensation)
                            customSensation = ""
                            showCustomInput = false
                        }
                }

                FlowLayout(items: sensations) { item in
                    Button {
                        sensations.removeAll { $0 == item }
                    } label: {
                        HStack(spacing: 6) {
                            Text(item)
                            Text("✕")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeManager.theme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(themeManager.theme.muted)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(themeManager.theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(label: "Next") {
                Task {
                    var draft = appState.wizard.draft
                    draft.situationText = situationText
                    draft.sensations = sensations
                    appState.wizard.draft = draft
                    await appState.wizard.persistDraft(draft)
                    router.push(.wizardStep3)
                }
            }
            .padding(16)
            .background(themeManager.theme.background)
        }
        .onAppear {
            situationText = appState.wizard.draft.situationText
            sensations = appState.wizard.draft.sensations
        }
    }

    private func addSensation(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !sensations.contains(trimmed) {
            sensations.append(trimmed)
        }
    }

    private func availableSensations() -> [String] {
        commonSensations.filter { !sensations.contains($0) }
    }
}

struct FlowLayout<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    init(items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading) {
            FlexibleView(data: items, spacing: 8, alignment: .leading, content: content)
        }
    }
}

struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    @State private var availableWidth: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
                contentBody
            }
            .onAppear {
                availableWidth = geometry.size.width
            }
            .onChange(of: geometry.size.width) { newValue in
                availableWidth = newValue
            }
        }
        .frame(minHeight: 0)
    }

    private var contentBody: some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        return ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
            ForEach(Array(data), id: \.self) { item in
                content(item)
                    .padding(.trailing, spacing)
                    .padding(.bottom, spacing)
                    .alignmentGuide(.leading) { dimension in
                        if width + dimension.width > availableWidth {
                            width = 0
                            height -= dimension.height + spacing
                        }
                        let result = width
                        width += dimension.width + spacing
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        return result
                    }
            }
        }
    }
}
