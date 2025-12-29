import SwiftUI

enum ProgressStatus {
    case inProgress
    case complete
}

struct ProgressPillView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let status: ProgressStatus
    var label: String? = nil

    var body: some View {
        let text = label ?? (status == .complete ? "Complete" : "In progress")
        let background = status == .complete ? themeManager.theme.accent : themeManager.theme.muted
        let foreground = status == .complete ? themeManager.theme.onAccent : themeManager.theme.textSecondary

        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background)
            .clipShape(Capsule())
    }
}
