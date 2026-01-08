// File: Models/ValuesProfile.swift
// User's complete values profile and per-entry selected values

import Foundation

// MARK: - ValuesProfile

/// The user's complete values profile containing entries for all 10 categories.
/// Stored locally and can be migrated to SwiftData/iCloud later.
struct ValuesProfile: Codable, Equatable {
    let id: String
    var entries: [ValuesCategory: ValuesCategoryEntry]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = Identifiers.generateId(),
        entries: [ValuesCategory: ValuesCategoryEntry] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.entries = entries
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Creates a profile with empty entries for all categories
    static func empty() -> ValuesProfile {
        var entries: [ValuesCategory: ValuesCategoryEntry] = [:]
        for category in ValuesCategory.allCases {
            entries[category] = ValuesCategoryEntry.empty(for: category)
        }
        return ValuesProfile(entries: entries)
    }
    
    /// Returns the entry for a category, creating an empty one if needed
    func entry(for category: ValuesCategory) -> ValuesCategoryEntry {
        entries[category] ?? ValuesCategoryEntry.empty(for: category)
    }
    
    /// Updates an entry for a category
    mutating func updateEntry(_ entry: ValuesCategoryEntry) {
        entries[entry.category] = entry
        updatedAt = Date()
    }
    
    /// Categories that have content, sorted by importance (highest first)
    var categoriesWithContent: [ValuesCategory] {
        entries.values
            .filter { $0.hasContent }
            .sorted { ($0.importance ?? 0) > ($1.importance ?? 0) }
            .map { $0.category }
    }
    
    /// Top 3 most important categories with content
    var topCategories: [ValuesCategory] {
        Array(categoriesWithContent.prefix(3))
    }
    
    /// Whether the profile has any meaningful content
    var hasContent: Bool {
        entries.values.contains { $0.hasContent }
    }
    
    /// All keywords across all categories
    var allKeywords: [String] {
        entries.values.flatMap { $0.keywords }
    }
    
    /// Completion progress (0.0 to 1.0)
    var completionProgress: Double {
        let filled = entries.values.filter { $0.hasContent }.count
        return Double(filled) / Double(ValuesCategory.allCases.count)
    }
}

// MARK: - SelectedValues

/// Values context selected for a specific thought entry.
/// Stored on ThoughtRecord/ThoughtEntry to personalize the AI reframe.
struct SelectedValues: Codable, Equatable, Hashable {
    var categories: [ValuesCategory]
    var keywords: [String]
    var howToShowUp: String
    
    init(
        categories: [ValuesCategory] = [],
        keywords: [String] = [],
        howToShowUp: String = ""
    ) {
        self.categories = categories
        self.keywords = keywords
        self.howToShowUp = howToShowUp
    }
    
    /// Whether any values have been selected
    var hasSelection: Bool {
        !categories.isEmpty || !keywords.isEmpty || !howToShowUp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Empty selection
    static let empty = SelectedValues()
    
    /// Brief summary for display
    var summaryText: String? {
        if !categories.isEmpty {
            let titles = categories.prefix(2).map { $0.title }
            if categories.count > 2 {
                return titles.joined(separator: ", ") + " +\(categories.count - 2)"
            }
            return titles.joined(separator: ", ")
        }
        if !keywords.isEmpty {
            return keywords.prefix(3).joined(separator: ", ")
        }
        return nil
    }
}

// MARK: - ValuesProfileSnippet

/// A lightweight snippet of values context for AI prompt construction.
/// Contains trimmed content to keep prompt tokens reasonable.
struct ValuesProfileSnippet: Codable, Equatable {
    let categories: [CategorySnippet]
    let howToShowUp: String
    let keywords: [String]
    
    struct CategorySnippet: Codable, Equatable {
        let title: String
        let whatMatters: String
        let howToShowUp: String
    }
    
    /// Creates a snippet from selected values and the full profile
    static func create(
        from selection: SelectedValues,
        profile: ValuesProfile,
        maxCharsPerField: Int = 200
    ) -> ValuesProfileSnippet {
        let categorySnippets = selection.categories.compactMap { category -> CategorySnippet? in
            let entry = profile.entry(for: category)
            guard entry.hasContent else { return nil }
            return CategorySnippet(
                title: category.title,
                whatMatters: truncate(entry.whatMatters, max: maxCharsPerField),
                howToShowUp: truncate(entry.howToShowUp, max: maxCharsPerField)
            )
        }
        
        return ValuesProfileSnippet(
            categories: categorySnippets,
            howToShowUp: truncate(selection.howToShowUp, max: maxCharsPerField),
            keywords: Array(selection.keywords.prefix(10))
        )
    }
    
    private static func truncate(_ text: String, max: Int) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= max { return trimmed }
        return String(trimmed.prefix(max)) + "…"
    }
    
    /// Whether this snippet has meaningful content
    var hasContent: Bool {
        !categories.isEmpty || !howToShowUp.isEmpty || !keywords.isEmpty
    }
}
