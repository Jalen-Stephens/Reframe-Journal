import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var viewModel: HomeViewModel
    @State private var showDailyLimitAlert = false

    init(repository: ThoughtRecordRepository) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(repository: repository))
    }

    var body: some View {
        let sections = splitEntriesByToday(viewModel.entries)
        return VStack(alignment: .leading, spacing: 0) {
            header
            List {
                Text("Ground yourself and gently work through a moment, step by step.")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.theme.textSecondary)
                    .padding(.top, 8)
                    .listRowInsets(rowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(themeManager.theme.background)

                if let latest = viewModel.entries.first {
                    Text("Last worked on: \(latestThoughtLabel(for: latest)) · \(DateUtils.formatRelativeDate(latest.createdAt))")
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.theme.textSecondary)
                        .listRowInsets(rowInsets)
                        .listRowSeparator(.hidden)
                        .listRowBackground(themeManager.theme.background)
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
                .listRowInsets(rowInsets)
                .listRowSeparator(.hidden)
                .listRowBackground(themeManager.theme.background)

                if sections.today.isEmpty && sections.past.isEmpty {
                    Text("No entries yet. Start a new thought record above.")
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.theme.textSecondary)
                        .listRowInsets(rowInsets)
                        .listRowSeparator(.hidden)
                        .listRowBackground(themeManager.theme.background)
                } else {
                    if !sections.today.isEmpty {
                        Section {
                            ForEach(sections.today) { entry in
                                EntryListItemView(entry: entry) {
                                    router.push(.entryDetail(id: entry.id))
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        editEntry(entry)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(themeManager.theme.accent)

                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteEntry(id: entry.id)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .listRowInsets(rowInsets)
                                .listRowSeparator(.hidden)
                                .listRowBackground(themeManager.theme.background)
                            }
                        } header: {
                            Text("Recent entries")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(themeManager.theme.textPrimary)
                                .textCase(nil)
                        }
                    }

                    if !sections.past.isEmpty {
                        Section {
                            ForEach(Array(sections.past.prefix(2))) { entry in
                                EntryListItemView(entry: entry) {
                                    router.push(.entryDetail(id: entry.id))
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        editEntry(entry)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(themeManager.theme.accent)

                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteEntry(id: entry.id)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .listRowInsets(rowInsets)
                                .listRowSeparator(.hidden)
                                .listRowBackground(themeManager.theme.background)
                            }
                        } header: {
                            Text("Past entries")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(themeManager.theme.textPrimary)
                                .textCase(nil)
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
                    .listRowInsets(rowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(themeManager.theme.background)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(themeManager.theme.background.ignoresSafeArea())
        .task {
            await viewModel.loadIfNeeded()
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

    private var rowInsets: EdgeInsets {
        EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    }

    private func editEntry(_ entry: ThoughtRecord) {
        appState.wizard.setDraft(entry, isEditing: true)
        Task { await appState.wizard.persistDraft(entry) }
        router.push(.wizardStep1)
    }
}
