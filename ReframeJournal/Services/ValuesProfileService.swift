// File: Services/ValuesProfileService.swift
// JSON-based persistence for the user's values profile
// Prepared for future migration to SwiftData/iCloud

import Foundation
import Combine

// MARK: - ValuesProfileService

/// Service for persisting and loading the user's values profile.
/// Uses FileManager + Codable JSON for local-first storage.
/// Can be migrated to SwiftData/iCloud later without changing the API.
@MainActor
final class ValuesProfileService: ObservableObject {
    @Published private(set) var profile: ValuesProfile
    @Published private(set) var isLoaded: Bool = false
    
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var saveTask: Task<Void, Never>?
    
    init() {
        // Start with empty profile, will load async
        self.profile = ValuesProfile.empty()
        
        // Configure encoder for readability
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        
        // Load profile on init
        Task { await load() }
    }
    
    // MARK: - Public API
    
    /// Loads the profile from disk
    func load() async {
        guard !isLoaded else { return }
        
        do {
            if let data = try? Data(contentsOf: profileURL),
               let loaded = try? decoder.decode(ValuesProfile.self, from: data) {
                profile = loaded
            }
        }
        isLoaded = true
    }
    
    /// Updates a category entry and persists
    func updateEntry(_ entry: ValuesCategoryEntry) {
        profile.updateEntry(entry)
        scheduleSave()
    }
    
    /// Updates the entire profile
    func updateProfile(_ newProfile: ValuesProfile) {
        profile = newProfile
        scheduleSave()
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
        try? fileManager.removeItem(at: profileURL)
    }
    
    // MARK: - Private
    
    private var profileURL: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("values_profile.json")
    }
    
    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            guard !Task.isCancelled else { return }
            await save()
        }
    }
    
    private func save() async {
        do {
            let data = try encoder.encode(profile)
            try data.write(to: profileURL, options: .atomic)
            #if DEBUG
            print("ValuesProfileService: saved profile to \(profileURL.lastPathComponent)")
            #endif
        } catch {
            #if DEBUG
            print("ValuesProfileService: save failed - \(error)")
            #endif
        }
    }
}

// MARK: - ValuesProfileService Environment

import SwiftUI

private struct ValuesProfileServiceKey: EnvironmentKey {
    @MainActor
    static var defaultValue: ValuesProfileService {
        ValuesProfileService()
    }
}

extension EnvironmentValues {
    @MainActor
    var valuesProfileService: ValuesProfileService {
        get { self[ValuesProfileServiceKey.self] }
        set { self[ValuesProfileServiceKey.self] = newValue }
    }
}
