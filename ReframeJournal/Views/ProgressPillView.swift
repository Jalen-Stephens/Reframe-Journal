import SwiftUI

enum ProgressStatus {
    case inProgress
    case complete
}

struct ProgressPillView: View {
    @Environment(\.notesPalette) private var notesPalette

    let status: ProgressStatus
    var label: String? = nil

    var body: some View {
        let text = label ?? (status == .complete ? "Complete" : "In progress")
        let background = status == .complete ? notesPalette.accent : notesPalette.muted
        let foreground = status == .complete ? notesPalette.onAccent : notesPalette.textSecondary

        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background)
            .clipShape(Capsule())
    }
}
