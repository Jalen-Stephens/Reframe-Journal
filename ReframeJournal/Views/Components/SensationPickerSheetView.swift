import SwiftUI

struct SensationPickerSheetView: View {
    @EnvironmentObject private var themeManager: ThemeManager

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
        .background(themeManager.theme.background)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if showCustomInput {
                    customInputBar
                }
                doneButton
            }
            .padding(16)
            .background(themeManager.theme.background)
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
                .foregroundColor(themeManager.theme.textPrimary)
            Spacer()
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager.theme.textSecondary)
            TextField("Search sensations", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(themeManager.theme.textPrimary)
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
                    .foregroundColor(themeManager.theme.textPrimary)
                Spacer()
                if isSelected(sensation) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(themeManager.theme.accent)
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
                        .foregroundColor(themeManager.theme.textPrimary)
                    Spacer()
                    Image(systemName: showCustomInput ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeManager.theme.textSecondary)
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
                .foregroundColor(themeManager.theme.textPrimary)
                .submitLabel(.done)
                .focused($isCustomFocused)
                .onSubmit {
                    addCustomSensation()
                }
            Button("Add") {
                addCustomSensation()
            }
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(themeManager.theme.muted)
            .foregroundColor(themeManager.theme.textPrimary)
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
                .background(themeManager.theme.accent)
                .foregroundColor(themeManager.theme.onAccent)
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

    @MainActor
    private func toggleSelection(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let index = selectedSensations.firstIndex(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            selectedSensations.remove(at: index)
        } else {
            selectedSensations.append(trimmed)
        }
    }

    @MainActor
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

    @MainActor
    private func handleDone() {
        let trimmed = customText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            addCustomSensation()
        }
        isPresented = false
    }
}
