import SwiftUI

struct StepBottomNavBar: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let onBack: () -> Void
    let onNext: () -> Void
    let nextLabel: String
    let isNextDisabled: Bool
    let isBackDisabled: Bool

    init(
        onBack: @escaping () -> Void,
        onNext: @escaping () -> Void,
        nextLabel: String = "Next",
        isNextDisabled: Bool = false,
        isBackDisabled: Bool = false
    ) {
        self.onBack = onBack
        self.onNext = onNext
        self.nextLabel = nextLabel
        self.isNextDisabled = isNextDisabled
        self.isBackDisabled = isBackDisabled
    }

    var body: some View {
        VStack(spacing: 10) {
            Button(action: onNext) {
                Text(nextLabel)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(themeManager.theme.accent)
            .disabled(isNextDisabled)

            Button(action: onBack) {
                Text("Back")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(themeManager.theme.textSecondary)
            .disabled(isBackDisabled)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
