// Purpose: Liquid glass-inspired background gradient for screens.
import SwiftUI

struct GlassBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(.systemBackground)

            LinearGradient(
                colors: [
                    Color.blue.opacity(colorScheme == .dark ? 0.22 : 0.12),
                    Color.mint.opacity(colorScheme == .dark ? 0.18 : 0.1),
                    Color.teal.opacity(colorScheme == .dark ? 0.14 : 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.12 : 0.4),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 260
            )
        }
        .ignoresSafeArea()
    }
}
