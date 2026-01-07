import SwiftUI

struct ExpandableTextView: View {
    @Environment(\.notesPalette) private var notesPalette

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
                .foregroundColor(displayText.isEmpty ? notesPalette.textSecondary : notesPalette.textPrimary)
                .lineLimit(isExpanded ? nil : lineLimit)
            if displayText.count > 120 {
                Button(isExpanded ? "Show less" : "Read more") {
                    isExpanded.toggle()
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(notesPalette.accent)
            }
        }
    }
}
