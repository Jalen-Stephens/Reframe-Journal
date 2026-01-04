import SwiftUI

struct ChangeSummaryCardView: View {
    @Environment(\.notesPalette) private var notesPalette

    let title: String
    let items: [String]
    let emptyState: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(notesPalette.textPrimary)
            if items.isEmpty {
                Text(emptyState)
                    .font(.system(size: 12))
                    .foregroundColor(notesPalette.textSecondary)
            } else {
                ForEach(items, id: \.self) { item in
                    Text("• \(item)")
                        .font(.system(size: 12))
                        .foregroundColor(notesPalette.textSecondary)
                }
            }
        }
        .padding(14)
        .cardSurface(cornerRadius: 14)
    }
}
