// File: Views/Components/ValuesSelectionSection.swift
// Values selection component for the thought entry flow

import SwiftUI

struct ValuesSelectionSection: View {
    @Environment(\.notesPalette) private var notesPalette
    @EnvironmentObject private var router: AppRouter
    
    @Binding var selectedValues: SelectedValues
    @StateObject private var valuesService = ValuesProfileService()
    
    @State private var showCategoryPicker = false
    @State private var howToShowUpText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            
            if valuesService.profile.hasContent {
                selectedCategoriesSection
                keywordsSection
                howToShowUpField
            } else {
                setupPrompt
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(spacing: 6) {
            GlassSectionHeader(text: "VALUES")
            
            Spacer()
            
            if valuesService.profile.hasContent {
                GlassPillButton {
                    showCategoryPicker = true
                } label: {
                    HStack(spacing: 4) {
                        AppIconView(icon: .plus, size: AppTheme.iconSizeSmall)
                        Text("Add")
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(notesPalette.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerSheet(
                selectedCategories: $selectedValues.categories,
                profile: valuesService.profile
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Selected Categories
    
    @ViewBuilder
    private var selectedCategoriesSection: some View {
        if selectedValues.categories.isEmpty {
            Button {
                showCategoryPicker = true
            } label: {
                GlassCard(padding: AppTheme.cardPaddingCompact) {
                    HStack {
                        Text("What values do you want to act from here?")
                            .font(.footnote)
                            .foregroundStyle(notesPalette.textSecondary)
                        Spacer()
                        AppIconView(icon: .chevronRight, size: AppTheme.iconSizeSmall)
                            .foregroundStyle(notesPalette.textTertiary)
                    }
                }
            }
            .buttonStyle(.plain)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedValues.categories) { category in
                        SelectedChipView(label: category.title) {
                            removeCategory(category)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Keywords
    
    @ViewBuilder
    private var keywordsSection: some View {
        let availableKeywords = collectKeywords()
        
        if !availableKeywords.isEmpty && !selectedValues.categories.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Related keywords")
                    .font(.system(size: 12))
                    .foregroundStyle(notesPalette.textTertiary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableKeywords, id: \.self) { keyword in
                            let isSelected = selectedValues.keywords.contains(keyword)
                            Button {
                                toggleKeyword(keyword)
                            } label: {
                                GlassPill(padding: EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)) {
                                    HStack(spacing: 4) {
                                        Text(keyword)
                                            .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                                            .foregroundStyle(isSelected ? notesPalette.textPrimary : notesPalette.textSecondary)
                                        
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(notesPalette.textPrimary)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - How To Show Up Field
    
    @ViewBuilder
    private var howToShowUpField: some View {
        if !selectedValues.categories.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("How I want to show up here")
                    .font(.system(size: 12))
                    .foregroundStyle(notesPalette.textTertiary)
                
                GlassCard(padding: AppTheme.cardPaddingCompact) {
                    ZStack(alignment: .topLeading) {
                        if howToShowUpText.isEmpty {
                            Text(placeholderText)
                                .font(.footnote)
                                .foregroundStyle(notesPalette.textTertiary)
                                .padding(.top, 2)
                        }
                        TextField("", text: $howToShowUpText)
                            .textFieldStyle(.plain)
                            .font(.footnote)
                            .foregroundStyle(notesPalette.textPrimary)
                            .onChange(of: howToShowUpText) { _, newValue in
                                selectedValues.howToShowUp = newValue
                            }
                    }
                }
            }
        }
    }
    
    private var placeholderText: String {
        // Use first selected category's "how to show up" as hint
        if let firstCategory = selectedValues.categories.first {
            let entry = valuesService.entry(for: firstCategory)
            if !entry.howToShowUp.isEmpty {
                let trimmed = entry.howToShowUp.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.count > 60 ? String(trimmed.prefix(60)) + "…" : trimmed
            }
        }
        return "e.g., I want to be patient and understanding"
    }
    
    // MARK: - Setup Prompt
    
    private var setupPrompt: some View {
        Button {
            router.push(.valuesProfile)
        } label: {
            GlassCard(padding: AppTheme.cardPaddingCompact) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 18))
                            .foregroundStyle(notesPalette.textSecondary)
                        
                        Text("Set up your values profile")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(notesPalette.textPrimary)
                        
                        Spacer()
                        
                        AppIconView(icon: .chevronRight, size: AppTheme.iconSizeSmall)
                            .foregroundStyle(notesPalette.textTertiary)
                    }
                    
                    Text("Define what matters to you for more personal reframes")
                        .font(.system(size: 12))
                        .foregroundStyle(notesPalette.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    
    private func collectKeywords() -> [String] {
        var keywords = Set<String>()
        for category in selectedValues.categories {
            let entry = valuesService.entry(for: category)
            keywords.formUnion(entry.keywords)
        }
        return Array(keywords).sorted()
    }
    
    private func removeCategory(_ category: ValuesCategory) {
        selectedValues.categories.removeAll { $0 == category }
    }
    
    private func toggleKeyword(_ keyword: String) {
        if selectedValues.keywords.contains(keyword) {
            selectedValues.keywords.removeAll { $0 == keyword }
        } else {
            selectedValues.keywords.append(keyword)
        }
    }
}

// MARK: - Category Picker Sheet

private struct CategoryPickerSheet: View {
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedCategories: [ValuesCategory]
    let profile: ValuesProfile
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(ValuesCategory.allCases) { category in
                        let entry = profile.entry(for: category)
                        let isSelected = selectedCategories.contains(category)
                        
                        Button {
                            toggleCategory(category)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: category.iconName)
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundStyle(entry.hasContent ? notesPalette.textSecondary : notesPalette.textTertiary)
                                    .frame(width: 24, alignment: .center)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(category.title)
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundStyle(notesPalette.textPrimary)
                                    
                                    if entry.hasContent, let summary = entry.summaryText {
                                        Text(summary)
                                            .font(.system(size: 12))
                                            .foregroundStyle(notesPalette.textTertiary)
                                            .lineLimit(1)
                                    }
                                }
                                
                                Spacer()
                                
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(notesPalette.textPrimary)
                                } else if entry.hasContent {
                                    Image(systemName: "circle")
                                        .font(.system(size: 22))
                                        .foregroundStyle(notesPalette.textTertiary)
                                } else {
                                    Text("Not set")
                                        .font(.system(size: 12))
                                        .foregroundStyle(notesPalette.textTertiary.opacity(0.6))
                                }
                            }
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!entry.hasContent)
                        .opacity(entry.hasContent ? 1 : 0.5)
                        
                        if category != ValuesCategory.allCases.last {
                            Divider()
                                .background(notesPalette.separator.opacity(0.5))
                                .padding(.leading, 48)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .background(notesPalette.background.ignoresSafeArea())
            .navigationTitle("Select Values")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(notesPalette.textPrimary)
                }
            }
        }
    }
    
    private func toggleCategory(_ category: ValuesCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.removeAll { $0 == category }
        } else {
            selectedCategories.append(category)
        }
    }
}

// MARK: - Preview

#Preview("Values Selection - Light") {
    VStack {
        ValuesSelectionSection(
            selectedValues: .constant(SelectedValues(
                categories: [.personalGrowth, .healthAndWellness],
                keywords: ["patience", "growth"],
                howToShowUp: ""
            ))
        )
        .environmentObject(AppRouter())
        .notesTheme()
    }
    .padding()
    .preferredColorScheme(.light)
}

#Preview("Values Selection - Empty") {
    VStack {
        ValuesSelectionSection(
            selectedValues: .constant(.empty)
        )
        .environmentObject(AppRouter())
        .notesTheme()
    }
    .padding()
    .preferredColorScheme(.dark)
}
