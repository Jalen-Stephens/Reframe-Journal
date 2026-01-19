// File: Persistence/ModelContainerConfig.swift
// SwiftData ModelContainer configuration with iCloud sync

import Foundation
import SwiftData

// MARK: - ModelContainer Configuration

enum ModelContainerConfig {
    /// Schema containing all SwiftData models
    static let schema = Schema([
        JournalEntry.self,
        ValuesProfileData.self,
        ValuesCategoryEntryData.self,
        PersonalValues.self
    ])
    
    /// Creates a ModelContainer with local storage only.
    /// Note: iCloud sync requires a paid Apple Developer account ($99/year).
    /// Personal/free accounts cannot use CloudKit/iCloud capabilities.
    /// To enable iCloud sync, upgrade to paid account and change cloudKitDatabase to .automatic
    static func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            "ReframeJournal",
            schema: schema,
            isStoredInMemoryOnly: false,
            // CloudKit disabled for personal accounts - change to .automatic with paid account
            cloudKitDatabase: .none
        )
        
        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
    
    /// Creates an in-memory container for previews and testing (no CloudKit)
    static func makePreviewContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            "PreviewReframeJournal",
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        
        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}

// MARK: - Preview Helpers

extension ModelContainer {
    /// Shared preview container with sample data
    @MainActor
    static var preview: ModelContainer {
        do {
            let container = try ModelContainerConfig.makePreviewContainer()
            
            // Add sample entries for previews
            let context = container.mainContext
            
            let sampleEntry = JournalEntry(
                title: "Sample Entry",
                situationText: "I felt anxious before the meeting",
                sensations: ["Racing heart", "Sweaty palms"],
                automaticThoughts: [
                    AutomaticThought(id: "thought1", text: "I'm going to mess up", beliefBefore: 80)
                ],
                emotions: [
                    Emotion(id: "emotion1", label: "Anxious", intensityBefore: 75, intensityAfter: nil)
                ]
            )
            
            context.insert(sampleEntry)
            
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}
