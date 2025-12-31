import SwiftUI

struct EntryDetailView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var viewModel = EntryDetailViewModel(repository: ThoughtRecordRepository())

    let entryId: String

    @State private var isEditMenuOpen = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                Text("Loading...")
                    .foregroundColor(themeManager.theme.textSecondary)
                    .padding(16)
            } else if let record = viewModel.record {
                content(for: record)
            } else {
                Text("Entry not found")
                    .foregroundColor(themeManager.theme.textSecondary)
                    .padding(16)
            }
        }
        .background(themeManager.theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            await viewModel.load(id: entryId)
        }
    }

    private func content(for record: ThoughtRecord) -> some View {
        let situationTitle = record.situationText.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = situationTitle.isEmpty ? "Untitled situation" : situationTitle
        let timeLabel = DateUtils.formatRelativeDateTime(record.createdAt)
        let status = statusFor(record)
        let thoughts = normalizeThoughts(record)
        let emotionsBefore = normalizeEmotionsBefore(record)
        let adaptiveSummaries = normalizeAdaptiveSummaries(record)
        let mainThought = thoughts.first
        let outcomeByThought = mainThought.flatMap { record.outcomesByThought[$0.id] }
        let beliefAfter = record.beliefAfterMainThought ?? outcomeByThought?.beliefAfter
        let emotionsAfter = normalizeEmotionsAfter(record, thoughtId: mainThought?.id)
        let deltas = computeOutcomeDeltas(record)

        let changeItems: [String] = {
            var items: [String] = []
            if let belief = deltas.belief {
                items.append("Belief: \(belief.before)% -> \(belief.after)%")
            }
            for item in deltas.emotions.prefix(3) {
                items.append("\(item.label): \(item.before)% -> \(item.after)%")
            }
            return items
        }()

        let beforeSummaryItems: [String] = {
            var items: [String] = []
            if let mainThought {
                items.append("Main thought before: \(Metrics.clampPercent(mainThought.belief))%")
            }
            if !thoughts.isEmpty {
                items.append("Thought recorded")
            }
            if !emotionsBefore.isEmpty {
                items.append("Emotions noted: \(emotionsBefore.count)")
            }
            return items
        }()

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                VStack(alignment: .leading, spacing: 10) {
                    ExpandableTextView(text: title, lineLimit: 2, textStyle: .system(size: 18, weight: .semibold))
                    HStack {
                        Text(timeLabel)
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.theme.textSecondary)
                        Spacer()
                        ProgressPillView(status: status)
                    }
                }
                .padding(16)
                .cardSurface(cornerRadius: 16)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Outcome")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(themeManager.theme.textPrimary)
                        Spacer()
                        Text("Belief in main thought")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.theme.textSecondary)
                    }
                    Text(beliefAfter != nil ? "\(Metrics.clampPercent(beliefAfter ?? 0))%" : "Not recorded")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(themeManager.theme.textPrimary)

                    if emotionsAfter.isEmpty {
                        Text("No emotions recorded after.")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.theme.textSecondary)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(emotionsAfter, id: \.id) { emotion in
                                SlimMeterRowView(label: emotion.label, value: emotion.intensity, labelLines: 1)
                            }
                        }
                    }
                }
                .padding(16)
                .cardSurface(cornerRadius: 16)

                ChangeSummaryCardView(
                    title: changeItems.isEmpty ? "What changed" : "You made progress",
                    items: changeItems,
                    emptyState: "No changes recorded yet."
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Before snapshot")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(themeManager.theme.textPrimary)
                    if beforeSummaryItems.isEmpty {
                        Text("No before details saved.")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.theme.textSecondary)
                    } else {
                        ForEach(beforeSummaryItems, id: \.self) { item in
                            Text(item)
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.theme.textSecondary)
                        }
                    }
                }
                .padding(16)
                .cardSurface(cornerRadius: 16)

                SectionCardView(title: "Automatic thought at the time", subtitle: "How true this felt in the moment", collapsible: true) {
                    if thoughts.isEmpty {
                        Text("No automatic thought saved.")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.theme.textSecondary)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(thoughts, id: \.id) { thought in
                                SlimMeterRowView(label: thought.text, value: thought.belief, boldLabel: true)
                            }
                        }
                    }
                }

                SectionCardView(title: "Emotions you noticed", collapsible: true) {
                    if emotionsBefore.isEmpty {
                        Text("No emotions saved.")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.theme.textSecondary)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(emotionsBefore, id: \.id) { emotion in
                                SlimMeterRowView(label: emotion.label, value: emotion.intensity, labelLines: 1)
                            }
                        }
                    }
                }

                SectionCardView(title: "Adaptive responses", subtitle: "Reframing work you completed", collapsible: true) {
                    if adaptiveSummaries.isEmpty {
                        Text("No adaptive responses saved.")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.theme.textSecondary)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(adaptiveSummaries, id: \.thoughtId) { summary in
                                Button {
                                    router.push(.thoughtResponseDetail(entryId: record.id, thoughtId: summary.thoughtId))
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(summary.thoughtText)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(themeManager.theme.textPrimary)
                                                .lineLimit(2)
                                            Text("Original \(summary.originalBelief)%")
                                                .font(.system(size: 12))
                                                .foregroundColor(themeManager.theme.textSecondary)
                                        }
                                        Spacer()
                                        if summary.completedCount == summary.totalCount {
                                            ProgressPillView(status: .complete, label: "Complete")
                                        } else {
                                            Text("\(summary.completedCount)/\(summary.totalCount)")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(themeManager.theme.textSecondary)
                                        }
                                        Text(">")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(themeManager.theme.textSecondary)
                                    }
                                    .padding(12)
                                    .pillSurface(cornerRadius: 12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                PrimaryButton(label: "Done") {
                    router.path.removeLast()
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
        .sheet(isPresented: $isEditMenuOpen) {
            EditEntrySheet(record: record) {
                isEditMenuOpen = false
            }
        }
    }

    private var header: some View {
        HStack {
            Button("Back") {
                router.path.removeLast()
            }
            .font(.system(size: 13, weight: .semibold))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .pillSurface(cornerRadius: 10)
            .foregroundColor(themeManager.theme.textPrimary)
            .buttonStyle(.plain)

            Spacer()

            Text("Entry")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.theme.textPrimary)

            Spacer()

            Button("More") {
                isEditMenuOpen = true
            }
            .font(.system(size: 13, weight: .semibold))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .pillSurface(cornerRadius: 10)
            .foregroundColor(themeManager.theme.textPrimary)
            .buttonStyle(.plain)
        }
    }

    private func statusFor(_ record: ThoughtRecord) -> ProgressStatus {
        guard let thought = record.automaticThoughts.first else {
            return .inProgress
        }
        let isComplete = record.outcomesByThought[thought.id]?.isComplete == true
        return isComplete ? .complete : .inProgress
    }

    private func normalizeThoughts(_ record: ThoughtRecord) -> [NormalizedThought] {
        record.automaticThoughts.prefix(1).map {
            NormalizedThought(
                id: $0.id,
                text: $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled thought" : $0.text,
                belief: $0.beliefBefore
            )
        }
    }

    private func normalizeEmotionsBefore(_ record: ThoughtRecord) -> [NormalizedEmotion] {
        record.emotions.map {
            NormalizedEmotion(
                id: $0.id,
                label: $0.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled emotion" : $0.label,
                intensity: $0.intensityBefore
            )
        }
    }

    private func normalizeEmotionsAfter(_ record: ThoughtRecord, thoughtId: String?) -> [NormalizedEmotion] {
        guard let thoughtId, let outcome = record.outcomesByThought[thoughtId] else {
            return []
        }
        return record.emotions.compactMap { emotion in
            guard let intensity = outcome.emotionsAfter[emotion.id] else { return nil }
            let label = emotion.label.trimmingCharacters(in: .whitespacesAndNewlines)
            return NormalizedEmotion(id: emotion.id, label: label.isEmpty ? "Untitled emotion" : label, intensity: intensity)
        }
    }

    private func normalizeAdaptiveSummaries(_ record: ThoughtRecord) -> [AdaptiveSummary] {
        record.automaticThoughts.prefix(1).map { thought in
            let responses = record.adaptiveResponses[thought.id]
            let completedCount = AdaptivePrompts.all.reduce(0) { count, prompt in
                let text = valueForTextKey(prompt.textKey, in: responses)
                return count + (text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0 : 1)
            }
            return AdaptiveSummary(
                thoughtId: thought.id,
                thoughtText: thought.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled thought" : thought.text,
                originalBelief: thought.beliefBefore,
                completedCount: completedCount,
                totalCount: AdaptivePrompts.all.count
            )
        }
    }

    private func valueForTextKey(_ key: AdaptivePrompts.TextKey, in responses: AdaptiveResponsesForThought?) -> String {
        guard let responses else { return "" }
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

    private func computeOutcomeDeltas(_ record: ThoughtRecord) -> OutcomeDeltas {
        let mainThought = record.automaticThoughts.first
        let outcome = mainThought.flatMap { record.outcomesByThought[$0.id] }
        let beliefBefore = mainThought?.beliefBefore
        let beliefAfter = record.beliefAfterMainThought ?? outcome?.beliefAfter

        var belief: (before: Int, after: Int)? = nil
        if let beliefBefore, let beliefAfter {
            belief = (beliefBefore, beliefAfter)
        }

        guard let outcome = outcome, !outcome.emotionsAfter.isEmpty else {
            return OutcomeDeltas(belief: belief, emotions: [])
        }

        var beforeByLabel: [String: Int] = [:]
        var afterByLabel: [String: Int] = [:]

        for emotion in record.emotions {
            let label = emotion.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled emotion" : emotion.label
            let key = label.lowercased()
            beforeByLabel[key] = emotion.intensityBefore
            if let after = outcome.emotionsAfter[emotion.id] {
                afterByLabel[key] = after
            }
        }

        let emotions: [OutcomeDelta] = afterByLabel.compactMap { key, after in
            guard let before = beforeByLabel[key], before != after else { return nil }
            let label = record.emotions.first { $0.label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == key }?.label ?? "Untitled emotion"
            return OutcomeDelta(label: label, before: before, after: after, delta: after - before)
        }.sorted { abs($0.delta) > abs($1.delta) }

        return OutcomeDeltas(belief: belief, emotions: emotions)
    }
}

private struct NormalizedThought: Identifiable {
    let id: String
    let text: String
    let belief: Int
}

private struct NormalizedEmotion: Identifiable {
    let id: String
    let label: String
    let intensity: Int
}

private struct AdaptiveSummary: Identifiable {
    let id = UUID()
    let thoughtId: String
    let thoughtText: String
    let originalBelief: Int
    let completedCount: Int
    let totalCount: Int
}

private struct OutcomeDelta {
    let label: String
    let before: Int
    let after: Int
    let delta: Int
}

private struct OutcomeDeltas {
    let belief: (before: Int, after: Int)?
    let emotions: [OutcomeDelta]
}

private struct EditEntrySheet: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var themeManager: ThemeManager

    let record: ThoughtRecord
    let onDismiss: () -> Void

    private let sections: [(String, Route)] = [
        ("Date & time", .wizardStep1),
        ("Situation", .wizardStep2),
        ("Automatic thought", .wizardStep3),
        ("Emotions", .wizardStep4),
        ("Adaptive responses", .wizardStep5),
        ("Outcome", .wizardStep6)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit entry")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.theme.textPrimary)
            ForEach(sections, id: \.0) { section in
                Button {
                    appState.wizard.setDraft(record, isEditing: true)
                    Task { await appState.wizard.persistDraft(record) }
                    onDismiss()
                    router.push(section.1)
                } label: {
                    HStack {
                        Text(section.0)
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.theme.textPrimary)
                        Spacer()
                        Text(">")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(themeManager.theme.textSecondary)
                    }
                    .padding(12)
                    .pillSurface(cornerRadius: 10)
                }
                .buttonStyle(.plain)
            }
            Button("Cancel") {
                onDismiss()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(themeManager.theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
        .padding(16)
        .background(themeManager.theme.background)
        .presentationDetents([.medium])
    }
}
