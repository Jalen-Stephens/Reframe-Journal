// File: Utilities/ValuesChecklist.swift
// Values checklist from ACT (Acceptance and Commitment Therapy) resources
// Based on "A Quick Look at Your Values" by Russ Harris

import Foundation

/// Comprehensive list of common values for users to select from
enum ValuesChecklist {
    static let allValues: [ValueItem] = [
        ValueItem(id: 1, name: "Acceptance", description: "to be open to and accepting of myself, others, life etc"),
        ValueItem(id: 2, name: "Adventure", description: "to be adventurous; to actively seek, create, or explore novel or stimulating experiences"),
        ValueItem(id: 3, name: "Assertiveness", description: "to respectfully stand up for my rights and request what I want"),
        ValueItem(id: 4, name: "Authenticity", description: "to be authentic, genuine, real; to be true to myself"),
        ValueItem(id: 5, name: "Beauty", description: "to appreciate, create, nurture or cultivate beauty in myself, others, the environment etc"),
        ValueItem(id: 6, name: "Caring", description: "to be caring towards myself, others, the environment etc"),
        ValueItem(id: 7, name: "Challenge", description: "to keep challenging myself to grow, learn, improve"),
        ValueItem(id: 8, name: "Compassion", description: "to act with kindness towards those who are suffering"),
        ValueItem(id: 9, name: "Connection", description: "to engage fully in whatever I am doing, and be fully present with others"),
        ValueItem(id: 10, name: "Contribution", description: "to contribute, help, assist, or make a positive difference to myself or others"),
        ValueItem(id: 11, name: "Conformity", description: "to be respectful and obedient of rules and obligations"),
        ValueItem(id: 12, name: "Cooperation", description: "to be cooperative and collaborative with others"),
        ValueItem(id: 13, name: "Courage", description: "to be courageous or brave; to persist in the face of fear, threat, or difficulty"),
        ValueItem(id: 14, name: "Creativity", description: "to be creative or innovative"),
        ValueItem(id: 15, name: "Curiosity", description: "to be curious, open-minded and interested; to explore and discover"),
        ValueItem(id: 16, name: "Encouragement", description: "to encourage and reward behaviour that I value in myself or others"),
        ValueItem(id: 17, name: "Equality", description: "to treat others as equal to myself, and vice-versa"),
        ValueItem(id: 18, name: "Excitement", description: "to seek, create and engage in activities that are exciting, stimulating or thrilling"),
        ValueItem(id: 19, name: "Fairness", description: "to be fair to myself or others"),
        ValueItem(id: 20, name: "Fitness", description: "to maintain or improve my fitness; to look after my physical and mental health and wellbeing"),
        ValueItem(id: 21, name: "Flexibility", description: "to adjust and adapt readily to changing circumstances"),
        ValueItem(id: 22, name: "Freedom", description: "to live freely; to choose how I live and behave, or help others do likewise"),
        ValueItem(id: 23, name: "Friendliness", description: "to be friendly, companionable, or agreeable towards others"),
        ValueItem(id: 24, name: "Forgiveness", description: "to be forgiving towards myself or others"),
        ValueItem(id: 25, name: "Fun", description: "to be fun-loving; to seek, create, and engage in fun-filled activities"),
        ValueItem(id: 26, name: "Generosity", description: "to be generous, sharing and giving, to myself or others"),
        ValueItem(id: 27, name: "Gratitude", description: "to be grateful for and appreciative of the positive aspects of myself, others and life"),
        ValueItem(id: 28, name: "Honesty", description: "to be honest, truthful, and sincere with myself and others"),
        ValueItem(id: 29, name: "Humour", description: "to see and appreciate the humorous side of life"),
        ValueItem(id: 30, name: "Humility", description: "to be humble or modest; to let my achievements speak for themselves"),
        ValueItem(id: 31, name: "Industry", description: "to be industrious, hard-working, dedicated"),
        ValueItem(id: 32, name: "Independence", description: "to be self-supportive, and choose my own way of doing things"),
        ValueItem(id: 33, name: "Intimacy", description: "to open up, reveal, and share myself -- emotionally or physically -- in my close personal relationships"),
        ValueItem(id: 34, name: "Justice", description: "to uphold justice and fairness"),
        ValueItem(id: 35, name: "Kindness", description: "to be kind, compassionate, considerate, nurturing or caring towards myself or others"),
        ValueItem(id: 36, name: "Love", description: "to act lovingly or affectionately towards myself or others"),
        ValueItem(id: 37, name: "Mindfulness", description: "to be conscious of, open to, and curious about my here-and-now experience"),
        ValueItem(id: 38, name: "Order", description: "to be orderly and organized"),
        ValueItem(id: 39, name: "Open-mindedness", description: "to think things through, see things from other's points of view, and weigh evidence fairly"),
        ValueItem(id: 40, name: "Patience", description: "to wait calmly for what I want"),
        ValueItem(id: 41, name: "Persistence", description: "to continue resolutely, despite problems or difficulties"),
        ValueItem(id: 42, name: "Pleasure", description: "to create and give pleasure to myself or others"),
        ValueItem(id: 43, name: "Power", description: "to strongly influence or wield authority over others, e.g. taking charge, leading, organizing"),
        ValueItem(id: 44, name: "Reciprocity", description: "to build relationships in which there is a fair balance of giving and taking"),
        ValueItem(id: 45, name: "Respect", description: "to be respectful towards myself or others; to be polite, considerate and show positive regard"),
        ValueItem(id: 46, name: "Responsibility", description: "to be responsible and accountable for my actions"),
        ValueItem(id: 47, name: "Romance", description: "to be romantic; to display and express love or strong affection"),
        ValueItem(id: 48, name: "Safety", description: "to secure, protect, or ensure safety of myself or others"),
        ValueItem(id: 49, name: "Self-awareness", description: "to be aware of my own thoughts, feelings and actions"),
        ValueItem(id: 50, name: "Self-care", description: "to look after my health and wellbeing, and get my needs met"),
        ValueItem(id: 51, name: "Self-development", description: "to keep growing, advancing or improving in knowledge, skills, character, or life experience"),
        ValueItem(id: 52, name: "Self-control", description: "to act in accordance with my own ideals"),
        ValueItem(id: 53, name: "Sensuality", description: "to create, explore and enjoy experiences that stimulate the five senses"),
        ValueItem(id: 54, name: "Sexuality", description: "to explore or express my sexuality"),
        ValueItem(id: 55, name: "Spirituality", description: "to connect with things bigger than myself"),
        ValueItem(id: 56, name: "Skilfulness", description: "to continually practice and improve my skills, and apply myself fully when using them"),
        ValueItem(id: 57, name: "Supportiveness", description: "to be supportive, helpful, encouraging, and available to myself or others"),
        ValueItem(id: 58, name: "Trust", description: "to be trustworthy; to be loyal, faithful, sincere, and reliable"),
    ]
    
    /// Search values by name (case-insensitive)
    static func search(_ query: String) -> [ValueItem] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return allValues
        }
        let lowerQuery = query.lowercased()
        return allValues.filter { $0.name.lowercased().contains(lowerQuery) }
    }
    
    /// Get values that match any of the provided keywords (for suggestions)
    static func matching(_ keywords: [String]) -> [ValueItem] {
        let lowerKeywords = Set(keywords.map { $0.lowercased() })
        return allValues.filter { value in
            lowerKeywords.contains(value.name.lowercased())
        }
    }
}

struct ValueItem: Identifiable, Hashable {
    let id: Int
    let name: String
    let description: String
}
