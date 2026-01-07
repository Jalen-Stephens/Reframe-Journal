// Purpose: Notes-style background base for screens.
import SwiftUI

struct GlassBackground: View {
    @Environment(\.notesPalette) private var notesPalette

    var body: some View {
        notesPalette.background
            .ignoresSafeArea()
    }
}
