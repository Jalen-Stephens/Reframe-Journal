import SwiftUI
import UIKit

struct AIReframeNotesView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: AIReframeNotesViewModel

    let entryId: String

    init(entryId: String, repository: ThoughtRecordRepository) {
        self.entryId = entryId
        _viewModel = StateObject(wrappedValue: AIReframeNotesViewModel(repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if viewModel.isLoading {
                    Text("Loading reframe...")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if let record = viewModel.record, let result = record.aiReframe {
                    let display = AIReframeResult.normalizeFromRaw(result)
                    Text(record.title?.isEmpty == false ? record.title! : "AI Reframe")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(dateLine(for: record))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    reframeSection(title: "Validation", text: display.validation ?? "Your feelings make sense.")
                    reframeSection(title: "What might be happening", text: bulletList(display.whatMightBeHappening))
                    reframeSection(title: "Cognitive distortions", text: distortionsText(display.cognitiveDistortions))
                    reframeSection(title: "Balanced thought", text: display.balancedThought ?? "A balanced perspective will appear here.")
                    reframeSection(title: "Micro action plan", text: microActionText(display.microActionPlan))
                    reframeSection(title: "Communication script", text: communicationScriptText(display.communicationScript))
                    reframeSection(title: "Self compassion", text: bulletList(display.selfCompassion))
                    reframeSection(title: "Reality check questions", text: bulletList(display.realityCheckQuestions))
                    reframeSection(title: "One small experiment", text: experimentText(display.oneSmallExperiment))
                    reframeSection(title: "Summary", text: display.summary ?? "")
                } else {
                    Text("AI Reframe not available.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(GlassBackground())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.loadIfNeeded(entryId: entryId)
        }
    }

    private var header: some View {
        HStack {
            GlassIconButton(icon: .chevronLeft, size: AppTheme.iconSizeMedium, accessibilityLabel: "Back") {
                router.pop()
            }
            Spacer()
            Text("AI Reframe")
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
            HStack(spacing: 10) {
                if let shareText = viewModel.shareText {
                    ShareLink(item: shareText) {
                        GlassIconButtonLabel(icon: .share)
                            .accessibilityLabel("Share")
                    }
                } else {
                    GlassIconButton(icon: .share, size: AppTheme.iconSizeMedium, accessibilityLabel: "Share") {}
                }
                Menu {
                    Button("Copy") {
                        UIPasteboard.general.string = viewModel.shareText ?? ""
                    }
                } label: {
                    GlassIconButtonLabel(icon: .ellipsis)
                        .accessibilityLabel("More")
                }
            }
        }
    }

    private func reframeSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .kerning(0.8)
            Text(text.isEmpty ? "—" : text)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding(.top, 4)
    }

    private func bulletList(_ items: [String]?) -> String {
        guard let items else { return "" }
        let trimmed = items.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return trimmed.map { "• \($0)" }.joined(separator: "\n")
    }

    private func distortionsText(_ distortions: [AIReframeResult.CognitiveDistortion]?) -> String {
        guard let distortions, !distortions.isEmpty else { return "" }
        return distortions.map { distortion in
            let label = distortion.label.trimmingCharacters(in: .whitespacesAndNewlines)
            let why = distortion.whyItFits.trimmingCharacters(in: .whitespacesAndNewlines)
            let reframe = distortion.gentleReframe.trimmingCharacters(in: .whitespacesAndNewlines)
            if label.isEmpty { return reframe }
            if why.isEmpty && reframe.isEmpty { return label }
            if reframe.isEmpty { return "\(label): \(why)" }
            if why.isEmpty { return "\(label): \(reframe)" }
            return "\(label): \(why)\n\(reframe)"
        }.joined(separator: "\n")
    }

    private func microActionText(_ plan: [AIReframeResult.MicroActionPlanItem]?) -> String {
        guard let plan, !plan.isEmpty else { return "" }
        return plan.map { item in
            let steps = item.steps.map { "• \($0)" }.joined(separator: "\n")
            if steps.isEmpty {
                return item.title
            }
            return item.title + "\n" + steps
        }.joined(separator: "\n\n")
    }

    private func communicationScriptText(_ script: AIReframeResult.CommunicationScript?) -> String {
        guard let script else { return "" }
        var lines: [String] = []
        if let text = script.textMessage, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("Text message:\n\(text)")
        }
        if let inPerson = script.inPerson, !inPerson.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("In person:\n\(inPerson)")
        }
        return lines.joined(separator: "\n\n")
    }

    private func experimentText(_ experiment: AIReframeResult.OneSmallExperiment?) -> String {
        guard let experiment else { return "" }
        var lines: [String] = []
        if let hypothesis = experiment.hypothesis, !hypothesis.isEmpty {
            lines.append("Hypothesis:\n\(hypothesis)")
        }
        if let action = experiment.experiment, !action.isEmpty {
            lines.append("Experiment:\n\(action)")
        }
        if let observe = experiment.whatToObserve, !observe.isEmpty {
            lines.append("What to observe:\n" + observe.map { "• \($0)" }.joined(separator: "\n"))
        }
        return lines.joined(separator: "\n\n")
    }

    private func dateLine(for record: ThoughtRecord) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let date = record.aiReframeCreatedAt ?? DateUtils.parseIso(record.updatedAt) ?? Date()
        return "Generated \(formatter.string(from: date))"
    }
}

final class AIReframeNotesViewModel: ObservableObject {
    @Published var record: ThoughtRecord?
    @Published var isLoading = true

    private let repository: ThoughtRecordRepository
    private var hasLoaded = false

    init(repository: ThoughtRecordRepository) {
        self.repository = repository
    }

    var shareText: String? {
        guard let record, let result = record.aiReframe else { return nil }
        let display = AIReframeResult.normalizeFromRaw(result)
        var sections: [String] = []
        if let validation = display.validation { sections.append("Validation: \(validation)") }
        if let happening = display.whatMightBeHappening, !happening.isEmpty {
            sections.append("What might be happening: " + happening.joined(separator: " • "))
        }
        if let balanced = display.balancedThought { sections.append("Balanced thought: \(balanced)") }
        if let summary = display.summary { sections.append("Summary: \(summary)") }
        return sections.joined(separator: "\n\n")
    }

    func loadIfNeeded(entryId: String) async {
        guard !hasLoaded else { return }
        hasLoaded = true
        defer { isLoading = false }
        do {
            record = try await repository.fetch(id: entryId)
        } catch {
            record = nil
        }
    }
}

private struct GlassIconButtonLabel: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: AppIcon

    var body: some View {
        AppIconView(icon: icon, size: AppTheme.iconSizeMedium)
            .foregroundStyle(.primary)
            .frame(width: AppTheme.iconButtonSize, height: AppTheme.iconButtonSize)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(
                Circle()
                    .fill(AppTheme.glassHighlightGradient(for: colorScheme))
                    .opacity(0.3)
            )
            .overlay(
                Circle()
                    .stroke(AppTheme.glassBorderColor(for: colorScheme), lineWidth: AppTheme.glassStrokeWidth)
            )
            .shadow(
                color: AppTheme.glassShadowColor(for: colorScheme),
                radius: AppTheme.glassShadowRadius * 0.5,
                x: 0,
                y: AppTheme.glassShadowYOffset * 0.4
            )
            .frame(minWidth: AppTheme.minTapSize, minHeight: AppTheme.minTapSize)
    }
}
