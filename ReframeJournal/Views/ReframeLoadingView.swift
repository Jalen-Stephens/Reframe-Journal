import SwiftUI

struct ReframeLoadingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.notesPalette) private var notesPalette
    @State private var isAnimating = false

    let message: String
    let showsProgress: Bool

    init(
        message: String = "Taking a moment to reframe this thought...",
        showsProgress: Bool = true
    ) {
        self.message = message
        self.showsProgress = showsProgress
    }

    var body: some View {
        ZStack {
            notesPalette.background
                .ignoresSafeArea()

            GeometryReader { proxy in
                VStack(spacing: 16) {
                    Spacer(minLength: 24)

                    Image("nuggie_mascot_full") // Swap mascot art by replacing this asset.
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: min(300, proxy.size.width * 0.7))
                        .scaleEffect(reduceMotion ? 1.0 : (isAnimating ? 1.03 : 1.0))
                        .opacity(reduceMotion ? 1.0 : (isAnimating ? 1.0 : 0.85))
                        .animation(
                            reduceMotion ? .none : .easeInOut(duration: 2.6).repeatForever(autoreverses: true),
                            value: isAnimating
                        )

                    Text(message)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    if showsProgress {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.secondary)
                            .scaleEffect(0.9)
                    }

                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            isAnimating = true
        }
    }

}

struct ReframeLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ReframeLoadingView()
                .notesTheme()
                .previewDisplayName("Light")
            ReframeLoadingView()
                .preferredColorScheme(.dark)
                .notesTheme()
                .previewDisplayName("Dark")
        }
    }
}
