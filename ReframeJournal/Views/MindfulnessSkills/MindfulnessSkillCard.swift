import SwiftUI

struct MindfulnessSkillCard: View {
    @Environment(\.notesPalette) private var notesPalette
    
    let title: String
    let description: String
    let instructions: [String]
    
    var body: some View {
        GlassCard(padding: AppTheme.cardPadding) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(notesPalette.textPrimary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(notesPalette.textSecondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(instructions.enumerated()), id: \.offset) { _, instruction in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundStyle(notesPalette.textTertiary)
                            Text(instruction)
                                .font(.footnote)
                                .foregroundStyle(notesPalette.textSecondary)
                        }
                    }
                }
            }
        }
    }
}
