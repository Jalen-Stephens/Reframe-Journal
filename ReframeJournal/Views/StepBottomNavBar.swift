import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct StepBottomNavBar: View {
    @Environment(\.notesPalette) private var notesPalette
    @State private var isKeyboardVisible = false

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
        Group {
            if !isKeyboardVisible {
                VStack(spacing: 10) {
                    Button(action: onNext) {
                        Text(nextLabel)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(notesPalette.accent)
                    .disabled(isNextDisabled)

                    Button(action: onBack) {
                        Text("Back")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(notesPalette.textSecondary)
                    .disabled(isBackDisabled)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(notesPalette.background)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
    }
}
