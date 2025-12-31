import SwiftUI

struct LabeledInput: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let label: String
    let placeholder: String
    @Binding var text: String
    var isMultiline: Bool = false
    var multilineMinHeight: CGFloat = 90

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
                        .frame(minHeight: multilineMinHeight)
                        .padding(4)
                        .background(Color.clear)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(themeManager.theme.textPrimary)
                        .keyboardDismissToolbar()
                }
                .cardSurface(cornerRadius: 8, shadow: false)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .submitLabel(.done)
                    .onSubmit {
                        dismissKeyboard()
                    }
                    .padding(10)
                    .foregroundColor(themeManager.theme.textPrimary)
                    .cardSurface(cornerRadius: 8, shadow: false)
            }
        }
    }
}
