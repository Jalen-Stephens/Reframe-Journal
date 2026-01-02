// Purpose: Section header style for liquid glass forms.
import SwiftUI

struct GlassSectionHeader: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .kerning(0.8)
    }
}
