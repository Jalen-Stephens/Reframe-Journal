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
        ScrollView {
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
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(viewModel.sections()) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(section.title)
                                .font(.system(size: 14))
                                .foregroundColor(notesPalette.textSecondary)
                            LazyVStack(spacing: 12) {
                                ForEach(section.entries) { entry in
                                    EntryListItemView(entry: entry) {
                                        router.push(.thoughtEntry(id: entry.id))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
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
}
