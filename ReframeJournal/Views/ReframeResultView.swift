// File: Views/ReframeResultView.swift
import SwiftUI

struct ReframeResultView: View {
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.dismiss) private var dismiss
    let thoughtId: UUID
    @ObservedObject private var store: ThoughtStore
    @ObservedObject private var entitlements: EntitlementsManager
    @ObservedObject private var limits: LimitsManager
    @ObservedObject private var adManager: RewardedAdManager
    private let openAIClient: AnyOpenAIClient

    @StateObject private var viewModel: ReframeResultViewModel

    init(
        thoughtId: UUID,
        store: ThoughtStore,
        entitlements: EntitlementsManager,
        limits: LimitsManager,
        adManager: RewardedAdManager,
        openAIClient: AnyOpenAIClient
    ) {
        self.thoughtId = thoughtId
        _store = ObservedObject(wrappedValue: store)
        _entitlements = ObservedObject(wrappedValue: entitlements)
        _limits = ObservedObject(wrappedValue: limits)
        _adManager = ObservedObject(wrappedValue: adManager)
        self.openAIClient = openAIClient
        _viewModel = StateObject(wrappedValue: ReframeResultViewModel(
            store: store,
            entitlements: entitlements,
            limits: limits,
            adManager: adManager,
            openAIClient: openAIClient
        ))
    }

    var body: some View {
        let thought = store.thought(id: thoughtId)
        let response = thought?.reframeResponse

        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let thought {
                        Text("Your Thought")
                            .font(.headline)
                        Text(thought.text)
                            .font(.title3.weight(.semibold))
                    }

                    if let response {
                        JourneySection(title: "Summary") {
                            Text(response.summary)
                        }

                        JourneySection(title: "Cognitive Distortions Detected") {
                            BulletList(items: response.cognitiveDistortionsDetected)
                        }

                        JourneySection(title: "Alternative Thoughts") {
                            BulletList(items: response.alternativeThoughts)
                        }

                        JourneySection(title: "Action Steps") {
                            BulletList(items: response.actionSteps)
                        }

                        JourneySection(title: "Compassionate Coach") {
                            Text(response.compassionateCoachMessage)
                        }

                        JourneySection(title: "Suggested Experiment") {
                            Text(response.suggestedExperiment)
                        }
                    } else {
                        Text("Reframe not available.")
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        guard let thought else { return }
                        viewModel.regenerate(for: thought)
                    } label: {
                        Text(viewModel.isGenerating ? "Regenerating..." : "Regenerate")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading || thought == nil)
                }
                .padding(24)
            }
            .scrollContentBackground(.hidden)
            .background(notesPalette.background)
            .allowsHitTesting(!viewModel.isGenerating)

            if viewModel.isGenerating {
                ReframeLoadingView(message: "Taking a moment to refresh this reframe...")
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isGenerating)
        .navigationTitle("Reframe")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                GlassIconButton(icon: .chevronLeft, size: AppTheme.iconSizeMedium, accessibilityLabel: "Back") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $viewModel.isPresentingAdSheet) {
            AdGateSheet(
                onWatchAd: {
                    guard let thought else { return }
                    viewModel.watchAdAndRegenerate(for: thought)
                },
                onUpgrade: {
                    viewModel.isPresentingAdSheet = false
                    viewModel.isPresentingPaywall = true
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $viewModel.isPresentingPaywall) {
            PaywallView()
        }
        .alert("Notice", isPresented: $viewModel.isPresentingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        }
    }
}

private struct JourneySection<Content: View>: View {
    @Environment(\.notesPalette) private var notesPalette
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(notesPalette.surface)
        )
    }
}

private struct BulletList: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("-")
                    Text(item)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

@MainActor
final class ReframeResultViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var isGenerating: Bool = false
    @Published var isPresentingAdSheet: Bool = false
    @Published var isPresentingPaywall: Bool = false
    @Published var isPresentingError: Bool = false
    @Published var errorMessage: String?

    private let store: ThoughtStore
    private let entitlements: EntitlementsManager
    private let limits: LimitsManager
    private let adManager: RewardedAdManager
    private let openAIClient: AnyOpenAIClient

    init(
        store: ThoughtStore,
        entitlements: EntitlementsManager,
        limits: LimitsManager,
        adManager: RewardedAdManager,
        openAIClient: AnyOpenAIClient
    ) {
        self.store = store
        self.entitlements = entitlements
        self.limits = limits
        self.adManager = adManager
        self.openAIClient = openAIClient
    }

    func regenerate(for thought: Thought) {
        guard !isLoading else { return }
        if entitlements.isPro {
            Task { await regenerate(thought: thought, requiresAd: false) }
        } else {
            isPresentingAdSheet = true
        }
    }

    func watchAdAndRegenerate(for thought: Thought) {
        guard !isLoading else { return }
        isPresentingAdSheet = false
        Task { await regenerate(thought: thought, requiresAd: true) }
    }

    private func regenerate(thought: Thought, requiresAd: Bool) async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            if requiresAd {
                let rewarded = try await adManager.presentAd()
                guard rewarded else {
                    throw RewardedAdManager.RewardedAdError.noAdAvailable
                }
            }

            try limits.assertCanGenerateReframe()
            isGenerating = true
            defer { isGenerating = false }
            let response = try await openAIClient.generateReframe(for: thought)
            await store.updateReframe(thoughtId: thought.id, response: response)
            limits.recordReframe()
        } catch {
            errorMessage = error.localizedDescription
            isPresentingError = true
        }
    }
}
