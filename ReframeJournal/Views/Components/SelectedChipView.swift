import SwiftUI

struct SelectedChipView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let label: String
    let onRemove: () -> Void

    var body: some View {
        Button(action: onRemove) {
            HStack(spacing: 6) {
                Text(label)
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(themeManager.theme.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(themeManager.theme.muted)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove \(label)")
    }
}
