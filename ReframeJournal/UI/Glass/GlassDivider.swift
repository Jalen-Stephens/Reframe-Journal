// Purpose: Subtle divider that matches glass surfaces.
import SwiftUI

struct GlassDivider: View {
    @Environment(\.notesPalette) private var notesPalette

    var body: some View {
        Rectangle()
            .fill(notesPalette.separator.opacity(0.6))
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}
