// File: Services/ValuesProfileService.swift
// SwiftData-based persistence for the user's values profile with iCloud sync

import Foundation
import SwiftData
import Combine

// MARK: - ValuesProfileService

/// Service for persisting and loading the user's values profile.
/// Uses SwiftData with CloudKit for automatic iCloud sync across devices.
@MainActor
final class ValuesProfileService: ObservableObject {
    @Published private(set) var profile: ValuesProfile
    @Published private(set) var isLoaded: Bool = false
    
    private var modelContext: ModelContext
    private var profileData: ValuesProfileData?
    private var hasMigratedFromJSON: Bool = false
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        // Start with empty profile, will load async
        self.profile = ValuesProfile.empty()
        
        // Load profile on init
        Task { await load() }
    }
    
    /// Updates the model context (used when environment context becomes available)
    func updateModelContext(_ newContext: ModelContext) {
        // Only update if different (compare by object identity)
        guard modelContext !== newContext else { return }
        modelContext = newContext
        // Reload if we already loaded with old context
        if isLoaded {
            isLoaded = false
            Task { await load() }
        }
    }
    
    // MARK: - Public API
    
    /// Loads the profile from SwiftData (with JSON migration if needed)
    func load() async {
        guard !isLoaded else { return }
        
        // First, try to migrate from JSON if it exists
        await migrateFromJSONIfNeeded()
        
        // Load from SwiftData
        do {
            let descriptor = FetchDescriptor<ValuesProfileData>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            let profiles = try modelContext.fetch(descriptor)
            
            if let existing = profiles.first {
                profileData = existing
                profile = existing.toValuesProfile()
            } else {
                // Create new profile
                let newProfileData = ValuesProfileData()
                modelContext.insert(newProfileData)
                try modelContext.save()
                profileData = newProfileData
                profile = newProfileData.toValuesProfile()
            }
        } catch {
            #if DEBUG
            print("ValuesProfileService: load failed - \(error)")
            #endif
            // Fallback to empty profile
            profile = ValuesProfile.empty()
        }
        
        isLoaded = true
    }
    
    /// Updates a category entry and persists
    func updateEntry(_ entry: ValuesCategoryEntry) {
        profile.updateEntry(entry)
        
        // Update SwiftData model
        if let profileData = profileData {
            // Check if entry already exists
            if let existingEntryData = profileData.entries.first(where: { $0.categoryRaw == entry.category.rawValue }) {
                // Update existing
                existingEntryData.whatMatters = entry.whatMatters
                existingEntryData.whyItMatters = entry.whyItMatters
                existingEntryData.howToShowUp = entry.howToShowUp
                existingEntryData.keywords = entry.keywords
                existingEntryData.importance = entry.importance
                existingEntryData.updatedAt = entry.updatedAt
            } else {
                // Create new entry
                let entryData = ValuesCategoryEntryData.from(entry, profile: profileData)
                modelContext.insert(entryData)
                profileData.entries.append(entryData)
            }
            profileData.updatedAt = Date()
        } else {
            // Create profile if it doesn't exist
            Task {
                await ensureProfileExists()
                if let profileData = profileData {
                    let entryData = ValuesCategoryEntryData.from(entry, profile: profileData)
                    modelContext.insert(entryData)
                    profileData.entries.append(entryData)
                    profileData.updatedAt = Date()
                }
            }
        }
        
        save()
    }
    
    /// Updates the entire profile
    func updateProfile(_ newProfile: ValuesProfile) {
        profile = newProfile
        
        if let profileData = profileData {
            // Update existing
            profileData.updatedAt = newProfile.updatedAt
            // Update entries
            for (_, entry) in newProfile.entries {
                let entryData = ValuesCategoryEntryData.from(entry, profile: profileData)
                profileData.updateEntry(entryData)
            }
        } else {
            // Create new
            Task {
                let newProfileData = ValuesProfileData.from(newProfile, context: modelContext)
                profileData = newProfileData
                try? modelContext.save()
            }
        }
        
        save()
    }
    
    /// Gets the entry for a category
    func entry(for category: ValuesCategory) -> ValuesCategoryEntry {
        profile.entry(for: category)
    }
    
    /// Creates a snippet for AI prompt construction
    func createSnippet(for selection: SelectedValues) -> ValuesProfileSnippet {
        ValuesProfileSnippet.create(from: selection, profile: profile)
    }
    
    /// Clears the profile (for testing or reset)
    func clear() async {
        profile = ValuesProfile.empty()
        if let profileData = profileData {
            modelContext.delete(profileData)
            self.profileData = nil
        }
        try? modelContext.save()
    }
    
    // MARK: - Private
    
    private func ensureProfileExists() async {
        guard profileData == nil else { return }
        
        do {
            let descriptor = FetchDescriptor<ValuesProfileData>()
            let profiles = try modelContext.fetch(descriptor)
            
            if let existing = profiles.first {
                profileData = existing
                profile = existing.toValuesProfile()
            } else {
                let newProfileData = ValuesProfileData()
                modelContext.insert(newProfileData)
                try modelContext.save()
                profileData = newProfileData
                profile = newProfileData.toValuesProfile()
            }
        } catch {
            #if DEBUG
            print("ValuesProfileService: ensureProfileExists failed - \(error)")
            #endif
        }
    }
    
    private func save() {
        do {
            try modelContext.save()
            #if DEBUG
            print("ValuesProfileService: saved profile to SwiftData/CloudKit")
            #endif
        } catch {
            #if DEBUG
            print("ValuesProfileService: save failed - \(error)")
            #endif
        }
    }
    
    // MARK: - JSON Migration
    
    /// Migrates existing JSON profile to SwiftData if it exists
    private func migrateFromJSONIfNeeded() async {
        guard !hasMigratedFromJSON else { return }
        hasMigratedFromJSON = true
        
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let profileURL = documents.appendingPathComponent("values_profile.json")
        
        guard fileManager.fileExists(atPath: profileURL.path) else {
            return // No JSON file to migrate
        }
        
        do {
            let data = try Data(contentsOf: profileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let jsonProfile = try decoder.decode(ValuesProfile.self, from: data)
            
            // Check if we already have a SwiftData profile
            let descriptor = FetchDescriptor<ValuesProfileData>()
            let existing = try modelContext.fetch(descriptor).first
            
            if existing == nil {
                // Migrate to SwiftData
                let profileData = ValuesProfileData.from(jsonProfile, context: modelContext)
                modelContext.insert(profileData)
                try modelContext.save()
                self.profileData = profileData
                profile = jsonProfile
                
                // Delete JSON file after successful migration
                try? fileManager.removeItem(at: profileURL)
                
                #if DEBUG
                print("ValuesProfileService: migrated JSON profile to SwiftData/CloudKit")
                #endif
            } else {
                // We have both - keep SwiftData version (it's newer/synced)
                #if DEBUG
                print("ValuesProfileService: SwiftData profile exists, keeping it over JSON")
                #endif
            }
        } catch {
            #if DEBUG
            print("ValuesProfileService: JSON migration failed - \(error)")
            #endif
        }
    }
}

// MARK: - ValuesProfileService Environment

import SwiftUI

private struct ValuesProfileServiceKey: EnvironmentKey {
    @MainActor
    static var defaultValue: ValuesProfileService {
        // This will be overridden by the app to provide the actual ModelContext
        fatalError("ValuesProfileService must be provided via environment with ModelContext")
    }
}

extension EnvironmentValues {
    @MainActor
    var valuesProfileService: ValuesProfileService {
        get { self[ValuesProfileServiceKey.self] }
        set { self[ValuesProfileServiceKey.self] = newValue }
    }
}
