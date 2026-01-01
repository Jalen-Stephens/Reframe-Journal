import SwiftUI

struct AIReframeResultView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var themeManager: ThemeManager
    @AppStorage("aiReframeEnabled") private var aiReframeEnabled: Bool = false

    @StateObject private var viewModel: AIReframeViewModel
    @State private var didStart = false

    let entryId: String
    let action: AIReframeAction

    init(entryId: String, repository: ThoughtRecordRepository, action: AIReframeAction = .view) {
        self.entryId = entryId
        self.action = action
        _viewModel = StateObject(wrappedValue: AIReframeViewModel(entryId: entryId, repository: repository, service: AIReframeService()))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if let result = viewModel.result {
                    resultContent(result)
                } else if viewModel.isLoading {
                    loadingContent
                } else if let error = viewModel.error {
                    errorContent(error)
                } else {
                    emptyContent
                }

                Text("AI suggestions aren't a substitute for professional care.")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.theme.textSecondary)
                    .padding(.top, 8)

                if viewModel.result != nil {
                    Button("Regenerate") {
                        Task { await viewModel.regenerateAndSave() }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(themeManager.theme.accent)
                    .disabled(!aiReframeEnabled)
                }
            }
            .padding(16)
        }
        .background(themeManager.theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            await viewModel.loadExisting()
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
            .foregroundColor(themeManager.theme.textPrimary)
            .buttonStyle(.plain)

            Spacer()

            Text("AI Reframe")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.theme.textPrimary)

            Spacer()

            Color.clear
                .frame(width: 52, height: 28)
        }
    }

    private var loadingContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: themeManager.theme.accent))
                Text("Generating...")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.theme.textPrimary)
            }
            Text("This can take a few moments.")
                .font(.system(size: 12))
                .foregroundColor(themeManager.theme.textSecondary)
        }
        .padding(16)
        .cardSurface(cornerRadius: 16)
    }

    private func resultContent(_ result: AIReframeResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if !result.validation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(result.validation)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.theme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Reframe")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.theme.textPrimary)
                Text(result.reframeSummary)
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.theme.textPrimary)
            }
            .padding(16)
            .cardSurface(cornerRadius: 16)

            if let balanced = result.balancedThought?.trimmingCharacters(in: .whitespacesAndNewlines), !balanced.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Balanced thought")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.theme.textPrimary)
                    Text(balanced)
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.theme.textPrimary)
                }
                .padding(16)
                .cardSurface(cornerRadius: 16)
            }

            if !result.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Try this")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.theme.textPrimary)
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(result.suggestions, id: \.self) { suggestion in
                            Text("- \(suggestion)")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.theme.textSecondary)
                        }
                    }
                }
                .padding(16)
                .cardSurface(cornerRadius: 16)
            }
        }
    }

    private func errorContent(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(error)
                .font(.system(size: 12))
                .foregroundColor(themeManager.theme.textSecondary)
            PrimaryButton(label: "Retry", onPress: {
                Task { await viewModel.generateAndSave() }
            }, disabled: !aiReframeEnabled)
        }
        .padding(16)
        .cardSurface(cornerRadius: 16)
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if aiReframeEnabled {
                Text("Generate an AI Reframe to see suggestions here.")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.theme.textSecondary)
                PrimaryButton(label: "Generate Reframe") {
                    Task { await viewModel.generateAndSave() }
                }
            } else {
                Text("AI Reframe is disabled in Settings.")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.theme.textSecondary)
                Button("Open Settings") {
                    router.push(.settings)
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeManager.theme.accent)
            }
        }
        .padding(16)
        .cardSurface(cornerRadius: 16)
    }
}
