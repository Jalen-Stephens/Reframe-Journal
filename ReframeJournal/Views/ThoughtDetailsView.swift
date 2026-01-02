// File: Views/ThoughtDetailsView.swift
import SwiftUI

struct ThoughtDetailsView: View {
    let thoughtId: UUID
    @ObservedObject private var store: ThoughtStore
    @ObservedObject private var entitlements: EntitlementsManager
    @ObservedObject private var limits: LimitsManager
    @ObservedObject private var adManager: RewardedAdManager
    private let openAIClient: AnyOpenAIClient

    @StateObject private var viewModel: ThoughtDetailsViewModel

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
        _viewModel = StateObject(wrappedValue: ThoughtDetailsViewModel(
            store: store,
            entitlements: entitlements,
            limits: limits,
            adManager: adManager,
            openAIClient: openAIClient
        ))
    }

    var body: some View {
        let thought = store.thought(id: thoughtId)

        VStack(alignment: .leading, spacing: 16) {
            if let thought {
                Text(thought.text)
                    .font(.title2.bold())

                Text(thought.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()

                if let response = thought.reframeResponse {
                    ReframeSummaryCard(response: response)
                } else {
                    Text("No AI reframe yet.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Entry not found.")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                guard let thought else { return }
                viewModel.generateReframe(for: thought)
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Generate Reframe")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading || thought == nil)
        }
        .padding()
        .navigationTitle("Entry")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.isPresentingAdSheet) {
            AdGateSheet(
                onWatchAd: {
                    guard let thought else { return }
                    viewModel.watchAdAndGenerate(for: thought)
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
        .navigationDestination(isPresented: $viewModel.isPresentingResult) {
            ReframeResultView(
                thoughtId: thoughtId,
                store: store,
                entitlements: entitlements,
                limits: limits,
                adManager: adManager,
                openAIClient: openAIClient
            )
        }
    }
}

private struct ReframeSummaryCard: View {
    let response: ReframeResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latest Reframe")
                .font(.headline)
            Text(response.summary)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct AdGateSheet: View {
    let onWatchAd: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Watch a short ad to unlock your AI reframe.")
                .font(.title3.bold())

            Button {
                onWatchAd()
            } label: {
                Text("Watch Ad")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button("Upgrade to Pro") {
                onUpgrade()
            }
        }
        .padding(24)
    }
}

@MainActor
final class ThoughtDetailsViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var isPresentingAdSheet: Bool = false
    @Published var isPresentingPaywall: Bool = false
    @Published var isPresentingResult: Bool = false
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

    func generateReframe(for thought: Thought) {
        guard !isLoading else { return }
        if entitlements.isPro {
            Task { await generateReframe(for: thought, requiresAd: false) }
        } else {
            isPresentingAdSheet = true
        }
    }

    func watchAdAndGenerate(for thought: Thought) {
        guard !isLoading else { return }
        isPresentingAdSheet = false
        Task { await generateReframe(for: thought, requiresAd: true) }
    }

    private func generateReframe(for thought: Thought, requiresAd: Bool) async {
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
            let response = try await openAIClient.generateReframe(for: thought)
            await store.updateReframe(thoughtId: thought.id, response: response)
            limits.recordReframe()
            isPresentingResult = true
        } catch {
            errorMessage = error.localizedDescription
            isPresentingError = true
        }
    }
}
