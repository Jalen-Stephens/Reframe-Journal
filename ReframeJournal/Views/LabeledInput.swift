import SwiftUI

struct LabeledInput: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let label: String
    let placeholder: String
    @Binding var text: String
    var isMultiline: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(themeManager.theme.textSecondary)
            if isMultiline {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(themeManager.theme.placeholder)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 10)
                    }
                    TextEditor(text: $text)
                        .frame(minHeight: 90)
                        .padding(4)
                        .background(themeManager.theme.card)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(themeManager.theme.textPrimary)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeManager.theme.border, lineWidth: 1)
                )
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(10)
                    .background(themeManager.theme.card)
                    .foregroundColor(themeManager.theme.textPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(themeManager.theme.border, lineWidth: 1)
                    )
            }
        }
    }
}
