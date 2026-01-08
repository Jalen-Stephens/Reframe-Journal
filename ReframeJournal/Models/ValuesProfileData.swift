// File: Models/ValuesProfileData.swift
// SwiftData models for Values Profile with iCloud sync

import Foundation
import SwiftData

// MARK: - ValuesProfileData

/// SwiftData model for the user's values profile.
/// Syncs automatically across devices via CloudKit/iCloud.
@Model
final class ValuesProfileData {
    @Attribute(.unique) var id: String
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \ValuesCategoryEntryData.profile)
    var entries: [ValuesCategoryEntryData] = []
    
    init(
        id: String = Identifiers.generateId(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Gets the entry for a category, creating one if needed
    func entry(for category: ValuesCategory) -> ValuesCategoryEntryData {
        if let existing = entries.first(where: { $0.categoryRaw == category.rawValue }) {
            return existing
        }
        let newEntry = ValuesCategoryEntryData(category: category, profile: self)
        entries.append(newEntry)
        return newEntry
    }
    
    /// Updates an entry for a category
    func updateEntry(_ entry: ValuesCategoryEntryData) {
        // Remove existing entry for this category if it exists
        if let existingIndex = entries.firstIndex(where: { $0.categoryRaw == entry.categoryRaw && $0.id != entry.id }) {
            entries.remove(at: existingIndex)
            // Note: We don't delete from context here to avoid cascade issues
        }
        
        // Add or update the entry
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            // Update existing
            entries[index] = entry
        } else {
            // Add new
            entries.append(entry)
        }
        updatedAt = Date()
    }
    
    /// Converts to the struct-based ValuesProfile for compatibility
    func toValuesProfile() -> ValuesProfile {
        var profileEntries: [ValuesCategory: ValuesCategoryEntry] = [:]
        for entryData in entries {
            if let category = ValuesCategory(rawValue: entryData.categoryRaw) {
                profileEntries[category] = entryData.toValuesCategoryEntry()
            }
        }
        return ValuesProfile(
            id: id,
            entries: profileEntries,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    /// Creates from a struct-based ValuesProfile
    static func from(_ profile: ValuesProfile, context: ModelContext) -> ValuesProfileData {
        let profileData: ValuesProfileData
        if let existing = try? context.fetch(FetchDescriptor<ValuesProfileData>(
            predicate: #Predicate { $0.id == profile.id }
        )).first {
            profileData = existing
            // Clear existing entries to replace with new ones
            for entry in profileData.entries {
                context.delete(entry)
            }
            profileData.entries.removeAll()
        } else {
            profileData = ValuesProfileData(id: profile.id, createdAt: profile.createdAt, updatedAt: profile.updatedAt)
            context.insert(profileData)
        }
        
        // Update entries
        for (_, entry) in profile.entries {
            let entryData = ValuesCategoryEntryData.from(entry, profile: profileData)
            context.insert(entryData)
            profileData.entries.append(entryData)
        }
        
        profileData.updatedAt = profile.updatedAt
        return profileData
    }
}

// MARK: - ValuesCategoryEntryData

/// SwiftData model for a single values category entry.
@Model
final class ValuesCategoryEntryData {
    @Attribute(.unique) var id: String
    var categoryRaw: String
    var whatMatters: String
    var whyItMatters: String
    var howToShowUp: String
    var keywordsData: Data? // Encoded [String]
    var importance: Int? // 1-5, nil if not set
    var updatedAt: Date
    
    var profile: ValuesProfileData?
    
    init(
        id: String = Identifiers.generateId(),
        category: ValuesCategory,
        whatMatters: String = "",
        whyItMatters: String = "",
        howToShowUp: String = "",
        keywords: [String] = [],
        importance: Int? = nil,
        updatedAt: Date = Date(),
        profile: ValuesProfileData? = nil
    ) {
        self.id = id
        self.categoryRaw = category.rawValue
        self.whatMatters = whatMatters
        self.whyItMatters = whyItMatters
        self.howToShowUp = howToShowUp
        self.keywordsData = try? JSONEncoder().encode(keywords)
        self.importance = importance
        self.updatedAt = updatedAt
        self.profile = profile
    }
    
    /// Keywords as array (computed property)
    var keywords: [String] {
        get {
            guard let data = keywordsData,
                  let decoded = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            keywordsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// Category enum (computed property)
    var category: ValuesCategory {
        get {
            ValuesCategory(rawValue: categoryRaw) ?? .personalGrowth
        }
        set {
            categoryRaw = newValue.rawValue
        }
    }
    
    /// Converts to the struct-based ValuesCategoryEntry
    func toValuesCategoryEntry() -> ValuesCategoryEntry {
        ValuesCategoryEntry(
            id: id,
            category: category,
            whatMatters: whatMatters,
            whyItMatters: whyItMatters,
            howToShowUp: howToShowUp,
            keywords: keywords,
            importance: importance,
            updatedAt: updatedAt
        )
    }
    
    /// Creates from a struct-based ValuesCategoryEntry
    static func from(_ entry: ValuesCategoryEntry, profile: ValuesProfileData?) -> ValuesCategoryEntryData {
        ValuesCategoryEntryData(
            id: entry.id,
            category: entry.category,
            whatMatters: entry.whatMatters,
            whyItMatters: entry.whyItMatters,
            howToShowUp: entry.howToShowUp,
            keywords: entry.keywords,
            importance: entry.importance,
            updatedAt: entry.updatedAt,
            profile: profile
        )
    }
    
    /// Whether this entry has any meaningful content
    var hasContent: Bool {
        !whatMatters.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !whyItMatters.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !howToShowUp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !keywords.isEmpty
    }
}
