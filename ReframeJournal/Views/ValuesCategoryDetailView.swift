// File: Views/ValuesCategoryDetailView.swift
// Detail view for editing a single values category with suggested chips

import SwiftUI
import SwiftData

struct ValuesCategoryDetailView: View {
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let category: ValuesCategory
    
    @Query private var valuesQuery: [PersonalValues]
    @State private var personalValues: PersonalValues?
    @State private var text: String = ""
    @State private var selectedSuggestions: Set<String> = []
    @State private var saveTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            notesPalette.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    
                    // Suggested values chips
                    if !category.suggestedValues.isEmpty {
                        suggestedValuesSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                    }
                    
                    // Text input
                    textInputSection
                        .padding(.horizontal, 20)
                    
                    // Bottom padding
                    Color.clear.frame(height: 100)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(category.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(notesPalette.textPrimary)
            }
        }
        .onAppear {
            loadValues()
        }
        .onChange(of: valuesQuery) { _, newValues in
            if let first = newValues.first {
                personalValues = first
                loadValueIntoState()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and title
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(notesPalette.accent)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(notesPalette.accent.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(notesPalette.textPrimary)
                }
            }
            
            // Description
            Text(category.description)
                .font(.system(size: 15))
                .foregroundStyle(notesPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Suggested Values Section
    
    private var suggestedValuesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested Values")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(notesPalette.textSecondary)
            
            Text("Tap to add to your values")
                .font(.caption)
                .foregroundStyle(notesPalette.textTertiary)
            
            FlowLayout(spacing: 8) {
                ForEach(category.suggestedValues, id: \.self) { suggestion in
                    let isSelected = selectedSuggestions.contains(suggestion)
                    
                    Button {
                        toggleSuggestion(suggestion)
                    } label: {
                        HStack(spacing: 4) {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            Text(suggestion)
                                .font(.footnote)
                        }
                        .foregroundStyle(isSelected ? notesPalette.textPrimary : notesPalette.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isSelected ? chipSelectedColor : Color.clear)
                        )
                        .overlay(
                            Capsule()
                                .stroke(dividerColor, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Text Input Section
    
    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Values")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(notesPalette.textSecondary)
                .padding(.top, 8)
            
            LabeledInput(
                label: "",
                placeholder: "Write your values here...",
                text: $text,
                isMultiline: true,
                multilineMinHeight: 200
            )
            .onChange(of: text) { _, _ in
                debouncedSave()
            }
        }
    }
    
    private var chipSelectedColor: Color {
        colorScheme == .dark 
            ? Color.white.opacity(0.15) 
            : Color.black.opacity(0.08)
    }
    
    private var dividerColor: Color {
        colorScheme == .dark 
            ? Color.white.opacity(0.1) 
            : Color.black.opacity(0.1)
    }
    
    // MARK: - Data Loading
    
    private func loadValues() {
        if let existing = valuesQuery.first {
            personalValues = existing
        } else {
            let newValues = PersonalValues()
            modelContext.insert(newValues)
            personalValues = newValues
            try? modelContext.save()
        }
        loadValueIntoState()
    }
    
    private func loadValueIntoState() {
        guard let values = personalValues else { return }
        
        let savedText = category.getValue(from: values) ?? ""
        text = savedText
        
        // Extract selected suggestions from text
        updateSelectedSuggestions(from: savedText)
    }
    
    private func updateSelectedSuggestions(from text: String) {
        let textLower = text.lowercased()
        selectedSuggestions = Set(
            category.suggestedValues.filter { suggestion in
                textLower.contains(suggestion.lowercased())
            }
        )
    }
    
    // MARK: - Suggestion Toggle
    
    private func toggleSuggestion(_ suggestion: String) {
        if selectedSuggestions.contains(suggestion) {
            // Remove from text
            selectedSuggestions.remove(suggestion)
            let words = text.components(separatedBy: .whitespacesAndNewlines)
            text = words.filter { word in
                word.lowercased() != suggestion.lowercased()
            }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            // Add to text
            selectedSuggestions.insert(suggestion)
            if !text.isEmpty && !text.hasSuffix("\n") && !text.hasSuffix(" ") {
                text += ", "
            }
            text += suggestion
            if !text.hasSuffix(" ") {
                text += " "
            }
        }
        debouncedSave()
    }
    
    // MARK: - Auto-Save
    
    private func debouncedSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            if !Task.isCancelled {
                await MainActor.run {
                    saveValue()
                }
            }
        }
    }
    
    private func saveValue() {
        guard var values = personalValues else { return }
        
        let valueToSave = text.trimmingCharacters(in: .whitespacesAndNewlines)
        category.setValue(valueToSave.isEmpty ? nil : valueToSave, in: values)
        values.touch()
        
        try? modelContext.save()
    }
}

// MARK: - FlowLayout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        
        return (
            size: CGSize(width: maxWidth, height: currentY + lineHeight),
            positions: positions
        )
    }
}

// MARK: - Preview

#Preview("Romantic Relationships") {
    NavigationStack {
        ValuesCategoryDetailView(category: .romanticRelationships)
            .modelContainer(try! ModelContainerConfig.makePreviewContainer())
            .notesTheme()
    }
}
