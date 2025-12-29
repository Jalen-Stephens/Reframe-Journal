import SwiftUI

struct ExpandableTextView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let text: String
    var lineLimit: Int = 2
    var placeholder: String? = nil
    var textStyle: Font = .system(size: 14)

    @State private var isExpanded = false

    var body: some View {
        let displayText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        VStack(alignment: .leading, spacing: 6) {
            Text(displayText.isEmpty ? (placeholder ?? "") : displayText)
                .font(textStyle)
                .foregroundColor(displayText.isEmpty ? themeManager.theme.textSecondary : themeManager.theme.textPrimary)
                .lineLimit(isExpanded ? nil : lineLimit)
            if displayText.count > 120 {
                Button(isExpanded ? "Show less" : "Read more") {
                    isExpanded.toggle()
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeManager.theme.accent)
            }
        }
    }
}
