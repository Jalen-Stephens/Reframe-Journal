// Purpose: Section header style for liquid glass forms.
import SwiftUI

struct GlassSectionHeader: View {
    @Environment(\.notesPalette) private var notesPalette

    let text: String

    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(notesPalette.promptLabel)
            .kerning(0.8)
    }
}
