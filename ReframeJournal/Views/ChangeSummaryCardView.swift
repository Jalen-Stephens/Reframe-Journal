import SwiftUI

struct ChangeSummaryCardView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let title: String
    let items: [String]
    let emptyState: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(themeManager.theme.textPrimary)
            if items.isEmpty {
                Text(emptyState)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.theme.textSecondary)
            } else {
                ForEach(items, id: \.self) { item in
                    Text("• \(item)")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.theme.textSecondary)
                }
            }
        }
        .padding(14)
        .background(themeManager.theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(themeManager.theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
