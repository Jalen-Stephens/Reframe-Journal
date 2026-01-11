// File: Models/ValuesCategory.swift
// Defines the 10 values categories from the Personal Values Worksheet

import Foundation

/// The 10 life categories from the Personal Values Worksheet.
/// These help users explore and clarify what matters most to them.
enum ValuesCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case romanticRelationships = "romantic_relationships"
    case leisureAndFun = "leisure_and_fun"
    case jobCareer = "job_career"
    case friends = "friends"
    case parenthood = "parenthood"
    case healthAndWellness = "health_and_wellness"
    case socialCitizenship = "social_citizenship"
    case familyRelationships = "family_relationships"
    case spirituality = "spirituality"
    case personalGrowth = "personal_growth"
    
    var id: String { rawValue }
    
    /// Display title for the category
    var title: String {
        switch self {
        case .romanticRelationships: return "Romantic Relationships"
        case .leisureAndFun: return "Leisure & Fun"
        case .jobCareer: return "Job / Career"
        case .friends: return "Friends"
        case .parenthood: return "Parenthood"
        case .healthAndWellness: return "Health & Wellness"
        case .socialCitizenship: return "Social Citizenship"
        case .familyRelationships: return "Family Relationships"
        case .spirituality: return "Spirituality"
        case .personalGrowth: return "Personal Growth"
        }
    }
    
    /// Short description/prompt for the category
    var description: String {
        switch self {
        case .romanticRelationships:
            return "What kind of partner do you want to be? What does your ideal relationship look like?"
        case .leisureAndFun:
            return "What activities bring you joy? How do you like to spend your free time?"
        case .jobCareer:
            return "What career goals matter to you? What kind of worker do you aspire to be?"
        case .friends:
            return "What does friendship mean to you? How do you want to show up for your friends?"
        case .parenthood:
            return "What kind of parent do you want to be? What qualities do you want to model?"
        case .healthAndWellness:
            return "What does physical well-being mean to you? What health goals matter most?"
        case .socialCitizenship:
            return "How do you want to contribute to your community and environment?"
        case .familyRelationships:
            return "How do you want to relate to your family members? What role do you play?"
        case .spirituality:
            return "What gives your life meaning at a deeper level? What beliefs guide you?"
        case .personalGrowth:
            return "What skills or capabilities do you want to develop? How do you want to grow?"
        }
    }
    
    /// SF Symbol icon for the category
    var iconName: String {
        switch self {
        case .romanticRelationships: return "heart.fill"
        case .leisureAndFun: return "sparkles"
        case .jobCareer: return "briefcase.fill"
        case .friends: return "person.2.fill"
        case .parenthood: return "figure.2.and.child.holdinghands"
        case .healthAndWellness: return "heart.text.square.fill"
        case .socialCitizenship: return "globe.americas.fill"
        case .familyRelationships: return "house.fill"
        case .spirituality: return "moon.stars.fill"
        case .personalGrowth: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - ValuesCategoryEntry

/// Entry data for a single values category.
/// Contains the user's reflections, keywords, and importance rating.
struct ValuesCategoryEntry: Codable, Equatable, Hashable, Identifiable {
    let id: String
    let category: ValuesCategory
    var whatMatters: String
    var whyItMatters: String
    var howToShowUp: String
    var keywords: [String]
    var importance: Int? // 1-5 scale, nil if not set
    var updatedAt: Date
    
    init(
        id: String = Identifiers.generateId(),
        category: ValuesCategory,
        whatMatters: String = "",
        whyItMatters: String = "",
        howToShowUp: String = "",
        keywords: [String] = [],
        importance: Int? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.whatMatters = whatMatters
        self.whyItMatters = whyItMatters
        self.howToShowUp = howToShowUp
        self.keywords = keywords
        self.importance = importance
        self.updatedAt = updatedAt
    }
    
    /// Creates an empty entry for a category
    static func empty(for category: ValuesCategory) -> ValuesCategoryEntry {
        ValuesCategoryEntry(category: category)
    }
    
    /// Whether this entry has any meaningful content
    var hasContent: Bool {
        !whatMatters.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !whyItMatters.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !howToShowUp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !keywords.isEmpty
    }
    
    /// Summary text for display (first non-empty field, truncated)
    var summaryText: String? {
        let candidates = [howToShowUp, whatMatters, whyItMatters]
        for text in candidates {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed.count > 80 ? String(trimmed.prefix(80)) + "…" : trimmed
            }
        }
        return nil
    }
}
