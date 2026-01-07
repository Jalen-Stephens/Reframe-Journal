import SwiftUI

struct ThoughtResponseDetailView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.notesPalette) private var notesPalette
    @StateObject private var viewModel: ThoughtResponseDetailViewModel

    let entryId: String
    let thoughtId: String

    init(entryId: String, thoughtId: String, repository: ThoughtRecordRepository) {
        self.entryId = entryId
        self.thoughtId = thoughtId
        _viewModel = StateObject(wrappedValue: ThoughtResponseDetailViewModel(repository: repository))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                Text("Loading...")
                    .foregroundColor(notesPalette.textSecondary)
                    .padding(16)
            } else if let record = viewModel.record {
                content(for: record)
            } else {
                Text("Entry not found")
                    .foregroundColor(notesPalette.textSecondary)
                    .padding(16)
            }
        }
        .background(notesPalette.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            await viewModel.loadIfNeeded(entryId: entryId)
        }
    }

    private func content(for record: ThoughtRecord) -> some View {
        let thought = record.automaticThoughts.first { $0.id == thoughtId }
        let responses = record.adaptiveResponses[thoughtId]

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button("Back") {
                        router.path.removeLast()
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .pillSurface(cornerRadius: 10)
                    .foregroundColor(notesPalette.textPrimary)
                    .buttonStyle(.plain)

                    Spacer()

                    Text("Adaptive responses")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(notesPalette.textPrimary)

                    Spacer()
                    Color.clear.frame(width: 58)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Thought")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(notesPalette.textSecondary)
                    ExpandableTextView(text: thought?.text ?? "Untitled thought", lineLimit: 2, textStyle: .system(size: 16, weight: .semibold))
                    Text("Original belief: \(Metrics.clampPercent(thought?.beliefBefore ?? 0))%")
                        .font(.system(size: 12))
                        .foregroundColor(notesPalette.textSecondary)
                }
                .padding(16)
                .cardSurface(cornerRadius: 16, shadow: false)

                ForEach(Array(AdaptivePrompts.all.enumerated()), id: \.element.id) { index, prompt in
                    let responseText = textValue(for: prompt.textKey, responses: responses)
                    let beliefValue = beliefValue(for: prompt.beliefKey, responses: responses)
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 28, height: 28)
                            .background(notesPalette.muted)
                            .clipShape(Circle())
                            .foregroundColor(notesPalette.textSecondary)
                        VStack(alignment: .leading, spacing: 10) {
                            Text(prompt.label)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(notesPalette.textPrimary)
                            VStack(alignment: .leading, spacing: 6) {
                                ExpandableTextView(
                                    text: responseText,
                                    lineLimit: 3,
                                    placeholder: "No response saved.",
                                    textStyle: .system(size: 13)
                                )
                            }
                            .padding(10)
                            .background(notesPalette.background)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(notesPalette.border, lineWidth: 1)
                            )

                            HStack {
                                Text("Belief in this response")
                                    .font(.system(size: 12))
                                    .foregroundColor(notesPalette.textSecondary)
                                Spacer()
                                Text("\(Metrics.clampPercent(beliefValue))%")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(notesPalette.textSecondary)
                            }

                            Slider(value: .constant(Double(Metrics.clampPercent(beliefValue))), in: 0...100, step: 1)
                                .disabled(true)
                                .accentColor(notesPalette.accent)
                        }
                    }
                    .padding(14)
                    .cardSurface(cornerRadius: 16, shadow: false)
                }
            }
            .padding(16)
        }
    }

    private func textValue(for key: AdaptivePrompts.TextKey, responses: AdaptiveResponsesForThought?) -> String {
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

    private func beliefValue(for key: AdaptivePrompts.BeliefKey, responses: AdaptiveResponsesForThought?) -> Int {
        guard let responses else { return 0 }
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
}
