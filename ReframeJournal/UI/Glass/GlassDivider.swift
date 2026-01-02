// Purpose: Subtle divider that matches glass surfaces.
import SwiftUI

struct GlassDivider: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Rectangle()
            .fill(AppTheme.glassBorderColor(for: colorScheme).opacity(colorScheme == .dark ? 0.5 : 0.35))
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}
