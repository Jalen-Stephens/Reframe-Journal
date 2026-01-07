import SwiftUI

struct PrimaryButton: View {
    @Environment(\.notesPalette) private var notesPalette

    let label: String
    let onPress: () -> Void
    var disabled: Bool = false
    var onDisabledPress: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            if disabled {
                onDisabledPress?()
            } else {
                onPress()
            }
        }) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(notesPalette.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(notesPalette.accent)
                .clipShape(Capsule())
                .opacity(disabled ? 0.5 : 1)
        }
        .accessibilityHint(disabled ? "Disabled" : "")
    }
}
