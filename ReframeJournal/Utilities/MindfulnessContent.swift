import Foundation

/// Static content and prompts for DBT mindfulness skills
struct MindfulnessContent {
    
    // MARK: - What Skills
    
    struct Observe {
        static let title = "Observe"
        static let description = "Notice your experience without getting caught up in it. Just pay attention, moment by moment."
        static let instructions = [
            "Notice what you're experiencing right now",
            "Pay attention to your breath",
            "Observe sensations in your body",
            "Watch thoughts come and go without judgment",
            "Notice sounds, sights, and other sensory experiences"
        ]
    }
    
    struct Describe {
        static let title = "Describe"
        static let description = "Put words on your experience. Label what you observe without interpretations or judgments."
        static let instructions = [
            "Name what you're experiencing",
            "Use factual, concrete language",
            "Describe sensations: 'I feel tension in my shoulders'",
            "Label emotions: 'I notice the feeling of anxiety'",
            "Stick to what you observe, not what you think it means"
        ]
    }
    
    struct Participate {
        static let title = "Participate"
        static let description = "Throw yourself completely into the present moment. Be fully present in what you're doing."
        static let instructions = [
            "Engage fully in the current activity",
            "Let go of self-consciousness",
            "Become one with the experience",
            "Flow with whatever is happening",
            "Practice with everyday activities: eating, walking, listening"
        ]
    }
    
    // MARK: - How Skills
    
    struct Nonjudgmentally {
        static let title = "Nonjudgmentally"
        static let description = "See, but don't evaluate as good or bad. Just the facts."
        static let instructions = [
            "Notice judgments when they arise",
            "Replace 'This is terrible' with 'I'm having this experience'",
            "Acknowledge values and feelings without judging them",
            "Accept each moment like a blanket accepting rain and sun",
            "When you find yourself judging, don't judge your judging"
        ]
    }
    
    struct OneMindfully {
        static let title = "One-Mindfully"
        static let description = "Do one thing at a time. Be completely present to this one moment."
        static let instructions = [
            "Focus on one thing at a time",
            "Notice the desire to multitask and let it go",
            "When eating, eat. When walking, walk.",
            "Let go of distractions gently, returning to what you're doing",
            "Rivet yourself to now"
        ]
    }
    
    struct Effectively {
        static let title = "Effectively"
        static let description = "Focus on what works. Do what's necessary to achieve your goals in the situation."
        static let instructions = [
            "Be mindful of your goals",
            "Focus on what works, not what's 'right'",
            "Play by the rules",
            "Act as skillfully as you can",
            "Let go of willfulness and sitting on your hands"
        ]
    }
    
    // MARK: - Skill Practice Ideas
    
    static func practiceIdeas(for skill: String) -> [String] {
        switch skill.lowercased() {
        case "observe":
            return [
                "Practice observing your breath",
                "Notice five things you can see",
                "Observe sensations in your body",
                "Watch thoughts without engaging",
                "Notice sounds around you"
            ]
        case "describe":
            return [
                "Describe what you're experiencing right now",
                "Write a nonjudgmental description of your situation",
                "Label your emotions with specific words",
                "Describe physical sensations factually",
                "Practice describing without interpretations"
            ]
        case "participate":
            return [
                "Fully engage in one activity",
                "Practice with eating mindfully",
                "Participate fully in a conversation",
                "Be fully present while walking",
                "Throw yourself into a creative activity"
            ]
        case "nonjudgmentally", "non-judgmentally":
            return [
                "Notice and label judgmental thoughts",
                "Replace judgments with factual descriptions",
                "Practice observing without evaluating",
                "Accept your experience as it is",
                "Acknowledge feelings without judging them"
            ]
        case "one-mindfully", "onemindfully":
            return [
                "Do one task at a time",
                "Focus fully on your current activity",
                "Let go of the desire to multitask",
                "Return attention when distracted",
                "Be completely present to this moment"
            ]
        case "effectively":
            return [
                "Ask yourself: 'Is this effective?'",
                "Focus on your goals, not being right",
                "Act skillfully in the situation",
                "Let go of willfulness",
                "Do what's necessary to achieve your goals"
            ]
        default:
            return []
        }
    }
    
    // MARK: - Quick Relaxation Guide
    
    static let quickRelaxationSteps = [
        "Take a deep breath in, counting to four",
        "Hold your breath for a count of four",
        "Exhale slowly, counting to four",
        "Repeat 3-5 times",
        "Notice how your body feels now"
    ]
    
    static let mindfulnessReminder = "Remember: You can't stop the waves, but you can learn to surf."
}
