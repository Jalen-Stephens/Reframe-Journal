import SwiftUI

struct ThoughtCardView: View {
    @Environment(\.notesPalette) private var notesPalette

    let text: String
    let belief: Int
    var badgeLabel: String? = nil
    var onEdit: (() -> Void)? = nil
    var onRemove: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(text)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(notesPalette.textPrimary)
                    .lineLimit(2)
                Spacer()
                if let onEdit {
                    Button("Edit") { onEdit() }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(notesPalette.accent)
                }
                if let onRemove {
                    Button("Remove") { onRemove() }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
            HStack {
                if let badgeLabel {
                    Text(badgeLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(notesPalette.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(notesPalette.muted)
                        .clipShape(Capsule())
                }
                Text("\(belief)%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(notesPalette.textSecondary)
                Spacer()
            }
        }
        .padding(12)
        .cardSurface(cornerRadius: 12, shadow: false)
    }
}
