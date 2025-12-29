import SwiftUI

struct WizardProgressView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let step: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Step \(step) of \(total)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeManager.theme.textSecondary)
            GeometryReader { proxy in
                let progress = CGFloat(step) / CGFloat(total)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(themeManager.theme.muted)
                        .frame(height: 6)
                    Capsule()
                        .fill(themeManager.theme.accent)
                        .frame(width: proxy.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}
