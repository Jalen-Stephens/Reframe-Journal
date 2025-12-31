import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var viewModel: HomeViewModel
    @State private var showDailyLimitAlert = false

    init() {
        _viewModel = StateObject(wrappedValue: HomeViewModel(repository: ThoughtRecordRepository()))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Ground yourself and gently work through a moment, step by step.")
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.theme.textSecondary)
                        .padding(.top, 8)

                    if let latest = viewModel.entries.first {
                        Text("Last worked on: \(latestThoughtLabel(for: latest)) · \(DateUtils.formatRelativeDate(latest.createdAt))")
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.theme.textSecondary)
                    }

                    VStack(spacing: 12) {
                        Button {
                            if appState.thoughtUsage.canCreateThought() {
                                Task {
                                    await appState.wizard.clearDraft()
                                    router.push(.wizardStep1)
                                }
                            } else {
                                showDailyLimitAlert = true
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("New thought record")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(themeManager.theme.onAccent)
                                Text("Work through a difficult moment step by step.")
                                    .font(.system(size: 13))
                                    .foregroundColor(themeManager.theme.onAccent.opacity(0.9))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(themeManager.theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)

                        if viewModel.hasDraft {
                            Button {
                                router.push(.wizardStep1)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Continue draft")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(themeManager.theme.textPrimary)
                                    Text("Pick up where you left off.")
                                        .font(.system(size: 13))
                                        .foregroundColor(themeManager.theme.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .cardSurface(cornerRadius: 14, shadow: false)
                        }
                        .buttonStyle(.plain)
                        }
                    }

                    entriesSection
                }
                .padding(16)
            }
        }
        .background(themeManager.theme.background.ignoresSafeArea())
        .task {
            await viewModel.refresh()
        }
        .alert("Daily limit reached", isPresented: $showDailyLimitAlert) {
            Button("OK", role: .cancel) {}
            Button("Upgrade") {
                // TODO: Wire up subscription flow when StoreKit integration is ready.
            }
        } message: {
            Text("You've used your 3 free thoughts for today.\nCome back tomorrow, or upgrade for unlimited thoughts.")
        }
    }

    private var header: some View {
        HStack {
            Text("Reframe Journal")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(themeManager.theme.textPrimary)
            Spacer()
            Button("Settings") {
                router.push(.settings)
            }
            .font(.system(size: 12))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .pillSurface(cornerRadius: 16)
            .foregroundColor(themeManager.theme.textSecondary)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func latestThoughtLabel(for record: ThoughtRecord) -> String {
        let thought = record.automaticThoughts.first?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return thought.isEmpty ? "Untitled thought" : thought
    }

    private var entriesSection: some View {
        let sections = splitEntriesByToday(viewModel.entries)
        return VStack(alignment: .leading, spacing: 12) {
            if sections.today.isEmpty && sections.past.isEmpty {
                Text("No entries yet. Start a new thought record above.")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.theme.textSecondary)
            } else {
                if !sections.today.isEmpty {
                    Text("Recent entries")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(themeManager.theme.textPrimary)
                    VStack(spacing: 12) {
                        ForEach(sections.today) { entry in
                            EntryListItemView(entry: entry) {
                                router.push(.entryDetail(id: entry.id))
                            }
                        }
                    }
                }

                if !sections.past.isEmpty {
                    Text("Past entries")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(themeManager.theme.textPrimary)
                        .padding(.top, sections.today.isEmpty ? 0 : 8)
                    VStack(spacing: 12) {
                        ForEach(sections.past) { entry in
                            EntryListItemView(entry: entry) {
                                router.push(.entryDetail(id: entry.id))
                            }
                        }
                    }
                }

                Button {
                    router.push(.allEntries)
                } label: {
                    HStack {
                        Text("View all entries")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(themeManager.theme.textSecondary)
                        Spacer()
                        Text(">")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(themeManager.theme.textSecondary)
                    }
                    .padding(12)
                    .pillSurface(cornerRadius: 12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func splitEntriesByToday(_ entries: [ThoughtRecord]) -> (today: [ThoughtRecord], past: [ThoughtRecord]) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        var today: [ThoughtRecord] = []
        var past: [ThoughtRecord] = []
        for entry in entries {
            guard let date = DateUtils.parseIso(entry.createdAt) else {
                past.append(entry)
                continue
            }
            if date >= startOfToday {
                today.append(entry)
            } else {
                past.append(entry)
            }
        }
        return (today, past)
    }
}
