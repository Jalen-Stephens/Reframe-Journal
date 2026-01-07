import SwiftUI
import UIKit

struct AIReframeResultView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.notesPalette) private var notesPalette
    @AppStorage("aiReframeEnabled") private var aiReframeEnabled: Bool = false

    @StateObject private var viewModel: AIReframeViewModel
    @State private var didStart = false
    @State private var depth: AIReframeDepth
    @State private var expandedRealityChecks = false
    @State private var expandedDistortions = false
    @State private var expandedScripts = false

    let entryId: String
    let action: AIReframeAction

    init(entryId: String, repository: ThoughtRecordRepository, action: AIReframeAction = .view, depth: AIReframeDepth = .deep) {
        self.entryId = entryId
        self.action = action
        _depth = State(initialValue: depth)
        _viewModel = StateObject(wrappedValue: AIReframeViewModel(entryId: entryId, repository: repository, service: AIReframeService(), depth: depth))
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    Text("Journey: 10 steps")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(notesPalette.textSecondary)

                    if let result = viewModel.result {
                        journeyContent(result)
                    } else if let error = viewModel.error {
                        errorContent(error)
                    } else {
                        emptyContent
                    }

                    Text("AI suggestions aren't a substitute for professional care.")
                        .font(.system(size: 12))
                        .foregroundColor(notesPalette.textSecondary)
                        .padding(.top, 4)

                    if viewModel.result != nil {
                        SecondaryActionButton(title: "Regenerate", isDisabled: !aiReframeEnabled) {
                            Task { await viewModel.regenerateAndSave() }
                        }
                    }
                }
                .padding(16)
            }
            .allowsHitTesting(!viewModel.isGenerating)

            if viewModel.isGenerating {
                ReframeLoadingView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isGenerating)
        .background(notesPalette.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            await viewModel.loadExisting()
            depth = viewModel.currentDepth()
            guard !didStart else { return }
            didStart = true
            guard aiReframeEnabled else { return }
            switch action {
            case .view:
                break
            case .generate:
                if viewModel.result == nil {
                    await viewModel.generateAndSave()
                }
            case .regenerate:
                await viewModel.regenerateAndSave()
            }
        }
        .onChange(of: depth) { _, newValue in
            viewModel.updateDepth(newValue)
        }
    }

    private var header: some View {
        HStack {
            Button("Back") {
                router.pop()
            }
            .font(.system(size: 13, weight: .semibold))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .pillSurface(cornerRadius: 10)
            .foregroundColor(notesPalette.textPrimary)
            .buttonStyle(.plain)

            Spacer()

            Text("AI Reframe")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(notesPalette.textPrimary)

            Spacer()

            Color.clear
                .frame(width: 52, height: 28)
        }
    }

    private func journeyContent(_ result: AIReframeResult) -> some View {
        let display = AIReframeResult.normalizeFromRaw(result)
        return VStack(alignment: .leading, spacing: 18) {
            StepCard(step: 1, title: "You're not alone", subtitle: "Validation") {
                Text(nonEmptyText(display.validation, fallback: "Your feelings make sense given what you've shared."))
                    .font(.system(size: 13))
                    .foregroundColor(notesPalette.textPrimary)
            }

            StepCard(step: 2, title: "What might be happening", subtitle: "Alternative explanations") {
                bulletList(display.whatMightBeHappening)
            }

            AccordionView(isExpanded: $expandedDistortions) {
                Text("Step 3 · Cognitive distortions")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(notesPalette.textPrimary)
            } content: {
                VStack(alignment: .leading, spacing: 10) {
                    if let distortions = display.cognitiveDistortions, !distortions.isEmpty {
                        ForEach(distortions, id: \.self) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.label)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(notesPalette.textPrimary)
                                Text(item.whyItFits)
                                    .font(.system(size: 12))
                                    .foregroundColor(notesPalette.textSecondary)
                                Text(item.gentleReframe)
                                    .font(.system(size: 12))
                                    .foregroundColor(notesPalette.textPrimary)
                            }
                            .padding(12)
                            .pillSurface(cornerRadius: 10)
                        }
                    } else {
                        Text("No clear distortions detected.")
                            .font(.system(size: 12))
                            .foregroundColor(notesPalette.textSecondary)
                    }
                }
            }

            StepCard(step: 4, title: "Balanced thought", subtitle: "A more believable reframe") {
                VStack(alignment: .leading, spacing: 10) {
                    Text(nonEmptyText(display.balancedThought, fallback: "You're making progress by slowing down and re-evaluating this thought."))
                        .font(.system(size: 13))
                        .foregroundColor(notesPalette.textPrimary)
                    let isEmpty = (display.balancedThought ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    HStack(spacing: 10) {
                        SecondaryActionButton(title: "Copy Balanced Thought", isDisabled: isEmpty) {
                            copyText(display.balancedThought)
                        }
                        SecondaryActionButton(title: "Save as my new thought", isDisabled: isEmpty) {
                            copyText(display.balancedThought)
                        }
                    }
                }
            }

            AccordionView(isExpanded: $expandedRealityChecks) {
                Text("Step 5 · Reality-check questions")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(notesPalette.textPrimary)
            } content: {
                bulletList(display.realityCheckQuestions)
            }

            StepCard(step: 6, title: "Micro action plan", subtitle: "Small, doable steps") {
                VStack(alignment: .leading, spacing: 12) {
                    if let plans = display.microActionPlan, !plans.isEmpty {
                        ForEach(plans, id: \.title) { plan in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(plan.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(notesPalette.textPrimary)
                                bulletList(plan.steps)
                            }
                            .padding(12)
                            .pillSurface(cornerRadius: 10)
                        }
                    } else {
                        Text("No action plan was provided.")
                            .font(.system(size: 12))
                            .foregroundColor(notesPalette.textSecondary)
                    }
                }
            }

            AccordionView(isExpanded: $expandedScripts) {
                Text("Step 7 · Communication scripts")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(notesPalette.textPrimary)
            } content: {
                VStack(alignment: .leading, spacing: 12) {
                    textBlock(title: "Text message", text: display.communicationScript?.textMessage) {
                        copyText(display.communicationScript?.textMessage)
                    }
                    textBlock(title: "In-person", text: display.communicationScript?.inPerson) {
                        copyText(display.communicationScript?.inPerson)
                    }
                }
            }

            StepCard(step: 8, title: "Self-compassion lines", subtitle: "What you can say to yourself") {
                bulletList(display.selfCompassion)
            }

            StepCard(step: 9, title: "One small experiment", subtitle: "Test a belief gently") {
                VStack(alignment: .leading, spacing: 8) {
                    labeledParagraph(title: "Hypothesis", text: display.oneSmallExperiment?.hypothesis)
                    labeledParagraph(title: "Experiment", text: display.oneSmallExperiment?.experiment)
                    labeledBulletList(title: "What to observe", items: display.oneSmallExperiment?.whatToObserve)
                }
            }

            StepCard(step: 10, title: "Summary", subtitle: "Wrap-up") {
                Text(nonEmptyText(display.summary, fallback: "You took time to slow down and consider a more grounded view."))
                    .font(.system(size: 13))
                    .foregroundColor(notesPalette.textPrimary)
            }

        }
    }

    private func errorContent(_ error: String) -> some View {
        StepCard(step: 1, title: "We couldn't generate yet", subtitle: error) {
            PrimaryButton(label: "Retry", onPress: {
                Task { await viewModel.generateAndSave() }
            }, disabled: !aiReframeEnabled)
        }
    }

    private var emptyContent: some View {
        StepCard(step: 1, title: "Ready to generate?", subtitle: "Choose a depth first.") {
            VStack(alignment: .leading, spacing: 12) {
                if aiReframeEnabled {
                    PrimaryButton(label: "Generate Reframe") {
                        Task { await viewModel.generateAndSave() }
                    }
                } else {
                    Text("AI Reframe is disabled in Settings.")
                        .font(.system(size: 12))
                        .foregroundColor(notesPalette.textSecondary)
                    Button("Open Settings") {
                        router.push(.settings)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(notesPalette.accent)
                }
            }
        }
    }

    private func bulletList(_ items: [String]?) -> some View {
        let list = (items ?? [])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { isValidListItem($0) }
        if list.isEmpty {
            return AnyView(
                Text("No items provided.")
                    .font(.system(size: 12))
                    .foregroundColor(notesPalette.textSecondary)
            )
        }
        return AnyView(
            VStack(alignment: .leading, spacing: 6) {
                ForEach(list, id: \.self) { item in
                    Text("• \(item)")
                        .font(.system(size: 12))
                        .foregroundColor(notesPalette.textSecondary)
                }
            }
        )
    }

    private func isValidListItem(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return false }
        let scrubbed = trimmed
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "•", with: "")
            .replacingOccurrences(of: "-", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let lowered = scrubbed.lowercased()
        return lowered != "item" && lowered != "..." && lowered != "…"
    }

    private func labeledParagraph(title: String, text: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(notesPalette.textPrimary)
            Text(nonEmptyText(text, fallback: "Not provided."))
                .font(.system(size: 12))
                .foregroundColor(notesPalette.textSecondary)
        }
    }

    private func labeledBulletList(title: String, items: [String]?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(notesPalette.textPrimary)
            bulletList(items)
        }
    }

    private func textBlock(title: String, text: String?, onCopy: (() -> Void)? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(notesPalette.textPrimary)
            Text(nonEmptyText(text, fallback: "Not provided."))
                .font(.system(size: 12))
                .foregroundColor(notesPalette.textSecondary)
            if let onCopy {
                SecondaryActionButton(title: "Copy", isDisabled: (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    onCopy()
                }
            }
        }
        .padding(12)
        .pillSurface(cornerRadius: 10)
    }

    private func nonEmptyText(_ text: String?, fallback: String) -> String {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? fallback : trimmed
    }

    private func copyText(_ text: String?) {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return }
        UIPasteboard.general.string = trimmed
    }

}

private struct StepCard<Content: View>: View {
    @Environment(\.notesPalette) private var notesPalette
    let step: Int
    let title: String
    let subtitle: String
    let content: Content

    init(step: Int, title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.step = step
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("Step \(step)")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(notesPalette.accent)
                    .foregroundColor(notesPalette.onAccent)
                    .clipShape(Capsule())
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(notesPalette.textPrimary)
            }
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(notesPalette.textSecondary)
            }
            content
        }
        .padding(16)
        .cardSurface(cornerRadius: 16)
    }
}

private struct SecondaryActionButton: View {
    @Environment(\.notesPalette) private var notesPalette
    let title: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(title) {
            if !isDisabled {
                action()
            }
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(notesPalette.accent)
        .opacity(isDisabled ? 0.5 : 1)
        .disabled(isDisabled)
    }
}
