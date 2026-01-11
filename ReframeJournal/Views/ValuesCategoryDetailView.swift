// File: Views/ValuesCategoryDetailView.swift
// Detail editor for a single values category

import SwiftUI

struct ValuesCategoryDetailView: View {
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var router: AppRouter
    
    let category: ValuesCategory
    @StateObject private var service: ValuesProfileService
    
    init(category: ValuesCategory) {
        self.category = category
        let tempContainer = try! ModelContainerConfig.makeContainer()
        _service = StateObject(wrappedValue: ValuesProfileService(modelContext: tempContainer.mainContext))
    }
    
    @State private var whatMatters: String = ""
    @State private var whyItMatters: String = ""
    @State private var howToShowUp: String = ""
    @State private var keywordsText: String = ""
    @State private var customKeywordInput: String = ""
    @State private var importance: Int = 0
    @State private var hasLoadedEntry: Bool = false
    @State private var searchQuery: String = ""
    @State private var showValueSuggestions: Bool = true
    
    @FocusState private var focusedField: Field?
    
    private enum Field: Hashable {
        case whatMatters
        case whyItMatters
        case howToShowUp
        case keywords
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                
                whatMattersSection
                
                GlassDivider()
                
                whyItMattersSection
                
                GlassDivider()
                
                howToShowUpSection
                
                GlassDivider()
                
                keywordsSection
                
                GlassDivider()
                
                importanceSection
                
                Spacer(minLength: 48)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(notesPalette.background.ignoresSafeArea())
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    saveAndDismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Values")
                            .font(.system(size: 17))
                    }
                    .foregroundStyle(notesPalette.textPrimary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveAndDismiss()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(notesPalette.textPrimary)
            }
        }
        .onAppear {
            service.updateModelContext(modelContext)
        }
        .task {
            await loadEntry()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: category.iconName)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(notesPalette.textSecondary)
                
                Text(category.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(notesPalette.textPrimary)
            }
            
            Text(category.description)
                .font(.system(size: 14))
                .foregroundStyle(notesPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - What Matters
    
    private var whatMattersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What matters to me (long-term)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(notesPalette.textSecondary)
            
            GlassCard(padding: AppTheme.cardPaddingCompact) {
                ZStack(alignment: .topLeading) {
                    if whatMatters.isEmpty {
                        Text("What do you value most in this area of life?")
                            .font(.body)
                            .foregroundStyle(notesPalette.textTertiary)
                            .padding(.top, 6)
                    }
                    TextEditor(text: $whatMatters)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(notesPalette.textPrimary)
                        .focused($focusedField, equals: .whatMatters)
                }
            }
        }
    }
    
    // MARK: - Why It Matters
    
    private var whyItMattersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why it matters")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(notesPalette.textSecondary)
            
            GlassCard(padding: AppTheme.cardPaddingCompact) {
                ZStack(alignment: .topLeading) {
                    if whyItMatters.isEmpty {
                        Text("Why is this important to you?")
                            .font(.body)
                            .foregroundStyle(notesPalette.textTertiary)
                            .padding(.top, 6)
                    }
                    TextEditor(text: $whyItMatters)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(notesPalette.textPrimary)
                        .focused($focusedField, equals: .whyItMatters)
                }
            }
        }
    }
    
    // MARK: - How To Show Up
    
    private var howToShowUpSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How I want to show up")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(notesPalette.textSecondary)
            
            Text("A short intention statement for this area")
                .font(.system(size: 12))
                .foregroundStyle(notesPalette.textTertiary)
            
            GlassCard(padding: AppTheme.cardPaddingCompact) {
                ZStack(alignment: .topLeading) {
                    if howToShowUp.isEmpty {
                        Text("e.g., \"I want to be patient and present\"")
                            .font(.body)
                            .foregroundStyle(notesPalette.textTertiary)
                            .padding(.top, 6)
                    }
                    TextEditor(text: $howToShowUp)
                        .frame(minHeight: 60)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(notesPalette.textPrimary)
                        .focused($focusedField, equals: .howToShowUp)
                }
            }
        }
    }
    
    // MARK: - Keywords
    
    private var keywordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Keywords")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(notesPalette.textSecondary)
                
                Spacer()
                
                Button {
                    showValueSuggestions.toggle()
                } label: {
                    Text(showValueSuggestions ? "Hide suggestions" : "Show suggestions")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(notesPalette.textTertiary)
                }
                .buttonStyle(.plain)
            }
            
            Text("Select from common values or add your own")
                .font(.system(size: 12))
                .foregroundStyle(notesPalette.textTertiary)
            
            // Custom keyword input
            GlassCard(padding: AppTheme.cardPaddingCompact) {
                TextField("Add custom value (e.g., patience, honesty)", text: $customKeywordInput)
                    .textFieldStyle(.plain)
                    .foregroundStyle(notesPalette.textPrimary)
                    .focused($focusedField, equals: .keywords)
                    .onSubmit {
                        addCustomKeyword()
                    }
            }
            
            // Display selected keywords as chips
            if !parsedKeywords.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Selected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(notesPalette.textTertiary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(parsedKeywords, id: \.self) { keyword in
                                Button {
                                    removeKeyword(keyword)
                                } label: {
                                    GlassPill(padding: EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)) {
                                        HStack(spacing: 4) {
                                            Text(keyword)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundStyle(notesPalette.textSecondary)
                                            Image(systemName: "xmark")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(notesPalette.textTertiary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            
            // Suggested values from checklist
            if showValueSuggestions {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Suggested values")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(notesPalette.textTertiary)
                        
                        Spacer()
                        
                        // Search field for values
                        TextField("Search...", text: $searchQuery)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .foregroundStyle(notesPalette.textPrimary)
                            .frame(width: 120)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(notesPalette.surface.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    
                    let suggestions = filteredValueSuggestions
                    if !suggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestions.prefix(20)) { value in
                                    let isSelected = parsedKeywords.contains(value.name)
                                    Button {
                                        toggleValue(value.name)
                                    } label: {
                                        GlassPill(padding: EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)) {
                                            HStack(spacing: 4) {
                                                Text(value.name)
                                                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                                                    .foregroundStyle(isSelected ? notesPalette.textPrimary : notesPalette.textSecondary)
                                                if isSelected {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 9, weight: .bold))
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
        }
    }
    
    private var parsedKeywords: [String] {
        keywordsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private var filteredValueSuggestions: [ValueItem] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            // Show all values, excluding already selected ones
            return ValuesChecklist.allValues.filter { !parsedKeywords.contains($0.name) }
        } else {
            // Search and filter out selected
            return ValuesChecklist.search(query).filter { !parsedKeywords.contains($0.name) }
        }
    }
    
    private func toggleValue(_ valueName: String) {
        var keywords = Set(parsedKeywords)
        if keywords.contains(valueName) {
            keywords.remove(valueName)
        } else {
            keywords.insert(valueName)
        }
        keywordsText = Array(keywords).sorted().joined(separator: ", ")
    }
    
    private func removeKeyword(_ keyword: String) {
        var keywords = Set(parsedKeywords)
        keywords.remove(keyword)
        keywordsText = Array(keywords).sorted().joined(separator: ", ")
    }
    
    private func addCustomKeyword() {
        let trimmed = customKeywordInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Check if it's already in the list
        if !parsedKeywords.contains(trimmed) {
            var keywords = Set(parsedKeywords)
            keywords.insert(trimmed)
            keywordsText = Array(keywords).sorted().joined(separator: ", ")
        }
        // Clear the input field
        customKeywordInput = ""
    }
    
    // MARK: - Importance
    
    private var importanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Importance to me")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(notesPalette.textSecondary)
            
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        importance = importance == level ? 0 : level
                    } label: {
                        ZStack {
                            Circle()
                                .fill(importance >= level ? notesPalette.textSecondary : notesPalette.surface)
                                .frame(width: 36, height: 36)
                            
                            Circle()
                                .stroke(notesPalette.separator, lineWidth: 1)
                                .frame(width: 36, height: 36)
                            
                            Text("\(level)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(importance >= level ? notesPalette.background : notesPalette.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                if importance > 0 {
                    Text(importanceLabel)
                        .font(.system(size: 12))
                        .foregroundStyle(notesPalette.textTertiary)
                }
            }
        }
    }
    
    private var importanceLabel: String {
        switch importance {
        case 1: return "Slightly important"
        case 2: return "Somewhat important"
        case 3: return "Important"
        case 4: return "Very important"
        case 5: return "Extremely important"
        default: return ""
        }
    }
    
    // MARK: - Actions
    
    private func loadEntry() async {
        guard !hasLoadedEntry else { return }
        await service.load()
        let entry = service.entry(for: category)
        whatMatters = entry.whatMatters
        whyItMatters = entry.whyItMatters
        howToShowUp = entry.howToShowUp
        keywordsText = entry.keywords.joined(separator: ", ")
        importance = entry.importance ?? 0
        hasLoadedEntry = true
    }
    
    private func saveAndDismiss() {
        let entry = ValuesCategoryEntry(
            id: service.entry(for: category).id,
            category: category,
            whatMatters: whatMatters.trimmingCharacters(in: .whitespacesAndNewlines),
            whyItMatters: whyItMatters.trimmingCharacters(in: .whitespacesAndNewlines),
            howToShowUp: howToShowUp.trimmingCharacters(in: .whitespacesAndNewlines),
            keywords: parsedKeywords,
            importance: importance > 0 ? importance : nil,
            updatedAt: Date()
        )
        service.updateEntry(entry)
        router.pop()
    }
}

// MARK: - Preview

#Preview("Category Detail - Light") {
    NavigationStack {
        ValuesCategoryDetailView(category: .romanticRelationships)
            .environmentObject(AppRouter())
            .modelContainer(try! ModelContainerConfig.makePreviewContainer())
            .notesTheme()
            .preferredColorScheme(.light)
    }
}

#Preview("Category Detail - Dark") {
    NavigationStack {
        ValuesCategoryDetailView(category: .personalGrowth)
            .environmentObject(AppRouter())
            .modelContainer(try! ModelContainerConfig.makePreviewContainer())
            .notesTheme()
            .preferredColorScheme(.dark)
    }
}
