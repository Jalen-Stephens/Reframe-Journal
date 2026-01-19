import SwiftUI

struct EntryStatusPicker: View {
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedStatus: EntryStatus?
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        selectedStatus = nil
                        onDismiss()
                        dismiss()
                    } label: {
                        HStack {
                            Text("None")
                                .foregroundStyle(notesPalette.textPrimary)
                            Spacer()
                            if selectedStatus == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(notesPalette.textSecondary)
                            }
                        }
                    }
                    
                    ForEach(EntryStatus.allCases, id: \.self) { status in
                        Button {
                            selectedStatus = status
                            onDismiss()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: status.icon)
                                    .foregroundStyle(notesPalette.textSecondary)
                                    .frame(width: 20)
                                Text(status.displayName)
                                    .foregroundStyle(notesPalette.textPrimary)
                                Spacer()
                                if selectedStatus == status {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(notesPalette.textSecondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Entry Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                        dismiss()
                    }
                }
            }
        }
    }
}
