// File: Views/HomeView.swift
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter
    @Environment(\.notesPalette) private var notesPalette
    @EnvironmentObject private var entitlementsManager: EntitlementsManager
    @StateObject private var viewModel: HomeViewModel
    @State private var showDailyLimitAlert = false
    @State private var showPaywall = false
    @State private var isPastEntriesExpanded = true

    init(repository: ThoughtRecordRepository) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(repository: repository))
    }

    var body: some View {
        let sections = splitEntriesByToday(viewModel.entries)
        return VStack(alignment: .leading, spacing: 0) {
            header
            List {
                Text("Ground yourself and gently work through a moment, step by step.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                    .listRowInsets(rowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                if let latest = viewModel.entries.first {
                    Text("Last worked on: \(latestThoughtLabel(for: latest)) · \(DateUtils.formatRelativeDate(latest.createdAt))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .listRowInsets(rowInsets)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }

                Button {
                    startNewThoughtRecord()
                } label: {
                    GlassCard(emphasized: true) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("New thought record")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("Work through a difficult moment step by step.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .listRowInsets(rowInsets)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                if sections.today.isEmpty && sections.past.isEmpty {
                    Text("No entries yet. Start a new thought record above.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .listRowInsets(rowInsets)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else {
                    if !sections.today.isEmpty {
                        Section {
                            ForEach(sections.today) { entry in
                                EntryListItemView(entry: entry) {
                                    router.push(.thoughtEntry(id: entry.id))
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        editEntry(entry)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(notesPalette.accent)

                                    Button(role: .destructive) {
                                        Task { @MainActor in
                                            await viewModel.deleteEntry(id: entry.id)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .listRowInsets(rowInsets)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        } header: {
                            GlassSectionHeader(text: "Recent entries")
                        }
                    }

                    if !sections.past.isEmpty {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPastEntriesExpanded.toggle()
                            }
                        } label: {
                            GlassCard(padding: AppTheme.cardPaddingCompact) {
                                HStack {
                                    Text("Recent entries")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    AppIconView(icon: isPastEntriesExpanded ? .chevronDown : .chevronRight, size: AppTheme.iconSizeSmall)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(rowInsets)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                        if isPastEntriesExpanded {
                            ForEach(Array(sections.past.prefix(2))) { entry in
                                EntryListItemView(entry: entry) {
                                    router.push(.thoughtEntry(id: entry.id))
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        editEntry(entry)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(notesPalette.accent)

                                    Button(role: .destructive) {
                                        Task { @MainActor in
                                            await viewModel.deleteEntry(id: entry.id)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .listRowInsets(rowInsets)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                    }

                    Button {
                        router.push(.allEntries)
                    } label: {
                        GlassCard(padding: AppTheme.cardPaddingCompact) {
                            HStack {
                                Text("View all entries")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                AppIconView(icon: .arrowRight, size: AppTheme.iconSizeSmall)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(rowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                    Image(isPastEntriesExpanded ? "NuggieStandingDogBed" : "NuggieDogBedJournal")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 220)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 12, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .accessibilityLabel(isPastEntriesExpanded ? "Nuggie standing by a dog bed" : "Nuggie resting on a dog bed")
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
        }
        .background(GlassBackground())
        .task {
            await viewModel.loadIfNeeded()
        }
        .onAppear {
            if viewModel.hasLoaded {
                Task { await viewModel.refresh() }
            }
        }
        .alert("Daily limit reached", isPresented: $showDailyLimitAlert) {
            Button("OK", role: .cancel) {}
            Button("Upgrade") {
                showPaywall = true
            }
        } message: {
            Text("You've used your 3 free thoughts for today.\nCome back tomorrow, or upgrade for unlimited thoughts.")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var header: some View {
        HStack {
            Text("Reframe Journal")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
            if !entitlementsManager.isPro {
                GlassPillButton {
                    showPaywall = true
                } label: {
                    HStack(spacing: 6) {
                        AppIconView(icon: .sparkles, size: AppTheme.iconSizeSmall)
                            .foregroundStyle(.secondary)
                        Text("Upgrade")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            GlassIconButton(icon: .settings, size: AppTheme.iconSizeMedium, accessibilityLabel: "Settings") {
                router.push(.settings)
            }

            GlassIconButton(icon: .plus, size: AppTheme.iconSizeMedium, accessibilityLabel: "New entry") {
                startNewThoughtRecord()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func latestThoughtLabel(for record: ThoughtRecord) -> String {
        if let title = record.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            return title
        }
        let situation = record.situationText.trimmingCharacters(in: .whitespacesAndNewlines)
        if situation.isEmpty {
            return "New Entry"
        }
        let firstLine = situation.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? situation
        if firstLine.count > 40 {
            let index = firstLine.index(firstLine.startIndex, offsetBy: 40)
            return String(firstLine[..<index])
        }
        return firstLine
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
        router.push(.thoughtEntry(id: entry.id))
    }

    private func startNewThoughtRecord() {
        if appState.thoughtUsage.canCreateThought() {
            router.push(.thoughtEntry(id: nil))
        } else {
            showDailyLimitAlert = true
        }
    }
}
