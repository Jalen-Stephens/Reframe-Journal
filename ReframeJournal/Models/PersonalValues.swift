// File: Models/PersonalValues.swift
// SwiftData model for storing user's personal values across 10 categories

import Foundation
import SwiftData

// MARK: - Personal Values Model

@Model
final class PersonalValues {
    // MARK: - Primary Key
    
    /// Unique identifier to ensure only one instance exists
    @Attribute(.unique) var id: String = "personal_values_singleton"
    
    // MARK: - Timestamps
    
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Value Categories
    
    var romanticRelationships: String?
    var leisureAndFun: String?
    var jobCareer: String?
    var friends: String?
    var parenthood: String?
    var healthAndPhysicalWellness: String?
    var socialCitizenshipEnvironmentalResponsibility: String?
    var familyRelationships: String?
    var spirituality: String?
    var personalDevelopmentAndGrowth: String?
    
    // MARK: - Initialization
    
    init(
        id: String = "personal_values_singleton",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        romanticRelationships: String? = nil,
        leisureAndFun: String? = nil,
        jobCareer: String? = nil,
        friends: String? = nil,
        parenthood: String? = nil,
        healthAndPhysicalWellness: String? = nil,
        socialCitizenshipEnvironmentalResponsibility: String? = nil,
        familyRelationships: String? = nil,
        spirituality: String? = nil,
        personalDevelopmentAndGrowth: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.romanticRelationships = romanticRelationships
        self.leisureAndFun = leisureAndFun
        self.jobCareer = jobCareer
        self.friends = friends
        self.parenthood = parenthood
        self.healthAndPhysicalWellness = healthAndPhysicalWellness
        self.socialCitizenshipEnvironmentalResponsibility = socialCitizenshipEnvironmentalResponsibility
        self.familyRelationships = familyRelationships
        self.spirituality = spirituality
        self.personalDevelopmentAndGrowth = personalDevelopmentAndGrowth
    }
    
    // MARK: - Helper Methods
    
    /// Updates the updatedAt timestamp
    func touch() {
        updatedAt = Date()
    }
}
