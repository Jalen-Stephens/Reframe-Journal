// File: Models/ReframeResponse.swift
import Foundation

struct ReframeResponse: Codable, Equatable {
    let summary: String
    let cognitiveDistortionsDetected: [String]
    let alternativeThoughts: [String]
    let actionSteps: [String]
    let compassionateCoachMessage: String
    let suggestedExperiment: String
}
