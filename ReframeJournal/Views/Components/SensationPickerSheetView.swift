import SwiftUI

@MainActor
struct SensationPickerSheetView: View {
    @Environment(\.notesPalette) private var notesPalette

    @Binding var selectedSensations: [String]
    @Binding var isPresented: Bool
    let commonSensations: [String]

    @State private var searchText: String = ""
    @State private var customText: String = ""
    @State private var showCustomInput = false
    @FocusState private var isCustomFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            header
            searchField
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(filteredSensations, id: \.self) { sensation in
                        selectionRow(for: sensation)
                    }
                    customRow
                }
                .padding(.vertical, 4)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .padding(16)
        .background(notesPalette.background)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if showCustomInput {
                    customInputBar
                }
                doneButton
            }
            .padding(16)
            .background(notesPalette.background)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: showCustomInput) { newValue in
            if newValue {
                isCustomFocused = true
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Physical sensations")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(notesPalette.textPrimary)
            Spacer()
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(notesPalette.textSecondary)
            TextField("Search sensations", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .onSubmit {
                    dismissKeyboard()
                }
                .foregroundColor(notesPalette.textPrimary)
                .submitLabel(.search)
        }
        .padding(10)
        .cardSurface(cornerRadius: 8, shadow: false)
    }

    private func selectionRow(for sensation: String) -> some View {
        Button {
            toggleSelection(sensation)
        } label: {
            HStack {
                Text(sensation)
                    .font(.system(size: 14))
                    .foregroundColor(notesPalette.textPrimary)
                Spacer()
                if isSelected(sensation) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(notesPalette.accent)
                }
            }
            .padding(12)
            .pillSurface(cornerRadius: 10)
        }
        .buttonStyle(.plain)
    }

    private var customRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                showCustomInput.toggle()
                if showCustomInput {
                    isCustomFocused = true
                }
            } label: {
                HStack {
                    Text("Custom...")
                        .font(.system(size: 14))
                        .foregroundColor(notesPalette.textPrimary)
                    Spacer()
                    Image(systemName: showCustomInput ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(notesPalette.textSecondary)
                }
                .padding(12)
                .pillSurface(cornerRadius: 10)
            }
            .buttonStyle(.plain)
        }
    }

    private var customInputBar: some View {
        HStack(spacing: 8) {
            TextField("Describe your sensation", text: $customText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(notesPalette.textPrimary)
                .submitLabel(.done)
                .focused($isCustomFocused)
                .onSubmit {
                    addCustomSensation()
                    dismissKeyboard()
                }
            Button("Add") {
                addCustomSensation()
            }
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(notesPalette.muted)
            .foregroundColor(notesPalette.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(10)
        .cardSurface(cornerRadius: 10, shadow: false)
    }

    private var doneButton: some View {
        Button {
            handleDone()
        } label: {
            Text("Done")
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(notesPalette.accent)
                .foregroundColor(notesPalette.onAccent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var filteredSensations: [String] {
        let base = commonSensations + customSelections
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return base }
        return base.filter { $0.localizedCaseInsensitiveContains(trimmedSearch) }
    }

    private var customSelections: [String] {
        let extras = selectedSensations.filter { !commonSensations.contains($0) }
        return extras.sorted()
    }

    private func isSelected(_ value: String) -> Bool {
        selectedSensations.contains { $0.caseInsensitiveCompare(value) == .orderedSame }
    }

    private func toggleSelection(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let index = selectedSensations.firstIndex(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            selectedSensations.remove(at: index)
        } else {
            selectedSensations.append(trimmed)
        }
    }

    private func addCustomSensation() {
        let trimmed = customText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !selectedSensations.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            selectedSensations.append(trimmed)
        }
        customText = ""
        showCustomInput = false
        isCustomFocused = false
    }

    private func handleDone() {
        let trimmed = customText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            addCustomSensation()
        }
        isPresented = false
    }
}
