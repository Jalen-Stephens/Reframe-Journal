// File: Views/AIReframeNotesView.swift
// Notes-style AI Reframe view matching the thought entry aesthetic

import SwiftUI
import UIKit

struct AIReframeNotesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: AppRouter
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: AIReframeNotesViewModel

    let entryId: String

    init(entryId: String, repository: ThoughtRecordRepository) {
        self.entryId = entryId
        _viewModel = StateObject(wrappedValue: AIReframeNotesViewModel(repository: repository))
    }
    
    // MARK: - Colors (matching NotesStyleEntryView)
    
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

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                notesHeader
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if viewModel.isLoading {
                            loadingState
                        } else if let record = viewModel.record, let result = record.aiReframe {
                            reframeContent(record: record, result: AIReframeResult.normalizeFromRaw(result))
                        } else {
                            emptyState
                        }
                        
                        // Bottom padding
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.loadIfNeeded(entryId: entryId)
        }
        .onAppear {
            AnalyticsService.shared.trackEvent("ai_reframe_accepted")
        }
    }
    
    // MARK: - Header
    
    private var notesHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(textSecondary)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text("AI Reframe")
                .font(.headline)
                .foregroundStyle(textPrimary)
            
            Spacer()
            
            // Share & More buttons
            HStack(spacing: 8) {
                if let shareText = viewModel.shareText {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(textSecondary)
                            .frame(width: 44, height: 44)
                    }
                }
                
                Menu {
                    Button {
                        UIPasteboard.general.string = viewModel.shareText ?? ""
                    } label: {
                        Label("Copy All", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(textSecondary)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
    
    // MARK: - Loading State
    
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading reframe...")
                .font(.subheadline)
                .foregroundStyle(textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(textTertiary)
            Text("AI Reframe not available")
                .font(.headline)
                .foregroundStyle(textSecondary)
            Text("Complete your thought entry to generate a reframe.")
                .font(.subheadline)
                .foregroundStyle(textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    // MARK: - Reframe Content
    
    private func reframeContent(record: ThoughtRecord, result: AIReframeResult) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title and date
            titleSection(record: record)
            
            // Validation
            if let validation = result.validation, !validation.isEmpty {
                reframeSection(
                    title: "VALIDATION",
                    content: { Text(validation).font(.body).foregroundStyle(textPrimary) }
                )
            }
            
            // What Might Be Happening
            if let items = result.whatMightBeHappening, !items.isEmpty {
                reframeSection(
                    title: "WHAT MIGHT BE HAPPENING",
                    content: { bulletList(items) }
                )
            }
            
            // Cognitive Distortions
            if let distortions = result.cognitiveDistortions, !distortions.isEmpty {
                reframeSection(
                    title: "COGNITIVE DISTORTIONS",
                    content: { distortionsView(distortions) }
                )
            }
            
            // Balanced Thought
            if let balanced = result.balancedThought, !balanced.isEmpty {
                reframeSection(
                    title: "BALANCED THOUGHT",
                    content: { Text(balanced).font(.body).foregroundStyle(textPrimary) }
                )
            }
            
            // Micro Action Plan
            if let plan = result.microActionPlan, !plan.isEmpty {
                reframeSection(
                    title: "MICRO ACTION PLAN",
                    content: { microActionView(plan) }
                )
            }
            
            // Communication Script
            if let script = result.communicationScript {
                if (script.textMessage?.isEmpty == false) || (script.inPerson?.isEmpty == false) {
                    reframeSection(
                        title: "COMMUNICATION SCRIPT",
                        content: { communicationScriptView(script) }
                    )
                }
            }
            
            // Self Compassion
            if let items = result.selfCompassion, !items.isEmpty {
                reframeSection(
                    title: "SELF COMPASSION",
                    content: { bulletList(items) }
                )
            }
            
            // Reality Check Questions
            if let items = result.realityCheckQuestions, !items.isEmpty {
                reframeSection(
                    title: "REALITY CHECK QUESTIONS",
                    content: { bulletList(items) }
                )
            }
            
            // One Small Experiment
            if let experiment = result.oneSmallExperiment {
                reframeSection(
                    title: "ONE SMALL EXPERIMENT",
                    content: { experimentView(experiment) }
                )
            }
            
            // Summary
            if let summary = result.summary, !summary.isEmpty {
                reframeSection(
                    title: "SUMMARY",
                    content: { Text(summary).font(.body).foregroundStyle(textPrimary) }
                )
            }
        }
    }
    
    // MARK: - Title Section
    
    private func titleSection(record: ThoughtRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(record.title?.isEmpty == false ? record.title! : "AI Reframe")
                .font(.title2.weight(.semibold))
                .foregroundStyle(textPrimary)
            
            Text(dateLine(for: record))
                .font(.subheadline)
                .foregroundStyle(textTertiary)
        }
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
    
    // MARK: - Section Template
    
    private func reframeSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section label
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(textTertiary)
                .kerning(1.2)
                .padding(.top, 24)
                .padding(.bottom, 4)
            
            content()
            
            // Divider
            Rectangle()
                .fill(dividerColor)
                .frame(height: 1)
                .padding(.top, 16)
        }
    }
    
    // MARK: - Bullet List
    
    private func bulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.body)
                        .foregroundStyle(textSecondary)
                    Text(item.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.body)
                        .foregroundStyle(textPrimary)
                }
            }
        }
    }
    
    // MARK: - Cognitive Distortions View
    
    private func distortionsView(_ distortions: [AIReframeResult.CognitiveDistortion]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(distortions.indices, id: \.self) { index in
                let distortion = distortions[index]
                VStack(alignment: .leading, spacing: 6) {
                    if !distortion.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(distortion.label.trimmingCharacters(in: .whitespacesAndNewlines))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(textPrimary)
                    }
                    
                    if !distortion.whyItFits.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(distortion.whyItFits.trimmingCharacters(in: .whitespacesAndNewlines))
                            .font(.body)
                            .foregroundStyle(textSecondary)
                    }
                    
                    if !distortion.gentleReframe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(distortion.gentleReframe.trimmingCharacters(in: .whitespacesAndNewlines))
                            .font(.body)
                            .foregroundStyle(textPrimary)
                            .italic()
                    }
                }
            }
        }
    }
    
    // MARK: - Micro Action Plan View
    
    private func microActionView(_ plan: [AIReframeResult.MicroActionPlanItem]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(plan.indices, id: \.self) { index in
                let item = plan[index]
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(textPrimary)
                    
                    if !item.steps.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(item.steps, id: \.self) { step in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(.body)
                                        .foregroundStyle(textSecondary)
                                    Text(step)
                                        .font(.body)
                                        .foregroundStyle(textPrimary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Communication Script View
    
    private func communicationScriptView(_ script: AIReframeResult.CommunicationScript) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let textMessage = script.textMessage, !textMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Text message")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(textSecondary)
                    Text(textMessage.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.body)
                        .foregroundStyle(textPrimary)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                        )
                }
            }
            
            if let inPerson = script.inPerson, !inPerson.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("In person")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(textSecondary)
                    Text(inPerson.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.body)
                        .foregroundStyle(textPrimary)
                }
            }
        }
    }
    
    // MARK: - Experiment View
    
    private func experimentView(_ experiment: AIReframeResult.OneSmallExperiment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let hypothesis = experiment.hypothesis, !hypothesis.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hypothesis")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(textSecondary)
                    Text(hypothesis)
                        .font(.body)
                        .foregroundStyle(textPrimary)
                }
            }
            
            if let action = experiment.experiment, !action.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Experiment")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(textSecondary)
                    Text(action)
                        .font(.body)
                        .foregroundStyle(textPrimary)
                }
            }
            
            if let observe = experiment.whatToObserve, !observe.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("What to observe")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(textSecondary)
                    ForEach(observe, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(.body)
                                .foregroundStyle(textSecondary)
                            Text(item)
                                .font(.body)
                                .foregroundStyle(textPrimary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func dateLine(for record: ThoughtRecord) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let date = record.aiReframeCreatedAt ?? DateUtils.parseIso(record.updatedAt) ?? Date()
        return "Generated \(formatter.string(from: date))"
    }
}

// MARK: - ViewModel

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
        if let validation = display.validation { sections.append("Validation:\n\(validation)") }
        if let happening = display.whatMightBeHappening, !happening.isEmpty {
            sections.append("What might be happening:\n" + happening.map { "• \($0)" }.joined(separator: "\n"))
        }
        if let balanced = display.balancedThought { sections.append("Balanced thought:\n\(balanced)") }
        if let summary = display.summary { sections.append("Summary:\n\(summary)") }
        return sections.joined(separator: "\n\n")
    }

    @MainActor
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
