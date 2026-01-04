import SwiftUI

struct AllEntriesView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AllEntriesViewModel

    init(repository: ThoughtRecordRepository) {
        _viewModel = StateObject(wrappedValue: AllEntriesViewModel(repository: repository))
    }

    var body: some View {
        Group {
            if viewModel.entries.isEmpty {
                VStack(spacing: 10) {
                    Text("No entries yet.")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(notesPalette.textPrimary)
                    Text("Your journal entries will appear here after you finish one.")
                        .font(.system(size: 13))
                        .foregroundColor(notesPalette.textSecondary)
                        .multilineTextAlignment(.center)
                    Button("Back to Home") {
                        router.popToRoot()
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .pillSurface(cornerRadius: 999)
                    .foregroundColor(notesPalette.textSecondary)
                    .buttonStyle(.plain)
                }
                .padding(.top, 48)
                .padding(.horizontal, 24)
            } else {
                List {
                    ForEach(viewModel.sections()) { section in
                        Section {
                            ForEach(section.entries) { entry in
                                EntryListItemView(entry: entry) {
                                    router.push(.thoughtEntry(id: entry.id))
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        router.push(.thoughtEntry(id: entry.id))
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
        .navigationTitle("All Entries")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                GlassIconButton(icon: .chevronLeft, size: AppTheme.iconSizeMedium, accessibilityLabel: "Back") {
                    dismiss()
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var rowInsets: EdgeInsets {
        EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    }
}
