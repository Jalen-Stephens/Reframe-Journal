// File: Views/AllEntriesView.swift
// All entries list with SwiftData @Query for automatic updates

import SwiftUI
import SwiftData

struct AllEntriesView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - SwiftData Query
    // Automatically updates when entries change
    @Query(
        filter: #Predicate<JournalEntry> { !$0.isDraft },
        sort: \JournalEntry.updatedAt,
        order: .reverse
    )
    private var allEntries: [JournalEntry]

    var body: some View {
        Group {
            if allEntries.isEmpty {
                VStack(spacing: 10) {
                    Text("No entries yet.")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(notesPalette.textPrimary)
                    Text("Your journal entries will appear here after you finish one.")
                        .font(.system(size: 13))
                        .foregroundColor(notesPalette.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 48)
                .padding(.horizontal, 24)
            } else {
                List {
                    ForEach(sections()) { section in
                        Section {
                            ForEach(section.entries) { entry in
                                EntryListItemView(entry: entry) {
                                    switch entry.entryType {
                                    case .thought:
                                        router.push(.thoughtEntry(id: entry.recordId))
                                    case .urge:
                                        router.push(.urgeEntry(id: entry.recordId))
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        switch entry.entryType {
                                        case .thought:
                                            router.push(.thoughtEntry(id: entry.recordId))
                                        case .urge:
                                            router.push(.urgeEntry(id: entry.recordId))
                                        }
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(notesPalette.accent)

                                    Button(role: .destructive) {
                                        deleteEntry(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .listRowInsets(rowInsets)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        } header: {
                            Text(section.title)
                                .font(.system(size: 14))
                                .foregroundColor(notesPalette.textSecondary)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(notesPalette.background.ignoresSafeArea())
        .navigationTitle("Entries")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
    }

    private var rowInsets: EdgeInsets {
        EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    }
    
    private func deleteEntry(_ entry: JournalEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }
    
    // MARK: - Sections
    
    private func sections() -> [AllEntriesSection] {
        var today: [JournalEntry] = []
        var yesterday: [JournalEntry] = []
        var older: [JournalEntry] = []

        for entry in allEntries {
            let label = DateUtils.formatRelativeDate(DateUtils.isoString(from: entry.createdAt))
            if label == "Today" {
                today.append(entry)
            } else if label == "Yesterday" {
                yesterday.append(entry)
            } else {
                older.append(entry)
            }
        }

        var sections: [AllEntriesSection] = []
        if !today.isEmpty { sections.append(AllEntriesSection(title: "Today", entries: today)) }
        if !yesterday.isEmpty { sections.append(AllEntriesSection(title: "Yesterday", entries: yesterday)) }
        if !older.isEmpty { sections.append(AllEntriesSection(title: "Older", entries: older)) }
        return sections
    }
}

// MARK: - Section Model

private struct AllEntriesSection: Identifiable {
    let id = UUID()
    let title: String
    let entries: [JournalEntry]
}
