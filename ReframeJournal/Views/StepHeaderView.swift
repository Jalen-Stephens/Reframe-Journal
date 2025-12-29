import SwiftUI

struct StepHeaderView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            BackButtonCircle(onTap: onBack)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.theme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(themeManager.theme.background)
    }
}

struct BackButtonCircle: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeManager.theme.textPrimary)
                .frame(width: 36, height: 36)
                .background(themeManager.theme.card)
                .overlay(
                    Circle()
                        .stroke(themeManager.theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
}
