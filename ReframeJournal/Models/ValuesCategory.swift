// File: Models/ValuesCategory.swift
// Enum defining the 10 personal values categories with icons and suggested values

import Foundation

enum ValuesCategory: String, CaseIterable, Identifiable, Hashable {
    case romanticRelationships
    case leisureAndFun
    case jobCareer
    case friends
    case parenthood
    case healthAndPhysicalWellness
    case socialCitizenshipEnvironmentalResponsibility
    case familyRelationships
    case spirituality
    case personalDevelopmentAndGrowth
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .romanticRelationships: return "Romantic Relationships"
        case .leisureAndFun: return "Leisure and Fun"
        case .jobCareer: return "Job/Career"
        case .friends: return "Friends"
        case .parenthood: return "Parenthood"
        case .healthAndPhysicalWellness: return "Health and Physical Wellness"
        case .socialCitizenshipEnvironmentalResponsibility: return "Social Citizenship/Environmental Responsibility"
        case .familyRelationships: return "Family Relationships"
        case .spirituality: return "Spirituality"
        case .personalDevelopmentAndGrowth: return "Personal Development and Growth"
        }
    }
    
    var icon: String {
        switch self {
        case .romanticRelationships: return "heart.fill"
        case .leisureAndFun: return "gamecontroller.fill"
        case .jobCareer: return "briefcase.fill"
        case .friends: return "person.2.fill"
        case .parenthood: return "figure.2.and.child.holdinghands"
        case .healthAndPhysicalWellness: return "heart.circle.fill"
        case .socialCitizenshipEnvironmentalResponsibility: return "leaf.fill"
        case .familyRelationships: return "house.fill"
        case .spirituality: return "sparkles"
        case .personalDevelopmentAndGrowth: return "brain.head.profile"
        }
    }
    
    var description: String {
        switch self {
        case .romanticRelationships:
            return "What sort of partner would you ideally like to be? How would you describe your ideal relationship? What sort of behaviors do you aspire to show toward a significant other?"
        case .leisureAndFun:
            return "What kinds of activities appeal to you for fun? How would you enjoy spending your down time? What's exciting for you? Relaxing?"
        case .jobCareer:
            return "What career goals matter to you? What kind of employment? Do you aspire to particular qualities as a worker? What sort of professional relationships do you want to develop?"
        case .friends:
            return "What social relationships do you consider important to develop? What do you consider an important social life to have? How would you like your friends to see you as a person?"
        case .parenthood:
            return "What kind of mother or father do you aspire to be? Are there particular qualities you'd like to role model for your kids? How would you describe your ideal relationships with them?"
        case .healthAndPhysicalWellness:
            return "Fitness goals, aspirations, as well as the importance of personal health, physical well-being, and personal care."
        case .socialCitizenshipEnvironmentalResponsibility:
            return "Being part of the community, environmental aspirations, and can include volunteer work."
        case .familyRelationships:
            return "Values pertaining to relatives like siblings, extended family, and so forth."
        case .spirituality:
            return "Religion, personal beliefs about anything that's meaningful at a deeper or bigger level."
        case .personalDevelopmentAndGrowth:
            return "Personal capabilities, competencies, skills, knowledge, and growth."
        }
    }
    
    var suggestedValues: [String] {
        switch self {
        case .romanticRelationships:
            return ["Trust", "Communication", "Respect", "Intimacy", "Partnership", "Support", "Honesty", "Loyalty", "Understanding", "Compassion"]
        case .leisureAndFun:
            return ["Adventure", "Creativity", "Relaxation", "Exploration", "Entertainment", "Socializing", "Learning", "Nature", "Sports", "Hobbies"]
        case .jobCareer:
            return ["Growth", "Impact", "Collaboration", "Innovation", "Excellence", "Leadership", "Balance", "Purpose", "Recognition", "Autonomy"]
        case .friends:
            return ["Loyalty", "Trust", "Support", "Fun", "Honesty", "Understanding", "Respect", "Connection", "Reliability", "Empathy"]
        case .parenthood:
            return ["Patience", "Love", "Guidance", "Protection", "Teaching", "Nurturing", "Respect", "Understanding", "Presence", "Values"]
        case .healthAndPhysicalWellness:
            return ["Fitness", "Energy", "Strength", "Vitality", "Balance", "Wellness", "Discipline", "Self-care", "Endurance", "Health"]
        case .socialCitizenshipEnvironmentalResponsibility:
            return ["Service", "Community", "Sustainability", "Environment", "Volunteering", "Impact", "Responsibility", "Conservation", "Advocacy", "Contribution"]
        case .familyRelationships:
            return ["Connection", "Support", "Tradition", "Love", "Respect", "Communication", "Unity", "Care", "Understanding", "Bonding"]
        case .spirituality:
            return ["Faith", "Meaning", "Connection", "Peace", "Purpose", "Gratitude", "Mindfulness", "Compassion", "Wisdom", "Transcendence"]
        case .personalDevelopmentAndGrowth:
            return ["Learning", "Growth", "Self-awareness", "Improvement", "Skills", "Knowledge", "Resilience", "Curiosity", "Adaptability", "Excellence"]
        }
    }
    
    func getValue(from personalValues: PersonalValues) -> String? {
        switch self {
        case .romanticRelationships: return personalValues.romanticRelationships
        case .leisureAndFun: return personalValues.leisureAndFun
        case .jobCareer: return personalValues.jobCareer
        case .friends: return personalValues.friends
        case .parenthood: return personalValues.parenthood
        case .healthAndPhysicalWellness: return personalValues.healthAndPhysicalWellness
        case .socialCitizenshipEnvironmentalResponsibility: return personalValues.socialCitizenshipEnvironmentalResponsibility
        case .familyRelationships: return personalValues.familyRelationships
        case .spirituality: return personalValues.spirituality
        case .personalDevelopmentAndGrowth: return personalValues.personalDevelopmentAndGrowth
        }
    }
    
    func setValue(_ value: String?, in personalValues: PersonalValues) {
        switch self {
        case .romanticRelationships: personalValues.romanticRelationships = value
        case .leisureAndFun: personalValues.leisureAndFun = value
        case .jobCareer: personalValues.jobCareer = value
        case .friends: personalValues.friends = value
        case .parenthood: personalValues.parenthood = value
        case .healthAndPhysicalWellness: personalValues.healthAndPhysicalWellness = value
        case .socialCitizenshipEnvironmentalResponsibility: personalValues.socialCitizenshipEnvironmentalResponsibility = value
        case .familyRelationships: personalValues.familyRelationships = value
        case .spirituality: personalValues.spirituality = value
        case .personalDevelopmentAndGrowth: personalValues.personalDevelopmentAndGrowth = value
        }
    }
}
